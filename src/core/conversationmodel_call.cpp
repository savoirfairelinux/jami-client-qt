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
ConversationModel::slotNewCall(const QString& fromId, const QString& callId, bool isOutgoing, const QString& toUri)
{
    if (isOutgoing) {
        // search contact
        d_->currentFilter = fromId;
        invalidateModel();
        d_->searchResults.clear();
        Q_EMIT searchResultUpdated();
        owner.contactModel->searchContact(d_->currentFilter);
        Q_EMIT filterChanged();
    }

    if (toUri == owner.profileInfo.uri) {
        auto isSip = owner.profileInfo.type == profile::Type::SIP;
        auto convIds = isSip ? storage::getConversationsWithPeer(d_->db, fromId) : VectorString {};
        if (convIds.empty()) {
            // in case if we receive call after removing contact add conversation request;
            try {
                auto contact = owner.contactModel->getContact(fromId);
                if (!isOutgoing && !contact.isBanned && fromId != owner.profileInfo.uri) {
                    addContactRequest(fromId);
                }
                if (isOutgoing && contact.profileInfo.type == profile::Type::TEMPORARY) {
                    owner.contactModel->addContact(contact);
                }
            } catch (const std::out_of_range&) {
            }
        }

        auto conversationIndices = getIndicesForContact(fromId);
        if (conversationIndices.empty()) {
            qDebug() << "ConversationModel::slotNewCall, but conversation not found.";
            return; // Not a contact
        }

        auto& conversation = d_->conversations.at(conversationIndices.at(0));
        conversation.callId = callId;

        addOrUpdateCallMessage(callId, fromId, true);
        Q_EMIT d_->behaviorController.showIncomingCallView(owner.id, conversation.uid);
    }
}


void
ConversationModel::slotCallStatusChanged(const QString& accountId, const QString& callId, int code)
{
    Q_UNUSED(code)
    // Get conversation
    auto i = std::find_if(d_->conversations.begin(), d_->conversations.end(), [callId](const conversation::Info& conversation) {
        return conversation.callId == callId;
    });

    try {
        auto accountProperties = d_->lrc.getAccountModel().getAccountConfig(accountId);
        auto call = owner.callModel->getCall(callId);
        if (i != d_->conversations.end()
            && (!accountProperties.denySecondCall || call.status == call::Status::IN_PROGRESS)) {
            // Update interaction status
            invalidateModel();
            selectConversation(i->uid);
            Q_EMIT conversationUpdated(i->uid);
            { const auto _idx = index(indexOf(i->uid)); Q_EMIT dataChanged(_idx, _idx); }
        }
    } catch (std::out_of_range& e) {
        qDebug() << "ConversationModel::slotCallStatusChanged is unable to get nonexistent call.";
    }
}


void
ConversationModel::slotCallStarted(const QString& callId)
{
    try {
        auto call = owner.callModel->getCall(callId);
        addOrUpdateCallMessage(callId, call.peerUri.remove("jami:"), !call.isOutgoing);
    } catch (std::out_of_range& e) {
        qDebug() << "ConversationModel::slotCallStarted is unable to start nonexistent call.";
    }
}


void
ConversationModel::slotCallEnded(const QString& callId)
{
    try {
        auto call = owner.callModel->getCall(callId);
        // get duration
        std::time_t duration = 0;
        if (call.startTime.time_since_epoch().count() != 0) {
            auto duration_ns = std::chrono::steady_clock::now() - call.startTime;
            duration = std::chrono::duration_cast<std::chrono::seconds>(duration_ns).count();
        }
        // add or update call interaction with duration
        addOrUpdateCallMessage(callId, call.peerUri.remove("jami:"), !call.isOutgoing, duration);
        /* Reset the callId stored in the conversation.
           Do not call selectConversation() since it is already done in slotCallStatusChanged. */
        size_t idx = 0;
        for (auto& conversation : d_->conversations) {
            if (conversation.callId == callId) {
                conversation.callId = "";
                conversation.confId = ""; // The participant is detached
                invalidateModel();
                Q_EMIT conversationUpdated(conversation.uid);
                { const auto _idx = index(idx); Q_EMIT dataChanged(_idx, _idx); }
            }
            ++idx;
        }
    } catch (std::out_of_range& e) {
        qDebug() << "ConversationModel::slotCallEnded is unable to end nonexistent call.";
    }
}


void
ConversationModel::slotCallAddedToConference(const QString& callId,
                                                  const QString& conversationId,
                                                  const QString& confId)
{
    for (auto& conversation : d_->conversations) {
        if ((conversationId == conversation.uid)
            || (!callId.isEmpty() && conversation.callId == callId && conversation.confId != confId)) {
            conversation.confId = confId;
            invalidateModel();
            // Refresh the conference status only if attached
            MapStringString confDetails = CallManager::instance().getConferenceDetails(owner.id, confId);
            if (confDetails["STATE"] == "ACTIVE_ATTACHED")
                selectConversation(conversation.uid);
            return;
        }
    }
}


void
ConversationModel::slotActiveCallsChanged(const QString& accountId,
                                               const QString& conversationId,
                                               const VectorMapStringString& activeCalls)
{
    if (accountId != owner.id || indexOf(conversationId) < 0) {
        return;
    }
    try {
        auto& conversation = convForUid(conversationId).get();
        conversation.activeCalls = activeCalls;
        if (activeCalls.empty())
            conversation.ignoredActiveCalls.clear();
        Q_EMIT activeCallsChanged(accountId, conversationId);
    } catch (...) {
    }
}


void
ConversationModel::addOrUpdateCallMessage(const QString& callId,
                                               const QString& from,
                                               bool incoming,
                                               const std::time_t& duration)
{
    auto isSip = owner.profileInfo.type == profile::Type::SIP;
    // Get conversation
    auto conv_it = std::find_if(d_->conversations.begin(),
                                d_->conversations.end(),
                                [&callId](const conversation::Info& conversation) {
                                    return conversation.callId == callId;
                                });
    if (conv_it == d_->conversations.end()) {
        // If we have no conversation with peer.
        try {
            auto contact = owner.contactModel->getContact(from);
            if (contact.profileInfo.type == profile::Type::PENDING) {
                addContactRequest(from);
                if (isSip) {
                    storage::beginConversationWithPeer(d_->db, contact.profileInfo.uri);
                }
            }
        } catch (const std::exception&) {
            return;
        }
        try {
            auto& conv = convForPeerUri(from).get();
            if (!conv.isSwarm() && conv.callId.isEmpty()) {
                conv.callId = callId;
            }
        } catch (...) {
            return;
        }
    }
    if (!isSip || conv_it == d_->conversations.end() || conv_it->isSwarm())
        return;
    auto uriString = incoming ? storage::prepareUri(from, owner.profileInfo.type) : owner.profileInfo.uri;
    auto msg = interaction::Info {uriString,
                                  {},
                                  std::time(nullptr),
                                  duration,
                                  interaction::Type::CALL,
                                  interaction::Status::SUCCESS,
                                  true};
    // update the d_->db
    auto msgId = storage::addOrUpdateMessage(d_->db, conv_it->uid, msg, callId);
    // now set the formatted call message string in memory only
    msg.body = interaction::getCallInteractionString(msg.authorUri == owner.profileInfo.uri, msg);
    auto [added, success] = conv_it->interactions->addOrUpdate(msgId, msg);
    if (!success) {
        qWarning() << Q_FUNC_INFO << QString("Failed: to %1 msg").arg(added ? "add" : "update");
        return;
    }
    if (added)
        Q_EMIT newInteraction(conv_it->uid, msgId, msg);

    invalidateModel();
    Q_EMIT modelChanged();
    { const auto _idx = index(static_cast<int>(std::distance(d_->conversations.begin(), conv_it))); Q_EMIT dataChanged(_idx, _idx); }
}


void
ConversationModel::startCallImpl(const QString& uid, bool isAudioOnly)
{
    try {
        auto& conversation = convForUid(uid, true).get();
        if (conversation.participants.empty()) {
            // Should not
            qDebug() << "ConversationModel::startCall is unable to call a conversation without participants.";
            return;
        }

        if (!conversation.isCoreDialog() && conversation.isSwarm()) {
            qDebug() << "Start call for swarm:" + uid;
            conversation.callId = owner.callModel->createCall("swarm:" + uid, false, {}, isAudioOnly);

            // Update interaction status
            invalidateModel();
            selectConversation(conversation.uid);
            Q_EMIT conversationUpdated(conversation.uid);
            { const auto _idx = index(indexOf(conversation.uid)); Q_EMIT dataChanged(_idx, _idx); }
            return;
        }

        auto& peers = peersForConversationInfo(conversation);
        // there is no calls in group with more than 2 participants
        if (peers.size() != 1) {
            return;
        }
        // Disallow multiple call
        if (!conversation.callId.isEmpty()) {
            try {
                auto call = owner.callModel->getCall(conversation.callId);
                switch (call.status) {
                case call::Status::INCOMING_RINGING:
                case call::Status::OUTGOING_RINGING:
                case call::Status::CONNECTING:
                case call::Status::SEARCHING:
                case call::Status::PAUSED:
                case call::Status::IN_PROGRESS:
                case call::Status::CONNECTED:
                    return;
                case call::Status::INVALID:
                case call::Status::INACTIVE:
                case call::Status::ENDED:
                case call::Status::PEER_BUSY:
                case call::Status::TIMEOUT:
                case call::Status::TERMINATING:
                default:
                    break;
                }
            } catch (const std::out_of_range&) {
            }
        }

        auto convId = uid;

        auto participant = peers.front();
        bool isTemporary = convId == participant || convId == "SEARCHSIP";
        auto contactInfo = owner.contactModel->getContact(participant);
        auto uri = contactInfo.profileInfo.uri;

        if (uri.isEmpty())
            return; // Incorrect item

        // Don't call blocked contact
        if (contactInfo.isBanned) {
            qDebug() << "ContactModel::startCall: denied, contact is blocked.";
            return;
        }

        if (owner.profileInfo.type != profile::Type::SIP) {
            uri = "jami:" + uri; // Add jami: before or it will fail.
        }

        auto cb = ([this, isTemporary, uri, isAudioOnly, &conversation](QString conversationId) {
            if (indexOf(conversationId) < 0) {
                qDebug() << "Unable to start call: conversation does not exist.";
                return;
            }

            auto& newConv = isTemporary ? convForUid(conversationId).get() : conversation;

            newConv.callId = owner.callModel->createCall(uri, isAudioOnly);
            if (newConv.callId.isEmpty()) {
                qDebug() << "Unable to start call (daemon side failure?)";
                return;
            }

            invalidateModel();

            Q_EMIT d_->behaviorController.showIncomingCallView(owner.id, newConv.uid);
        });

        if (isTemporary) {
            QMetaObject::Connection* const connection = new QMetaObject::Connection;
            *connection = connect(this,
                                  &ConversationModel::conversationReady,
                                  [cb, connection, convId](QString conversationId, QString participantId) {
                                      if (participantId != convId && convId != "SEARCHSIP") {
                                          return;
                                      }
                                      cb(conversationId);
                                      QObject::disconnect(*connection);
                                      if (connection) {
                                          delete connection;
                                      }
                                  });
        }

        sendContactRequest(participant);

        if (!isTemporary) {
            cb(convId);
        }
    } catch (const std::out_of_range& e) {
        qDebug() << "Unable to start call as conversation does not exist.";
    }
}


} // namespace lrc
