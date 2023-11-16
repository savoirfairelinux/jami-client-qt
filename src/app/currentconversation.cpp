/*
 * Copyright (C) 2021-2024 Savoir-faire Linux Inc.
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

#include <api/conversationmodel.h>

CurrentConversation::CurrentConversation(LRCInstance* lrcInstance, QObject* parent)
    : QObject(parent)
    , lrcInstance_(lrcInstance)
{
    membersModel_ = new CurrentConversationMembers(lrcInstance, this);
    set_members(QVariant::fromValue(membersModel_));

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

    connect(&lrcInstance_->behaviorController(),
            &BehaviorController::showIncomingCallView,
            this,
            &CurrentConversation::onShowIncomingCallView);

    updateData();
}

void
CurrentConversation::updateData()
{
    auto convId = lrcInstance_->get_selectedConvUid();

    // If the conversation is empty, clear the id and return.
    if (convId.isEmpty()) {
        set_id();
        membersModel_->setMembers({}, {}, {});
        return;
    }

    // We need to emit the id changed signal after other properties have been updated.
    // We also need to set the id_ member variable before updating the other properties.
    auto cleanup = qScopeGuard([&, previousId = id_] {
        // Only emit the id changed signal if the id has changed.
        if (id_ != previousId)
            Q_EMIT idChanged();

        updateErrors(convId);
    });
    // Now we can change the id without emitting the signal.
    id_ = convId;

    try {
        auto accountId = lrcInstance_->get_currentAccountId();
        const auto& accInfo = lrcInstance_->accountModel().getAccountInfo(accountId);
        auto optConv = accInfo.conversationModel->getConversationForUid(convId);
        if (!optConv)
            return;
        auto& convInfo = optConv->get();
        set_lastSelfMessageId(convInfo.lastSelfMessageId);
        QStringList uris, bannedUris;
        auto isAdmin = false;
        for (const auto& p : convInfo.participants) {
            if (p.uri == accInfo.profileInfo.uri) {
                isAdmin = p.role == member::Role::ADMIN;
            }
            if (p.role == member::Role::BANNED) {
                bannedUris.push_back(p.uri);
            } else {
                uris.push_back(p.uri);
            }
        }
        if (isAdmin) {
            for (const auto& banned : bannedUris)
                uris.push_back(banned);
        }
        membersModel_->setMembers(accountId, convId, uris);
        set_isSwarm(convInfo.isSwarm());
        set_isLegacy(convInfo.isLegacy());
        set_isCoreDialog(convInfo.isCoreDialog());
        set_isRequest(convInfo.isRequest);
        set_needsSyncing(convInfo.needsSyncing);
        set_isSip(accInfo.profileInfo.type == profile::Type::SIP);
        set_callId(convInfo.getCallId());
        set_allMessagesLoaded(convInfo.allMessagesLoaded);
        if (accInfo.callModel->hasCall(callId_)) {
            auto call = accInfo.callModel->getCall(callId_);
            set_callState(call.status);
            set_hasCall(callState_ != call::Status::ENDED);
        } else {
            set_callState(call::Status::INVALID);
            set_hasCall(false);
        }
        set_inCall(callState_ == call::Status::CONNECTED || callState_ == call::Status::IN_PROGRESS
                   || callState_ == call::Status::PAUSED);

        // The temporary status is only for dialogs.
        // It can be used to display add contact/conversation UI and
        // is consistently determined by the peer's uri being equal to
        // the conversation id.
        auto members = accInfo.conversationModel->peersForConversation(convId);
        set_isTemporary(isCoreDialog_ ? (convId == members.at(0) || convId == "SEARCHSIP") : false);

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

        if (convInfo.mode == conversation::Mode::ONE_TO_ONE) {
            set_modeString(tr("Private"));
        } else if (convInfo.mode == conversation::Mode::ADMIN_INVITES_ONLY) {
            set_modeString(tr("Private group (restricted invites)"));
        } else if (convInfo.mode == conversation::Mode::INVITES_ONLY) {
            set_modeString(tr("Private group"));
        } else if (convInfo.mode == conversation::Mode::PUBLIC) {
            set_modeString(tr("Public group"));
        }

        updateConversationPreferences(convId);
        updateProfile(convId);
        updateActiveCalls(accountId, convId);
    } catch (...) {
        qWarning() << "Can't update current conversation data for" << convId;
    }
}

void
CurrentConversation::onNeedsHost(const QString& convId)
{
    if (convId != id_)
        return;
    Q_EMIT needsHost();
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
    return getPreferences().value(key);
}

MapStringString
CurrentConversation::getPreferences() const
{
    auto accountId = lrcInstance_->get_currentAccountId();
    const auto& accInfo = lrcInstance_->accountModel().getAccountInfo(accountId);
    auto convId = lrcInstance_->get_selectedConvUid();
    if (auto optConv = accInfo.conversationModel->getConversationForUid(convId)) {
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
    if (convId != id_)
        return;
    updateData();
}

void
CurrentConversation::updateProfile(const QString& convId)
{
    if (convId != id_)
        return;
    const auto& convModel = lrcInstance_->getCurrentConversationModel();
    set_title(convModel->title(convId));
    set_description(convModel->description(convId));

    try {
        if (auto optConv = convModel->getConversationForUid(convId)) {
            auto& convInfo = optConv->get();
            // Now, update call informations (rdvAccount/device)
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
        }
    } catch (...) {
    }
}

void
CurrentConversation::updateConversationPreferences(const QString& convId)
{
    if (convId != id_)
        return;
    auto accountId = lrcInstance_->get_currentAccountId();
    const auto& accInfo = lrcInstance_->accountModel().getAccountInfo(accountId);
    if (auto optConv = accInfo.conversationModel->getConversationForUid(convId)) {
        auto& convInfo = optConv->get();
        auto color = Utils::getAvatarColor(convId).name();
        if (convInfo.preferences.contains("color")) {
            color = convInfo.preferences["color"];
        }
        set_color(color);
        set_ignoreNotifications(convInfo.preferences.contains("ignoreNotifications")
                                && convInfo.preferences["ignoreNotifications"] == "true");
    }
}

void
CurrentConversation::connectModel()
{
    membersModel_->setMembers({}, {}, {});
    auto convModel = lrcInstance_->getCurrentConversationModel();
    if (!convModel)
        return;

    auto connectObjectSignal = [this](auto obj, auto signal, auto slot) {
        connect(obj, signal, this, slot, Qt::UniqueConnection);
    };

    connectObjectSignal(convModel,
                        &ConversationModel::conversationUpdated,
                        &CurrentConversation::onConversationUpdated);
    connectObjectSignal(convModel,
                        &ConversationModel::profileUpdated,
                        &CurrentConversation::updateProfile);

    connect(lrcInstance_->getCurrentConversationModel(),
            &ConversationModel::profileUpdated,
            this,
            &CurrentConversation::updateProfile,
            Qt::UniqueConnection);
    connect(lrcInstance_->getCurrentConversationModel(),
            &ConversationModel::onConversationErrorsUpdated,
            this,
            &CurrentConversation::updateErrors,
            Qt::UniqueConnection);
    connect(lrcInstance_->getCurrentConversationModel(),
            &ConversationModel::activeCallsChanged,
            this,
            &CurrentConversation::updateActiveCalls,
            Qt::UniqueConnection);
    connect(lrcInstance_->getCurrentConversationModel(),
            &ConversationModel::conversationPreferencesUpdated,
            this,
            &CurrentConversation::updateConversationPreferences,
            Qt::UniqueConnection);
    connect(lrcInstance_->getCurrentConversationModel(),
            &ConversationModel::needsHost,
            this,
            &CurrentConversation::onNeedsHost,
            Qt::UniqueConnection);
    connect(lrcInstance_->getCurrentCallModel(),
            &CallModel::callStatusChanged,
            this,
            &CurrentConversation::onCallStatusChanged,
            Qt::UniqueConnection);
}

void
CurrentConversation::updateErrors(const QString& convId)
{
    if (convId != id_)
        return;
    try {
        QStringList newErrors;
        QStringList newBackendErr;
        const auto& convModel = lrcInstance_->getCurrentConversationModel();
        if (auto optConv = convModel->getConversationForUid(convId)) {
            auto& convInfo = optConv->get();
            for (const auto& [code, error] : convInfo.errors) {
                if (code == 1) {
                    newErrors.append(tr("An error occurred while fetching this repository"));
                } else if (code == 2) {
                    newErrors.append(tr("Unrecognized conversation mode"));
                } else if (code == 3) {
                    newErrors.append(tr("An invalid message was detected"));
                } else if (code == 4) {
                    newErrors.append(tr("Not authorized to update conversation information"));
                } else if (code == 5) {
                    newErrors.append(tr("An error occurred while committing a new message"));
                } else {
                    continue;
                }
                newBackendErr.push_back(error);
            }
        }
        set_backendErrors(newBackendErr);
        set_errors(newErrors);
    } catch (...) {
    }
}

void
CurrentConversation::updateActiveCalls(const QString&, const QString& convId)
{
    if (convId != id_)
        return;
    const auto& convModel = lrcInstance_->getCurrentConversationModel();
    if (auto optConv = convModel->getConversationForUid(convId)) {
        auto& convInfo = optConv->get();
        QVariantList callList;
        for (int i = 0; i < convInfo.activeCalls.size(); i++) {
            // Check if ignored.
            auto ignored = false;
            for (int ignoredIdx = 0; ignoredIdx < convInfo.ignoredActiveCalls.size(); ignoredIdx++) {
                auto& ignoreCall = convInfo.ignoredActiveCalls[ignoredIdx];
                if (ignoreCall["id"] == convInfo.activeCalls[i]["id"]
                    && ignoreCall["uri"] == convInfo.activeCalls[i]["uri"]
                    && ignoreCall["device"] == convInfo.activeCalls[i]["device"]) {
                    ignored = true;
                    break;
                }
            }
            if (ignored) {
                continue;
            }

            // Else, add to model
            QVariantMap mapCall;
            Q_FOREACH (QString key, convInfo.activeCalls[i].keys()) {
                mapCall[key] = convInfo.activeCalls[i][key];
            }
            callList.append(mapCall);
        }
        set_activeCalls(callList);
    }
}

void
CurrentConversation::onCallStatusChanged(const QString& callId, int)
{
    if (callId != callId_) {
        return;
    }
    auto callModel = lrcInstance_->getCurrentCallModel();
    if (callModel->hasCall(callId_)) {
        auto callInfo = callModel->getCall(callId_);
        set_hasCall(callInfo.status != call::Status::ENDED);
    }
}

void
CurrentConversation::onShowIncomingCallView(const QString& accountId, const QString& convUid)
{
    if (accountId != lrcInstance_->get_currentAccountId()) {
        return;
    }
    const auto& convModel = lrcInstance_->getCurrentConversationModel();
    if (auto optConv = convModel->getConversationForUid(convUid)) {
        auto& convInfo = optConv->get();
        set_hasCall(!convInfo.getCallId().isEmpty());
    }
}

void
CurrentConversation::scrollToMsg(const QString& msg)
{
    Q_EMIT scrollTo(msg);
}
