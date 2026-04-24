/*
 * Copyright (C) 2024-2026 Savoir-faire Linux Inc.
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

#include "conversationcontext.h"
#include "messagesadapter.h"

#include "global.h"

#include <api/conversationmodel.h>
#include <api/contact.h>

ConversationContext::ConversationContext(LRCInstance* lrcInstance,
                                         const QString& convId,
                                         const QString& accountId,
                                         QObject* parent)
    : QObject(parent)
    , lrcInstance_(lrcInstance)
    , convId_(convId)
    , accountId_(accountId)
{
    membersModel_ = new CurrentConversationMembers(lrcInstance, this);
    set_members(QVariant::fromValue(membersModel_));

    filteredMsgListModel_ = new FilteredMsgListModel(this);

    try {
        const auto& accInfo = lrcInstance_->accountModel().getAccountInfo(accountId_);
        const auto& conversation = lrcInstance_->getConversationFromConvUid(convId_, accountId_);
        filteredMsgListModel_->setSourceModel(conversation.interactions.get());
    } catch (const std::exception& e) {
        qWarning() << "ConversationContext: failed to set message model:" << e.what();
    }

    set_messageListModel(QVariant::fromValue(filteredMsgListModel_));

    connect(&lrcInstance_->behaviorController(),
            &BehaviorController::showIncomingCallView,
            this,
            &ConversationContext::onShowIncomingCallView);

    connectModel();
    updateData();
}

void
ConversationContext::updateData()
{
    if (convId_.isEmpty()) {
        set_id();
        membersModel_->setMembers({}, {}, {});
        return;
    }

    auto cleanup = qScopeGuard([&, previousId = id_] {
        if (id_ != previousId)
            Q_EMIT idChanged();

        updateErrors(convId_);
    });
    id_ = convId_;

    try {
        const auto& accInfo = lrcInstance_->accountModel().getAccountInfo(accountId_);
        auto optConv = accInfo.conversationModel->getConversationForUid(convId_);
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
        membersModel_->setMembers(accountId_, convId_, uris);
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

        auto members = accInfo.conversationModel->peersForConversation(convId_);
        set_isTemporary(isCoreDialog_ ? (convId_ == members.at(0) || convId_ == "SEARCHSIP") : false);

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

        updateConversationPreferences(convId_);
        updateProfile(convId_);
        updateActiveCalls(accountId_, convId_);
    } catch (...) {
        qWarning() << "Error while updating conversation context data for" << convId_;
    }
}

void
ConversationContext::onNeedsHost(const QString& convId)
{
    if (convId != id_)
        return;
    Q_EMIT needsHost();
}

void
ConversationContext::setPreference(const QString& key, const QString& value)
{
    if (key == "color")
        set_color(value);
    auto preferences = getPreferences();
    preferences[key] = value;
    const auto& accInfo = lrcInstance_->accountModel().getAccountInfo(accountId_);
    accInfo.conversationModel->setConversationPreferences(convId_, preferences);
}

QString
ConversationContext::getPreference(const QString& key) const
{
    return getPreferences().value(key);
}

MapStringString
ConversationContext::getPreferences() const
{
    const auto& accInfo = lrcInstance_->accountModel().getAccountInfo(accountId_);
    if (auto optConv = accInfo.conversationModel->getConversationForUid(convId_)) {
        return accInfo.conversationModel->getConversationPreferences(convId_);
    }
    return {};
}

void
ConversationContext::setInfo(const QString& key, const QString& value)
{
    MapStringString infos;
    infos[key] = value;
    const auto& accInfo = lrcInstance_->accountModel().getAccountInfo(accountId_);
    accInfo.conversationModel->updateConversationInfos(convId_, infos);
}

void
ConversationContext::loadMoreMessages()
{
    try {
        const auto& accInfo = lrcInstance_->accountModel().getAccountInfo(accountId_);
        const auto optConv = accInfo.conversationModel->getConversationForUid(convId_);
        if (optConv && optConv->get().isSwarm())
            accInfo.conversationModel->loadConversationMessages(convId_, 20);
    } catch (const std::exception& e) {
        qWarning() << e.what();
    }
}

void
ConversationContext::onConversationUpdated(const QString& convId)
{
    if (convId != id_)
        return;
    updateData();
}

void
ConversationContext::updateProfile(const QString& convId)
{
    if (convId != id_)
        return;
    const auto& accInfo = lrcInstance_->accountModel().getAccountInfo(accountId_);
    const auto& convModel = accInfo.conversationModel;
    set_title(convModel->title(convId));
    set_description(convModel->description(convId));

    try {
        if (auto optConv = convModel->getConversationForUid(convId)) {
            auto& convInfo = optConv->get();
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
ConversationContext::updateConversationPreferences(const QString& convId)
{
    if (convId != id_)
        return;
    const auto& accInfo = lrcInstance_->accountModel().getAccountInfo(accountId_);
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
ConversationContext::connectModel()
{
    membersModel_->setMembers({}, {}, {});

    auto* conversationModel = lrcInstance_->accountModel().getAccountInfo(accountId_).conversationModel.get();
    auto* callModel = lrcInstance_->accountModel().getAccountInfo(accountId_).callModel.get();
    if (!conversationModel || !callModel) {
        C_DBG << "ConversationContext: unable to connect to unavailable models";
        return;
    }

    auto connectObjectSignal = [this](auto obj, auto signal, auto slot) {
        connect(obj, signal, this, slot, Qt::UniqueConnection);
    };

    connectObjectSignal(conversationModel,
                        &ConversationModel::conversationUpdated,
                        &ConversationContext::onConversationUpdated);
    connectObjectSignal(conversationModel,
                        &ConversationModel::profileUpdated,
                        &ConversationContext::updateProfile);
    connectObjectSignal(conversationModel,
                        &ConversationModel::conversationErrorsUpdated,
                        &ConversationContext::updateErrors);
    connectObjectSignal(conversationModel,
                        &ConversationModel::activeCallsChanged,
                        &ConversationContext::updateActiveCalls);
    connectObjectSignal(conversationModel,
                        &ConversationModel::conversationPreferencesUpdated,
                        &ConversationContext::updateConversationPreferences);
    connectObjectSignal(conversationModel,
                        &ConversationModel::needsHost,
                        &ConversationContext::onNeedsHost);
    connectObjectSignal(callModel,
                        &CallModel::callStatusChanged,
                        &ConversationContext::onCallStatusChanged);

    connect(conversationModel,
            &ConversationModel::newInteraction,
            this,
            [this](const QString& convUid, const QString&, const interaction::Info&) {
                if (convUid == convId_)
                    Q_EMIT newInteraction();
            });

    connect(conversationModel,
            &ConversationModel::conversationMessagesLoaded,
            this,
            [this](uint32_t requestId, const QString& convId) {
                if (convId == convId_)
                    Q_EMIT moreMessagesLoaded(static_cast<int>(requestId));
            });
}

void
ConversationContext::updateErrors(const QString& convId)
{
    if (convId != id_)
        return;
    try {
        QStringList newErrors;
        QStringList newBackendErr;
        const auto& accInfo = lrcInstance_->accountModel().getAccountInfo(accountId_);
        if (auto optConv = accInfo.conversationModel->getConversationForUid(convId)) {
            auto& convInfo = optConv->get();
            for (const auto& [code, error] : convInfo.errors) {
                if (code == 1) {
                    newErrors.append(tr("An error occurred while fetching this repository."));
                } else if (code == 2) {
                    newErrors.append(tr("Unrecognized conversation mode."));
                } else if (code == 3) {
                    newErrors.append(tr("An invalid message was detected."));
                } else if (code == 4) {
                    newErrors.append(tr("Insufficient permission to update conversation information."));
                } else if (code == 5) {
                    newErrors.append(tr("An error occurred while committing a new message."));
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
ConversationContext::updateActiveCalls(const QString&, const QString& convId)
{
    if (convId != id_)
        return;
    const auto& accInfo = lrcInstance_->accountModel().getAccountInfo(accountId_);
    if (auto optConv = accInfo.conversationModel->getConversationForUid(convId)) {
        auto& convInfo = optConv->get();
        QVariantList callList;
        for (int i = 0; i < convInfo.activeCalls.size(); i++) {
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
            if (ignored)
                continue;

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
ConversationContext::onCallStatusChanged(const QString& accountId, const QString& callId, int)
{
    if (callId != callId_)
        return;
    const auto& accInfo = lrcInstance_->accountModel().getAccountInfo(accountId_);
    if (accInfo.callModel->hasCall(callId_)) {
        auto callInfo = accInfo.callModel->getCall(callId_);
        set_hasCall(callInfo.status != call::Status::ENDED);
    }
}

void
ConversationContext::onShowIncomingCallView(const QString& accountId, const QString& convUid)
{
    if (accountId != accountId_)
        return;
    const auto& accInfo = lrcInstance_->accountModel().getAccountInfo(accountId_);
    if (auto optConv = accInfo.conversationModel->getConversationForUid(convUid)) {
        auto& convInfo = optConv->get();
        set_hasCall(!convInfo.getCallId().isEmpty());
    }
}

void
ConversationContext::scrollToMsg(const QString& msg)
{
    Q_EMIT scrollTo(msg);
}
