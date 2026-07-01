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

#include <QSet>
#include <algorithm>

CollaborativeAdapter::CollaborativeAdapter(LRCInstance* instance, QObject* parent)
    : QmlAdapterBase(instance, parent)
{
    connect(&ConfigurationManager::instance(),
            &ConfigurationManagerInterface::collaborativeDocumentChanged,
            this,
            [this](const QString& accountId,
                   const QString& convId,
                   const QString& documentId,
                   int index,
                   int deleteLen,
                   const QString& insert) {
                if (accountId != lrcInstance_->get_currentAccountId())
                    return;
                markDocumentUpdated(convId, documentId);
                Q_EMIT documentChanged(convId, documentId, index, deleteLen, insert);
            });
    connect(&ConfigurationManager::instance(),
            &ConfigurationManagerInterface::collaborativeCursorChanged,
            this,
            [this](const QString& accountId,
                   const QString& convId,
                   const QString& documentId,
                   const QString& peerId,
                   int position,
                   int anchor) {
                if (accountId != lrcInstance_->get_currentAccountId())
                    return;
                Q_EMIT cursorChanged(convId, documentId, peerId, position, anchor);
            });
    connect(&ConfigurationManager::instance(),
            &ConfigurationManagerInterface::collaborativeParticipantLeft,
            this,
            [this](const QString& accountId,
                   const QString& convId,
                   const QString& documentId,
                   const QString& peerId) {
                if (accountId != lrcInstance_->get_currentAccountId())
                    return;
                Q_EMIT participantLeft(convId, documentId, peerId);
            });
    connect(&ConfigurationManager::instance(),
            &ConfigurationManagerInterface::collaborativeDocumentRenamed,
            this,
            [this](const QString& accountId,
                   const QString& convId,
                   const QString& documentId,
                   const QString& name) {
                if (accountId != lrcInstance_->get_currentAccountId())
                    return;
                Q_EMIT documentRenamed(convId, documentId, name);
            });
    connect(&ConfigurationManager::instance(),
            &ConfigurationManagerInterface::collaborativeDocumentDelta,
            this,
            [this](const QString& accountId,
                   const QString& convId,
                   const QString& documentId,
                   const QString& deltaJson) {
                if (accountId != lrcInstance_->get_currentAccountId())
                    return;
                markDocumentUpdated(convId, documentId);
                Q_EMIT documentDelta(convId, documentId, deltaJson);
            });
}

QString
CollaborativeAdapter::createDocument(const QString& convId, const QString& name, const QString& kind)
{
    return ConfigurationManager::instance()
        .createCollaborativeDocument(lrcInstance_->get_currentAccountId(), convId, name, kind);
}

QString
CollaborativeAdapter::openDocument(const QString& convId, const QString& documentId)
{
    clearDocumentUpdated(convId, documentId);
    return ConfigurationManager::instance()
        .openCollaborativeDocument(lrcInstance_->get_currentAccountId(), convId, documentId);
}

void
CollaborativeAdapter::closeDocument(const QString& convId, const QString& documentId)
{
    ConfigurationManager::instance()
        .closeCollaborativeDocument(lrcInstance_->get_currentAccountId(), convId, documentId);
}

void
CollaborativeAdapter::edit(const QString& convId,
                           const QString& documentId,
                           int index,
                           int deleteLen,
                           const QString& insert)
{
    ConfigurationManager::instance().editCollaborativeDocument(lrcInstance_->get_currentAccountId(),
                                                               convId,
                                                               documentId,
                                                               index,
                                                               deleteLen,
                                                               insert);
}

void
CollaborativeAdapter::setCursor(const QString& convId,
                                const QString& documentId,
                                int position,
                                int anchor)
{
    ConfigurationManager::instance().setCollaborativeCursor(lrcInstance_->get_currentAccountId(),
                                                            convId,
                                                            documentId,
                                                            position,
                                                            anchor);
}

void
CollaborativeAdapter::setName(const QString& convId,
                              const QString& documentId,
                              const QString& name)
{
    ConfigurationManager::instance()
        .setCollaborativeDocumentName(lrcInstance_->get_currentAccountId(), convId, documentId, name);
}

QString
CollaborativeAdapter::documentName(const QString& convId, const QString& documentId)
{
    return ConfigurationManager::instance()
        .collaborativeDocumentName(lrcInstance_->get_currentAccountId(), convId, documentId);
}

void
CollaborativeAdapter::applyDelta(const QString& convId,
                                 const QString& documentId,
                                 const QString& deltaJson)
{
    ConfigurationManager::instance()
        .applyCollaborativeDelta(lrcInstance_->get_currentAccountId(), convId, documentId, deltaJson);
}

QString
CollaborativeAdapter::contentDelta(const QString& convId, const QString& documentId)
{
    return ConfigurationManager::instance()
        .collaborativeDocumentContentDelta(lrcInstance_->get_currentAccountId(), convId, documentId);
}

QVariantList
CollaborativeAdapter::documents(const QString& convId)
{
    QVariantList result;
    const auto accountId = lrcInstance_->get_currentAccountId();

    // Ask the daemon for every document in the conversation (read from its history),
    // so the list is complete regardless of which messages the UI has paged in.
    const VectorMapStringString docs = ConfigurationManager::instance()
                                           .getCollaborativeDocuments(accountId, convId);
    QSet<QString> seen;
    for (const auto& commit : docs) {
        const auto documentId = commit.value(QStringLiteral("uri"));
        if (documentId.isEmpty() || seen.contains(documentId))
            continue;
        seen.insert(documentId);

        // Prefer the live CRDT name (reflects renames); fall back to the announcing
        // commit's display name.
        QString name = ConfigurationManager::instance()
                           .collaborativeDocumentName(accountId, convId, documentId);
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

bool
CollaborativeAdapter::hasUnreadDocumentUpdate(const QString& convId) const
{
    return unreadDocumentUpdateCount(convId) > 0;
}

int
CollaborativeAdapter::unreadDocumentUpdateCount(const QString& convId) const
{
    auto it = updatedDocumentsByConversation_.constFind(convId);
    return it != updatedDocumentsByConversation_.constEnd() ? it->size() : 0;
}

bool
CollaborativeAdapter::hasUnreadDocumentUpdateForDocument(const QString& convId,
                                                         const QString& documentId) const
{
    auto it = updatedDocumentsByConversation_.constFind(convId);
    return it != updatedDocumentsByConversation_.constEnd() && it->contains(documentId);
}

void
CollaborativeAdapter::markDocumentUpdated(const QString& convId, const QString& documentId)
{
    auto& documents = updatedDocumentsByConversation_[convId];
    if (documents.contains(documentId))
        return;
    documents.insert(documentId);
    Q_EMIT documentUpdateIndicatorChanged(convId);
}

void
CollaborativeAdapter::clearDocumentUpdated(const QString& convId, const QString& documentId)
{
    auto it = updatedDocumentsByConversation_.find(convId);
    if (it == updatedDocumentsByConversation_.end() || !it->remove(documentId))
        return;
    if (it->isEmpty())
        updatedDocumentsByConversation_.erase(it);
    Q_EMIT documentUpdateIndicatorChanged(convId);
}
