/*
 * Copyright (C) 2004-2026 Savoir-faire Linux Inc.
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

#include "lrcinstance.h"
#include "qmladapterbase.h"

#include <QObject>
#include <QHash>
#include <QSet>
#include <QString>
#include <QVariant>
#include <QVariantList>

#include <QQmlEngine>   // QML registration
#include <QApplication> // QML registration

/**
 * Adapter exposing real-time collaborative text-document editing to QML.
 * It forwards local edits to the daemon and re-emits remote edits (received via
 * the daemon's CollaborativeDocumentChanged signal) so an open editor can apply
 * them while preserving the local cursor.
 */
class CollaborativeAdapter final : public QmlAdapterBase
{
    Q_OBJECT
    QML_SINGLETON

public:
    static CollaborativeAdapter* create(QQmlEngine*, QJSEngine*)
    {
        return new CollaborativeAdapter(qApp->property("LRCInstance").value<LRCInstance*>());
    }

    explicit CollaborativeAdapter(LRCInstance* instance, QObject* parent = nullptr);
    ~CollaborativeAdapter() = default;

    /// Create a new editable document in @p convId; returns its generated id.
    /// @p kind is "text" (plain) or "rich" (WYSIWYG/HTML).
    Q_INVOKABLE QString createDocument(const QString& convId,
                                       const QString& name,
                                       const QString& kind = QStringLiteral("text"));
    /// Open a document and return its current full text.
    Q_INVOKABLE QString openDocument(const QString& convId, const QString& documentId);
    /// Release the local editing session for a document.
    Q_INVOKABLE void closeDocument(const QString& convId, const QString& documentId);
    /// Apply a local edit: remove @p deleteLen UTF-16 units at @p index then insert @p insert.
    Q_INVOKABLE void edit(const QString& convId,
                          const QString& documentId,
                          int index,
                          int deleteLen,
                          const QString& insert);
    /// Broadcast the local cursor position/selection (UTF-16 units) to other members.
    Q_INVOKABLE void setCursor(const QString& convId,
                               const QString& documentId,
                               int position,
                               int anchor);
    /// Rename a document; the new name syncs to all members and persists.
    Q_INVOKABLE void setName(const QString& convId, const QString& documentId, const QString& name);
    /// Current name of a document, or an empty string if unknown.
    Q_INVOKABLE QString documentName(const QString& convId, const QString& documentId);
    /// Apply a local rich-text edit (Quill-style delta JSON) to a document.
    Q_INVOKABLE void applyDelta(const QString& convId,
                                const QString& documentId,
                                const QString& deltaJson);
    /// Whole current content of a document as a Quill delta JSON (for initial render).
    Q_INVOKABLE QString contentDelta(const QString& convId, const QString& documentId);
    /// List the editable documents shared in @p convId, most recent first. Each
    /// entry is a map: { documentId, name, author, kind, hasUpdate, timestamp }.
    Q_INVOKABLE QVariantList documents(const QString& convId);
    /// Whether @p convId has a collaborative document update that hasn't been opened yet.
    Q_INVOKABLE bool hasUnreadDocumentUpdate(const QString& convId) const;
    /// Number of collaborative documents in @p convId that haven't been opened since their update.
    Q_INVOKABLE int unreadDocumentUpdateCount(const QString& convId) const;
    /// Whether @p documentId has an update that hasn't been opened yet.
    Q_INVOKABLE bool hasUnreadDocumentUpdateForDocument(const QString& convId,
                                                        const QString& documentId) const;

Q_SIGNALS:
    /// A remote edit was applied to a document; the editor should mirror it.
    void documentChanged(const QString& convId,
                         const QString& documentId,
                         int index,
                         int deleteLen,
                         const QString& insert);
    /// A remote participant moved their cursor/selection in a document.
    void cursorChanged(const QString& convId,
                       const QString& documentId,
                       const QString& peerId,
                       int position,
                       int anchor);
    /// A remote participant stopped editing a document.
    void participantLeft(const QString& convId, const QString& documentId, const QString& peerId);
    /// A document was renamed (locally or remotely); UIs should update the title.
    void documentRenamed(const QString& convId, const QString& documentId, const QString& name);
    /// A remote rich-text edit (Quill-style delta JSON) should be applied to the editor.
    void documentDelta(const QString& convId, const QString& documentId, const QString& deltaJson);
    /// The blue document-update indicator changed for @p convId.
    void documentUpdateIndicatorChanged(const QString& convId);

private:
    void markDocumentUpdated(const QString& convId, const QString& documentId);
    void clearDocumentUpdated(const QString& convId, const QString& documentId);

    QHash<QString, QSet<QString>> updatedDocumentsByConversation_;
};
