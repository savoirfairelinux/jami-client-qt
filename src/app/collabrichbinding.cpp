/*
 * Copyright (C) 2026 Savoir-faire Linux Inc.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301 USA.
 */
#include "collabrichbinding.h"

#include <QQuickTextDocument>
#include <QTextDocument>
#include <QTextCursor>
#include <QTextCharFormat>
#include <QTextList>
#include <QTextBlock>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QColor>
#include <QGuiApplication>
#include <QClipboard>
#include <QTextImageFormat>
#include <QImage>
#include <QImageReader>
#include <QBuffer>
#include <QUrl>
#include <QTextLayout>
#include <QAbstractTextDocumentLayout>

namespace {

const QColor LINK_COLOR(0x1a, 0x73, 0xe8);
// Resource URL under which an attachment's bytes are registered with the
// document. The id is the git oid of the content, so the URL is stable across
// participants and two identical images share one entry.
const QString ATTACHMENT_URL_PREFIX = QStringLiteral("collab-attachment:");
// The character a QTextDocument shows for an inline object. One image occupies
// exactly one of these in toPlainText(), which is what keeps the shadow diff --
// and therefore every offset sent to the CRDT -- aligned. Verified by running it.
constexpr QChar OBJECT_REPLACEMENT = QChar(0xFFFC);
// Largest image this editor will decode, in pixels. The bytes are already
// capped, but nothing followed what they become: a 160 kB PNG of a single
// colour decodes to 187 MB of memory, on every replica that opens the document.
// That is measured, not supposed. The ceiling is deliberately generous -- it
// takes any photograph a camera produces -- because what matters here is that
// there is one at all.
constexpr qint64 MAX_DECODED_PIXELS = 32LL * 1024 * 1024;
// Widest an image may ever be drawn, whoever asked. A width arriving from a
// peer is not a request this replica has to honour.
constexpr int MAX_IMAGE_WIDTH = 4096;

// Attribute carrying an image's display width, in pixels. Only the width is
// ever set: the layout then scales the height itself, so a resize cannot
// distort the image and the two values can never contradict each other.
const QString IMAGE_WIDTH_ATTR = QStringLiteral("w");

// An image narrower than this cannot be grabbed again to be made larger.
constexpr int MIN_IMAGE_WIDTH = 24;
// Per-character property marking the list kind of the line (1 = bullet, 2 =
// ordered). Stored on the character format so it travels with the text and is
// inherited by typed characters; QTextList membership is rebuilt from it.
constexpr int LIST_PROPERTY = QTextFormat::UserProperty + 1;

int
listTypeFromStyle(const QString& style)
{
    if (style == QLatin1String("bullet"))
        return 1;
    if (style == QLatin1String("ordered"))
        return 2;
    return 0;
}

// Inline formatting attributes carried by the document. Anchors (links) underline
// and colour the text, so plain underline is reported only for non-anchors.
QJsonObject
charFormatToAttrs(const QTextCharFormat& f)
{
    QJsonObject a;
    if (f.fontWeight() >= QFont::Bold)
        a[QStringLiteral("b")] = true;
    if (f.fontItalic())
        a[QStringLiteral("i")] = true;
    if (f.isAnchor()) {
        a[QStringLiteral("link")] = f.anchorHref();
    } else if (f.fontUnderline()) {
        a[QStringLiteral("u")] = true;
    }
    if (f.fontStrikeOut())
        a[QStringLiteral("s")] = true;
    // Headings are stored as a per-line character attribute rendered through the
    // font size adjustment (H1 = +3, H2 = +2, H3 = +1), exactly as Qt renders the
    // HTML <h1>..<h3> tags. This avoids the Quill trailing-newline invariant.
    if (f.hasProperty(QTextFormat::FontSizeAdjustment)) {
        const int adj = f.intProperty(QTextFormat::FontSizeAdjustment);
        if (adj >= 1 && adj <= 3)
            a[QStringLiteral("header")] = 4 - adj;
    }
    if (f.hasProperty(LIST_PROPERTY)) {
        const int t = f.intProperty(LIST_PROPERTY);
        if (t == 1)
            a[QStringLiteral("list")] = QStringLiteral("bullet");
        else if (t == 2)
            a[QStringLiteral("list")] = QStringLiteral("ordered");
    }
    return a;
}

// A link reaches us either from the local UI or from a peer's delta, as an
// arbitrary string, and it ends up in a document that can be copied out to any
// application. Only schemes that address a document are kept: "javascript:"
// executes, while "file:" and "data:" address the local machine. An empty return
// means the text stays, without the link.
QString
sanitizedHref(const QString& href)
{
    const QString trimmed = href.trimmed();
    if (trimmed.isEmpty())
        return {};
    // fromUserInput() also turns "www.example.com" into a proper https URL, which
    // is what a user typing in the link field expects.
    const QUrl url = QUrl::fromUserInput(trimmed);
    if (!url.isValid())
        return {};
    const QString scheme = url.scheme().toLower();
    if (scheme != QLatin1String("http") && scheme != QLatin1String("https") && scheme != QLatin1String("mailto"))
        return {};
    return url.toString();
}

// Build a QTextCharFormat that, when *merged* over a range, sets exactly the
// properties named in @p attrs (a true/href value applies, a null value clears).
QTextCharFormat
mergeFormatFromAttrs(const QJsonObject& attrs)
{
    QTextCharFormat f;
    for (auto it = attrs.begin(); it != attrs.end(); ++it) {
        const QString& key = it.key();
        const QJsonValue v = it.value();
        const bool on = v.isBool() ? v.toBool() : (v.isString() ? !v.toString().isEmpty() : false);
        if (key == QLatin1String("b"))
            f.setFontWeight(on ? QFont::Bold : QFont::Normal);
        else if (key == QLatin1String("i"))
            f.setFontItalic(on);
        else if (key == QLatin1String("u"))
            f.setFontUnderline(on);
        else if (key == QLatin1String("s"))
            f.setFontStrikeOut(on);
        else if (key == QLatin1String("header")) {
            const int level = v.isDouble() ? v.toInt() : 0;
            // Headings adjust only the font size (no bold), so they don't fight the
            // independent "b" attribute.
            f.setProperty(QTextFormat::FontSizeAdjustment, (level >= 1 && level <= 3) ? (4 - level) : 0);
        } else if (key == QLatin1String("list")) {
            f.setProperty(LIST_PROPERTY, listTypeFromStyle(v.isString() ? v.toString() : QString()));
        } else if (key == QLatin1String("link")) {
            const QString href = on ? sanitizedHref(v.toString()) : QString();
            if (!href.isEmpty()) {
                f.setAnchor(true);
                f.setAnchorHref(href);
                f.setForeground(LINK_COLOR);
                f.setFontUnderline(true);
            } else {
                f.setAnchor(false);
                f.setAnchorHref(QString());
                f.clearForeground();
                f.setFontUnderline(false);
            }
        }
    }
    return f;
}

// Inline attributes of the character at @p index (charFormat() reports the format
// of the character preceding the cursor, hence index + 1).
QJsonObject
charAttrsAt(QTextDocument* d, int index)
{
    QTextCursor c(d);
    c.setPosition(index + 1);
    return charFormatToAttrs(c.charFormat());
}

// The embed the character at @p index stands for, as the object a delta carries,
// or an empty object if that character is not an inline image this binding put
// there.
QJsonObject
embedAt(QTextDocument* d, int index)
{
    QTextCursor c(d);
    c.setPosition(index + 1);
    const QTextCharFormat f = c.charFormat();
    if (!f.isImageFormat())
        return {};
    const QTextImageFormat img = f.toImageFormat();
    if (!img.name().startsWith(ATTACHMENT_URL_PREFIX))
        return {};
    // Identity only. Everything that can be changed afterwards is an attribute.
    QJsonObject ref {{QStringLiteral("id"), img.name().mid(ATTACHMENT_URL_PREFIX.size())}};
    return QJsonObject {{QStringLiteral("image"), ref}};
}

// The formatting attributes of the embed at unit @p index.
QJsonObject
imageAttrsAt(QTextDocument* d, int index)
{
    QTextCursor c(d);
    c.setPosition(index + 1);
    const QTextCharFormat f = c.charFormat();
    if (!f.isImageFormat())
        return {};
    const QTextImageFormat img = f.toImageFormat();
    QJsonObject attrs;
    if (img.width() > 0)
        attrs[IMAGE_WIDTH_ATTR] = static_cast<int>(img.width());
    return attrs;
}

// Gives the image at unit @p index a display width. Applied as a whole format
// rather than merged, because a height inherited from an older document has to
// go: kept alongside a new width it would stretch the image out of shape.
//
// @return whether there was an image there to resize.
bool
setImageWidthAt(QTextDocument* d, int index, int width)
{
    QTextCursor c(d);
    c.setPosition(index + 1);
    const QTextCharFormat f = c.charFormat();
    if (!f.isImageFormat())
        return false;
    QTextImageFormat img = f.toImageFormat();
    if (!img.name().startsWith(ATTACHMENT_URL_PREFIX))
        return false;
    img.setWidth(width);
    img.clearProperty(QTextFormat::ImageHeight);
    c.setPosition(index);
    c.setPosition(index + 1, QTextCursor::KeepAnchor);
    c.setCharFormat(img);
    return true;
}

// Whether @p id can name an attachment at all. Same shape as the daemon's own
// check: an attachment id is the hexadecimal git oid of its content. Anything
// else is refused before it is ever turned into a URL.
bool
isAttachmentId(const QString& id)
{
    if (id.size() != 40)
        return false;
    for (const QChar c : id)
        if (!isxdigit(c.toLatin1()))
            return false;
    return true;
}

// Drawn in place of an image whose bytes have not arrived yet.
//
// Registered as soon as the reference is met, and not merely left missing: an
// unresolved resource sends the layout looking for it, network included. There
// is nothing useful at the other end of a collab-attachment: URL, and an editor
// must not emit a request because of what a peer wrote in a document.
QImage
placeholderImage()
{
    static const QImage img = [] {
        QImage i(160, 120, QImage::Format_ARGB32);
        i.fill(QColor(0xE0, 0xE0, 0xE0));
        return i;
    }();
    return img;
}

// The image format an embed asks for.
//
// The display width lives in the attributes, not in the embed: an embed is
// immutable in the CRDT, so resizing one would mean deleting it and inserting
// another -- and two participants resizing at once would then each keep their
// own copy, leaving two images where there was one. An attribute is changed in
// place, and converges the way bold does.
//
// @p attrs wins over the embed, which is only read so that documents written
// before the width moved out of it still open at the size they were given.
QTextImageFormat
imageFormatFromEmbed(const QJsonObject& embed, const QJsonObject& attrs = {})
{
    const QJsonObject ref = embed.value(QStringLiteral("image")).toObject();
    QTextImageFormat img;
    img.setName(ATTACHMENT_URL_PREFIX + ref.value(QStringLiteral("id")).toString());

    // Bounded, both of them: these numbers were written by whoever produced the
    // embed. A width of two billion is not a request this replica has to honour,
    // it is a way to make the document unusable for everyone who opens it.
    if (const int w = ref.value(QStringLiteral("width")).toInt(); w > 0)
        img.setWidth(qMin(w, MAX_IMAGE_WIDTH));
    if (const int h = ref.value(QStringLiteral("height")).toInt(); h > 0)
        img.setHeight(qMin(h, MAX_IMAGE_WIDTH));
    if (const int w = attrs.value(IMAGE_WIDTH_ATTR).toInt(); w > 0) {
        img.setWidth(qBound(MIN_IMAGE_WIDTH, w, MAX_IMAGE_WIDTH));
        // Width alone, so the layout keeps the image's own aspect ratio. A height
        // left over from the embed would fight it and squash the image.
        img.clearProperty(QTextFormat::ImageHeight);
    }
    return img;
}

// The size an image is drawn at, from its format and its own pixel size.
QSizeF
imageDisplaySize(QTextDocument* d, const QTextImageFormat& img)
{
    const QImage src = qvariant_cast<QImage>(d->resource(QTextDocument::ImageResource, QUrl(img.name())));
    const QSizeF natural = src.isNull() ? QSizeF(0, 0) : QSizeF(src.size());
    const qreal w = img.width();
    const qreal h = img.height();
    if (w > 0 && h > 0)
        return QSizeF(w, h);
    if (w > 0)
        return QSizeF(w, natural.width() > 0 ? w * natural.height() / natural.width() : w);
    if (h > 0)
        return QSizeF(natural.height() > 0 ? h * natural.width() / natural.height() : h, h);
    return natural;
}

// Where the image at unit @p index is drawn, in document coordinates. Null
// rectangle if that unit is not an attachment image.
QRectF
imageRectAt(QTextDocument* d, int index)
{
    QTextCursor c(d);
    c.setPosition(index + 1);
    const QTextCharFormat f = c.charFormat();
    if (!f.isImageFormat())
        return {};
    const QTextImageFormat img = f.toImageFormat();
    if (!img.name().startsWith(ATTACHMENT_URL_PREFIX))
        return {};
    const QTextBlock blk = d->findBlock(index);
    if (!blk.isValid() || !blk.layout())
        return {};
    const QTextLine line = blk.layout()->lineForTextPosition(index - blk.position());
    if (!line.isValid())
        return {};
    const QRectF blockRect = d->documentLayout()->blockBoundingRect(blk);
    const QSizeF size = imageDisplaySize(d, img);
    const qreal left = blockRect.left() + line.cursorToX(index - blk.position());
    // An inline image sits on the baseline, so its top is as far above the
    // bottom of the line as it is tall.
    const qreal top = blockRect.top() + line.y() + line.height() - size.height();
    return QRectF(left, top, size.width(), size.height());
}

// Units holding an attachment image, in document order.
QList<int>
imageUnits(QTextDocument* d)
{
    QList<int> units;
    for (QTextBlock blk = d->begin(); blk.isValid(); blk = blk.next()) {
        for (auto it = blk.begin(); it != blk.end(); ++it) {
            const QTextFragment frag = it.fragment();
            if (!frag.isValid() || !frag.charFormat().isImageFormat())
                continue;
            if (!frag.charFormat().toImageFormat().name().startsWith(ATTACHMENT_URL_PREFIX))
                continue;
            // A fragment can gather several images sharing one format.
            for (int u = 0; u < frag.length(); ++u)
                units.append(frag.position() + u);
        }
    }
    return units;
}

// List kind (0/1/2) of a block, read from its first character's list attribute.
int
blockListType(const QTextBlock& blk)
{
    auto it = blk.begin();
    if (it != blk.end()) {
        const QTextCharFormat f = it.fragment().charFormat();
        if (f.hasProperty(LIST_PROPERTY))
            return f.intProperty(LIST_PROPERTY);
    }
    return 0;
}

} // namespace

CollabRichBinding::CollabRichBinding(QObject* parent)
    : QObject(parent)
{}

QQuickTextDocument*
CollabRichBinding::textDocument() const
{
    return quickDoc_;
}

QTextDocument*
CollabRichBinding::doc() const
{
    return quickDoc_ ? quickDoc_->textDocument() : nullptr;
}

void
CollabRichBinding::setTextDocument(QQuickTextDocument* doc)
{
    if (quickDoc_ == doc)
        return;
    if (auto* d = this->doc())
        disconnect(d, nullptr, this, nullptr);
    quickDoc_ = doc;
    if (auto* d = this->doc()) {
        shadow_ = d->toPlainText();
        connect(d, &QTextDocument::contentsChange, this, &CollabRichBinding::onContentsChange, Qt::UniqueConnection);
    }
    Q_EMIT textDocumentChanged();
}

void
CollabRichBinding::reconcileLists()
{
    QTextDocument* d = doc();
    if (!d)
        return;
    QTextList* currentList = nullptr;
    int currentType = 0;
    for (QTextBlock blk = d->begin(); blk.isValid(); blk = blk.next()) {
        const int t = blockListType(blk);
        if (t == 0) {
            if (QTextList* l = blk.textList())
                l->remove(blk);
            currentList = nullptr;
            currentType = 0;
        } else if (currentList && currentType == t) {
            currentList->add(blk);
        } else {
            QTextCursor cc(blk);
            QTextListFormat lf;
            lf.setStyle(t == 1 ? QTextListFormat::ListDisc : QTextListFormat::ListDecimal);
            currentList = cc.createList(lf);
            currentType = t;
        }
    }
}

void
CollabRichBinding::onContentsChange(int /*position*/, int /*charsRemoved*/, int /*charsAdded*/)
{
    if (applyingRemote_)
        return;
    QTextDocument* d = doc();
    if (!d)
        return;

    // Trust neither the reported counts (they include the document's implicit
    // final block, which the CRDT does not have) nor a single contiguous edit:
    // diff the current plain text against a shadow kept equal to the CRDT content.
    // The resulting positions therefore always map onto the CRDT, so the daemon's
    // ytext_* never receives an out-of-range index.
    const QString now = d->toPlainText();
    if (now == shadow_)
        return; // a format-only change (no text change); handled by the toolbar ops

    const int oldLen = shadow_.size();
    const int newLen = now.size();
    int prefix = 0;
    const int maxPrefix = qMin(oldLen, newLen);
    while (prefix < maxPrefix && shadow_.at(prefix) == now.at(prefix))
        ++prefix;
    int suffix = 0;
    const int maxSuffix = qMin(oldLen, newLen) - prefix;
    while (suffix < maxSuffix && shadow_.at(oldLen - 1 - suffix) == now.at(newLen - 1 - suffix))
        ++suffix;

    const int removed = oldLen - prefix - suffix;
    const int added = newLen - prefix - suffix;

    QJsonArray ops;
    if (prefix > 0)
        ops.append(QJsonObject {{QStringLiteral("retain"), prefix}});
    if (removed > 0)
        ops.append(QJsonObject {{QStringLiteral("delete"), removed}});
    if (added > 0) {
        const QString text = now.mid(prefix, added);
        // Group consecutive characters sharing the same inline attributes into runs.
        int i = 0;
        while (i < text.size()) {
            if (text.at(i) == OBJECT_REPLACEMENT) {
                // An inline object. It counts as exactly one unit either way: if
                // we cannot name it we still send one character rather than drop
                // it, because a length the CRDT does not share is what makes a
                // later edit land out of range.
                const QJsonObject embed = embedAt(d, prefix + i);
                if (embed.isEmpty()) {
                    ops.append(QJsonObject {{QStringLiteral("insert"), QString(OBJECT_REPLACEMENT)}});
                } else {
                    QJsonObject op {{QStringLiteral("insert"), embed}};
                    if (const QJsonObject a = imageAttrsAt(d, prefix + i); !a.isEmpty())
                        op[QStringLiteral("attributes")] = a;
                    ops.append(op);
                }
                ++i;
                continue;
            }
            const QJsonObject a = charAttrsAt(d, prefix + i);
            int j = i + 1;
            while (j < text.size() && text.at(j) != OBJECT_REPLACEMENT && charAttrsAt(d, prefix + j) == a)
                ++j;
            QJsonObject op {{QStringLiteral("insert"), text.mid(i, j - i)}};
            if (!a.isEmpty())
                op[QStringLiteral("attributes")] = a;
            ops.append(op);
            i = j;
        }
    }
    shadow_ = now;
    if (!ops.isEmpty())
        Q_EMIT localDelta(QString::fromUtf8(QJsonDocument(ops).toJson(QJsonDocument::Compact)));
}

void
CollabRichBinding::loadContentDelta(const QString& deltaJson)
{
    QTextDocument* d = doc();
    if (!d)
        return;
    // This carries the whole document, not a change to it. Applying it as a delta
    // would append a second copy of the content to whatever the editor already
    // shows -- which happens whenever a window is reused, or the document is
    // reloaded after a restore.
    applyingRemote_ = true;
    d->clear();
    shadow_.clear();
    applyingRemote_ = false;
    applyRemoteDelta(deltaJson);
}

void
CollabRichBinding::applyRemoteDelta(const QString& deltaJson)
{
    QTextDocument* d = doc();
    if (!d)
        return;
    const QJsonDocument jd = QJsonDocument::fromJson(deltaJson.toUtf8());
    if (!jd.isArray())
        return;
    const QJsonArray ops = jd.array();

    applyingRemote_ = true;
    QTextCursor c(d);
    int index = 0;
    for (const auto& v : ops) {
        const int docLen = d->characterCount() - 1; // exclude the implicit final block
        const QJsonObject op = v.toObject();
        if (op.contains(QStringLiteral("insert")) && op.value(QStringLiteral("insert")).isString()) {
            const QString text = op.value(QStringLiteral("insert")).toString();
            const QJsonObject attrs = op.value(QStringLiteral("attributes")).toObject();
            c.setPosition(qBound(0, index, docLen));
            c.insertText(text, mergeFormatFromAttrs(attrs));
            index += text.size();
        } else if (op.contains(QStringLiteral("insert")) && op.value(QStringLiteral("insert")).isObject()) {
            const QJsonObject embed = op.value(QStringLiteral("insert")).toObject();
            const QJsonObject attrs = op.value(QStringLiteral("attributes")).toObject();
            c.setPosition(qBound(0, index, docLen));
            const QString id = embed.value(QStringLiteral("image")).toObject().value(QStringLiteral("id")).toString();
            if (isAttachmentId(id)) {
                const QUrl url(ATTACHMENT_URL_PREFIX + id);
                if (!d->resource(QTextDocument::ImageResource, url).isValid()) {
                    // Put there before the image is, so the layout never goes
                    // looking for a resource that is missing.
                    d->addResource(QTextDocument::ImageResource, url, placeholderImage());
                    pendingAttachments_.insert(id);
                }
                c.insertImage(imageFormatFromEmbed(embed, attrs));
            } else {
                // An embed of a kind this editor does not render. It still has to
                // occupy one unit, or every later offset would be off by one.
                c.insertText(QString(OBJECT_REPLACEMENT));
            }
            index += 1;
        } else if (op.contains(QStringLiteral("retain"))) {
            const int n = op.value(QStringLiteral("retain")).toInt();
            const QJsonObject attrs = op.value(QStringLiteral("attributes")).toObject();
            if (!attrs.isEmpty() && n > 0) {
                QTextCursor cc(d);
                cc.setPosition(qBound(0, index, docLen));
                cc.setPosition(qBound(0, index + n, docLen), QTextCursor::KeepAnchor);
                cc.mergeCharFormat(mergeFormatFromAttrs(attrs));
                // Width is set whole rather than merged, so it is applied on its
                // own, unit by unit -- the range is one image in practice. The
                // number comes from a peer, so it is bounded the same way a
                // locally dragged one is; the editor obeys the document, it does
                // not obey whoever wrote it.
                if (const int w = attrs.value(IMAGE_WIDTH_ATTR).toInt(); w > 0) {
                    const int bounded = qBound(MIN_IMAGE_WIDTH, w, MAX_IMAGE_WIDTH);
                    const int last = qMin(index + n, docLen);
                    for (int u = qMax(0, index); u < last; ++u)
                        setImageWidthAt(d, u, bounded);
                }
            }
            index += n;
        } else if (op.contains(QStringLiteral("delete"))) {
            const int n = op.value(QStringLiteral("delete")).toInt();
            if (n > 0) {
                c.setPosition(qBound(0, index, docLen));
                c.setPosition(qBound(0, index + n, docLen), QTextCursor::KeepAnchor);
                c.removeSelectedText();
            }
        }
    }
    // Rebuild list blocks from the per-character attributes just applied.
    reconcileLists();
    applyingRemote_ = false;
    // Keep the shadow equal to the (converged) content so local diffs stay aligned.
    shadow_ = d->toPlainText();

    // Asked for after the document is consistent, never from inside the loop: a
    // handler that answered straight away would edit a half-applied document.
    const auto wanted = pendingAttachments_;
    pendingAttachments_.clear();
    for (const auto& id : wanted)
        Q_EMIT attachmentNeeded(id);
}

void
CollabRichBinding::insertImage(int position, const QString& id, int width, int height)
{
    QTextDocument* d = doc();
    if (!d || !isAttachmentId(id))
        return;
    QJsonObject ref {{QStringLiteral("id"), id}};
    QJsonObject attrs;
    if (width > 0)
        attrs[IMAGE_WIDTH_ATTR] = width;
    Q_UNUSED(height) // the layout scales the height from the width
    // Deliberately not guarded by applyingRemote_: this is a local edit, and the
    // delta it produces is the one that tells the other participants about it.
    const QUrl url(ATTACHMENT_URL_PREFIX + id);
    if (!d->resource(QTextDocument::ImageResource, url).isValid())
        d->addResource(QTextDocument::ImageResource, url, placeholderImage());
    QTextCursor c(d);
    c.setPosition(qBound(0, position, d->characterCount() - 1));
    c.insertImage(imageFormatFromEmbed(QJsonObject {{QStringLiteral("image"), ref}}, attrs));
}

QImage
CollabRichBinding::decodeBounded(const QByteArray& data)
{
    if (data.isEmpty())
        return {};
    QBuffer buffer;
    buffer.setData(data);
    if (!buffer.open(QIODevice::ReadOnly))
        return {};
    QImageReader reader(&buffer);
    // From the content, never from a name: a suffix is not evidence of anything.
    const QSize size = reader.size();
    if (!size.isValid() || size.isEmpty())
        return {};
    if (qint64(size.width()) * qint64(size.height()) > MAX_DECODED_PIXELS)
        return {};
    return reader.read();
}

void
CollabRichBinding::registerAttachment(const QString& id, const QByteArray& data)
{
    QTextDocument* d = doc();
    if (!d || !isAttachmentId(id))
        return;
    // Bounded: these bytes come from a peer, and an image is decoded on every
    // replica that opens the document, not only on the one that inserted it.
    const QImage image = decodeBounded(data);
    if (image.isNull())
        return; // not something this editor can draw; leave the placeholder
    d->addResource(QTextDocument::ImageResource, QUrl(ATTACHMENT_URL_PREFIX + id), image);

    // The layout measured this image while it was still the placeholder, so it
    // has to measure it again. markContentsDirty() alone does not do it: it
    // records the dirty range but only the end of an edit hands it to the
    // layout, so the editor kept showing the grey box until the next keystroke.
    // An empty edit block is that end of an edit, without changing the text --
    // so no delta is produced and the shadow stays valid.
    d->markContentsDirty(0, d->characterCount());
    QTextCursor c(d);
    c.beginEditBlock();
    c.endEditBlock();
}

bool
CollabRichBinding::referencesAttachment(const QString& id) const
{
    QTextDocument* d = doc();
    if (!d || id.isEmpty())
        return false;
    const QString url = ATTACHMENT_URL_PREFIX + id;
    for (QTextBlock blk = d->begin(); blk.isValid(); blk = blk.next())
        for (auto it = blk.begin(); it != blk.end(); ++it) {
            const QTextCharFormat f = it.fragment().charFormat();
            if (f.isImageFormat() && f.toImageFormat().name() == url)
                return true;
        }
    return false;
}

void
CollabRichBinding::toggleInline(const QString& attr, int start, int end)
{
    QTextDocument* d = doc();
    if (!d || start >= end)
        return;
    // Toggle based on the first character of the selection.
    const QJsonObject current = charAttrsAt(d, start);
    const bool isSet = current.contains(attr);
    QJsonObject attrs;
    attrs[attr] = isSet ? QJsonValue(QJsonValue::Null) : QJsonValue(true);

    applyingRemote_ = true;
    QTextCursor c(d);
    c.setPosition(start);
    c.setPosition(end, QTextCursor::KeepAnchor);
    c.mergeCharFormat(mergeFormatFromAttrs(attrs));
    applyingRemote_ = false;

    QJsonArray ops;
    if (start > 0)
        ops.append(QJsonObject {{QStringLiteral("retain"), start}});
    ops.append(QJsonObject {{QStringLiteral("retain"), end - start}, {QStringLiteral("attributes"), attrs}});
    Q_EMIT localDelta(QString::fromUtf8(QJsonDocument(ops).toJson(QJsonDocument::Compact)));
}

void
CollabRichBinding::setHeading(int level, int start, int end)
{
    QTextDocument* d = doc();
    if (!d)
        return;
    // Expand the selection to whole lines: a heading applies to entire paragraphs.
    QTextCursor a(d);
    a.setPosition(qMax(0, start));
    a.movePosition(QTextCursor::StartOfBlock);
    QTextCursor b(d);
    b.setPosition(qMax(start, end));
    b.movePosition(QTextCursor::EndOfBlock);
    const int lineStart = a.position();
    const int lineEnd = b.position();
    if (lineStart >= lineEnd)
        return; // empty line: nothing to format (type some text first)

    QJsonObject attrs;
    attrs[QStringLiteral("header")] = (level >= 1 && level <= 3) ? QJsonValue(level) : QJsonValue(QJsonValue::Null);

    applyingRemote_ = true;
    QTextCursor c(d);
    c.setPosition(lineStart);
    c.setPosition(lineEnd, QTextCursor::KeepAnchor);
    c.mergeCharFormat(mergeFormatFromAttrs(attrs));
    applyingRemote_ = false;

    QJsonArray ops;
    if (lineStart > 0)
        ops.append(QJsonObject {{QStringLiteral("retain"), lineStart}});
    ops.append(QJsonObject {{QStringLiteral("retain"), lineEnd - lineStart}, {QStringLiteral("attributes"), attrs}});
    Q_EMIT localDelta(QString::fromUtf8(QJsonDocument(ops).toJson(QJsonDocument::Compact)));
}

void
CollabRichBinding::setList(const QString& style, int start, int end)
{
    QTextDocument* d = doc();
    if (!d)
        return;
    // Lists are line-level: expand the selection to whole paragraphs.
    QTextCursor a(d);
    a.setPosition(qMax(0, start));
    a.movePosition(QTextCursor::StartOfBlock);
    QTextCursor b(d);
    b.setPosition(qMax(start, end));
    b.movePosition(QTextCursor::EndOfBlock);
    const int lineStart = a.position();
    const int lineEnd = b.position();
    if (lineStart >= lineEnd)
        return; // empty line: nothing to mark (type some text first)

    // Toggle: if the first line already has this style, remove it.
    const QString current = charAttrsAt(d, lineStart).value(QStringLiteral("list")).toString();
    const QString target = (current == style) ? QString() : style;

    QJsonObject attrs;
    attrs[QStringLiteral("list")] = target.isEmpty() ? QJsonValue(QJsonValue::Null) : QJsonValue(target);

    applyingRemote_ = true;
    QTextCursor c(d);
    c.setPosition(lineStart);
    c.setPosition(lineEnd, QTextCursor::KeepAnchor);
    c.mergeCharFormat(mergeFormatFromAttrs(attrs));
    reconcileLists();
    applyingRemote_ = false;

    QJsonArray ops;
    if (lineStart > 0)
        ops.append(QJsonObject {{QStringLiteral("retain"), lineStart}});
    ops.append(QJsonObject {{QStringLiteral("retain"), lineEnd - lineStart}, {QStringLiteral("attributes"), attrs}});
    Q_EMIT localDelta(QString::fromUtf8(QJsonDocument(ops).toJson(QJsonDocument::Compact)));
}

void
CollabRichBinding::pasteText(int start, int end)
{
    QTextDocument* d = doc();
    if (!d)
        return;
    const QString text = QGuiApplication::clipboard()->text();
    if (text.isEmpty() && start == end)
        return;
    // Insert as literal plain text (not interpreted as HTML), replacing any
    // selection. This goes through onContentsChange like a normal edit, so it
    // syncs; rich clipboard styling is intentionally dropped for consistency.
    QTextCursor c(d);
    c.setPosition(qMin(start, end));
    if (start != end) {
        c.setPosition(qMax(start, end), QTextCursor::KeepAnchor);
        c.removeSelectedText();
    }
    if (!text.isEmpty()) {
        QTextCharFormat plain;
        c.setCharFormat(plain);
        c.insertText(text, plain);
    }
}

void
CollabRichBinding::setLink(const QString& href, int start, int end)
{
    QTextDocument* d = doc();
    if (!d || start >= end)
        return;
    const QString safe = sanitizedHref(href);
    if (!href.trimmed().isEmpty() && safe.isEmpty()) {
        // Refuse rather than clear: clearing would drop a link the user already
        // had, as a side effect of typing an address we do not accept.
        qWarning() << "Refusing a collaborative link with an unsupported scheme";
        return;
    }
    QJsonObject attrs;
    attrs[QStringLiteral("link")] = safe.isEmpty() ? QJsonValue(QJsonValue::Null) : QJsonValue(safe);

    applyingRemote_ = true;
    QTextCursor c(d);
    c.setPosition(start);
    c.setPosition(end, QTextCursor::KeepAnchor);
    c.mergeCharFormat(mergeFormatFromAttrs(attrs));
    applyingRemote_ = false;

    QJsonArray ops;
    if (start > 0)
        ops.append(QJsonObject {{QStringLiteral("retain"), start}});
    ops.append(QJsonObject {{QStringLiteral("retain"), end - start}, {QStringLiteral("attributes"), attrs}});
    Q_EMIT localDelta(QString::fromUtf8(QJsonDocument(ops).toJson(QJsonDocument::Compact)));
}

void
CollabRichBinding::clearFormat(int start, int end)
{
    QTextDocument* d = doc();
    if (!d || start >= end)
        return;
    QJsonObject attrs {{QStringLiteral("b"), QJsonValue(QJsonValue::Null)},
                       {QStringLiteral("i"), QJsonValue(QJsonValue::Null)},
                       {QStringLiteral("u"), QJsonValue(QJsonValue::Null)},
                       {QStringLiteral("s"), QJsonValue(QJsonValue::Null)},
                       {QStringLiteral("link"), QJsonValue(QJsonValue::Null)}};

    applyingRemote_ = true;
    QTextCursor c(d);
    c.setPosition(start);
    c.setPosition(end, QTextCursor::KeepAnchor);
    c.mergeCharFormat(mergeFormatFromAttrs(attrs));
    applyingRemote_ = false;

    QJsonArray ops;
    if (start > 0)
        ops.append(QJsonObject {{QStringLiteral("retain"), start}});
    ops.append(QJsonObject {{QStringLiteral("retain"), end - start}, {QStringLiteral("attributes"), attrs}});
    Q_EMIT localDelta(QString::fromUtf8(QJsonDocument(ops).toJson(QJsonDocument::Compact)));
}

QVariantMap
CollabRichBinding::selectionFormat(int start, int end)
{
    QVariantMap result;
    QTextDocument* d = doc();
    if (!d)
        return result;
    // Report formatting of the character at the caret/selection start.
    const QJsonObject a = charAttrsAt(d, start);
    result[QStringLiteral("b")] = a.contains(QStringLiteral("b"));
    result[QStringLiteral("i")] = a.contains(QStringLiteral("i"));
    result[QStringLiteral("u")] = a.contains(QStringLiteral("u"));
    result[QStringLiteral("s")] = a.contains(QStringLiteral("s"));
    result[QStringLiteral("link")] = a.value(QStringLiteral("link")).toString();
    result[QStringLiteral("header")] = a.contains(QStringLiteral("header")) ? a.value(QStringLiteral("header")).toInt()
                                                                            : 0;
    result[QStringLiteral("list")] = a.value(QStringLiteral("list")).toString();
    return result;
}

QVariantMap
CollabRichBinding::imageInfoAt(int index) const
{
    QTextDocument* d = doc();
    if (!d || index < 0)
        return {};
    const QRectF r = imageRectAt(d, index);
    if (r.isNull())
        return {};
    QTextCursor c(d);
    c.setPosition(index + 1);
    const QTextImageFormat img = c.charFormat().toImageFormat();
    const QImage src = qvariant_cast<QImage>(d->resource(QTextDocument::ImageResource, QUrl(img.name())));
    return QVariantMap {{QStringLiteral("index"), index},
                        {QStringLiteral("x"), r.x()},
                        {QStringLiteral("y"), r.y()},
                        {QStringLiteral("width"), r.width()},
                        {QStringLiteral("height"), r.height()},
                        {QStringLiteral("naturalWidth"), src.width()},
                        {QStringLiteral("naturalHeight"), src.height()},
                        {QStringLiteral("minWidth"), MIN_IMAGE_WIDTH},
                        {QStringLiteral("maxWidth"), maxImageWidth()}};
}

int
CollabRichBinding::imageAtPoint(qreal x, qreal y) const
{
    QTextDocument* d = doc();
    if (!d)
        return -1;
    const QPointF p(x, y);
    // Walked in document order and answered on the first hit: images do not
    // overlap, so there is nothing to arbitrate.
    for (const int u : imageUnits(d)) {
        if (imageRectAt(d, u).contains(p))
            return u;
    }
    return -1;
}

void
CollabRichBinding::setViewWidth(int width)
{
    if (viewWidth_ == width)
        return;
    viewWidth_ = width;
    Q_EMIT viewWidthChanged();
}

int
CollabRichBinding::maxImageWidth() const
{
    // Before the editor has a width, the bound is only there to keep a slip of
    // the hand from producing something enormous.
    return viewWidth_ > MIN_IMAGE_WIDTH ? qMin(viewWidth_, MAX_IMAGE_WIDTH) : MAX_IMAGE_WIDTH;
}

int
CollabRichBinding::previewImageWidth(int index, int width)
{
    QTextDocument* d = doc();
    if (!d || index < 0)
        return 0;
    const int w = qBound(MIN_IMAGE_WIDTH, width, maxImageWidth());
    // Guarded like any other local formatting: the text does not change, so no
    // delta is due, and none must be inferred from the layout moving.
    applyingRemote_ = true;
    const bool done = setImageWidthAt(d, index, w);
    applyingRemote_ = false;
    return done ? w : 0;
}

void
CollabRichBinding::setImageWidth(int index, int width)
{
    const int w = previewImageWidth(index, width);
    if (w <= 0)
        return;
    QJsonArray ops;
    if (index > 0)
        ops.append(QJsonObject {{QStringLiteral("retain"), index}});
    ops.append(QJsonObject {{QStringLiteral("retain"), 1},
                            {QStringLiteral("attributes"), QJsonObject {{IMAGE_WIDTH_ATTR, w}}}});
    Q_EMIT localDelta(QString::fromUtf8(QJsonDocument(ops).toJson(QJsonDocument::Compact)));
}
