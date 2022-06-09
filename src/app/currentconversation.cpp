/*
 * Copyright (C) 2021-2022 Savoir-faire Linux Inc.
 * Author: Andreas Traczyk <andreas.traczyk@savoirfairelinux.com>
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
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

#include "currentconversation.h"
#include "qmlregister.h"

CurrentConversation::CurrentConversation(LRCInstance* lrcInstance, QObject* parent)
    : QObject(parent)
    , lrcInstance_(lrcInstance)
{
    activeCalls_.reset(new ActiveCallsModel(this, lrcInstance_));
    QML_REGISTERSINGLETONTYPE_POBJECT(NS_MODELS, activeCalls_.get(), "ActiveCallsModel");
    // whenever the account changes, reconnect the new conversation model
    // for updates to the conversation and call state/id
    connect(lrcInstance_,
            &LRCInstance::currentAccountIdChanged,
            this,
            &CurrentConversation::connectModel);
    connectModel();

    // update when the conversation itself changes
    connect(lrcInstance_,
            &LRCInstance::selectedConvUidChanged,
            this,
            &CurrentConversation::updateData);
    updateData();
}

void
CurrentConversation::updateData()
{
    auto convId = lrcInstance_->get_selectedConvUid();
    if (convId.isEmpty())
        return;
    set_id(convId);
    try {
        auto accountId = lrcInstance_->get_currentAccountId();
        const auto& accInfo = lrcInstance_->accountModel().getAccountInfo(accountId);
        if (auto optConv = accInfo.conversationModel->getConversationForUid(convId)) {
            auto& convInfo = optConv->get();
            set_title(accInfo.conversationModel->title(convId));
            set_description(accInfo.conversationModel->description(convId));
            set_uris(convInfo.participantsUris());
            set_isSwarm(convInfo.isSwarm());
            set_isLegacy(convInfo.isLegacy());
            set_isCoreDialog(convInfo.isCoreDialog());
            set_isRequest(convInfo.isRequest);
            set_needsSyncing(convInfo.needsSyncing);
            set_color(Utils::getAvatarColor(convId).name());
            set_isSip(accInfo.profileInfo.type == profile::Type::SIP);
            set_callId(convInfo.getCallId());
            set_allMessagesLoaded(convInfo.allMessagesLoaded);
            if (accInfo.callModel->hasCall(callId_)) {
                auto call = accInfo.callModel->getCall(callId_);
                set_callState(call.status);
            } else {
                set_callState(call::Status::INVALID);
            }
            set_inCall(callState_ == call::Status::CONNECTED
                       || callState_ == call::Status::IN_PROGRESS
                       || callState_ == call::Status::PAUSED);

            // The temporary status is only for dialogs.
            // It can be used to display add contact/conversation UI and
            // is consistently determined by the peer's uri being equal to
            // the conversation id.
            auto members = accInfo.conversationModel->peersForConversation(convId);
            set_isTemporary(isCoreDialog_ ? convId == members.at(0) : false);

            auto isContact {false};
            if (isCoreDialog_)
                try {
                    auto& contact = accInfo.contactModel->getContact(members.at(0));
                    set_isBanned(contact.isBanned);
                    isContact = contact.profileInfo.type != profile::Type::TEMPORARY;
                } catch (const std::exception& e) {
                    qInfo() << "Contact not found: " << e.what();
                }
            set_isContact(isContact);

            QString modeString;
            if (convInfo.mode == conversation::Mode::ONE_TO_ONE) {
                set_modeString(tr("Private"));
            } else if (convInfo.mode == conversation::Mode::ADMIN_INVITES_ONLY) {
                set_modeString(tr("Private group (restricted invites)"));
            } else if (convInfo.mode == conversation::Mode::INVITES_ONLY) {
                set_modeString(tr("Private group"));
            } else if (convInfo.mode == conversation::Mode::PUBLIC) {
                set_modeString(tr("Public group"));
            }

            activeCalls_->reset();
        }
    } catch (...) {
        qWarning() << "Can't update current conversation data for" << convId;
    }
    updateErrors(convId);
}

QVector<QMap<QString, QString>>
CurrentConversation::activeCalls() const
{
    auto accountId = lrcInstance_->get_currentAccountId();
    const auto& accInfo = lrcInstance_->accountModel().getAccountInfo(accountId);
    if (auto optConv = accInfo.conversationModel->getConversationForUid(id_)) {
        auto& convInfo = optConv->get();
        return convInfo.activeCalls;
    }
    return {};
}

void
CurrentConversation::onConversationUpdated(const QString& convId)
{
    // filter for our currently set id
    if (id_ != convId)
        return;
    updateData();
}

void
CurrentConversation::onProfileUpdated(const QString& convId)
{
    // filter for our currently set id
    if (id_ != convId)
        return;
    set_title(lrcInstance_->getCurrentConversationModel()->title(convId));
    set_description(lrcInstance_->getCurrentConversationModel()->description(convId));
}

void
CurrentConversation::connectModel()
{
    auto convModel = lrcInstance_->getCurrentConversationModel();
    if (!convModel)
        return;

    connect(lrcInstance_->getCurrentConversationModel(),
            &ConversationModel::conversationUpdated,
            this,
            &CurrentConversation::onConversationUpdated,
            Qt::UniqueConnection);
    connect(lrcInstance_->getCurrentConversationModel(),
            &ConversationModel::profileUpdated,
            this,
            &CurrentConversation::onProfileUpdated,
            Qt::UniqueConnection);
    connect(lrcInstance_->getCurrentConversationModel(),
            &ConversationModel::onConversationErrorsUpdated,
            this,
            &CurrentConversation::updateErrors,
            Qt::UniqueConnection);
}

void
CurrentConversation::showSwarmDetails() const
{
    Q_EMIT showDetails();
}

void
CurrentConversation::updateErrors(const QString& convId)
{
    if (convId != id_)
        return;
    try {
        const auto& convModel = lrcInstance_->getCurrentConversationModel();
        if (auto optConv = convModel->getConversationForUid(convId)) {
            auto& convInfo = optConv->get();
            QStringList newErrors;
            QStringList newBackendErr;
            for (const auto& [code, error] : convInfo.errors) {
                if (code == 1) {
                    newErrors.append(tr("An error occurred while fetching this repository"));
                } else if (code == 2) {
                    newErrors.append(tr("The conversation's mode is un-recognized"));
                } else if (code == 3) {
                    newErrors.append(tr("An invalid message was detected"));
                } else if (code == 4) {
                    newErrors.append(
                        tr("Not enough authorization for updating conversation's infos"));
                } else {
                    continue;
                }
                newBackendErr.push_back(error);
            }
            set_backendErrors(newBackendErr);
            set_errors(newErrors);
        }
    } catch (...) {
    }
}

void
CurrentConversation::scrollToMsg(const QString& msg)
{
    Q_EMIT scrollTo(msg);
}
