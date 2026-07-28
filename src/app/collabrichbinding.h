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
#pragma once

#include <QObject>
#include <QImage>
#include <QPointer>
#include <QSet>
#include <QQuickTextDocument>
#include <QString>
#include <QVariantMap>

class QTextDocument;

/**
 * Binds a QML TextArea's QTextDocument to the collaborative rich-text CRDT,
 * translating both ways:
 *  - local edits (typing, paste, delete, toolbar formatting) become a Quill-style
 *    delta emitted through localDelta(), which the QML layer forwards to the
 *    daemon (CollaborativeAdapter.applyDelta);
 *  - remote deltas (received from peers) are applied to the same QTextDocument via
 *    applyRemoteDelta(), so the local caret is shifted automatically by Qt and
 *    every participant converges, formatting included.
 *
 * Inline attributes use the Quill convention: "b" (bold), "i" (italic), "u"
 * (underline), "s" (strikethrough) as booleans, and "link" as an href string. A
 * null attribute value removes the attribute. Offsets are UTF-16 code units,
 * matching QString/QTextDocument indexing and the daemon's Y_OFFSET_UTF16.
 */
class CollabRichBinding : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QQuickTextDocument* textDocument READ textDocument WRITE setTextDocument NOTIFY textDocumentChanged)

public:
    explicit CollabRichBinding(QObject* parent = nullptr);
    ~CollabRichBinding() = default;

    QQuickTextDocument* textDocument() const;
    void setTextDocument(QQuickTextDocument* doc);

    /// Render the whole document from a Quill content delta (used once on open).
    Q_INVOKABLE void loadContentDelta(const QString& deltaJson);
    /// Apply a remote rich-text edit (Quill delta JSON) to the document.
    Q_INVOKABLE void applyRemoteDelta(const QString& deltaJson);

    /// Toggle an inline attribute ("b"/"i"/"u"/"s") over [start, end) (UTF-16).
    Q_INVOKABLE void toggleInline(const QString& attr, int start, int end);
    /// Apply a heading level (1..3, or 0 for normal) to every line touched by
    /// [start, end). Headings are line-level, so the whole lines are reformatted.
    Q_INVOKABLE void setHeading(int level, int start, int end);
    /// Apply a list style ("bullet"/"ordered", or "" to remove) to every line
    /// touched by [start, end).
    Q_INVOKABLE void setList(const QString& style, int start, int end);
    /// Replace [start, end) with the clipboard's plain text (sanitized paste): rich
    /// clipboard formatting is dropped so every participant stays consistent.
    Q_INVOKABLE void pasteText(int start, int end);
    /// Set (or, with an empty href, clear) a link over [start, end).
    Q_INVOKABLE void setLink(const QString& href, int start, int end);
    /// Remove all inline formatting over [start, end).
    Q_INVOKABLE void clearFormat(int start, int end);
    /// Inline attributes currently set across [start, end), for toolbar state.
    Q_INVOKABLE QVariantMap selectionFormat(int start, int end);

    /// Insert the attachment @p id as an inline image at @p position (UTF-16).
    /// Goes through the normal local-edit path, so the delta is emitted as for
    /// any other typing.
    Q_INVOKABLE void insertImage(int position, const QString& id, int width = 0, int height = 0);
    /// Make the bytes of attachment @p id available to the layout, so an image
    /// already present in the document stops rendering as a broken placeholder.
    void registerAttachment(const QString& id, const QByteArray& data);
    /// Whether the document holds an image referring to attachment @p id.
    Q_INVOKABLE bool referencesAttachment(const QString& id) const;

    /**
     * Decode @p data only once its header says what decoding will cost.
     *
     * A cap on the bytes says nothing about the memory they turn into: a
     * uniform 7000x7000 PNG travels as 160 kB and decodes to 187 MB, on every
     * replica that opens the document. The size is therefore read from the
     * header -- which allocates no pixels -- and the image is decoded only if
     * it fits.
     *
     * A format that will not state its size is refused rather than decoded to
     * find out: knowing the cost beforehand is the entire point.
     *
     * @return the decoded image, or a null image if it is too large, not an
     *         image, or of a kind this build cannot read.
     */
    static QImage decodeBounded(const QByteArray& data);

Q_SIGNALS:
    void textDocumentChanged();
    /// A local edit produced a Quill delta to be sent to the daemon.
    void localDelta(const QString& deltaJson);
    /// The document refers to an attachment whose bytes are not loaded yet.
    /// Whoever can fetch them answers with registerAttachment().
    void attachmentNeeded(const QString& id);

private:
    QTextDocument* doc() const;
    void onContentsChange(int position, int charsRemoved, int charsAdded);
    // Reconcile QTextList membership of every block from the per-character "list"
    // attribute, grouping consecutive same-type blocks into one list.
    void reconcileLists();

    QPointer<QQuickTextDocument> quickDoc_;
    // Plain-text mirror of the CRDT content. Local edits are computed by diffing
    // the document against this shadow, guaranteeing the produced offsets map onto
    // the CRDT (so the daemon never receives an out-of-range index). Kept equal to
    // the converged content after every local and remote change.
    QString shadow_;
    // True while applying a remote/initial delta, so contentsChange is not echoed
    // back as a local edit.
    bool applyingRemote_ {false};
    // Attachments met while applying a delta whose bytes the document does not
    // hold. Asked for once the delta is fully applied, not during.
    QSet<QString> pendingAttachments_;
};
