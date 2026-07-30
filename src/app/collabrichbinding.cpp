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
#include <QMimeData>
#include <QVariantMap>
#include <QFile>
#include <QFileInfo>
#include <QTextLayout>
#include <QAbstractTextDocumentLayout>
#include <QTextDocumentWriter>
#include <QPdfWriter>
#include <QPageSize>
#include <QMarginsF>
#include <memory>

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

// Paragraph alignment, held on the characters of the line for the same reason
// lists are: the CRDT only knows about units of text and their attributes, it
// has no notion of a paragraph. The block format is rebuilt from it afterwards.
// 0 left (the default, never stored), 1 centre, 2 right, 3 justified.
constexpr int ALIGN_PROPERTY = QTextFormat::UserProperty + 2;

// 0 left, 1 centre, 2 right, 3 justified -- and back.
int
alignTypeFromStyle(const QString& style)
{
    if (style == QLatin1String("center"))
        return 1;
    if (style == QLatin1String("right"))
        return 2;
    if (style == QLatin1String("justify"))
        return 3;
    return 0;
}

Qt::Alignment
alignmentFromType(int type)
{
    if (type == 1)
        return Qt::AlignHCenter;
    if (type == 2)
        return Qt::AlignRight;
    if (type == 3)
        return Qt::AlignJustify;
    return Qt::AlignLeft;
}

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
    // Left is the default, so it is never written: a document says what departs
    // from the ordinary, and nothing more.
    if (f.hasProperty(ALIGN_PROPERTY)) {
        const int t = f.intProperty(ALIGN_PROPERTY);
        if (t == 1)
            a[QStringLiteral("align")] = QStringLiteral("center");
        else if (t == 2)
            a[QStringLiteral("align")] = QStringLiteral("right");
        else if (t == 3)
            a[QStringLiteral("align")] = QStringLiteral("justify");
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
        } else if (key == QLatin1String("align")) {
            f.setProperty(ALIGN_PROPERTY, alignTypeFromStyle(v.isString() ? v.toString() : QString()));
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

// The attributes of the first character of the paragraph @p index falls in.
//
// Alignment, headings and lists are paragraph-wide, and every character of the
// line carries them, so the first one answers for the whole of it. Asking at the
// caret instead answers for the *next* paragraph whenever the caret sits at the
// end of a line, which is exactly where it is left after typing one.
QJsonObject
blockAttrsAt(QTextDocument* d, int index)
{
    const QTextBlock blk = d->findBlock(qBound(0, index, d->characterCount() - 1));
    if (!blk.isValid())
        return {};
    auto it = blk.begin();
    if (it == blk.end())
        return {};
    return charFormatToAttrs(it.fragment().charFormat());
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

// Alignment kind (0/1/2/3) of a block, read from its first character.
int
blockAlignType(const QTextBlock& blk)
{
    auto it = blk.begin();
    if (it != blk.end()) {
        const QTextCharFormat f = it.fragment().charFormat();
        if (f.hasProperty(ALIGN_PROPERTY))
            return f.intProperty(ALIGN_PROPERTY);
    }
    return 0;
}

// Whether a block holds an image this binding put there.
bool
blockHasAttachmentImage(const QTextBlock& blk)
{
    for (auto it = blk.begin(); it != blk.end(); ++it) {
        const QTextFragment frag = it.fragment();
        if (!frag.isValid() || !frag.charFormat().isImageFormat())
            continue;
        if (frag.charFormat().toImageFormat().name().startsWith(ATTACHMENT_URL_PREFIX))
            return true;
    }
    return false;
}

// Aligns a paragraph holding an image, which Qt cannot be asked to do.
//
// Qt lays such a paragraph out correctly but draws the image at the left edge of
// its line whatever the alignment says: the image node is placed from
// QTextLine::position(), which -- unlike the glyph positions and cursorToX() --
// leaves the alignment offset out. A centred image therefore stayed on the left
// while the selection frame, computed from cursorToX(), sat in the right place.
//
// So the paragraph is laid out flush left and pushed across with a left margin
// instead, which leaves Qt nothing to ignore: image and text are moved by the
// very same offset. One offset can only stand for a whole paragraph while it
// occupies a single line, so wrapped ones are left to Qt.
void
placeAlignedImageBlock(QTextDocument* d, const QTextBlock& blk, int type)
{
    QTextBlockFormat bf = blk.blockFormat();
    qreal margin = 0;
    // Justified is not centre or right, and a lone line is never stretched.
    if (type == 1 || type == 2) {
        // The line has to be measured, so it has to have been laid out.
        d->documentLayout()->blockBoundingRect(blk);
        const QTextLayout* layout = blk.layout();
        if (layout && layout->lineCount() == 1) {
            const QTextLine line = layout->lineAt(0);
            // A margin already in place is part of the room the paragraph has.
            const qreal room = line.width() + bf.leftMargin() - line.naturalTextWidth();
            if (room > 0)
                margin = type == 1 ? room / 2 : room;
        }
    }
    // Sub-pixel differences are not worth a relayout, and rewriting a block
    // format for nothing reports an edit on every paragraph of the document.
    if (bf.alignment() == Qt::AlignLeft && qAbs(bf.leftMargin() - margin) < 0.5)
        return;
    bf.setAlignment(Qt::AlignLeft);
    bf.setLeftMargin(margin);
    QTextCursor cc(blk);
    cc.setBlockFormat(bf);
}

// A copy of the document fit to leave the editor: its pictures carry their own
// bytes and an explicit size, and the paragraphs holding them state their real
// alignment instead of the left margin the on-screen workaround needs.
std::unique_ptr<QTextDocument>
preparedForExport(QTextDocument* d, qreal maxWidth)
{
    std::unique_ptr<QTextDocument> copy(d->clone());
    struct Sized
    {
        int position;
        QTextImageFormat format;
    };
    QList<Sized> sized;
    QList<int> realigned;
    for (QTextBlock blk = copy->begin(); blk.isValid(); blk = blk.next()) {
        bool holdsPicture = false;
        for (auto it = blk.begin(); it != blk.end(); ++it) {
            const QTextFragment frag = it.fragment();
            const QTextCharFormat cf = frag.charFormat();
            if (!cf.isImageFormat())
                continue;
            QTextImageFormat img = cf.toImageFormat();
            if (!img.name().startsWith(ATTACHMENT_URL_PREFIX))
                continue;
            // Read from the living document: a clone is handed no resources of
            // its own, and the layout it inherits from the editor draws no
            // picture once it is off screen.
            const QImage src = qvariant_cast<QImage>(
                d->resource(QTextDocument::ImageResource, QUrl(img.name())));
            if (src.isNull() || src.width() <= 0 || src.height() <= 0)
                continue;
            holdsPicture = true;
            copy->addResource(QTextDocument::ImageResource, QUrl(img.name()), src);
            // Both sizes have to be stated: left without a height the ODF
            // writer falls back on the one in raw pixels, which is taller than
            // the page as soon as the picture is a large one.
            qreal w = img.hasProperty(QTextFormat::ImageWidth) ? img.width() : src.width();
            w = qBound(1.0, w, maxWidth);
            img.setWidth(w);
            img.setHeight(w * src.height() / src.width());
            sized.append({frag.position(), img});
        }
        if (holdsPicture)
            realigned.append(blk.position());
    }
    // Applied afterwards: rewriting a format under the iterators would leave
    // them pointing at fragments that no longer exist.
    for (const Sized& s : sized) {
        QTextCursor cur(copy.get());
        cur.setPosition(s.position);
        cur.setPosition(s.position + 1, QTextCursor::KeepAnchor);
        cur.setCharFormat(s.format);
    }
    for (int pos : realigned) {
        const QTextBlock blk = copy->findBlock(pos);
        if (!blk.isValid())
            continue;
        QTextBlockFormat bf = blk.blockFormat();
        bf.setAlignment(alignmentFromType(blockAlignType(blk)));
        bf.setLeftMargin(0);
        QTextCursor cur(blk);
        cur.setBlockFormat(bf);
    }
    return copy;
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
{
    if (QClipboard* clipboard = QGuiApplication::clipboard())
        connect(clipboard, &QClipboard::dataChanged, this, &CollabRichBinding::onClipboardChanged);
}

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

// Puts back on each paragraph the alignment its characters carry.
//
// Run after reconcileLists(): building a list rewrites the block format, and
// would undo an alignment set before it.
void
CollabRichBinding::reconcileAlignment()
{
    QTextDocument* d = doc();
    if (!d)
        return;
    for (QTextBlock blk = d->begin(); blk.isValid(); blk = blk.next()) {
        if (blk.text().isEmpty())
            continue; // no characters, so nothing said about it: leave it alone
        const int type = blockAlignType(blk);
        if (blockHasAttachmentImage(blk)) {
            placeAlignedImageBlock(d, blk, type);
            continue;
        }
        const Qt::Alignment wanted = alignmentFromType(type);
        // Rewriting a block format for nothing would report an edit on every
        // incoming delta, on every paragraph of the document.
        if (blk.blockFormat().alignment() == wanted && blk.blockFormat().leftMargin() == 0)
            continue;
        QTextBlockFormat bf = blk.blockFormat();
        bf.setAlignment(wanted);
        // A margin left over from an image this paragraph no longer holds.
        bf.setLeftMargin(0);
        QTextCursor cc(blk);
        cc.setBlockFormat(bf);
    }
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
    // Rebuild list blocks and paragraph alignment from the per-character
    // attributes just applied.
    reconcileLists();
    reconcileAlignment();
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
    // The paragraph it lands in may be centred or right aligned.
    reflowAlignedImages();
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
    // It was the placeholder that was measured, so an aligned image was placed
    // from the wrong width and has to be placed again.
    reflowAlignedImages();
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

int
CollabRichBinding::unresolvedImageCount() const
{
    QTextDocument* d = doc();
    if (!d)
        return 0;
    const QImage placeholder = placeholderImage();
    int count = 0;
    for (QTextBlock blk = d->begin(); blk.isValid(); blk = blk.next())
        for (auto it = blk.begin(); it != blk.end(); ++it) {
            const QTextCharFormat f = it.fragment().charFormat();
            if (!f.isImageFormat())
                continue;
            const QString name = f.toImageFormat().name();
            if (!name.startsWith(ATTACHMENT_URL_PREFIX))
                continue;
            // The placeholder is what stands in until the bytes arrive, so an
            // image still equal to it is one this replica cannot yet draw.
            const QImage img = qvariant_cast<QImage>(
                d->resource(QTextDocument::ImageResource, QUrl(name)));
            if (img.isNull() || img == placeholder)
                ++count;
        }
    return count;
}

bool
CollabRichBinding::exportToFile(const QUrl& file, const QString& title)
{
    QTextDocument* d = doc();
    if (!d)
        return false;
    const QString path = file.isLocalFile() ? file.toLocalFile() : file.toString();
    const QString suffix = QFileInfo(path).suffix().toLower();
    const bool odf = suffix == QLatin1String("odt");
    if (!odf && suffix != QLatin1String("pdf"))
        return false;

    // 640 pixels of picture width at the 96 dpi the document is measured in:
    // A4 less our own margins, and still inside the narrower text area a word
    // processor opens a document with.
    const std::unique_ptr<QTextDocument> copy = preparedForExport(d, 640.0);

    if (odf) {
        QTextDocumentWriter writer(path, "ODF");
        // ODF carries the pictures into the archive itself, so the file stands
        // on its own once it leaves this machine.
        return writer.write(copy.get());
    }

    // Opened here rather than left to QPdfWriter's own filename constructor,
    // which reports nothing when the path cannot be written.
    QFile target(path);
    if (!target.open(QIODevice::WriteOnly))
        return false;
    {
        QPdfWriter pdf(&target);
        pdf.setPageSize(QPageSize(QPageSize::A4));
        pdf.setPageMargins(QMarginsF(15, 15, 15, 15), QPageLayout::Millimeter);
        if (!title.isEmpty())
            pdf.setTitle(title);
        copy->print(&pdf);
    }
    const bool written = target.size() > 0;
    target.close();
    if (!written)
        QFile::remove(path);
    return written;
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
    reconcileAlignment();
    applyingRemote_ = false;

    QJsonArray ops;
    if (lineStart > 0)
        ops.append(QJsonObject {{QStringLiteral("retain"), lineStart}});
    ops.append(QJsonObject {{QStringLiteral("retain"), lineEnd - lineStart}, {QStringLiteral("attributes"), attrs}});
    Q_EMIT localDelta(QString::fromUtf8(QJsonDocument(ops).toJson(QJsonDocument::Compact)));
}

void
CollabRichBinding::setAlign(const QString& align, int start, int end)
{
    QTextDocument* d = doc();
    if (!d)
        return;
    // Alignment belongs to whole paragraphs, so the selection is widened to them.
    QTextCursor a(d);
    a.setPosition(qMax(0, start));
    a.movePosition(QTextCursor::StartOfBlock);
    QTextCursor b(d);
    b.setPosition(qMax(start, end));
    b.movePosition(QTextCursor::EndOfBlock);
    const int lineStart = a.position();
    const int lineEnd = b.position();
    if (lineStart >= lineEnd)
        return; // empty line: there is no character to hold the attribute

    // The four alignments exclude one another, so this is not a toggle. Left is
    // the default and clears the attribute rather than storing itself.
    const int type = alignTypeFromStyle(align);
    QJsonObject attrs;
    attrs[QStringLiteral("align")] = type == 0 ? QJsonValue(QJsonValue::Null) : QJsonValue(align);

    applyingRemote_ = true;
    QTextCursor c(d);
    c.setPosition(lineStart);
    c.setPosition(lineEnd, QTextCursor::KeepAnchor);
    c.mergeCharFormat(mergeFormatFromAttrs(attrs));
    reconcileAlignment();
    applyingRemote_ = false;

    QJsonArray ops;
    if (lineStart > 0)
        ops.append(QJsonObject {{QStringLiteral("retain"), lineStart}});
    ops.append(QJsonObject {{QStringLiteral("retain"), lineEnd - lineStart}, {QStringLiteral("attributes"), attrs}});
    Q_EMIT localDelta(QString::fromUtf8(QJsonDocument(ops).toJson(QJsonDocument::Compact)));
}

// What the clipboard is asked for, in the order it is asked. The bytes a source
// already holds are preferred to anything re-encoded from them: a JPEG turned
// into a PNG would be stored several times larger for no gain, and a re-encode
// can only lose.
static const char* const IMAGE_MIME_TYPES[] = {"image/png", "image/jpeg", "image/webp", "image/gif", "image/bmp"};

// The daemon's own ceiling. Applied before reading a file so a huge one is never
// pulled into memory just to be refused afterwards.
constexpr qint64 MAX_PASTED_IMAGE_SIZE = 16 * 1024 * 1024;

// Text wins when the clipboard carries both. A word processor puts a rendered
// picture of the selection next to the text it copies; pasting that picture
// instead of the words would surprise everyone.
//
// A lone URL is the one text that does not win -- but only against an image the
// source offers as encoded bytes. That is the browser case: a picture copied
// from a page comes with the address of that picture, and treating it as text
// pasted the link where the user copied the image.
//
// Against a merely rendered bitmap the URL keeps winning. An application that
// has no picture of its own hands over a picture *of* what it copied, and a
// copied link is exactly what that happens to. Pasting a rendered image of a
// link instead of the link is the surprise this rule exists to prevent.
static bool
textWins(const QMimeData* mime, bool loneUrlIsNotText)
{
    if (!mime->hasText())
        return false;
    const QString text = mime->text().trimmed();
    if (text.isEmpty())
        return false;
    if (!loneUrlIsNotText)
        return true;
    if (text.contains(QLatin1Char('\n')) || text.contains(QLatin1Char(' ')))
        return true;
    const QUrl url(text);
    return !(url.isValid() && !url.scheme().isEmpty());
}

// Whether the clipboard offers the image already encoded, in a format we accept.
// hasImage() alone would not do: it asks for a decoded image, which a source
// offering nothing but encoded bytes does not claim to have.
static bool
carriesEncodedImage(const QMimeData* mime)
{
    for (const char* type : IMAGE_MIME_TYPES)
        if (mime->hasFormat(QLatin1String(type)))
            return !textWins(mime, true);
    return false;
}

// The single local file a drop or a paste points at, empty if it is not exactly
// one, or not on this machine: fetching a remote URL would make the editor emit
// a request because of what was put on the clipboard.
static QString
soleLocalFile(const QMimeData* mime)
{
    if (!mime->hasUrls())
        return {};
    const QList<QUrl> urls = mime->urls();
    if (urls.size() != 1 || !urls.first().isLocalFile())
        return {};
    return urls.first().toLocalFile();
}

// Whether these bytes are a picture this editor can draw, small enough to hold
// once decoded. Reads the header, never the pixels: a handful of bytes can
// announce more pixels than memory holds, and the size cap on the bytes says
// nothing about what they become.
static bool
encodedIsDrawable(const QByteArray& data)
{
    if (data.isEmpty() || data.size() > MAX_PASTED_IMAGE_SIZE)
        return false;
    QBuffer buffer;
    buffer.setData(data);
    if (!buffer.open(QIODevice::ReadOnly))
        return false;
    QImageReader reader(&buffer);
    const QSize size = reader.size();
    return size.isValid() && !size.isEmpty() && qint64(size.width()) * qint64(size.height()) <= MAX_DECODED_PIXELS;
}

// The encoded picture the source offers, empty when what it offers is not one.
// A format can be advertised and yet deliver nothing -- an X11 selection target
// that fails to convert is the ordinary case -- so the next format gets its turn.
static QByteArray
encodedImage(const QMimeData* mime)
{
    for (const char* type : IMAGE_MIME_TYPES) {
        const QByteArray data = mime->data(QLatin1String(type));
        if (encodedIsDrawable(data))
            return data;
    }
    return {};
}

// Where a paste will take its picture from, None when nothing on offer is one.
//
// This is the single cascade: the picture offered as encoded bytes, then the one
// offered decoded, then the single local file pointed at. Deciding costs a
// header read and a stat, never a decode and never an encode, which is what lets
// the menu ask the very same question as the paste without paying for it -- and
// is why the two cannot promise different things.
//
// One residue is irreducible: a header that parses over a body that does not.
// Only decoding settles that, and decoding is the cost this exists to avoid.
enum class ImageSource { None, Encoded, Decoded, LocalFile };

static ImageSource
imageSource(const QMimeData* mime, QByteArray* encodedOut = nullptr)
{
    if (!mime)
        return ImageSource::None;

    if (carriesEncodedImage(mime)) {
        QByteArray data = encodedImage(mime);
        if (!data.isEmpty()) {
            if (encodedOut)
                *encodedOut = std::move(data);
            return ImageSource::Encoded;
        }
    }

    // A source offering only a decoded image, a screenshot tool say.
    if (mime->hasImage() && !textWins(mime, false)) {
        const QImage image = qvariant_cast<QImage>(mime->imageData());
        if (!image.isNull() && qint64(image.width()) * qint64(image.height()) <= MAX_DECODED_PIXELS)
            return ImageSource::Decoded;
    }

    // An image file copied from a file manager. Its path is also offered as
    // text, which is why this is not subject to the text rule above.
    const QString path = soleLocalFile(mime);
    if (path.isEmpty())
        return ImageSource::None;
    const qint64 size = QFileInfo(path).size();
    if (size <= 0 || size > MAX_PASTED_IMAGE_SIZE)
        return ImageSource::None;
    // The header alone settles it, and reads no pixel: 0 ms against the 63 ms a
    // full read and decode of the same file costs.
    QImageReader reader(path);
    const QSize dims = reader.size();
    if (!dims.isValid() || dims.isEmpty() || qint64(dims.width()) * qint64(dims.height()) > MAX_DECODED_PIXELS)
        return ImageSource::None;
    return ImageSource::LocalFile;
}

QByteArray
CollabRichBinding::imageFromMimeData(const QMimeData* mime)
{
    QByteArray encoded;
    switch (imageSource(mime, &encoded)) {
    case ImageSource::Encoded:
        return encoded;

    case ImageSource::Decoded: {
        // PNG because it is lossless and keeps transparency. Bounded again: the
        // pixel count passed, the bytes it encodes to still have to fit.
        QByteArray out;
        QBuffer buffer(&out);
        buffer.open(QIODevice::WriteOnly);
        const QImage image = qvariant_cast<QImage>(mime->imageData());
        if (image.save(&buffer, "PNG") && out.size() <= MAX_PASTED_IMAGE_SIZE)
            return out;
        return {};
    }

    case ImageSource::LocalFile: {
        QFile file(soleLocalFile(mime));
        if (!file.open(QIODevice::ReadOnly))
            return {};
        const QByteArray data = file.readAll();
        // Read as bytes, not as a name: the suffix is not evidence. The header
        // was already checked; this file was not chosen by anyone, only pointed
        // at, so it is decoded in full before it is handed on.
        return decodeBounded(data).isNull() ? QByteArray {} : data;
    }

    case ImageSource::None:
        break;
    }
    return {};
}

bool
CollabRichBinding::mimeCarriesImage(const QMimeData* mime)
{
    return imageSource(mime) != ImageSource::None;
}

bool
CollabRichBinding::clipboardHasImage() const
{
    if (!clipboardImageKnown_) {
        clipboardImage_ = mimeCarriesImage(QGuiApplication::clipboard()->mimeData());
        clipboardImageKnown_ = true;
    }
    return clipboardImage_;
}

void
CollabRichBinding::onClipboardChanged()
{
    // Do not answer the question here: most clipboard changes are never pasted
    // into a document. Forget the answer, and work it out again if asked.
    clipboardImageKnown_ = false;
    Q_EMIT clipboardHasImageChanged();
}

QByteArray
CollabRichBinding::imageFromDropData(const QVariantMap& payload)
{
    QMimeData mime;
    for (auto it = payload.begin(); it != payload.end(); ++it) {
        if (it.key() == QLatin1String("text")) {
            const QString text = it.value().toString();
            if (!text.isEmpty())
                mime.setText(text);
        } else if (it.key() == QLatin1String("urls")) {
            QList<QUrl> urls;
            const QVariantList list = it.value().toList();
            for (const QVariant& v : list) {
                const QUrl url = v.canConvert<QUrl>() ? v.toUrl() : QUrl(v.toString());
                if (url.isValid())
                    urls.append(url);
            }
            if (!urls.isEmpty())
                mime.setUrls(urls);
        } else if (it.key().startsWith(QLatin1String("image/"))) {
            const QByteArray data = it.value().toByteArray();
            if (!data.isEmpty())
                mime.setData(it.key(), data);
        }
    }
    return imageFromMimeData(&mime);
}

bool
CollabRichBinding::dropCarriesLocalFile(const QVariantMap& payload)
{
    const QVariantList list = payload.value(QStringLiteral("urls")).toList();
    for (const QVariant& v : list) {
        const QUrl url = v.canConvert<QUrl>() ? v.toUrl() : QUrl(v.toString());
        if (url.isValid() && url.isLocalFile())
            return true;
    }
    return false;
}

void
CollabRichBinding::pasteText(int start, int end)
{
    QTextDocument* d = doc();
    if (!d)
        return;
    // Rich clipboard styling is intentionally dropped so every participant
    // stays consistent.
    insertText(start, end, QGuiApplication::clipboard()->text());
}

void
CollabRichBinding::insertText(int start, int end, const QString& text)
{
    QTextDocument* d = doc();
    if (!d)
        return;
    if (text.isEmpty() && start == end)
        return;
    // Literal text, never interpreted as markup. This goes through
    // onContentsChange like a normal edit, so it syncs.
    QTextCursor c(d);
    const int last = d->characterCount() - 1;
    c.setPosition(qBound(0, qMin(start, end), last));
    if (start != end) {
        c.setPosition(qBound(0, qMax(start, end), last), QTextCursor::KeepAnchor);
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
    if (!d || start > end)
        return;
    const QString safe = sanitizedHref(href);
    if (!href.trimmed().isEmpty() && safe.isEmpty()) {
        // Refuse rather than clear: clearing would drop a link the user already
        // had, as a side effect of typing an address we do not accept.
        qWarning() << "Refusing a collaborative link with an unsupported scheme";
        return;
    }
    if (start == end) {
        // Nothing is selected, so there is no text to turn into a link. Insert
        // the address and link that: asking for a link with an empty selection
        // means "put one here", not "do nothing". Clearing is a no-op instead,
        // since an empty range carries no link to remove.
        if (safe.isEmpty())
            return;
        // insertText() clamps to the document, so clamp here too and keep both
        // ends of the new range consistent with where the text actually landed.
        start = qBound(0, start, d->characterCount() - 1);
        insertText(start, start, safe);
        end = start + safe.size();
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
    // Paragraph-wide, so read from the paragraph rather than from the caret.
    const QJsonObject p = blockAttrsAt(d, start);
    result[QStringLiteral("header")] = p.contains(QStringLiteral("header")) ? p.value(QStringLiteral("header")).toInt()
                                                                            : 0;
    result[QStringLiteral("list")] = p.value(QStringLiteral("list")).toString();
    // Left is the absence of the attribute, and is reported as such.
    result[QStringLiteral("align")] = p.value(QStringLiteral("align")).toString();
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
    // A narrower image leaves more room, so a centred one has to move.
    if (done)
        reconcileAlignment();
    applyingRemote_ = false;
    return done ? w : 0;
}

void
CollabRichBinding::reflowAlignedImages()
{
    // Nothing here changes the text, so no delta is due -- and none must be
    // inferred from the layout moving.
    const bool wasApplying = applyingRemote_;
    applyingRemote_ = true;
    reconcileAlignment();
    applyingRemote_ = wasApplying;
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
