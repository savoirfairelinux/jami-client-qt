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
ConversationModel::slotMessageReceived(const QString& accountId,
                                            const QString& conversationId,
                                            const SwarmMessage& message)
{
    if (accountId != owner.id)
        return;
    try {
        auto& conversation = convForUid(conversationId).get();
        if (message.type == "initial") {
            conversation.allMessagesLoaded = true;
            Q_EMIT conversationUpdated(conversationId);
            if (message.body.find("invited") == message.body.end()) {
                return;
            }
        }
        QString msgId = message.id;
        auto msg = interaction::Info(message, owner.profileInfo.uri, accountId, conversationId);

        if (msg.type == interaction::Type::CALL) {
            msg.body = interaction::getCallInteractionString(msg.authorUri == owner.profileInfo.uri, msg);
        } else if (msg.type == interaction::Type::DATA_TRANSFER) {
            QString fileId = message.body.value("fileId");
            owner.dataTransferModel->registerTransferId(fileId, msgId);
        }

        if (!conversation.interactions->append(msgId, msg)) {
            qDebug() << Q_FUNC_INFO << "Append failed: duplicate ID." << msgId;
            return;
        }

        auto updateUnread = msg.authorUri != owner.profileInfo.uri;
        if (updateUnread)
            conversation.unreadMessages++;
        conversation.lastSelfMessageId = conversation.interactions->lastSelfMessageId(owner.profileInfo.uri);
        invalidateModel();
        if (!interaction::isOutgoing(msg) && updateUnread) {
            Q_EMIT d_->behaviorController.newUnreadInteraction(owner.id, conversationId, msgId, msg);
        }
        Q_EMIT newInteraction(conversationId, msgId, msg);
        Q_EMIT modelChanged();
        if (msg.transferStatus == interaction::TransferStatus::TRANSFER_AWAITING_HOST) {
            handleIncomingFile(conversationId, msgId, QString(message.body.value("totalSize")).toInt());
        }
        { const auto _idx = index(indexOf(conversationId)); Q_EMIT dataChanged(_idx, _idx); }
        // Update status
        using namespace libjami::Account;
        for (const auto& uri : message.status.keys()) {
            if (uri == owner.profileInfo.uri)
                continue;
            if (message.status.value(uri) == static_cast<int>(MessageStates::DISPLAYED))
                conversation.interactions->setRead(uri, message.id);
        }
    } catch (const std::exception& e) {
        qDebug() << "Messages received for conversation that does not exist.";
    }
}


void
ConversationModel::slotMessageUpdated(const QString& accountId,
                                           const QString& conversationId,
                                           const SwarmMessage& message)
{
    if (accountId != owner.id)
        return;
    try {
        auto& conversation = convForUid(conversationId).get();
        QString msgId = message.id;
        auto msg = interaction::Info(message, owner.profileInfo.uri, accountId, conversationId);

        if (!conversation.interactions->update(msgId, msg)) {
            qDebug() << "Message not found or unable to be reparented.";
            return;
        }
        // The conversation is updated, so we need to notify the view.
        invalidateModel();
        Q_EMIT modelChanged();
        { const auto _idx = index(indexOf(conversationId)); Q_EMIT dataChanged(_idx, _idx); }
    } catch (const std::exception& e) {
        qDebug() << "Messages received for conversation that does not exist.";
    }
}


void
ConversationModel::slotReactionAdded(const QString& accountId,
                                          const QString& conversationId,
                                          const QString& messageId,
                                          const MapStringString& reaction)
{
    if (accountId != owner.id) {
        return;
    }
    try {
        auto& conversation = convForUid(conversationId).get();
        conversation.interactions->addReaction(messageId, reaction);
    } catch (const std::exception& e) {
        qWarning() << e.what();
    }
    Q_EMIT reactionAdded(accountId, conversationId, messageId, reaction);
}


void
ConversationModel::slotReactionRemoved(const QString& accountId,
                                            const QString& conversationId,
                                            const QString& messageId,
                                            const QString& reactionId)
{
    if (accountId != owner.id) {
        return;
    }
    try {
        auto& conversation = convForUid(conversationId).get();
        conversation.interactions->rmReaction(messageId, reactionId);
    } catch (const std::exception& e) {
        qWarning() << e.what();
    }
    Q_EMIT reactionRemoved(accountId, conversationId, messageId, reactionId);
}


void
ConversationModel::slotNewAccountMessage(const QString& accountId,
                                              const QString& peerId,
                                              const QString& msgId,
                                              const MapStringString& payloads)
{
    if (accountId != owner.id)
        return;

    for (auto it = payloads.constBegin(); it != payloads.constEnd(); ++it) {
        const auto& payload = it.key();
        if (payload.contains(TEXT_PLAIN)) {
            addIncomingMessage(peerId, it.value(), 0, msgId);
        } else {
            qDebug() << payload;
        }
    }
}


void
ConversationModel::slotIncomingCallMessage(const QString& accountId,
                                                const QString& callId,
                                                const QString& from,
                                                const QString& body)
{
    if (accountId != owner.id || !owner.callModel->hasCall(callId))
        return;

    auto& call = owner.callModel->getCall(callId);
    if (call.type == call::Type::CONFERENCE) {
        // Show messages in all d_->conversations for conferences.
        for (const auto& conversation : d_->conversations) {
            if (conversation.confId == callId) {
                if (conversation.participants.empty()) {
                    continue;
                }
                addIncomingMessage(from, body);
            }
        }
    } else {
        addIncomingMessage(from, body);
    }
}


void
ConversationModel::slotComposingStatusChanged(const QString& accountId,
                                                   const QString& convId,
                                                   const QString& contactUri,
                                                   bool isComposing)
{
    if (accountId != owner.id)
        return;

    try {
        auto& conversation = convForUid(convId).get();
        if (isComposing)
            conversation.typers.insert(contactUri);
        else
            conversation.typers.remove(contactUri);
    } catch (const std::out_of_range& e) {
        qDebug() << "Unable to update message status for conversation that does not exist.";
    }

    Q_EMIT composingStatusChanged(convId, contactUri, isComposing);
}


void
ConversationModel::slotConversationProfileUpdated(const QString& accountId,
                                                       const QString& conversationId,
                                                       const MapStringString& profile)
{
    if (accountId != owner.id) {
        return;
    }
    try {
        auto& conversation = convForUid(conversationId).get();
        conversation.infos = profile;
        Q_EMIT profileUpdated(conversationId);
    } catch (...) {
    }
}


QString
ConversationModel::addIncomingMessage(const QString& peerId,
                                           const QString& body,
                                           const uint64_t& timestamp,
                                           const QString& daemonId)
{
    if (owner.profileInfo.type != profile::Type::SIP)
        return "";
    auto convIds = storage::getConversationsWithPeer(d_->db, peerId);
    if (convIds.empty()) {
        // in case if we receive a message after removing contact, add a conversation request
        try {
            auto contact = owner.contactModel->getContact(peerId);
            convIds.push_back(storage::beginConversationWithPeer(d_->db, contact.profileInfo.uri));
            auto& conv = convForPeerUri(contact.profileInfo.uri).get();
            conv.uid = convIds[0];
        } catch (const std::out_of_range&) {
            return "";
        }
    }
    auto msg = interaction::Info {peerId,
                                  body,
                                  timestamp == 0 ? std::time(nullptr) : static_cast<time_t>(timestamp),
                                  0,
                                  interaction::Type::TEXT,
                                  interaction::Status::SUCCESS,
                                  false};
    auto msgId = storage::addMessageToConversation(d_->db, convIds[0], msg);
    if (!daemonId.isEmpty()) {
        storage::addDaemonMsgId(d_->db, msgId, daemonId);
    }
    auto conversationIdx = indexOf(convIds[0]);
    // Add the conversation if not already here
    if (conversationIdx == -1) {
        addConversationWith(convIds[0], peerId, false);
        Q_EMIT newConversation(convIds[0]);
    } else {
        // Maybe check if this is failing?
        d_->conversations[conversationIdx].interactions->append(msgId, msg);
        d_->conversations[conversationIdx].unreadMessages = getNumberOfUnreadMessagesFor(convIds[0]);
    }

    Q_EMIT d_->behaviorController.newUnreadInteraction(owner.id, convIds[0], msgId, msg);
    Q_EMIT newInteraction(convIds[0], msgId, msg);

    invalidateModel();
    Q_EMIT modelChanged();
    { const auto idx = index(conversationIdx); Q_EMIT dataChanged(idx, idx); }

    return msgId;
}


void
ConversationModel::updateInteractionStatus(const QString& accountId,
                                                const QString& conversationId,
                                                const QString& peerUri,
                                                const QString& messageId,
                                                int status)
{
    if (accountId != owner.id) {
        return;
    }
    try {
        auto& conversation = convForUid(conversationId).get();
        // Proceed only if the conversation is a swarm
        if (!conversation.isSwarm() || peerUri == owner.profileInfo.uri) {
            return;
        }

        auto emitDisplayed = false;
        using namespace libjami::Account;
        auto msgState = static_cast<MessageStates>(status);
        auto& interactions = conversation.interactions;
        interactions->with(messageId, [&](const QString& id, const interaction::Info&) {
            interaction::Status newState;
            if (msgState == MessageStates::SENDING) {
                newState = interaction::Status::SENDING;
            } else if (msgState == MessageStates::SENT) {
                newState = interaction::Status::SUCCESS;
            } else if (msgState == MessageStates::DISPLAYED) {
                newState = interaction::Status::DISPLAYED;
            } else {
                return;
            }
            if (interactions->updateStatus(id, newState) && newState == interaction::Status::DISPLAYED) {
                emitDisplayed = true;
            }
        });

        if (emitDisplayed)
            conversation.interactions->setRead(peerUri, messageId);
    } catch (const std::out_of_range& e) {
        qDebug() << "Unable to update message status for conversation that does not exist.";
    }
}


int
ConversationModel::getNumberOfUnreadMessagesForImpl(const QString& uid)
{
    return storage::countUnreadFromInteractions(d_->db, uid);
}


} // namespace lrc
