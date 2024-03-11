/*
 * Copyright (C) 2024 Savoir-faire Linux Inc.
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

#include "observableconversation.h"

#include "utils.h"

ObservableConversation::ObservableConversation(QObject* parent)
    : QObject(parent)
    , UsesLibclient()
{
    // Connect to reinitialize when either the account or conversation changes.
    // Note: changing the account and conversation shouldn't cause a double initialization.
    //    connect(this,
    //            &ObservableConversation::accountIdChanged,
    //            this,
    //            &ObservableConversation::initializeWithLatest,
    //            Qt::QueuedConnection);
    //    connect(this,
    //            &ObservableConversation::uidChanged,
    //            this,
    //            &ObservableConversation::initializeWithLatest,
    //            Qt::QueuedConnection);
    connect(
        this,
        &ObservableConversation::accountIdChanged,
        this,
        [this] {
            qWarning() << "accountIdChanged";
            initializeWithLatest();
        },
        Qt::QueuedConnection);
    connect(
        this,
        &ObservableConversation::uidChanged,
        this,
        [this] {
            qWarning() << "uidChanged";
            initializeWithLatest();
        },
        Qt::QueuedConnection);
}

void
ObservableConversation::configure(const QString& accountId, const QString& convId)
{
    if (accountId_ == accountId && uid_ == convId) {
        qWarning() << "ObservableConversation already configured for" << accountId << convId;
        return;
    }

    accountId_ = accountId;
    uid_ = convId;

    initialize();
}

void
ObservableConversation::initializeWithLatest()
{
    if (initializing_.testAndSetOrdered(false, true)) {
        qWarning() << "Already initializing" << accountId_ << uid_;
        return;
    }
    QMetaObject::invokeMethod(this, "initialize", Qt::QueuedConnection);
}

void
ObservableConversation::initialize()
{
    qWarning() << "initializing" << accountId_ << uid_;
    QScopeGuard guard([this] {
        qWarning() << "initialized" << accountId_ << uid_;
        initializing_.fetchAndStoreRelaxed(false);
    });

    auto connectObjectSignal = [this](auto obj, auto signal, auto slot) {
        connect(obj, signal, this, slot, Qt::UniqueConnection);
    };

    try {
        const auto& accInfo = lrcInstance_->accountModel().getAccountInfo(accountId_);

        // We just need to listen for conversation updates. This may be extended
        // to provide an observable interface for a conversation's call also.
        conversationModel_ = accInfo.conversationModel.get();
        callModel_ = accInfo.callModel.get();
    } catch (...) {
        qWarning() << "Can't update current conversation data for" << uid_;
    }

    // Make sure we got the model pointers
    if (!conversationModel_ || !callModel_) {
        qWarning() << "Can't account model pointers for" << accountId_;
        return;
    }

    connectObjectSignal(conversationModel_,
                        &ConversationModel::conversationUpdated,
                        &ObservableConversation::onConversationUpdated);
    connectObjectSignal(conversationModel_,
                        &ConversationModel::profileUpdated,
                        &ObservableConversation::updateProfile);
    connectObjectSignal(conversationModel_,
                        &ConversationModel::activeCallsChanged,
                        &ObservableConversation::updateActiveCalls);
    connectObjectSignal(conversationModel_,
                        &ConversationModel::conversationErrorsUpdated,
                        &ObservableConversation::updateErrors);
    connectObjectSignal(conversationModel_,
                        &ConversationModel::conversationPreferencesUpdated,
                        &ObservableConversation::updateConversationPreferences);
    connectObjectSignal(conversationModel_,
                        &ConversationModel::needsHost,
                        &ObservableConversation::onNeedsHost);
    connectObjectSignal(callModel_,
                        &CallModel::callStatusChanged,
                        &ObservableConversation::onCallStatusChanged);

    connectObjectSignal(&lrcInstance_->behaviorController(),
                        &BehaviorController::showIncomingCallView,
                        &ObservableConversation::onShowIncomingCallView);
}

void
ObservableConversation::onConversationUpdated(const QString& convId)
{
    if (convId != uid_)
        return;
    updateData();
}

void
ObservableConversation::updateProfile(const QString& convId)
{
    if (convId != uid_)
        return;

    set_title(conversationModel_->title(convId));
    set_description(conversationModel_->description(convId));

    // Now, update call informations (rdvAccount/device)
    const auto convInfoOpt = conversationModel_->getConversationForUid(convId);
    if (!convInfoOpt) {
        qWarning() << "Can't find conversation info for" << convId;
        return;
    }
    const auto& convInfo = convInfoOpt->get();
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

void
ObservableConversation::updateActiveCalls(const QString& accountId, const QString& convId)
{
    // TODO: why is accountId passed to this slot?
    if (accountId != accountId_ || convId != uid_)
        return;

    const auto convInfoOpt = conversationModel_->getConversationForUid(convId);
    if (!convInfoOpt) {
        qWarning() << "Can't find conversation info for" << convId;
        return;
    }
    const auto& convInfo = convInfoOpt->get();
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

void
ObservableConversation::updateErrors(const QString& convId)
{
    if (convId != uid_)
        return;

    QStringList newErrors;
    QStringList newBackendErr;
    if (const auto convInfoOpt = conversationModel_->getConversationForUid(convId)) {
        const auto& convInfo = convInfoOpt->get();
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
}

void
ObservableConversation::updateConversationPreferences(const QString& convId)
{
    if (convId != uid_)
        return;

    const auto convInfoOpt = conversationModel_->getConversationForUid(convId);
    if (!convInfoOpt) {
        qWarning() << "Can't find conversation info for" << convId;
        return;
    }
    const auto& convInfo = convInfoOpt->get();
    auto color = Utils::getAvatarColor(convId).name();
    if (convInfo.preferences.contains("color")) {
        color = convInfo.preferences["color"];
    }
    set_color(color);
    set_ignoreNotifications(convInfo.preferences.contains("ignoreNotifications")
                            && convInfo.preferences["ignoreNotifications"] == "true");
}

void
ObservableConversation::onNeedsHost(const QString& convId)
{
    if (convId != uid_)
        return;
    Q_EMIT needsHost();
}

void
ObservableConversation::onCallStatusChanged(const QString& callId, int)
{
    if (callId != callId_) {
        return;
    }

    if (callModel_->hasCall(callId_)) {
        auto callInfo = callModel_->getCall(callId_);
        set_hasCall(callInfo.status != call::Status::ENDED);
    }
}

void
ObservableConversation::onShowIncomingCallView(const QString& accountId, const QString& convId)
{
    if (accountId != accountId_ || convId != uid_)
        return;

    if (const auto convInfoOpt = conversationModel_->getConversationForUid(convId)) {
        const auto& convInfo = convInfoOpt->get();
        set_hasCall(!convInfo.getCallId().isEmpty());
    }
}

void
ObservableConversation::updateData()
{}
