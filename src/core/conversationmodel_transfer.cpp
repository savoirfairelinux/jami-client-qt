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
ConversationModel::slotTransferStatusCreated(const QString& fileId, datatransfer::Info info)
{
    auto isSip = owner.profileInfo.type == profile::Type::SIP;
    // check if transfer is for the current account
    if (info.accountId != owner.id)
        return;

    const MapStringString accountDetails = ConfigurationManager::instance().getAccountDetails(owner.id);
    if (accountDetails.empty())
        return;
    // create a new conversation if needed
    auto convIds = storage::getConversationsWithPeer(d_->db, info.peerUri);
    bool isRequest = false;
    if (convIds.empty()) {
        // in case if we receive file after removing contact add conversation request. If we have
        // swarm request this function will do nothing.
        try {
            auto contact = owner.contactModel->getContact(info.peerUri);
            isRequest = contact.profileInfo.type == profile::Type::PENDING;
            if (isRequest && !contact.isBanned && info.peerUri != owner.profileInfo.uri) {
                addContactRequest(info.peerUri);
                if (isSip) {
                    convIds.push_back(storage::beginConversationWithPeer(d_->db, contact.profileInfo.uri));
                    auto& conv = convForPeerUri(contact.profileInfo.uri).get();
                    conv.uid = convIds[0];
                }
            } else {
                return;
            }
        } catch (const std::out_of_range&) {
            return;
        }
    }

    // add interaction to the d_->db
    const auto& convId = convIds[0];
    auto interactionId = storage::addDataTransferToConversation(d_->db, convId, info);

    // map fileId and interactionId for latter retrivial from client (that only known the interactionId)
    owner.dataTransferModel->registerTransferId(fileId, interactionId);

    auto interaction = interaction::Info {info.isOutgoing ? "" : info.peerUri,
                                          info.isOutgoing ? info.path : info.displayName,
                                          std::time(nullptr),
                                          0,
                                          interaction::Type::DATA_TRANSFER,
                                          interaction::Status::SENDING,
                                          false,
                                          interaction::TransferStatus::TRANSFER_CREATED};

    // prepare interaction Info and emit signal for the client
    auto conversationIdx = indexOf(convId);
    if (conversationIdx == -1) {
        addConversationWith(convId, info.peerUri, isRequest);
        Q_EMIT newConversation(convId);
    } else {
        d_->conversations[conversationIdx].interactions->append(interactionId, interaction);
        d_->conversations[conversationIdx].unreadMessages = getNumberOfUnreadMessagesFor(convId);
    }
    Q_EMIT d_->behaviorController.newUnreadInteraction(owner.id, convId, interactionId, interaction);
    Q_EMIT newInteraction(convId, interactionId, interaction);

    invalidateModel();
    Q_EMIT modelChanged();
    {
        const auto idx = index(conversationIdx);
        Q_EMIT dataChanged(idx, idx);
    }
}

void
ConversationModel::slotTransferStatusCanceled(const QString& fileId, datatransfer::Info info)
{
    if (info.accountId != owner.id)
        return;
    bool intUpdated;
    updateTransferStatus(fileId, info, interaction::TransferStatus::TRANSFER_CANCELED, intUpdated);
}

void
ConversationModel::slotTransferStatusAwaitingPeer(const QString& fileId, datatransfer::Info info)
{
    if (info.accountId != owner.id)
        return;
    bool intUpdated;
    updateTransferStatus(fileId, info, interaction::TransferStatus::TRANSFER_AWAITING_PEER, intUpdated);
}

void
ConversationModel::slotTransferStatusAwaitingHost(const QString& fileId, datatransfer::Info info)
{
    if (info.accountId != owner.id)
        return;
    awaitingHost(fileId, info);
}

void
ConversationModel::slotTransferStatusOngoing(const QString& fileId, datatransfer::Info info)
{
    if (info.accountId != owner.id)
        return;
    QString interactionId;
    QString conversationId;
    if (not usefulDataFromDataTransfer(fileId, info, interactionId, conversationId))
        return;
    bool intUpdated;

    if (!updateTransferStatus(fileId, info, interaction::TransferStatus::TRANSFER_ONGOING, intUpdated)) {
        return;
    }
    if (!intUpdated) {
        return;
    }
    auto conversationIdx = indexOf(conversationId);
    auto* timer = new QTimer();
    connect(timer, &QTimer::timeout, this, [this, timer, conversationIdx, interactionId] {
        updateTransferProgress(timer, conversationIdx, interactionId);
    });
    timer->start(1000);
}

void
ConversationModel::slotTransferStatusFinished(const QString& fileId, datatransfer::Info info)
{
    if (info.accountId != owner.id)
        return;
    QString interactionId;
    QString conversationId;
    if (not usefulDataFromDataTransfer(fileId, info, interactionId, conversationId))
        return;
    // prepare interaction Info and emit signal for the client
    auto conversationIdx = indexOf(conversationId);
    if (conversationIdx != -1) {
        bool emitUpdated = false;
        auto newStatus = interaction::TransferStatus::TRANSFER_FINISHED;
        auto& interactions = d_->conversations[conversationIdx].interactions;
        interactions->with(interactionId, [&](const QString& id, interaction::Info& interaction) {
            // We need to check if current status is ONGOING as CANCELED must not be
            // transformed into FINISHED
            if (interaction.transferStatus == interaction::TransferStatus::TRANSFER_ONGOING) {
                emitUpdated = true;
                interactions->updateTransferStatus(id, newStatus);
            }
        });
        if (emitUpdated) {
            invalidateModel();
            if (d_->conversations[conversationIdx].mode != conversation::Mode::NON_SWARM) {
                if (d_->transfIdToDbIntId.find(fileId) != d_->transfIdToDbIntId.end()) {
                    auto dbIntId = d_->transfIdToDbIntId[fileId];
                    storage::updateInteractionTransferStatus(d_->db, dbIntId, newStatus);
                }
            } else {
                storage::updateInteractionTransferStatus(d_->db, interactionId, newStatus);
            }
            d_->transfIdToDbIntId.remove(fileId);
        }
    }
}

void
ConversationModel::slotTransferStatusError(const QString& fileId, datatransfer::Info info)
{
    if (info.accountId != owner.id)
        return;
    bool intUpdated;
    updateTransferStatus(fileId, info, interaction::TransferStatus::TRANSFER_ERROR, intUpdated);
}

void
ConversationModel::slotTransferStatusTimeoutExpired(const QString& fileId, datatransfer::Info info)
{
    if (info.accountId != owner.id)
        return;
    bool intUpdated;
    updateTransferStatus(fileId, info, interaction::TransferStatus::TRANSFER_TIMEOUT_EXPIRED, intUpdated);
}

void
ConversationModel::slotTransferStatusUnjoinable(const QString& fileId, datatransfer::Info info)
{
    if (info.accountId != owner.id)
        return;
    bool intUpdated;
    updateTransferStatus(fileId, info, interaction::TransferStatus::TRANSFER_UNJOINABLE_PEER, intUpdated);
}

bool
ConversationModel::updateTransferStatus(const QString& fileId,
                                        datatransfer::Info info,
                                        interaction::TransferStatus newStatus,
                                        bool& updated)
{
    QString interactionId;
    QString conversationId;
    if (not usefulDataFromDataTransfer(fileId, info, interactionId, conversationId)) {
        return false;
    }

    auto conversationIdx = indexOf(conversationId);
    if (conversationIdx < 0) {
        return false;
    }
    auto& conversation = d_->conversations[conversationIdx];
    if (conversation.isLegacy()) {
        storage::updateInteractionTransferStatus(d_->db, interactionId, newStatus);
    }
    auto& interactions = conversation.interactions;
    bool emitUpdated = interactions->updateTransferStatus(interactionId,
                                                          newStatus,
                                                          conversation.isSwarm() ? info.path : QString());
    if (emitUpdated) {
        invalidateModel();
    }
    updated = emitUpdated;
    return true;
}

void
ConversationModel::updateTransferProgress(QTimer* timer, int conversationIdx, const QString& interactionId)
{
    try {
        bool emitUpdated = false;
        {
            const auto& interactions = d_->conversations[conversationIdx].interactions;
            interactions->with(interactionId, [&](const QString& id, interaction::Info& interaction) {
                if (interaction.transferStatus == interaction::TransferStatus::TRANSFER_ONGOING) {
                    emitUpdated = true;
                    interactions->updateTransferStatus(id, interaction::TransferStatus::TRANSFER_ONGOING);
                }
            });
        }
        if (emitUpdated)
            return;
    } catch (...) {
    }

    timer->stop();
    timer->deleteLater();
}

bool
ConversationModel::usefulDataFromDataTransfer(const QString& fileId,
                                              const datatransfer::Info& info,
                                              QString& interactionId,
                                              QString& conversationId)
{
    if (info.accountId != owner.id)
        return false;
    try {
        interactionId = owner.dataTransferModel->getInteractionIdFromFileId(fileId);
        conversationId = info.conversationId.isEmpty() ? storage::conversationIdFromInteractionId(d_->db, interactionId)
                                                       : info.conversationId;
    } catch (const std::out_of_range&) {
        qWarning() << "Couldn't get interaction from daemon Id: " << fileId;
        return false;
    }
    return true;
}

bool
ConversationModel::hasOneOneSwarmWith(const contact::Info& participant)
{
    try {
        if (!participant.conversationId.isEmpty()) {
            auto& conversation = convForUid(participant.conversationId).get();
            return conversation.mode == conversation::Mode::ONE_TO_ONE;
        }
    } catch (std::out_of_range&) {
    }
    return false;
}

void
ConversationModel::awaitingHost(const QString& fileId, datatransfer::Info info)
{
    if (info.accountId != owner.id)
        return;
    QString interactionId;
    QString conversationId;
    if (not usefulDataFromDataTransfer(fileId, info, interactionId, conversationId))
        return;

    bool intUpdated;

    if (!updateTransferStatus(fileId, info, interaction::TransferStatus::TRANSFER_AWAITING_HOST, intUpdated)) {
        return;
    }
    if (!intUpdated) {
        return;
    }
    auto conversationIdx = indexOf(conversationId);
    auto& peers = peersForConversationInfo(d_->conversations[conversationIdx]);
    handleIncomingFile(conversationId, interactionId, info.totalSize);
}

void
ConversationModel::handleIncomingFile(const QString& convId, const QString& interactionId, int totalSize)
{
    // If it's an accepted file type and less than 20 MB, accept transfer.
    if (owner.accountModel->autoTransferFromTrusted) {
        if (owner.accountModel->autoTransferSizeThreshold == 0
            || (totalSize > 0
                && static_cast<unsigned>(totalSize) < owner.accountModel->autoTransferSizeThreshold * 1024 * 1024)) {
            acceptTransfer(convId, interactionId);
        }
    }
}

void
ConversationModel::acceptTransferImpl(const QString& convUid, const QString& interactionId)
{
    auto& conversation = convForUid(convUid).get();
    if (conversation.isLegacy()) // Ignore legacy
        return;

    auto& interactions = conversation.interactions;
    if (!interactions->with(interactionId, [&](const QString&, interaction::Info& interaction) {
            auto fileId = interaction.commit["fileId"];
            if (fileId.isEmpty()) {
                qWarning() << "Unable to download file without fileId";
                return;
            }
            owner.dataTransferModel->download(owner.id, convUid, interactionId, fileId);
        })) {
        qWarning() << "Unable to download file without valid interaction";
    }
}

} // namespace lrc
