/*
 * Copyright (C) 2020-2024 Savoir-faire Linux Inc.
 * Author: Edric Ladent Milaret <edric.ladent-milaret@savoirfairelinux.com>
 * Author: Anthony Léonard <anthony.leonard@savoirfairelinux.com>
 * Author: Olivier Soldano <olivier.soldano@savoirfairelinux.com>
 * Author: Andreas Traczyk <andreas.traczyk@savoirfairelinux.com>
 * Author: Isa Nanic <isa.nanic@savoirfairelinux.com>
 * Author: Mingrui Zhang <mingrui.zhang@savoirfairelinux.com>
 * Author: Sébastien Blin <sebastien.blin@savoirfairelinux.com>
 * Author: Capucine Berthet <capucine.berthet@savoirfairelinux.com>
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

#include "calladapter.h"

#include "systemtray.h"
#include "appsettingsmanager.h"
#include "pttlistener.h"

#include <api/callmodel.h>
#include <api/callparticipantsmodel.h>

#include <media_const.h>

#include <QApplication>
#include <QTimer>
#include <QJsonObject>

CallAdapter::CallAdapter(AppSettingsManager* settingsManager,
                         SystemTray* systemTray,
                         LRCInstance* instance,
                         QObject* parent)
    : QmlAdapterBase(instance, parent)
    , systemTray_(systemTray)
    , callInformationListModel_(std::make_unique<CallInformationListModel>())
{
    // Get the PTTListener instance.
    listener_ = qApp->property("PTTListener").value<PTTListener*>();

    set_callInformationList(QVariant::fromValue(callInformationListModel_.get()));

    timer = new QTimer(this);
    connect(timer, &QTimer::timeout, this, &CallAdapter::updateAdvancedInformation);

    accountId_ = lrcInstance_->get_currentAccountId();
    connectCallModel(accountId_);

    connect(&lrcInstance_->behaviorController(),
            &BehaviorController::showIncomingCallView,
            this,
            &CallAdapter::onShowIncomingCallView);

    connect(&lrcInstance_->behaviorController(),
            &BehaviorController::showCallView,
            this,
            &CallAdapter::onShowCallView);

    connect(lrcInstance_,
            &LRCInstance::currentAccountIdChanged,
            this,
            &CallAdapter::onAccountChanged);

#ifdef Q_OS_LINUX
    // notification responses (gnu/linux currently)
    connect(systemTray_,
            &SystemTray::answerCallActivated,
            this,
            [this](const QString& accountId, const QString& convUid) {
                acceptACall(accountId, convUid);
                Q_EMIT lrcInstance_->notificationClicked();
                lrcInstance_->selectConversation(convUid, accountId);
                updateCall(convUid, accountId);
                Q_EMIT lrcInstance_->conversationUpdated(convUid, accountId);
            });
    connect(systemTray_,
            &SystemTray::declineCallActivated,
            this,
            [this](const QString& accountId, const QString& convUid) {
                hangUpACall(accountId, convUid);
            });
#endif

    connect(&lrcInstance_->behaviorController(),
            &BehaviorController::callStatusChanged,
            this,
            QOverload<const QString&, const QString&>::of(&CallAdapter::onCallStatusChanged));

    connect(lrcInstance_,
            &LRCInstance::selectedConvUidChanged,
            this,
            &CallAdapter::saveConferenceSubcalls);

#ifdef HAVE_GLOBAL_PTT
    connectPtt();
#endif
}

CallAdapter::~CallAdapter()
{
#ifdef HAVE_GLOBAL_PTT
    disconnectPtt();
#endif
}

void
CallAdapter::connectPtt()
{
#ifdef HAVE_GLOBAL_PTT
    if (listener_->getPttState()) {
        QObject::connect(
            listener_,
            &PTTListener::pttKeyPressed,
            this,
            [this]() {
                const auto callId
                    = lrcInstance_->getCallIdForConversationUid(lrcInstance_->get_selectedConvUid(),
                                                                accountId_);
                try {
                    isMicrophoneMuted_ = isMuted(callId);
                    if (isMicrophoneMuted_)
                        muteAudioToggle();
                } catch (const std::exception& e) {
                    qWarning() << e.what();
                }
            },
            Qt::QueuedConnection);

        QObject::connect(
            listener_,
            &PTTListener::pttKeyReleased,
            this,
            [this]() {
                if (isMicrophoneMuted_) {
                    muteAudioToggle();
                }
            },
            Qt::QueuedConnection);
    }
#endif
}

void
CallAdapter::disconnectPtt()
{
#ifdef HAVE_GLOBAL_PTT
    if (listener_->getPttState()) {
        QObject::disconnect(listener_, &PTTListener::pttKeyPressed, this, nullptr);
        QObject::disconnect(listener_, &PTTListener::pttKeyReleased, this, nullptr);
    }
#endif
}

void
CallAdapter::startTimerInformation()
{
    updateAdvancedInformation();
    timer->start(1000);
}

void
CallAdapter::stopTimerInformation()
{
    timer->stop();
}

void
CallAdapter::onAccountChanged()
{
    accountId_ = lrcInstance_->get_currentAccountId();
    connectCallModel(accountId_);
}

void
CallAdapter::onCallStatusChanged(const QString& accountId, const QString& callId)
{
    set_hasCall(lrcInstance_->hasActiveCall());

#ifdef Q_OS_LINUX
    auto& accInfo = lrcInstance_->accountModel().getAccountInfo(accountId);
    auto& callModel = accInfo.callModel;
    const auto call = callModel->getCall(callId);

    const auto& convInfo = lrcInstance_->getConversationFromCallId(callId, accountId);
    if (convInfo.uid.isEmpty() || call.isOutgoing)
        return;

    // handle notifications
    if (call.status == lrc::api::call::Status::IN_PROGRESS) {
        // Call answered and in progress; close the notification
        systemTray_->hideNotification(QString("%1;%2").arg(accountId, convInfo.uid));
    } else if (call.status == lrc::api::call::Status::ENDED) {
        // Call ended; close the notification
        if (systemTray_->hideNotification(QString("%1;%2").arg(accountId, convInfo.uid))
            && call.startTime.time_since_epoch().count() == 0) {
            // This was a missed call; show a missed call notification
            auto convAvatar = Utils::conversationAvatar(lrcInstance_,
                                                        convInfo.uid,
                                                        QSize(50, 50),
                                                        accountId);
            auto& accInfo = lrcInstance_->getAccountInfo(accountId);
            auto from = accInfo.conversationModel->title(convInfo.uid);
            auto notifId = QString("%1;%2").arg(accountId, convInfo.uid);
            systemTray_->showNotification(notifId,
                                          tr("Missed call"),
                                          tr("Missed call with %1").arg(from),
                                          SystemTray::NotificationType::CHAT,
                                          Utils::QImageToByteArray(convAvatar));
        }
    }
#else
    Q_UNUSED(accountId)
    Q_UNUSED(callId)
#endif
}

void
CallAdapter::onCallStarted(const QString& callId)
{
    if (lrcInstance_->get_selectedConvUid().isEmpty())
        return;
    auto& accInfo = lrcInstance_->accountModel().getAccountInfo(accountId_);
    auto& callModel = accInfo.callModel;
    // update call Information list by adding the new information related to the callId
    callInformationListModel_->addElement(
        qMakePair(callId, callModel->advancedInformationForCallId(callId)));
    if (listener_->getPttState()) {
#ifdef HAVE_GLOBAL_PTT
        listener_->startListening();
        toMute += callId;
#endif
    }
}

void
CallAdapter::onCallEnded(const QString& callId)
{
    if (lrcInstance_->get_selectedConvUid().isEmpty())
        return;
    // update call Information list by removing information related to the callId
    callInformationListModel_->removeElement(callId);
#ifdef HAVE_GLOBAL_PTT
    if (listener_->getPttState() && !hasCall_)
        listener_->stopListening();
#endif
}

void
CallAdapter::onCallStatusChanged(const QString& callId, int code)
{
    Q_UNUSED(code)

    auto& accInfo = lrcInstance_->accountModel().getAccountInfo(accountId_);
    auto& callModel = accInfo.callModel;

    try {
        const auto call = callModel->getCall(callId);
        /*
         * Change status label text.
         */
        const auto& convInfo = lrcInstance_->getConversationFromCallId(callId);
        if (!convInfo.uid.isEmpty()) {
            Q_EMIT callStatusChanged(static_cast<int>(call.status), accountId_, convInfo.uid);
        }

        switch (call.status) {
        case lrc::api::call::Status::INVALID:
        case lrc::api::call::Status::INACTIVE:
        case lrc::api::call::Status::ENDED:
        case lrc::api::call::Status::PEER_BUSY:
        case lrc::api::call::Status::TIMEOUT:
        case lrc::api::call::Status::TERMINATING: {
            const auto& convInfo = lrcInstance_->getConversationFromCallId(callId);
            if (convInfo.uid.isEmpty()) {
                return;
            }

            const auto& currentConvId = lrcInstance_->get_selectedConvUid();
            const auto& currentConvInfo = lrcInstance_->getConversationFromConvUid(currentConvId);

            // was it a conference and now is a dialog?
            if (currentConvInfo.isCoreDialog() && currentConvInfo.confId.isEmpty()
                && currentConfSubcalls_.size() == 2) {
                auto it = std::find_if(currentConfSubcalls_.cbegin(),
                                       currentConfSubcalls_.cend(),
                                       [&callId](const QString& cid) { return cid != callId; });
                if (it != currentConfSubcalls_.cend()) {
                    // select the conversation using the other callId
                    auto otherCall = lrcInstance_->getCurrentCallModel()->getCall(*it);
                    if (otherCall.status == lrc::api::call::Status::IN_PROGRESS) {
                        const auto& otherConv = lrcInstance_->getConversationFromCallId(*it);
                        if (!otherConv.uid.isEmpty() && otherConv.uid != convInfo.uid) {
                            lrcInstance_->selectConversation(otherConv.uid);
                            Q_EMIT lrcInstance_->conversationUpdated(otherConv.uid, accountId_);
                            updateCall(otherConv.uid);
                        }
                    }
                    // then clear the list
                    currentConfSubcalls_.clear();
                    return;
                }
            } else if (currentConfSubcalls_.size() >= 2) {
                // okay, still a conference, so just update the subcall list and this call
                saveConferenceSubcalls();
                Q_EMIT lrcInstance_->conversationUpdated(currentConvInfo.uid, accountId_);
                updateCall(currentConvInfo.uid);
                return;
            }

            Q_EMIT lrcInstance_->conversationUpdated(convInfo.uid, accountId_);
            updateCall(currentConvInfo.uid);
            preventScreenSaver(false);
            break;
        }
        case lrc::api::call::Status::CONNECTED:
        case lrc::api::call::Status::IN_PROGRESS: {
            const auto& convInfo = lrcInstance_->getConversationFromCallId(callId, accountId_);
            if (!convInfo.uid.isEmpty() && convInfo.uid == lrcInstance_->get_selectedConvUid()) {
                accInfo.conversationModel->selectConversation(convInfo.uid);
            }
            saveConferenceSubcalls();
            updateCall(convInfo.uid, accountId_);
            preventScreenSaver(true);
            break;
        }
        case lrc::api::call::Status::PAUSED:
            updateCall();
            break;
        default:
            break;
        }
    } catch (...) {
    }
}

void
CallAdapter::onCallInfosChanged(const QString& accountId, const QString& callId)
{
    Q_UNUSED(accountId)
    auto mute = toMute.remove(callId);
    if (mute && listener_->getPttState())
        muteAudioToggle();
}

void
CallAdapter::onCallAddedToConference(const QString& callId, const QString& confId)
{
    Q_UNUSED(callId)
    Q_UNUSED(confId)
    saveConferenceSubcalls();
}

void
CallAdapter::placeAudioOnlyCall()
{
    const auto convUid = lrcInstance_->get_selectedConvUid();
    if (!convUid.isEmpty()) {
        lrcInstance_->getCurrentConversationModel()->placeAudioOnlyCall(convUid);
    }
}

void
CallAdapter::placeCall()
{
    const auto convUid = lrcInstance_->get_selectedConvUid();
    if (!convUid.isEmpty()) {
        lrcInstance_->getCurrentConversationModel()->placeCall(convUid);
    }
}

void
CallAdapter::hangUpACall(const QString& accountId, const QString& convUid)
{
    const auto& convInfo = lrcInstance_->getConversationFromConvUid(convUid, accountId);
    if (!convInfo.uid.isEmpty()) {
        lrcInstance_->getAccountInfo(accountId).callModel->hangUp(convInfo.callId);
    }
}

void
CallAdapter::setCallMedia(const QString& accountId, const QString& convUid, bool video)
{
    const auto& convInfo = lrcInstance_->getConversationFromConvUid(convUid, accountId);
    if (convInfo.uid.isEmpty())
        return;
    try {
        lrcInstance_->getAccountInfo(accountId).callModel->updateCallMediaList(convInfo.callId,
                                                                               video);
    } catch (...) {
    }
}

void
CallAdapter::acceptACall(const QString& accountId, const QString& convUid)
{
    const auto& convInfo = lrcInstance_->getConversationFromConvUid(convUid, accountId);
    if (convInfo.uid.isEmpty())
        return;

    lrcInstance_->getAccountInfo(accountId).callModel->accept(convInfo.callId);
}

void
CallAdapter::onShowIncomingCallView(const QString& accountId, const QString& convUid)
{
    const auto& convInfo = lrcInstance_->getConversationFromConvUid(convUid, accountId);
    if (convInfo.uid.isEmpty()) {
        qWarning() << Q_FUNC_INFO << "No conversation for id: " << convUid;
        return;
    }

    const auto& accInfo = lrcInstance_->getAccountInfo(accountId);
    if (!accInfo.callModel->hasCall(convInfo.callId)) {
        qWarning() << Q_FUNC_INFO << "No call for id: " << convInfo.callId;
        return;
    }
    auto call = accInfo.callModel->getCall(convInfo.callId);

    // this will update various UI elements that portray the call state
    Q_EMIT callStatusChanged(static_cast<int>(call.status), accountId, convInfo.uid);

    auto accountProperties = lrcInstance_->accountModel().getAccountConfig(accountId);

    // do nothing but update the status UI for incoming calls on RendezVous accounts
    if (accountProperties.isRendezVous && !call.isOutgoing) {
        qInfo() << Q_FUNC_INFO << "The call's associated account is a RendezVous point";
        return;
    }

    auto currentConvId = lrcInstance_->get_selectedConvUid();
    auto isCallSelected = currentConvId == convInfo.uid;

    // pop a notification when:
    // - the window is not focused
    // - the call is incoming AND the call's target account is
    //   not a RendezVous point
    // - the call has just transitioned to the INCOMING_RINGING state
    if (QApplication::focusObject() == nullptr && !call.isOutgoing
        && !accountProperties.isRendezVous && call.status == call::Status::INCOMING_RINGING) {
        // if the window is not focused then select the conversation immediately to show the call view
        if (isCallSelected) {
            Q_EMIT lrcInstance_->conversationUpdated(convInfo.uid, accountId);
        } else {
            lrcInstance_->selectConversation(convInfo.uid, accountId);
        }
        showNotification(accountId, convInfo.uid);
        return;
    }

    // this slot has been triggered as a result of either selecting a conversation
    // with an active call, placing a call, or an incoming call for the current
    // or any other conversation
    if (isCallSelected) {
        // current conversation, only update
        Q_EMIT lrcInstance_->conversationUpdated(convInfo.uid, accountId);
        return;
    }

    // pop a notification if the current conversation has an in-progress call
    const auto& currentConvInfo = lrcInstance_->getConversationFromConvUid(currentConvId);
    auto currentConvHasCall = accInfo.callModel->hasCall(currentConvInfo.callId);
    if (currentConvHasCall) {
        auto currentCall = accInfo.callModel->getCall(currentConvInfo.callId);
        if ((currentCall.status == call::Status::CONNECTED
             || currentCall.status == call::Status::IN_PROGRESS)
            && !accountProperties.autoAnswer && !currentCall.isOutgoing) {
            showNotification(accountId, convInfo.uid);
            return;
        }
    }

    // finally, in this case, the conversation isn't selected yet
    // and there are no other special conditions, so just select the conversation
    lrcInstance_->selectConversation(convInfo.uid, accountId);
}

void
CallAdapter::onShowCallView(const QString& accountId, const QString& convUid)
{
    Q_EMIT lrcInstance_->conversationUpdated(convUid, accountId); // This will show the call
}

void
CallAdapter::updateCall(const QString& convUid, const QString& accountId, bool forceCallOnly)
{
    if (convUid != lrcInstance_->get_selectedConvUid())
        return;
    accountId_ = accountId.isEmpty() ? accountId_ : accountId;

    const auto& convInfo = lrcInstance_->getConversationFromConvUid(convUid);
    if (convInfo.uid.isEmpty())
        return;

    auto call = lrcInstance_->getCallInfoForConversation(convInfo, forceCallOnly);
    if (!call)
        return;

    if (convInfo.uid == lrcInstance_->get_selectedConvUid()) {
        auto& accInfo = lrcInstance_->accountModel().getAccountInfo(accountId_);
        if (accInfo.profileInfo.type != lrc::api::profile::Type::SIP) {
            // Only setCurrentCall if call is actually answered
            try {
                if (call->status == call::Status::IN_PROGRESS
                    || call->status == call::Status::PAUSED)
                    accInfo.callModel->setCurrentCall(call->id);
            } catch (...) {
            }
        }
    }
}

void
CallAdapter::showNotification(const QString& accountId, const QString& convUid)
{
    auto& accInfo = lrcInstance_->getAccountInfo(accountId);
    auto title = accInfo.conversationModel->title(convUid);

    auto preferences = accInfo.conversationModel->getConversationPreferences(convUid);
    // Ignore notifications for this conversation
    if (preferences["ignoreNotifications"] == "true")
        return;

#ifdef Q_OS_LINUX
    auto convAvatar = Utils::conversationAvatar(lrcInstance_, convUid, QSize(50, 50), accountId);
    auto notifId = QString("%1;%2").arg(accountId, convUid);
    systemTray_->showNotification(notifId,
                                  tr("Incoming call"),
                                  tr("%1 is calling you").arg(title),
                                  SystemTray::NotificationType::CALL,
                                  Utils::QImageToByteArray(convAvatar));
#else
    auto onClicked = [this, accountId, convUid]() {
        Q_EMIT lrcInstance_->notificationClicked();
        const auto& convInfo = lrcInstance_->getConversationFromConvUid(convUid, accountId);
        if (convUid.isEmpty())
            return;
        lrcInstance_->selectConversation(convUid, accountId);
    };
    systemTray_->showNotification(tr("is calling you"), title, onClicked);
#endif
}

void
CallAdapter::connectCallModel(const QString& accountId)
{
    if (accountId.isEmpty())
        return;

    auto& accInfo = lrcInstance_->accountModel().getAccountInfo(accountId);
    connect(accInfo.callModel.get(),
            &CallModel::callStarted,
            this,
            &CallAdapter::onCallStarted,
            Qt::UniqueConnection);

    connect(accInfo.callModel.get(),
            &CallModel::callEnded,
            this,
            &CallAdapter::onCallEnded,
            Qt::UniqueConnection);

    connect(accInfo.callModel.get(),
            &CallModel::callStatusChanged,
            this,
            QOverload<const QString&, int>::of(&CallAdapter::onCallStatusChanged),
            Qt::UniqueConnection);

    connect(accInfo.callModel.get(),
            &CallModel::callInfosChanged,
            this,
            &CallAdapter::onCallInfosChanged,
            Qt::UniqueConnection);

    connect(accInfo.callModel.get(),
            &CallModel::callAddedToConference,
            this,
            &CallAdapter::onCallAddedToConference,
            Qt::UniqueConnection);
}

void
CallAdapter::sipInputPanelPlayDTMF(const QString& key)
{
    auto callId = lrcInstance_->getCallIdForConversationUid(lrcInstance_->get_selectedConvUid(),
                                                            accountId_);
    if (callId.isEmpty() || !lrcInstance_->getCurrentCallModel()->hasCall(callId)) {
        return;
    }

    lrcInstance_->getCurrentCallModel()->playDTMF(callId, key);
}

void
CallAdapter::saveConferenceSubcalls()
{
    const auto& currentConvId = lrcInstance_->get_selectedConvUid();
    const auto& convInfo = lrcInstance_->getConversationFromConvUid(currentConvId);
    if (!convInfo.confId.isEmpty()) {
        auto* callModel = lrcInstance_->getAccountInfo(accountId_).callModel.get();
        currentConfSubcalls_ = callModel->getConferenceSubcalls(convInfo.confId);
    }
}

void
CallAdapter::hangUpCall(const QString& callId)
{
    lrcInstance_->getCurrentCallModel()->hangUp(callId);
}

void
CallAdapter::setActiveStream(const QString& uri, const QString& deviceId, const QString& streamId)
{
    auto* callModel = lrcInstance_->getAccountInfo(accountId_).callModel.get();
    const auto& convInfo
        = lrcInstance_->getConversationFromConvUid(lrcInstance_->get_selectedConvUid(), accountId_);

    auto confId = convInfo.confId;
    if (confId.isEmpty())
        confId = convInfo.callId;
    try {
        const auto call = callModel->getCall(confId);
        auto& participantsModel = callModel->getParticipantsInfos(call.id);
        auto participants = participantsModel.getParticipants();
        decltype(participants) activeParticipants = {};
        bool removeActive = false;
        for (const auto& part : participants) {
            auto isParticipant = part.uri == uri && part.device == deviceId
                                 && part.sinkId == streamId;
            if (part.active && !isParticipant)
                activeParticipants.push_back(part);

            if (isParticipant) {
                // Else, continue.
                if (!part.active) {
                    callModel->setActiveStream(confId, uri, deviceId, streamId, true);
                    callModel->setConferenceLayout(confId, lrc::api::call::Layout::ONE_WITH_SMALL);
                } else if (call.layout == lrc::api::call::Layout::ONE_WITH_SMALL) {
                    removeActive = true;
                    callModel->setConferenceLayout(confId, lrc::api::call::Layout::ONE);
                }
            }
        }
        if (removeActive) {
            // If in Big, we can remove other actives
            for (const auto& part : activeParticipants)
                callModel->setActiveStream(confId, part.uri, part.device, part.sinkId, false);
        }
    } catch (...) {
    }
}

void
CallAdapter::minimizeParticipant(const QString& uri)
{
    auto* callModel = lrcInstance_->getAccountInfo(accountId_).callModel.get();
    const auto& convInfo
        = lrcInstance_->getConversationFromConvUid(lrcInstance_->get_selectedConvUid(), accountId_);
    auto confId = convInfo.confId;

    if (confId.isEmpty())
        confId = convInfo.callId;
    try {
        const auto call = callModel->getCall(confId);
        auto& participantsModel = callModel->getParticipantsInfos(call.id);
        auto participants = participantsModel.getParticipants();
        auto activeParticipants = 0;
        for (auto& part : participants) {
            if (part.active) {
                activeParticipants += 1;
                if (part.uri == uri && call.layout == lrc::api::call::Layout::ONE_WITH_SMALL) {
                    callModel->setActiveStream(confId, part.uri, part.device, part.sinkId, false);
                }
            }
        }
        if (activeParticipants == 1) {
            // only one active left, we can change the layout.
            if (call.layout == lrc::api::call::Layout::ONE)
                callModel->setConferenceLayout(confId, lrc::api::call::Layout::ONE_WITH_SMALL);
            else
                callModel->setConferenceLayout(confId, lrc::api::call::Layout::GRID);
        }
    } catch (...) {
    }
}

void
CallAdapter::showGridConferenceLayout()
{
    auto* callModel = lrcInstance_->getAccountInfo(accountId_).callModel.get();
    const auto& convInfo
        = lrcInstance_->getConversationFromConvUid(lrcInstance_->get_selectedConvUid(), accountId_);

    auto confId = convInfo.confId;
    if (confId.isEmpty())
        confId = convInfo.callId;

    callModel->setConferenceLayout(confId, lrc::api::call::Layout::GRID);
}

void
CallAdapter::hangUpThisCall()
{
    const auto& convInfo
        = lrcInstance_->getConversationFromConvUid(lrcInstance_->get_selectedConvUid(), accountId_);
    if (!convInfo.uid.isEmpty()) {
        auto* callModel = lrcInstance_->getAccountInfo(accountId_).callModel.get();
        if (!convInfo.confId.isEmpty() && callModel->hasCall(convInfo.confId)) {
            callModel->hangUp(convInfo.confId);
        } else if (callModel->hasCall(convInfo.callId)) {
            callModel->hangUp(convInfo.callId);
        }
    }
}

bool
CallAdapter::isRecordingThisCall()
{
    const auto& convInfo
        = lrcInstance_->getConversationFromConvUid(lrcInstance_->get_selectedConvUid(), accountId_);
    auto& accInfo = lrcInstance_->accountModel().getAccountInfo(accountId_);
    return accInfo.callModel->isRecording(convInfo.confId)
           || accInfo.callModel->isRecording(convInfo.callId);
}

bool
CallAdapter::isCurrentHost() const
{
    const auto& convInfo
        = lrcInstance_->getConversationFromConvUid(lrcInstance_->get_selectedConvUid(), accountId_);
    if (!convInfo.uid.isEmpty()) {
        auto* callModel = lrcInstance_->getAccountInfo(accountId_).callModel.get();
        try {
            auto confId = convInfo.confId;
            if (confId.isEmpty())
                confId = convInfo.callId;
            if (callModel->getParticipantsInfos(confId).getParticipants().size() == 0) {
                return true;
            } else {
                return !convInfo.confId.isEmpty() && callModel->hasCall(convInfo.confId);
            }
        } catch (...) {
        }
    }
    return true;
}

bool
CallAdapter::participantIsHost(const QString& uri) const
{
    const auto& convInfo = lrcInstance_->getConversationFromConvUid(
        lrcInstance_->get_selectedConvUid());
    if (!convInfo.uid.isEmpty()) {
        auto& accInfo = lrcInstance_->getAccountInfo(accountId_);
        auto* callModel = accInfo.callModel.get();
        try {
            if (isCurrentHost()) {
                return uri == accInfo.profileInfo.uri;
            } else {
                auto call = callModel->getCall(convInfo.callId);
                auto peer = call.peerUri.remove("jami:").remove("ring:");
                return (uri == peer);
            }
        } catch (...) {
        }
    }
    return true;
}

bool
CallAdapter::isHandRaised(const QString& uri) const
{
    auto* callModel = lrcInstance_->getAccountInfo(accountId_).callModel.get();
    const auto& convInfo = lrcInstance_->getConversationFromConvUid(
        lrcInstance_->get_selectedConvUid());
    auto confId = convInfo.confId;

    if (confId.isEmpty())
        confId = convInfo.callId;
    return callModel->isHandRaised(confId, uri);
}

void
CallAdapter::raiseHand(const QString& uri, const QString& deviceId, bool state)
{
    auto* callModel = lrcInstance_->getAccountInfo(accountId_).callModel.get();
    const auto& convInfo = lrcInstance_->getConversationFromConvUid(
        lrcInstance_->get_selectedConvUid());
    auto confId = convInfo.confId;
    if (confId.isEmpty())
        confId = convInfo.callId;
    try {
        callModel->raiseHand(confId, uri, deviceId, state);
    } catch (...) {
    }
}

void
CallAdapter::setModerator(const QString& uri, const bool state)
{
    auto* callModel = lrcInstance_->getAccountInfo(accountId_).callModel.get();
    const auto& convInfo = lrcInstance_->getConversationFromConvUid(
        lrcInstance_->get_selectedConvUid());
    auto confId = convInfo.confId;
    if (confId.isEmpty())
        confId = convInfo.callId;
    try {
        callModel->setModerator(confId, uri, state);
    } catch (...) {
    }
}

void
CallAdapter::muteParticipant(const QString& accountUri,
                             const QString& deviceId,
                             const QString& streamId,
                             const bool state)
{
    auto* callModel = lrcInstance_->getAccountInfo(accountId_).callModel.get();
    const auto& convInfo = lrcInstance_->getConversationFromConvUid(
        lrcInstance_->get_selectedConvUid());
    auto confId = convInfo.confId;

    if (confId.isEmpty())
        confId = convInfo.callId;
    try {
        const auto call = callModel->getCall(confId);
        callModel->muteStream(confId, accountUri, deviceId, streamId, state);
    } catch (...) {
    }
}

CallAdapter::MuteStates
CallAdapter::getMuteState(const QString& uri) const
{
    const auto& convInfo = lrcInstance_->getConversationFromConvUid(
        lrcInstance_->get_selectedConvUid());
    auto* callModel = lrcInstance_->getAccountInfo(accountId_).callModel.get();
    auto confId = convInfo.confId.isEmpty() ? convInfo.callId : convInfo.confId;
    try {
        auto& participantsModel = callModel->getParticipantsInfos(confId);
        if (participantsModel.getParticipants().size() == 0) {
            return MuteStates::UNMUTED;
        } else {
            for (const auto& participant : participantsModel.getParticipants()) {
                if (participant.uri == uri) {
                    if (participant.audioLocalMuted) {
                        if (participant.audioModeratorMuted) {
                            return MuteStates::BOTH_MUTED;
                        } else {
                            return MuteStates::LOCAL_MUTED;
                        }
                    } else if (participant.audioModeratorMuted) {
                        return MuteStates::MODERATOR_MUTED;
                    }
                    return MuteStates::UNMUTED;
                }
            }
        }
        return MuteStates::UNMUTED;
    } catch (...) {
    }
    return MuteStates::UNMUTED;
}

void
CallAdapter::hangupParticipant(const QString& uri, const QString& deviceId)
{
    auto* callModel = lrcInstance_->getAccountInfo(accountId_).callModel.get();
    const auto& convInfo = lrcInstance_->getConversationFromConvUid(
        lrcInstance_->get_selectedConvUid());
    auto confId = convInfo.confId;

    if (confId.isEmpty())
        confId = convInfo.callId;
    try {
        const auto call = callModel->getCall(confId);
        callModel->hangupParticipant(confId, uri, deviceId);
    } catch (...) {
    }
}

void
CallAdapter::holdThisCallToggle()
{
    const auto callId = lrcInstance_->getCallIdForConversationUid(lrcInstance_->get_selectedConvUid(),
                                                                  accountId_);
    if (callId.isEmpty() || !lrcInstance_->getCurrentCallModel()->hasCall(callId)) {
        return;
    }
    auto* callModel = lrcInstance_->getCurrentCallModel();
    if (callModel->hasCall(callId)) {
        callModel->togglePause(callId);
    }
}

bool
CallAdapter::isMuted(const QString& callId)
{
    if (!(callId.isEmpty() || !lrcInstance_->getCurrentCallModel()->hasCall(callId))) {
        auto* callModel = lrcInstance_->getCurrentCallModel();
        if (callModel->hasCall(callId)) {
            const auto callInfo = lrcInstance_->getCurrentCallModel()->getCall(callId);
            auto mute = false;
            for (const auto& m : callInfo.mediaList)
                if (m[libjami::Media::MediaAttributeKey::LABEL] == "audio_0")
                    mute = m[libjami::Media::MediaAttributeKey::MUTED] == TRUE_STR;
            return mute;
        }
    }
    throw std::runtime_error("CallAdapter::isMuted: callId is empty or call does not exist");
}

void
CallAdapter::muteAudioToggle()
{
    const auto callId = lrcInstance_->getCallIdForConversationUid(lrcInstance_->get_selectedConvUid(),
                                                                  accountId_);
    if (callId.isEmpty() || !lrcInstance_->getCurrentCallModel()->hasCall(callId)) {
        return;
    }
    auto* callModel = lrcInstance_->getCurrentCallModel();
    try {
        callModel->muteMedia(callId, "audio_0", !isMuted(callId));
    } catch (const std::exception& e) {
        qWarning() << e.what();
    }
}

void
CallAdapter::recordThisCallToggle()
{
    const auto callId = lrcInstance_->getCallIdForConversationUid(lrcInstance_->get_selectedConvUid(),
                                                                  accountId_);
    if (callId.isEmpty() || !lrcInstance_->getCurrentCallModel()->hasCall(callId)) {
        return;
    }
    auto* callModel = lrcInstance_->getCurrentCallModel();
    if (callModel->hasCall(callId)) {
        callModel->toggleAudioRecord(callId);
    }
}

void
CallAdapter::muteCameraToggle()
{
    const auto callId = lrcInstance_->getCallIdForConversationUid(lrcInstance_->get_selectedConvUid(),
                                                                  accountId_);
    if (callId.isEmpty() || !lrcInstance_->getCurrentCallModel()->hasCall(callId)) {
        return;
    }
    auto* callModel = lrcInstance_->getCurrentCallModel();
    if (callModel->hasCall(callId)) {
        const auto callInfo = lrcInstance_->getCurrentCallModel()->getCall(callId);
        auto mute = false;
        for (const auto& m : callInfo.mediaList) {
            if (m[libjami::Media::MediaAttributeKey::SOURCE].startsWith(
                    libjami::Media::VideoProtocolPrefix::CAMERA)
                && m[libjami::Media::MediaAttributeKey::MEDIA_TYPE]
                       == libjami::Media::Details::MEDIA_TYPE_VIDEO) {
                mute = m[libjami::Media::MediaAttributeKey::MUTED] == FALSE_STR;
            }
        }

        // Note: here we do not use mute, because for video we can have several inputs, so if we are
        // sharing and showing the camera, we just want to remove the camera
        // TODO Enum
        if (mute)
            callModel->removeMedia(callId,
                                   libjami::Media::Details::MEDIA_TYPE_VIDEO,
                                   libjami::Media::VideoProtocolPrefix::CAMERA,
                                   mute,
                                   false);
        else
            callModel->addMedia(callId,
                                lrcInstance_->avModel().getCurrentVideoCaptureDevice(),
                                lrc::api::CallModel::MediaRequestType::CAMERA);
    }
}

QString
CallAdapter::getCallDurationTime(const QString& accountId, const QString& convUid)
{
    const auto callId = lrcInstance_->getCallIdForConversationUid(convUid, accountId);
    if (callId.isEmpty() || !lrcInstance_->getCurrentCallModel()->hasCall(callId)) {
        return QString();
    }
    const auto callInfo = lrcInstance_->getCurrentCallModel()->getCall(callId);
    if (callInfo.status == lrc::api::call::Status::IN_PROGRESS
        || callInfo.status == lrc::api::call::Status::PAUSED) {
        return lrcInstance_->getCurrentCallModel()->getFormattedCallDuration(callId);
    }

    return QString();
}

void
CallAdapter::resetCallInfo()
{
    callInformationListModel_->reset();
}

void
CallAdapter::setCallInfo()
{
    try {
        auto& callModel = lrcInstance_->accountModel().getAccountInfo(accountId_).callModel;
        for (auto callId : callModel->getCallIds()) {
            callInformationListModel_->addElement(
                qMakePair(callId, callModel->advancedInformationForCallId(callId)));
        }

    } catch (const std::exception& e) {
        qWarning() << e.what();
    }
}

void
CallAdapter::updateAdvancedInformation()
{
    try {
        auto& callModel = lrcInstance_->accountModel().getAccountInfo(accountId_).callModel;
        for (auto callId : callModel->getCallIds()) {
            if (!callInformationListModel_->addElement(
                    qMakePair(callId, callModel->advancedInformationForCallId(callId)))) {
                callInformationListModel_->editElement(
                    qMakePair(callId, callModel->advancedInformationForCallId(callId)));
            }
        }
    } catch (const std::exception& e) {
        qWarning() << e.what();
    }
}

bool
CallAdapter::takeScreenshot(const QImage& image, const QString& path)
{
    QString name = QString("%1 %2").arg(tr("Screenshot"),
#ifdef WIN32
                                        QDateTime::currentDateTime().toString("yyyy-MM-dd HHmmss")
#else
                                        QDateTime::currentDateTime().toString(Qt::ISODate)
#endif
    );

    bool fileAlreadyExists = true;
    int nb = 0;
    QString filePath = QString("%1%2.png").arg(path, name);
    while (fileAlreadyExists) {
        filePath = QString("%1%2.png").arg(path, name);
        if (nb)
            filePath = QString("%1(%2).png").arg(filePath, QString::number(nb));
        QFileInfo check_file(filePath);
        fileAlreadyExists = check_file.exists() && check_file.isFile();
        nb++;
    }
    return image.save(filePath, "PNG");
}

void
CallAdapter::preventScreenSaver(bool state)
{
    if (state) {
        if (!screenSaver.isInhibited())
            screenSaver.inhibit();
    } else if (screenSaver.isInhibited()) {
        screenSaver.uninhibit();
    }
};
