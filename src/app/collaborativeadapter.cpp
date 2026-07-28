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
#include "collaborativeadapter.h"

#include "dbus/configurationmanager.h"

#include <api/messagelistmodel.h>

#include <QJsonDocument>
#include <QJsonObject>
#include <QRandomGenerator>
#include <QSet>
#include <algorithm>

namespace {

/// Ephemeral awareness is opaque to the daemon, so its shape is settled here.
/// Kept to a small JSON object, so a field can be added without a daemon change.
QString
encodeCursor(int position, int anchor)
{
    QJsonObject state;
    state[QStringLiteral("p")] = position;
    state[QStringLiteral("a")] = anchor;
    return QString::fromUtf8(QJsonDocument(state).toJson(QJsonDocument::Compact));
}

bool
decodeCursor(const QString& state, int& position, int& anchor)
{
    const auto doc = QJsonDocument::fromJson(state.toUtf8());
    if (!doc.isObject())
        return false;
    const auto object = doc.object();
    position = object.value(QStringLiteral("p")).toInt();
    anchor = object.value(QStringLiteral("a")).toInt(position);
    return true;
}

} // namespace

CollaborativeAdapter::CollaborativeAdapter(LRCInstance* instance, QObject* parent)
    : QmlAdapterBase(instance, parent)
{
    // A single channel for every document type: the payload is an opaque Y-CRDT
    // update, merged into the local replica, which then reports the change in
    // whatever form each open editor understands.
    connect(&ConfigurationManager::instance(),
            &ConfigurationManagerInterface::collaborativeDocumentUpdate,
            this,
            [this](const QString& accountId,
                   const QString& convId,
                   const QString& documentId,
                   const QString& base64Update) {
                markDocumentUpdated(accountId, convId, documentId);
                mergeRemoteUpdate(accountId, convId, documentId, base64Update);
            });
    connect(&ConfigurationManager::instance(),
            &ConfigurationManagerInterface::collaborativeAwarenessChanged,
            this,
            [this](const QString& accountId,
                   const QString& convId,
                   const QString& documentId,
                   const QString& peerId,
                   const QString& state) {
                int position = 0;
                int anchor = 0;
                if (decodeCursor(state, position, anchor))
                    Q_EMIT cursorChanged(accountId, convId, documentId, peerId, position, anchor);
            });
    connect(&ConfigurationManager::instance(),
            &ConfigurationManagerInterface::collaborativeParticipantLeft,
            this,
            [this](const QString& accountId, const QString& convId, const QString& documentId, const QString& peerId) {
                Q_EMIT participantLeft(accountId, convId, documentId, peerId);
            });
    connect(&ConfigurationManager::instance(),
            &ConfigurationManagerInterface::collaborativeDocumentRenamed,
            this,
            [this](const QString& accountId, const QString& convId, const QString& documentId, const QString& name) {
                Q_EMIT documentRenamed(accountId, convId, documentId, name);
            });
}

QString
CollaborativeAdapter::replicaKey(const QString& accountId, const QString& convId, const QString& documentId)
{
    // All three are fixed-width hex, so concatenating cannot make two distinct
    // triples collide.
    return accountId + convId + documentId;
}

std::shared_ptr<CollaborativeAdapter::Replica>
CollaborativeAdapter::findReplica(const QString& accountId, const QString& convId, const QString& documentId) const
{
    return replicas_.value(replicaKey(accountId, convId, documentId));
}

uint64_t
CollaborativeAdapter::replicaId()
{
    // Fresh on every replica, deliberately, and it must stay that way.
    //
    // A replica id is only half of an item id: the other half is a counter that
    // starts at zero and is never persisted on its own. Reusing an id across two
    // instances therefore lets the second one mint item ids the first already
    // used, and peers -- which deduplicate by id -- drop the new content without
    // a word. Since an edit is broadcast right away but only committed to git ten
    // seconds later, any crash inside that window leaves the next run with a
    // clock lower than what peers recorded. The documents diverge for good: no
    // later synchronisation, in either direction, repairs it.
    //
    // The cost of not reusing is one state vector entry, and only for a replica
    // that actually writes -- opening a document a hundred times to read it adds
    // nothing. Measured against this contrib's libyrs: three bytes per writing
    // replica, next to nothing beside a corrupt document. This is why yjs draws
    // its client id at random for every Doc, and we follow.
    //
    // Ids must also stay below 2^53: the yjs ecosystem carries them through JSON.
    return QRandomGenerator::global()->generate64() & ((uint64_t(1) << 53) - 1);
}

std::shared_ptr<CollaborativeAdapter::Replica>
CollaborativeAdapter::createReplica(const QString& accountId, const QString& convId, const QString& documentId)
{
    auto replica = std::make_shared<Replica>();
    replica->accountId = accountId;
    replica->convId = convId;
    replica->documentId = documentId;
    replica->doc = std::make_shared<collab::YrsDocument>(replicaId());

    std::weak_ptr<Replica> weakReplica = replica;
    replica->doc->setUpdateCallback([this, weakReplica](const collab::YrsDocument::Bytes& update, bool isLocal) {
        auto r = weakReplica.lock();
        if (!r || !isLocal)
            return; // an update we merged is already known to the daemon
        ConfigurationManager::instance().applyCollaborativeUpdate(
            r->accountId,
            r->convId,
            r->documentId,
            QString::fromLatin1(QByteArray(reinterpret_cast<const char*>(update.data()), update.size()).toBase64()));
    });
    replica->doc->setChangeCallback(
        [this, weakReplica](const std::vector<collab::YrsDocument::TextChange>& changes, bool isLocal) {
            auto r = weakReplica.lock();
            if (!r || (isLocal && !r->announceLocal))
                return; // a local edit already lives in the editor that produced it
            for (const auto& change : changes)
                Q_EMIT documentChanged(r->accountId,
                                       r->convId,
                                       r->documentId,
                                       static_cast<int>(change.index),
                                       static_cast<int>(change.deleteLen),
                                       QString::fromStdString(change.inserted));
        });
    replica->doc->setRichChangeCallback(
        [this, weakReplica](const std::vector<collab::YrsDocument::RichOp>& ops, bool isLocal) {
            auto r = weakReplica.lock();
            if (!r || (isLocal && !r->announceLocal))
                return;
            Q_EMIT documentDelta(r->accountId,
                                 r->convId,
                                 r->documentId,
                                 QString::fromStdString(collab::YrsDocument::richOpsToDeltaJson(ops)));
        });

    replicas_.insert(replicaKey(accountId, convId, documentId), replica);
    return replica;
}

void
CollaborativeAdapter::mergeRemoteUpdate(const QString& accountId,
                                        const QString& convId,
                                        const QString& documentId,
                                        const QString& base64Update)
{
    auto replica = findReplica(accountId, convId, documentId);
    if (!replica)
        return; // not open here: the daemon holds it, we rebuild on open
    const auto bytes = QByteArray::fromBase64(base64Update.toLatin1());
    replica->doc->applyUpdate(
        collab::YrsDocument::Bytes(reinterpret_cast<const uint8_t*>(bytes.constData()),
                                   reinterpret_cast<const uint8_t*>(bytes.constData()) + bytes.size()));
}

QString
CollaborativeAdapter::createDocument(const QString& convId, const QString& name, const QString& kind)
{
    return ConfigurationManager::instance().createCollaborativeDocument(lrcInstance_->get_currentAccountId(),
                                                                        convId,
                                                                        name,
                                                                        kind);
}

QString
CollaborativeAdapter::openDocument(const QString& accountId, const QString& convId, const QString& documentId)
{
    clearDocumentUpdated(accountId, convId, documentId);
    // Opening tells the daemon to join the document and hands back its whole
    // state as one update. A second view of an already open document reuses the
    // replica rather than building a divergent one.
    const auto state = ConfigurationManager::instance().openCollaborativeDocument(accountId, convId, documentId);
    auto replica = findReplica(accountId, convId, documentId);
    if (!replica) {
        replica = createReplica(accountId, convId, documentId);
        const auto bytes = QByteArray::fromBase64(state.toLatin1());
        if (!bytes.isEmpty())
            replica->doc->applyUpdate(collab::YrsDocument::Bytes(reinterpret_cast<const uint8_t*>(bytes.constData()),
                                                                 reinterpret_cast<const uint8_t*>(bytes.constData())
                                                                     + bytes.size()),
                                      /*silent=*/true);
    }
    ++replica->openCount;
    return QString::fromStdString(replica->doc->text());
}

void
CollaborativeAdapter::closeDocument(const QString& accountId, const QString& convId, const QString& documentId)
{
    const auto key = replicaKey(accountId, convId, documentId);
    const auto it = replicas_.find(key);
    if (it != replicas_.end() && --(*it)->openCount > 0)
        return; // another view still has it open: leaving now would drop its cursor
    if (it != replicas_.end())
        replicas_.erase(it);
    ConfigurationManager::instance().closeCollaborativeDocument(accountId, convId, documentId);
}

void
CollaborativeAdapter::edit(const QString& accountId,
                           const QString& convId,
                           const QString& documentId,
                           int index,
                           int deleteLen,
                           const QString& insert)
{
    auto replica = findReplica(accountId, convId, documentId);
    if (!replica)
        return;
    // A replace is expressed as a delete then an insert at the same index. The
    // resulting update reaches the daemon through the replica's update callback.
    if (deleteLen > 0)
        replica->doc->remove(static_cast<uint32_t>(index), static_cast<uint32_t>(deleteLen));
    if (!insert.isEmpty())
        replica->doc->insert(static_cast<uint32_t>(index), insert.toStdString());
}

void
CollaborativeAdapter::setCursor(
    const QString& accountId, const QString& convId, const QString& documentId, int position, int anchor)
{
    ConfigurationManager::instance().setCollaborativeAwareness(accountId,
                                                               convId,
                                                               documentId,
                                                               encodeCursor(position, anchor));
}

void
CollaborativeAdapter::setName(const QString& accountId,
                              const QString& convId,
                              const QString& documentId,
                              const QString& name)
{
    ConfigurationManager::instance().setCollaborativeDocumentName(accountId, convId, documentId, name);
}

QString
CollaborativeAdapter::documentName(const QString& accountId, const QString& convId, const QString& documentId)
{
    return ConfigurationManager::instance().collaborativeDocumentName(accountId, convId, documentId);
}

void
CollaborativeAdapter::applyDelta(const QString& accountId,
                                 const QString& convId,
                                 const QString& documentId,
                                 const QString& deltaJson)
{
    auto replica = findReplica(accountId, convId, documentId);
    if (replica)
        replica->doc->applyDelta(collab::YrsDocument::deltaJsonToRichOps(deltaJson.toStdString()));
}

QString
CollaborativeAdapter::contentDelta(const QString& accountId, const QString& convId, const QString& documentId)
{
    auto replica = findReplica(accountId, convId, documentId);
    return replica ? QString::fromStdString(replica->doc->contentDelta()) : QString {};
}

QVariantList
CollaborativeAdapter::documents(const QString& convId)
{
    QVariantList result;
    const auto accountId = lrcInstance_->get_currentAccountId();

    // Ask the daemon for every document in the conversation (read from its history),
    // so the list is complete regardless of which messages the UI has paged in.
    const auto docs = ConfigurationManager::instance().getCollaborativeDocuments(accountId, convId);
    QSet<QString> seen;
    for (const auto& commit : docs) {
        const auto documentId = commit.value(QStringLiteral("uri"));
        if (documentId.isEmpty() || seen.contains(documentId))
            continue;
        seen.insert(documentId);

        // Prefer the live CRDT name (reflects renames); fall back to the announcing
        // commit's display name.
        QString name = ConfigurationManager::instance().collaborativeDocumentName(accountId, convId, documentId);
        if (name.isEmpty())
            name = commit.value(QStringLiteral("displayName"));

        QVariantMap entry;
        entry[QStringLiteral("documentId")] = documentId;
        entry[QStringLiteral("name")] = name;
        entry[QStringLiteral("author")] = commit.value(QStringLiteral("author"));
        const auto kind = commit.value(QStringLiteral("kind"));
        entry[QStringLiteral("kind")] = kind == QStringLiteral("rich") ? kind : QStringLiteral("text");
        entry[QStringLiteral("hasUpdate")] = hasUnreadDocumentUpdateForDocument(convId, documentId);
        entry[QStringLiteral("timestamp")] = commit.value(QStringLiteral("timestamp")).toLongLong();
        result.append(entry);
    }

    // Most recent first.
    std::sort(result.begin(), result.end(), [](const QVariant& a, const QVariant& b) {
        return a.toMap().value(QStringLiteral("timestamp")).toLongLong()
               > b.toMap().value(QStringLiteral("timestamp")).toLongLong();
    });
    return result;
}

QVariantList
CollaborativeAdapter::history(const QString& accountId, const QString& convId, const QString& documentId, int max)
{
    QVariantList result;
    const auto entries = ConfigurationManager::instance().getCollaborativeDocumentHistory(accountId,
                                                                                          convId,
                                                                                          documentId,
                                                                                          max);
    for (const auto& entry : entries) {
        QVariantMap item;
        item[QStringLiteral("id")] = entry.value(QStringLiteral("id"));
        item[QStringLiteral("author")] = entry.value(QStringLiteral("author"));
        item[QStringLiteral("device")] = entry.value(QStringLiteral("device"));
        item[QStringLiteral("timestamp")] = entry.value(QStringLiteral("timestamp")).toLongLong();
        item[QStringLiteral("deltas")] = entry.value(QStringLiteral("deltas")).toInt();
        result.append(item);
    }
    return result;
}

QString
CollaborativeAdapter::textAt(const QString& accountId,
                             const QString& convId,
                             const QString& documentId,
                             const QString& commitId)
{
    // The daemon returns the state of that checkpoint as an update; what it means
    // is ours to decide, so it is replayed into a throwaway replica and read here.
    const auto state = ConfigurationManager::instance().collaborativeDocumentStateAt(accountId,
                                                                                     convId,
                                                                                     documentId,
                                                                                     commitId);
    const auto bytes = QByteArray::fromBase64(state.toLatin1());
    if (bytes.isEmpty())
        return {};
    // A throwaway replica that never edits, so its id only has to be valid.
    collab::YrsDocument snapshot {1};
    snapshot.applyUpdate(collab::YrsDocument::Bytes(reinterpret_cast<const uint8_t*>(bytes.constData()),
                                                    reinterpret_cast<const uint8_t*>(bytes.constData()) + bytes.size()),
                         /*silent=*/true);
    return QString::fromStdString(snapshot.text());
}

bool
CollaborativeAdapter::restore(const QString& accountId,
                              const QString& convId,
                              const QString& documentId,
                              const QString& commitId)
{
    auto replica = findReplica(accountId, convId, documentId);
    if (!replica || commitId.isEmpty())
        return false; // the document must be open: restoring is an edit like any other
    const auto target = textAt(accountId, convId, documentId, commitId);
    if (target.isEmpty()) {
        // An unknown or unreachable checkpoint yields nothing; emptying the
        // document on that basis would destroy content for the whole conversation.
        auto known = false;
        const auto entries = history(accountId, convId, documentId, 0);
        for (const auto& entry : entries)
            if (entry.toMap().value(QStringLiteral("id")).toString() == commitId) {
                known = true;
                break;
            }
        if (!known)
            return false;
    }
    // Applied as an ordinary edit, so it reaches the other members through the
    // usual path and can itself be undone by restoring a later checkpoint. It is
    // announced despite being local: no editor typed it, so the open ones have to
    // be told, exactly as they would be for a remote change.
    // Restored under a guard rather than a plain pair of assignments: leaving the
    // flag raised -- which an exception escaping spliceTo on a large document
    // would do -- makes every later keystroke be announced back to the editor
    // that produced it, and so typed twice.
    struct AnnounceGuard
    {
        bool& flag;
        explicit AnnounceGuard(bool& f)
            : flag(f)
        {
            flag = true;
        }
        ~AnnounceGuard()
        {
            flag = false;
        }
    } guard {replica->announceLocal};
    // The return value reports that the checkpoint was reached, not that the text
    // moved: restoring a version identical to the current one is a success, and
    // the caller closes its preview on it.
    replica->doc->spliceTo(target.toStdString());
    return true;
}

QString
CollaborativeAdapter::unreadKey(const QString& accountId, const QString& convId)
{
    // Account ids are fixed-width hex, so concatenating cannot make two distinct
    // pairs collide.
    return accountId + convId;
}

bool
CollaborativeAdapter::hasUnreadDocumentUpdate(const QString& convId) const
{
    return unreadDocumentUpdateCount(convId) > 0;
}

int
CollaborativeAdapter::unreadDocumentUpdateCount(const QString& convId) const
{
    // The conversation list only ever shows the selected account.
    auto it = updatedDocumentsByConversation_.constFind(unreadKey(lrcInstance_->get_currentAccountId(), convId));
    return it != updatedDocumentsByConversation_.constEnd() ? it->size() : 0;
}

bool
CollaborativeAdapter::hasUnreadDocumentUpdateForDocument(const QString& convId, const QString& documentId) const
{
    auto it = updatedDocumentsByConversation_.constFind(unreadKey(lrcInstance_->get_currentAccountId(), convId));
    return it != updatedDocumentsByConversation_.constEnd() && it->contains(documentId);
}

void
CollaborativeAdapter::markDocumentUpdated(const QString& accountId, const QString& convId, const QString& documentId)
{
    // A document the user has open needs no unread mark: they are watching the
    // change arrive. Marking it anyway lit the badge on the very document being
    // edited, and it stayed lit until the editor was closed and reopened.
    if (findReplica(accountId, convId, documentId))
        return;
    auto& documents = updatedDocumentsByConversation_[unreadKey(accountId, convId)];
    if (documents.contains(documentId))
        return;
    documents.insert(documentId);
    if (accountId == lrcInstance_->get_currentAccountId())
        Q_EMIT documentUpdateIndicatorChanged(convId);
}

void
CollaborativeAdapter::clearDocumentUpdated(const QString& accountId, const QString& convId, const QString& documentId)
{
    auto it = updatedDocumentsByConversation_.find(unreadKey(accountId, convId));
    if (it == updatedDocumentsByConversation_.end() || !it->remove(documentId))
        return;
    if (it->isEmpty())
        updatedDocumentsByConversation_.erase(it);
    if (accountId == lrcInstance_->get_currentAccountId())
        Q_EMIT documentUpdateIndicatorChanged(convId);
}
