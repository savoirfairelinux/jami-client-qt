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

namespace {

const QColor LINK_COLOR(0x1a, 0x73, 0xe8);
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
            f.setProperty(QTextFormat::FontSizeAdjustment,
                          (level >= 1 && level <= 3) ? (4 - level) : 0);
        } else if (key == QLatin1String("list")) {
            f.setProperty(LIST_PROPERTY,
                          listTypeFromStyle(v.isString() ? v.toString() : QString()));
        } else if (key == QLatin1String("link")) {
            if (on) {
                f.setAnchor(true);
                f.setAnchorHref(v.toString());
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
        connect(d,
                &QTextDocument::contentsChange,
                this,
                &CollabRichBinding::onContentsChange,
                Qt::UniqueConnection);
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
    while (suffix < maxSuffix
           && shadow_.at(oldLen - 1 - suffix) == now.at(newLen - 1 - suffix))
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
            const QJsonObject a = charAttrsAt(d, prefix + i);
            int j = i + 1;
            while (j < text.size() && charAttrsAt(d, prefix + j) == a)
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
        } else if (op.contains(QStringLiteral("retain"))) {
            const int n = op.value(QStringLiteral("retain")).toInt();
            const QJsonObject attrs = op.value(QStringLiteral("attributes")).toObject();
            if (!attrs.isEmpty() && n > 0) {
                QTextCursor cc(d);
                cc.setPosition(qBound(0, index, docLen));
                cc.setPosition(qBound(0, index + n, docLen), QTextCursor::KeepAnchor);
                cc.mergeCharFormat(mergeFormatFromAttrs(attrs));
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
    // Rebuild list blocks from the per-character list attributes just applied.
    reconcileLists();
    applyingRemote_ = false;
    // Keep the shadow equal to the (converged) content so local diffs stay aligned.
    shadow_ = d->toPlainText();
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
    ops.append(QJsonObject {{QStringLiteral("retain"), end - start},
                            {QStringLiteral("attributes"), attrs}});
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
    attrs[QStringLiteral("header")] = (level >= 1 && level <= 3) ? QJsonValue(level)
                                                                 : QJsonValue(QJsonValue::Null);

    applyingRemote_ = true;
    QTextCursor c(d);
    c.setPosition(lineStart);
    c.setPosition(lineEnd, QTextCursor::KeepAnchor);
    c.mergeCharFormat(mergeFormatFromAttrs(attrs));
    applyingRemote_ = false;

    QJsonArray ops;
    if (lineStart > 0)
        ops.append(QJsonObject {{QStringLiteral("retain"), lineStart}});
    ops.append(QJsonObject {{QStringLiteral("retain"), lineEnd - lineStart},
                            {QStringLiteral("attributes"), attrs}});
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
    attrs[QStringLiteral("list")] = target.isEmpty() ? QJsonValue(QJsonValue::Null)
                                                      : QJsonValue(target);

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
    ops.append(QJsonObject {{QStringLiteral("retain"), lineEnd - lineStart},
                            {QStringLiteral("attributes"), attrs}});
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
    QJsonObject attrs;
    attrs[QStringLiteral("link")] = href.isEmpty() ? QJsonValue(QJsonValue::Null) : QJsonValue(href);

    applyingRemote_ = true;
    QTextCursor c(d);
    c.setPosition(start);
    c.setPosition(end, QTextCursor::KeepAnchor);
    c.mergeCharFormat(mergeFormatFromAttrs(attrs));
    applyingRemote_ = false;

    QJsonArray ops;
    if (start > 0)
        ops.append(QJsonObject {{QStringLiteral("retain"), start}});
    ops.append(QJsonObject {{QStringLiteral("retain"), end - start},
                            {QStringLiteral("attributes"), attrs}});
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
    ops.append(QJsonObject {{QStringLiteral("retain"), end - start},
                            {QStringLiteral("attributes"), attrs}});
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
    result[QStringLiteral("header")] = a.contains(QStringLiteral("header"))
                                           ? a.value(QStringLiteral("header")).toInt()
                                           : 0;
    result[QStringLiteral("list")] = a.value(QStringLiteral("list")).toString();
    return result;
}
