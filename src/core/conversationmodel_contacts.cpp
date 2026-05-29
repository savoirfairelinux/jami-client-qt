/*
 * Copyright (C) 2017-2026 Savoir-faire Linux Inc.
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
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#include "api/conversationmodel.h"
#include "conversationmodel_p.h"

#include "api/lrc.h"
#include "api/behaviorcontroller.h"
#include "api/contactmodel.h"
#include "api/callmodel.h"
#include "api/accountmodel.h"
#include "api/account.h"
#include "api/call.h"
#include "api/datatransfer.h"
#include "api/datatransfermodel.h"
#include "callbackshandler.h"
#include "authority/storagehelper.h"
#include "dbus/configurationmanager.h"
#include "dbus/callmanager.h"

#include <account_const.h>
#include <datatransfer_interface.h>
#include <QtCore/QTimer>
#include <QFileInfo>
#include <algorithm>
#include <mutex>
#include <regex>

namespace lrc {

using namespace authority;
using namespace api;

void
ConversationModel::slotContactUpdated(const QString& uri)
{
    // Update all d_->conversations with this peer
    for (auto& conversation : d_->conversations) {
        auto members = peersForConversationInfo(conversation);
        if (members.indexOf(uri) != -1) {
            invalidateModel();
            Q_EMIT conversationUpdated(conversation.uid);
            { const auto _idx = index(indexOf(conversation.uid)); Q_EMIT dataChanged(_idx, _idx); }
        }
    }

    // TODO: investigate and possibly refactor the following search list management.
    // Might just need comments to clarify the intent.
    if (d_->currentFilter.isEmpty()) {
        if (d_->searchResults.empty())
            return;
        d_->searchResults.clear();
        Q_EMIT searchResultUpdated();
        return;
    }

    d_->searchResults.clear();
    auto users = owner.contactModel->getSearchResults();
    for (auto& user : users) {
        auto uid = owner.profileInfo.type == profile::Type::SIP ? "SEARCHSIP" : user.profileInfo.uri;
        conversation::Info conversationInfo(uid, &owner);
        // For SIP, we always got one search result, so "" is ok as there is no empty uri
        // For Jami accounts, the nameserver can return several results, so we use the uniqueness of
        // the id as id for a temporary conversation.
        conversationInfo.participants.append(member::Member {user.profileInfo.uri, member::Role::MEMBER});
        d_->searchResults.emplace_front(std::move(conversationInfo));
    }
    Q_EMIT searchResultUpdated();
    Q_EMIT searchResultEnded();
}


void
ConversationModel::slotContactAdded(const QString& contactUri)
{
    QString convId;
    try {
        convId = owner.contactModel->getContact(contactUri).conversationId;
    } catch (std::out_of_range& e) {
        return;
    }
    auto isSip = owner.profileInfo.type == profile::Type::SIP;
    auto isSwarm = !convId.isEmpty();
    auto conv = !isSwarm ? (isSip ? storage::getConversationsWithPeer(d_->db, contactUri) : VectorString {})
                         : VectorString {convId};
    if (conv.isEmpty()) {
        if (isSip) {
            auto convId = storage::beginConversationWithPeer(d_->db,
                                                             contactUri,
                                                             true,
                                                             owner.contactModel->getAddedTs(contactUri));
            addConversationWith(convId, contactUri, false);
            Q_EMIT conversationReady(convId, contactUri);
            Q_EMIT newConversation(convId);
        }
        return;
    }
    convId = conv[0];
    try {
        auto& conversation = convForUid(convId).get();
        MapStringString details = ConfigurationManager::instance().conversationInfos(owner.id, conversation.uid);
        bool needsSyncing = details["syncing"] == "true";
        if (conversation.needsSyncing != needsSyncing) {
            conversation.isRequest = false;
            conversation.needsSyncing = needsSyncing;
            { const auto _idx = index(indexOf(conversation.uid)); Q_EMIT dataChanged(_idx, _idx); }
            Q_EMIT conversationUpdated(conversation.uid);
            invalidateModel();
            Q_EMIT modelChanged();
        }
    } catch (...) {
        if (isSwarm) {
            addSwarmConversation(convId);
        }
    }
}


void
ConversationModel::slotPendingContactAccepted(const QString& uri)
{
    profile::Type type = profile::Type::INVALID;
    try {
        type = owner.contactModel->getContact(uri).profileInfo.type;
    } catch (std::out_of_range& e) {
    }
    profile::Info profileInfo {uri, {}, {}, type};
    storage::vcard::setProfile(owner.id, profileInfo, true);
    auto isSip = owner.profileInfo.type == profile::Type::SIP;
    auto convs = isSip ? storage::getConversationsWithPeer(d_->db, uri) : VectorString {};
    if (!convs.empty()) {
        try {
            auto contact = owner.contactModel->getContact(uri);
            auto interaction = interaction::Info {uri,
                                                  {},
                                                  std::time(nullptr),
                                                  0,
                                                  interaction::Type::CONTACT,
                                                  interaction::Status::SUCCESS,
                                                  true};
            auto msgId = storage::addMessageToConversation(d_->db, convs[0], interaction);
            interaction.body = storage::getContactInteractionString(uri, interaction::Status::SUCCESS);
            auto convIdx = indexOf(convs[0]);
            if (convIdx >= 0) {
                d_->conversations[convIdx].interactions->append(msgId, interaction);
            }
            d_->filteredConversations.invalidate();
            Q_EMIT newInteraction(convs[0], msgId, interaction);
            { const auto idx = index(convIdx); Q_EMIT dataChanged(idx, idx); }
        } catch (std::out_of_range& e) {
            qDebug() << "ConversationModel::slotContactAdded is unable to find contact.";
        }
    }
}


void
ConversationModel::slotContactRemoved(const QString& uri)
{
    std::vector<QString> convIdsToRemove;

    // save the ids to remove from the list
    for (auto i : getIndicesForContact(uri)) {
        convIdsToRemove.emplace_back(d_->conversations[i].uid);
    }

    // actually remove them from the list
    for (const auto& id : convIdsToRemove) {
        eraseConversation(id);
        Q_EMIT conversationRemoved(id);
    }

    invalidateModel();
    Q_EMIT modelChanged();
}


void
ConversationModel::slotSwarmLoaded(uint32_t requestId,
                                        const QString& accountId,
                                        const QString& conversationId,
                                        const VectorSwarmMessage& messages)
{
    if (accountId != owner.id)
        return;
    auto allLoaded = false;
    try {
        auto& conversation = convForUid(conversationId).get();
        for (const auto& message : messages) {
            QString msgId = message.id;
            auto msg = interaction::Info(message, owner.profileInfo.uri, accountId, conversationId);
            auto downloadFile = false;
            if (msg.type == interaction::Type::INITIAL) {
                allLoaded = true;
            } else if (msg.type == interaction::Type::DATA_TRANSFER) {
                QString fileId = message.body.value("fileId");
                owner.dataTransferModel->registerTransferId(fileId, msgId);
                downloadFile = (msg.transferStatus == interaction::TransferStatus::TRANSFER_AWAITING_HOST);
            }

            // If message is loaded, insert message at beginning
            if (!conversation.interactions->insert(msgId, msg, 0)) {
                qDebug() << Q_FUNC_INFO << "Insert failed: duplicate ID.";
                continue;
            }

            if (downloadFile) {
                handleIncomingFile(conversationId, msgId, QString(message.body.value("totalSize")).toInt());
            }
        }

        conversation.lastSelfMessageId = conversation.interactions->lastSelfMessageId(owner.profileInfo.uri);
        invalidateModel();
        Q_EMIT modelChanged();
        Q_EMIT newMessagesAvailable(owner.id, conversationId);
        auto conversationIdx = indexOf(conversationId);
        { const auto idx = index(conversationIdx); Q_EMIT dataChanged(idx, idx); }
        Q_EMIT conversationMessagesLoaded(requestId, conversationId);
        if (allLoaded) {
            conversation.allMessagesLoaded = true;
            Q_EMIT conversationUpdated(conversationId);
        }
    } catch (const std::exception& e) {
        qWarning() << e.what();
    }
}


void
ConversationModel::slotMessagesFound(uint32_t requestId,
                                          const QString& accountId,
                                          const QString& conversationId,
                                          const VectorMapStringString& messageIds)
{
    QMap<QString, interaction::Info> messageDetailedInformation;
    if (requestId == d_->mediaResearchRequestId) {
        Q_FOREACH (const MapStringString& msg, messageIds) {
            auto intInfo = interaction::Info(msg, "", accountId, conversationId);
            messageDetailedInformation[msg["id"]] = std::move(intInfo);
        }
    } else if (requestId == d_->msgResearchRequestId) {
        Q_FOREACH (const MapStringString& msg, messageIds) {
            auto intInfo = interaction::Info(msg, "", accountId, conversationId);
            if (intInfo.type == interaction::Type::TEXT) {
                messageDetailedInformation[msg["id"]] = std::move(intInfo);
            }
        }
    }
    Q_EMIT messagesFoundProcessed(accountId, messageDetailedInformation);
}


void
ConversationModel::slotConversationReady(const QString& accountId, const QString& conversationId)
{
    // we receive this signal after we accept or after we send a conversation request
    if (accountId != owner.id) {
        return;
    }
    // remove non swarm conversation that was added from slotContactAdded
    const VectorMapStringString& members = ConfigurationManager::instance().getConversationMembers(accountId,
                                                                                                   conversationId);
    QVector<member::Member> participants;
    // it means conversation with one participant. In this case we could have non swarm conversation
    bool shouldRemoveNonSwarmConversation = members.size() == 2;
    for (const auto& member : members) {
        participants.append({member["uri"], api::member::to_role(member["role"])});
        if (shouldRemoveNonSwarmConversation) {
            try {
                auto& conversation = convForPeerUri(member["uri"]).get();
                // remove non swarm conversation
                if (conversation.isLegacy()) {
                    eraseConversation(conversation.uid);
                    storage::removeContactConversations(d_->db, member["uri"]);
                    invalidateModel();
                    Q_EMIT conversationRemoved(conversation.uid);
                    Q_EMIT modelChanged();
                }
            } catch (...) {
            }
        }
    }

    auto conversationIt = d_->conversationMap.find(conversationId);
    bool conversationExists = conversationIt != d_->conversationMap.end();

    if (!conversationExists) {
        addSwarmConversation(conversationId);
        conversationIt = d_->conversationMap.find(conversationId);
        if (conversationIt == d_->conversationMap.end()) {
            return;
        }
    }
    auto& conversation = d_->conversations.at(conversationIt->second);
    if (conversationExists) {
        // if swarm request already exists, update participnts
        conversation.participants = participants;
        const MapStringString& details = ConfigurationManager::instance().conversationInfos(accountId, conversationId);
        conversation.infos = details;
        const MapStringString& preferences = ConfigurationManager::instance().getConversationPreferences(accountId,
                                                                                                         conversationId);
        conversation.preferences = preferences;
        conversation.mode = conversation::to_mode(details["mode"].toInt());
        conversation.isRequest = false;
        conversation.needsSyncing = false;
        Q_EMIT conversationUpdated(conversationId);
        { const auto _idx = index(indexOf(conversationId)); Q_EMIT dataChanged(_idx, _idx); }
        ConfigurationManager::instance().loadConversation(owner.id, conversationId, "", 0);
        auto& peers = peersForConversationInfo(conversation);
        if (peers.size() == 1)
            Q_EMIT conversationReady(conversationId, peers.front());
        return;
    }
    invalidateModel();
    // we use conversationReady callback only for conversation with one participant. We could use
    // participants.front()
    auto& peers = peersForConversationInfo(conversation);
    if (peers.size() == 1)
        Q_EMIT conversationReady(conversationId, peers.front());
    Q_EMIT newConversation(conversationId);
    Q_EMIT modelChanged();
}


void
ConversationModel::slotConversationRemoved(const QString& accountId, const QString& conversationId)
{
    if (accountId != owner.id)
        return;
    try {
        eraseConversation(conversationId);
        invalidateModel();
        Q_EMIT conversationRemoved(conversationId);
    } catch (const std::exception& e) {
        qWarning() << e.what();
    }
}


void
ConversationModel::slotConversationMemberEvent(const QString& accountId,
                                                    const QString& conversationId,
                                                    const QString& memberUri,
                                                    int event)
{
    if (accountId != owner.id || indexOf(conversationId) < 0) {
        return;
    }
    if (event == 0 /* add */) {
        // clear search result
        for (unsigned int i = 0; i < d_->searchResults.size(); ++i) {
            if (d_->searchResults.at(i).uid == memberUri)
                d_->searchResults.erase(d_->searchResults.begin() + i);
        }
    }
    // update participants
    try {
        auto& conversation = convForUid(conversationId).get();
        const VectorMapStringString& members = ConfigurationManager::instance().getConversationMembers(owner.id,
                                                                                                       conversationId);
        QVector<member::Member> participants;
        for (auto& member : members) {
            participants.append(member::Member {member["uri"], member::to_role(member["role"])});
        }
        conversation.participants = participants;
        invalidateModel();
    } catch (...) {
    }
    Q_EMIT modelChanged();
    Q_EMIT conversationUpdated(conversationId);
    { const auto _idx = index(indexOf(conversationId)); Q_EMIT dataChanged(_idx, _idx); }
}


void
ConversationModel::slotOnConversationError(const QString& accountId,
                                                const QString& conversationId,
                                                int code,
                                                const QString& what)
{
    if (accountId != owner.id || indexOf(conversationId) < 0) {
        return;
    }
    try {
        auto& conversation = convForUid(conversationId).get();
        conversation.errors.push_back({code, what});
        Q_EMIT conversationErrorsUpdated(conversationId);
    } catch (...) {
    }
}


void
ConversationModel::slotConversationRequestReceived(const QString& accountId,
                                                        const QString&,
                                                        const MapStringString& metadatas)
{
    if (accountId != owner.id)
        return;
    addConversationRequest(metadatas, true);
}


void
ConversationModel::slotConversationPreferencesUpdated(const QString& accountId,
                                                           const QString& conversationId,
                                                           const MapStringString& preferences)
{
    if (accountId != owner.id)
        return;
    try {
        auto& conversation = convForUid(conversationId).get();
        conversation.preferences = preferences;
        Q_EMIT conversationPreferencesUpdated(conversationId);
    } catch (const std::out_of_range&) {
        qWarning() << Q_FUNC_INFO << "Unable to find conversation" << conversationId;
    }
}


void
ConversationModel::addSwarmConversation(const QString& convId)
{
    if (Lrc::dbusIsValid()) {
        // Because the daemon may have already loaded interactions
        // we clear them to receive all signals
        ConfigurationManager::instance().clearCache(owner.id, convId);
    }
    QVector<member::Member> participants;
    const VectorMapStringString& members = ConfigurationManager::instance().getConversationMembers(owner.id,
                                                                                                   convId);
    auto accountURI = owner.profileInfo.uri;
    QString otherMember;
    const MapStringString& details = ConfigurationManager::instance().conversationInfos(owner.id, convId);
    auto mode = conversation::to_mode(details["mode"].toInt());
    conversation::Info conversation(convId, &owner);
    conversation.infos = details;
    VectorMapStringString activeCalls = ConfigurationManager::instance().getActiveCalls(owner.id, convId);
    conversation.activeCalls = activeCalls;
    QString lastRead;
    VectorString membersLeft;
    for (auto& member : members) {
        // this check should be removed once all usage of participants replaced by
        // peersForConversation. We should have ourself in participants list
        // Note: if members.size() == 1, it's a conv with self so we're also the peer
        participants.append(member::Member {member["uri"], member::to_role(member["role"])});
        if (mode == conversation::Mode::ONE_TO_ONE && member["uri"] != accountURI) {
            otherMember = member["uri"];
        } else if (member["uri"] == accountURI) {
            lastRead = member["lastDisplayed"];
        } else if (mode != conversation::Mode::ONE_TO_ONE) {
            // Note: a conversation may be with non contacts.
            // So, refresh bestName to be sure to get quick updates in UI
            owner.contactModel->bestNameForContact(member["uri"]);
        }
        if (member["uri"] != accountURI)
            conversation.interactions->setRead(member["uri"], member["lastDisplayed"]);
        if (member["role"] == "left")
            membersLeft.append(member["uri"]);
    }
    conversation.participants = participants;
    conversation.mode = mode;
    const MapStringString& preferences = ConfigurationManager::instance().getConversationPreferences(owner.id,
                                                                                                     convId);
    conversation.preferences = preferences;
    conversation.unreadMessages = ConfigurationManager::instance().countInteractions(owner.id,
                                                                                     convId,
                                                                                     lastRead,
                                                                                     "",
                                                                                     accountURI);
    if (mode == conversation::Mode::ONE_TO_ONE && !otherMember.isEmpty()) {
        try {
            conversation.confId = owner.callModel->getConferenceFromURI(otherMember).id;
        } catch (...) {
            conversation.confId = "";
        }
        try {
            conversation.callId = owner.callModel->getCallFromURI(otherMember).id;
        } catch (...) {
            conversation.callId = "";
        }
    }
    // If conversation has only one peer it is possible that non swarm conversation was created.
    // remove non swarm conversation
    auto& peers = peersForConversationInfo(conversation);
    if (peers.size() == 1) {
        try {
            auto& participantId = peers.front();
            auto& conv = convForPeerUri(participantId).get();
            if (conv.mode == conversation::Mode::NON_SWARM) {
                eraseConversation(conv.uid);
                invalidateModel();
                Q_EMIT conversationRemoved(conv.uid);
                storage::removeContactConversations(d_->db, participantId);
            }
        } catch (...) {
        }
    }
    if (details["syncing"] == "true") {
        MapStringString messageMap = {
            {"type", "initial"},
            {"author", otherMember},
            {"timestamp", details["created"]},
            {"linearizedParent", ""},
        };
        auto msg = interaction::Info(messageMap, owner.profileInfo.uri);
        conversation.interactions->append(convId, msg);
        conversation.needsSyncing = true;
        Q_EMIT conversationUpdated(conversation.uid);
        { const auto _idx = index(indexOf(conversation.uid)); Q_EMIT dataChanged(_idx, _idx); }
    }
    emplaceBackConversation(std::move(conversation));
    ConfigurationManager::instance().loadConversation(owner.id, convId, "", 1);
}


void
ConversationModel::addConversationWith(const QString& convId, const QString& contactUri, bool isRequest)
{
    conversation::Info conversation(convId, &owner);
    conversation.participants = {{contactUri, member::Role::MEMBER}};
    conversation.mode = conversation::Mode::NON_SWARM;
    conversation.needsSyncing = false;
    conversation.isRequest = isRequest;

    try {
        conversation.confId = owner.callModel->getConferenceFromURI(contactUri).id;
    } catch (...) {
        conversation.confId = "";
    }
    try {
        conversation.callId = owner.callModel->getCallFromURI(contactUri).id;
    } catch (...) {
        conversation.callId = "";
    }
    auto isSip = owner.profileInfo.type == profile::Type::SIP;
    if (isSip) {
        storage::getHistory(d_->db, conversation, owner.profileInfo.uri);

        QList<std::function<void(void)>> toUpdate;
        conversation.interactions->forEach([&](const QString& id, interaction::Info& interaction) {
            if (interaction.status != interaction::Status::SENDING) {
                return;
            }
            // Get the message status from daemon, else unknown
            auto daemonId = storage::getDaemonIdByInteractionId(d_->db, id);
            int status = 0;
            if (daemonId.isEmpty()) {
                return;
            }
            try {
                auto msgId = std::stoull(daemonId.toStdString());
                status = ConfigurationManager::instance().getMessageStatus(msgId);
                toUpdate.emplace_back([this, convId, contactUri, daemonId, status]() {
                    auto accId = owner.id;
                    updateInteractionStatus(accId, convId, contactUri, daemonId, status);
                });
            } catch (const std::exception& e) {
                qWarning() << Q_FUNC_INFO << "Failed: message id was invalid";
            }
        });
        Q_FOREACH (const auto& func, toUpdate)
            func();
    }

    conversation.unreadMessages = getNumberOfUnreadMessagesFor(convId);

    emplaceBackConversation(std::move(conversation));
    invalidateModel();
}


void
ConversationModel::addConversationRequest(const MapStringString& convRequest, bool emitToClient)
{
    auto convId = convRequest["id"];
    auto convIdx = indexOf(convId);
    if (convIdx != -1)
        return;

    auto peerUri = convRequest["from"];
    auto mode = conversation::to_mode(convRequest["mode"].toInt());
    QString callId, confId;
    const MapStringString& details = ConfigurationManager::instance().conversationInfos(owner.id, convId);
    conversation::Info conversation(convId, &owner);
    conversation.infos = details;
    conversation.callId = callId;
    conversation.confId = confId;
    conversation.participants = {{owner.profileInfo.uri, member::Role::INVITED}, {peerUri, member::Role::MEMBER}};
    conversation.mode = mode;
    conversation.isRequest = true;

    MapStringString messageMap = {
        {"type", "initial"},
        {"mode", QString::number(static_cast<int>(mode))},
        {"author", peerUri},
        {"timestamp", convRequest["received"]},
        {"linearizedParent", ""},
    };
    auto msg = interaction::Info(messageMap, owner.profileInfo.uri);
    conversation.interactions->insert(convId, msg, 0);

    // add the author to the contact model's contact list as a PENDING
    // if they aren't already a contact
    auto isSelf = owner.profileInfo.uri == peerUri;
    if (isSelf)
        return;

    if (mode == conversation::Mode::ONE_TO_ONE) {
        try {
            profile::Info profileInfo;
            profileInfo.uri = peerUri;
            profileInfo.type = profile::Type::JAMI;
            profileInfo.alias = details["title"];
            profileInfo.avatar = details["avatar"];
            contact::Info contactInfo;
            contactInfo.profileInfo = profileInfo;
            owner.contactModel->addContact(contactInfo);
        } catch (std::out_of_range&) {
            qWarning() << "Couldn't find contact request conversation for" << peerUri;
        }
    }

    emplaceBackConversation(std::move(conversation));
    invalidateModel();
    Q_EMIT newConversation(convId);
    Q_EMIT modelChanged();
    if (!callId.isEmpty()) {
        // If we replace a non swarm request by a swarm request while having a call.
        selectConversation(convId);
    }
    if (emitToClient)
        Q_EMIT d_->behaviorController.newTrustRequest(owner.id, convId, peerUri);
}


void
ConversationModel::addContactRequest(const QString& contactUri)
{
    try {
        convForPeerUri(contactUri).get();
        // request from contact already exists, return
        return;
    } catch (std::out_of_range&) {
        // no conversation exists. Add contact request
        conversation::Info conversation(contactUri, &owner);
        conversation.participants = {{contactUri, member::Role::INVITED}};
        conversation.mode = conversation::Mode::NON_SWARM;
        conversation.isRequest = true;
        emplaceBackConversation(std::move(conversation));
        invalidateModel();
        Q_EMIT newConversation(contactUri);
        Q_EMIT modelChanged();
    }
}


void
ConversationModel::sendContactRequest(const QString& contactUri)
{
    try {
        auto contact = owner.contactModel->getContact(contactUri);
        auto isNotUsed = contact.profileInfo.type == profile::Type::TEMPORARY
                         || contact.profileInfo.type == profile::Type::PENDING;
        if (isNotUsed)
            owner.contactModel->addContact(contact);
    } catch (std::out_of_range& e) {
    }
}


} // namespace lrc
