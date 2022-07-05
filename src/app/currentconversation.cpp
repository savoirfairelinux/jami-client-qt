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
#include <api/conversationmodel.h>

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
            auto preferences = accInfo.conversationModel->getConversationPreferences(convId);
            set_title(accInfo.conversationModel->title(convId));
            set_description(accInfo.conversationModel->description(convId));
            set_uris(convInfo.participantsUris());
            set_isSwarm(convInfo.isSwarm());
            set_isLegacy(convInfo.isLegacy());
            set_isCoreDialog(convInfo.isCoreDialog());
            set_isRequest(convInfo.isRequest);
            set_readOnly(convInfo.readOnly);
            set_needsSyncing(convInfo.needsSyncing);
            auto color = Utils::getAvatarColor(convId).name();
            if (preferences.contains("color")) {
                color = preferences["color"];
            }
            set_color(color);
            if (convInfo.infos.contains("rdvAccount")) {
                set_rdvAccount(convInfo.infos["rdvAccount"]);
            } else {
                set_rdvAccount("");
            }
            if (convInfo.infos.contains("rdvDevice")) {
                set_rdvDevice(convInfo.infos["rdvDevice"]);
            } else {
                set_rdvDevice("");
            }
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
}

void
CurrentConversation::onNeedsHoster(const QString& convId)
{
    if (id_ != convId)
        return;
    Q_EMIT needsHoster();
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
CurrentConversation::setPreference(const QString& key, const QString& value)
{
    if (key == "color")
        set_color(value);
    auto preferences = getPreferences();
    preferences[key] = value;
    auto accountId = lrcInstance_->get_currentAccountId();
    const auto& accInfo = lrcInstance_->accountModel().getAccountInfo(accountId);
    auto convId = lrcInstance_->get_selectedConvUid();
    accInfo.conversationModel->setConversationPreferences(convId, preferences);
}

QString
CurrentConversation::getPreference(const QString& key) const
{
    return getPreferences()[key];
}

MapStringString
CurrentConversation::getPreferences() const
{
    auto accountId = lrcInstance_->get_currentAccountId();
    const auto& accInfo = lrcInstance_->accountModel().getAccountInfo(accountId);
    auto convId = lrcInstance_->get_selectedConvUid();
    if (auto optConv = accInfo.conversationModel->getConversationForUid(convId)) {
        auto& convInfo = optConv->get();
        auto preferences = accInfo.conversationModel->getConversationPreferences(convId);
        return preferences;
    }
    return {};
}

void
CurrentConversation::setInfo(const QString& key, const QString& value)
{
    MapStringString infos;
    infos[key] = value;
    auto accountId = lrcInstance_->get_currentAccountId();
    const auto& accInfo = lrcInstance_->accountModel().getAccountInfo(accountId);
    auto convId = lrcInstance_->get_selectedConvUid();
    accInfo.conversationModel->updateConversationInfos(convId, infos);
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
            &ConversationModel::needsHoster,
            this,
            &CurrentConversation::onNeedsHoster,
            Qt::UniqueConnection);
    connect(lrcInstance_->getCurrentConversationModel(),
            &ConversationModel::profileUpdated,
            this,
            &CurrentConversation::onConversationUpdated,
            Qt::UniqueConnection);
}
