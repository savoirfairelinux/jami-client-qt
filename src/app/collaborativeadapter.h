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
#include "collabrichbinding.h"
#include "yrsdocument.h"

#include <QObject>
#include <QHash>
#include <QSet>
#include <QString>
#include <QVariant>
#include <QVariantList>

#include <memory>

#include <QQmlEngine>   // QML registration
#include <QApplication> // QML registration

/**
 * Adapter exposing real-time collaborative document editing to QML.
 *
 * This is where the client's replica of a document lives. The daemon carries
 * opaque Y-CRDT updates and knows nothing of what a document holds, so
 * interpreting one -- as plain text, as rich text, as anything yrs supports --
 * is the client's job and happens here.
 *
 * One replica per open document, shared by every view of it: an edit typed in
 * one editor is reported to the others through the same mutation, which is what
 * keeps a plain-text and a rich-text view of the same document in step.
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
    Q_INVOKABLE QString createDocument(const QString& convId, const QString& name);
    /// Open a document, build the local replica from the daemon's state and return
    /// its current full text.
    Q_INVOKABLE QString openDocument(const QString& accountId, const QString& convId, const QString& documentId);
    /// Release the local editing session for a document.
    Q_INVOKABLE void closeDocument(const QString& accountId, const QString& convId, const QString& documentId);
    /// Remove a document from the conversation, for every member and every device.
    /// Only its author can; false means the daemon refused or could not find it.
    Q_INVOKABLE bool removeDocument(const QString& accountId, const QString& convId, const QString& documentId);
    /// Apply a local edit: remove @p deleteLen UTF-16 units at @p index then insert @p insert.
    Q_INVOKABLE void edit(const QString& accountId,
                          const QString& convId,
                          const QString& documentId,
                          int index,
                          int deleteLen,
                          const QString& insert);
    /// Broadcast the local cursor position/selection (UTF-16 units) to other members.
    Q_INVOKABLE void setCursor(
        const QString& accountId, const QString& convId, const QString& documentId, int position, int anchor);
    /// Rename a document; the new name syncs to all members and persists.
    Q_INVOKABLE void setName(const QString& accountId,
                             const QString& convId,
                             const QString& documentId,
                             const QString& name);
    /// Current name of a document, or an empty string if unknown.
    Q_INVOKABLE QString documentName(const QString& accountId, const QString& convId, const QString& documentId);
    /// Apply a local rich-text edit (Quill-style delta JSON) to a document.
    Q_INVOKABLE void applyDelta(const QString& accountId,
                                const QString& convId,
                                const QString& documentId,
                                const QString& deltaJson);
    /// Whole current content of a document as a Quill delta JSON (for initial render).
    Q_INVOKABLE QString contentDelta(const QString& accountId, const QString& convId, const QString& documentId);
    /// List the editable documents shared in @p convId, most recent first. Each
    /// entry is a map: { documentId, name, author, hasUpdate, timestamp }.
    Q_INVOKABLE QVariantList documents(const QString& convId);
    /// Checkpoints of a document, newest first. Each entry is a map:
    /// { id, author, device, timestamp, deltas }.
    Q_INVOKABLE QVariantList history(const QString& accountId,
                                     const QString& convId,
                                     const QString& documentId,
                                     int max = 0);
    /// Content of a document as of a checkpoint, for read-only review. Rebuilt
    /// here from the state the daemon returns for that checkpoint.
    Q_INVOKABLE QString textAt(const QString& accountId,
                               const QString& convId,
                               const QString& documentId,
                               const QString& commitId);
    /// Restore an open document to a checkpoint. Computed here, then applied as a
    /// normal edit, so every member converges on it and it can itself be undone.
    Q_INVOKABLE bool restore(const QString& accountId,
                             const QString& convId,
                             const QString& documentId,
                             const QString& commitId);
    /// Whether @p convId has a collaborative document update that hasn't been opened yet.
    Q_INVOKABLE bool hasUnreadDocumentUpdate(const QString& convId) const;
    /// Number of collaborative documents in @p convId that haven't been opened since their update.
    Q_INVOKABLE int unreadDocumentUpdateCount(const QString& convId) const;
    /// Whether @p documentId has an update that hasn't been opened yet.
    Q_INVOKABLE bool hasUnreadDocumentUpdateForDocument(const QString& convId, const QString& documentId) const;

    /// Store @p file as an attachment of the document and describe how to show
    /// it: {"id", "width", "height"}, or an empty map when the file cannot be
    /// read, is not an image, or is too large.
    ///
    /// The bytes go to the document's repository, not through the real-time
    /// path: an image is worth thousands of keystrokes, and the CRDT keeps every
    /// byte it is ever given for good.
    Q_INVOKABLE QVariantMap addAttachment(const QString& accountId,
                                          const QString& convId,
                                          const QString& documentId,
                                          const QUrl& file);
    /// Store the picture the clipboard holds, the same way a picked file is
    /// stored. Reads the clipboard here rather than in QML: several megabytes of
    /// image have no reason to travel through the script engine.
    /// @return an empty map when the clipboard holds no usable picture.
    Q_INVOKABLE QVariantMap addAttachmentFromClipboard(const QString& accountId,
                                                       const QString& convId,
                                                       const QString& documentId);

    /// Store the picture a drop carries. @p payload is what QML could read of
    /// the drop event; the decision of what counts as a picture is the one taken
    /// for a paste.
    /// @return an empty map when the drop carries no usable picture.
    Q_INVOKABLE QVariantMap addAttachmentFromDrop(const QString& accountId,
                                                  const QString& convId,
                                                  const QString& documentId,
                                                  const QVariantMap& payload);

    /// Hand the bytes of @p attachmentId to @p binding, if this replica holds
    /// them yet. Passing the binding rather than returning the bytes keeps them
    /// in C++ instead of round-tripping several megabytes through QML.
    /// @return false when the payload has not arrived; wait for attachmentAdded.
    Q_INVOKABLE bool deliverAttachment(const QString& accountId,
                                       const QString& convId,
                                       const QString& documentId,
                                       const QString& attachmentId,
                                       CollabRichBinding* binding);

Q_SIGNALS:
    // Every document signal names the account it belongs to. Editor windows are
    // top-level and outlive the selection made in the main window, and two local
    // accounts in the same swarm share the conversation and document ids, so
    // filtering on those alone would let one account's events drive the other's
    // window.

    /// A remote edit was applied to a document; the editor should mirror it.
    void documentChanged(const QString& accountId,
                         const QString& convId,
                         const QString& documentId,
                         int index,
                         int deleteLen,
                         const QString& insert);
    /// A remote participant moved their cursor/selection in a document.
    /// @c clientId identifies the editing device: one person can have several,
    /// each with its own cursor.
    void cursorChanged(const QString& accountId,
                       const QString& convId,
                       const QString& documentId,
                       const QString& peerId,
                       quint64 clientId,
                       int position,
                       int anchor);
    /// The payload of an attachment arrived; an editor showing a placeholder for
    /// it can now draw it.
    void attachmentAdded(const QString& accountId,
                         const QString& convId,
                         const QString& documentId,
                         const QString& attachmentId);
    /// A remote participant stopped editing a document.
    void participantLeft(const QString& accountId,
                         const QString& convId,
                         const QString& documentId,
                         const QString& peerId,
                         quint64 clientId);
    /// A document was renamed (locally or remotely); UIs should update the title.
    void documentRenamed(const QString& accountId,
                         const QString& convId,
                         const QString& documentId,
                         const QString& name);
    /// A document was removed by its author: it is gone everywhere, so any editor
    /// showing it must close and any list must drop it.
    void documentRemoved(const QString& accountId, const QString& convId, const QString& documentId);
    /// A remote rich-text edit (Quill-style delta JSON) should be applied to the editor.
    void documentDelta(const QString& accountId,
                       const QString& convId,
                       const QString& documentId,
                       const QString& deltaJson);
    /// The blue document-update indicator changed for @p convId.
    void documentUpdateIndicatorChanged(const QString& convId);

private:
    /// Validate @p data as a picture and store it with the document. Shared by
    /// the picked-file and the pasted paths, so both refuse the same things.
    QVariantMap storeAttachment(const QString& accountId,
                                const QString& convId,
                                const QString& documentId,
                                const QByteArray& data);

    /// The replica of one open document, plus what the adapter needs to route its
    /// mutations back to the right editor.
    struct Replica
    {
        std::shared_ptr<collab::YrsDocument> doc;
        QString accountId;
        QString convId;
        QString documentId;
        int openCount {0};
        /// Set while restoring a checkpoint: the resulting mutation is local, but
        /// no editor typed it, so it must be reported like a remote one.
        bool announceLocal {false};
    };

    /// Key of a replica: an account, a conversation and a document. Two local
    /// accounts in the same swarm share the last two, so the account is part of it.
    static QString replicaKey(const QString& accountId, const QString& convId, const QString& documentId);
    std::shared_ptr<Replica> findReplica(const QString& accountId,
                                         const QString& convId,
                                         const QString& documentId) const;
    /// A fresh Y-CRDT replica id. Never reuse one across instances: see the
    /// definition for why a stable id corrupts the document beyond repair.
    static uint64_t replicaId();
    /// Build the replica and wire its callbacks. Its content is seeded by the
    /// caller, from the state the daemon hands back when opening.
    std::shared_ptr<Replica> createReplica(const QString& accountId, const QString& convId, const QString& documentId);
    /// Apply an update coming from the daemon to the matching replica.
    void mergeRemoteUpdate(const QString& accountId,
                           const QString& convId,
                           const QString& documentId,
                           const QByteArray& bytes);

    void markDocumentUpdated(const QString& accountId, const QString& convId, const QString& documentId);
    void clearDocumentUpdated(const QString& accountId, const QString& convId, const QString& documentId);
    /// Unread state is per account as well as per conversation: the same swarm
    /// seen from two local accounts carries the same conversation id.
    static QString unreadKey(const QString& accountId, const QString& convId);

    QHash<QString, QSet<QString>> updatedDocumentsByConversation_;
    QHash<QString, std::shared_ptr<Replica>> replicas_;
};
