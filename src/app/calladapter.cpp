/*
 * Copyright (C) 2020-2022 Savoir-faire Linux Inc.
 * Author: Edric Ladent Milaret <edric.ladent-milaret@savoirfairelinux.com>
 * Author: Anthony Léonard <anthony.leonard@savoirfairelinux.com>
 * Author: Olivier Soldano <olivier.soldano@savoirfairelinux.com>
 * Author: Andreas Traczyk <andreas.traczyk@savoirfairelinux.com>
 * Author: Isa Nanic <isa.nanic@savoirfairelinux.com>
 * Author: Mingrui Zhang <mingrui.zhang@savoirfairelinux.com>
 * Author: Sébastien Blin <sebastien.blin@savoirfairelinux.com>
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
#include "utils.h"
#include "qmlregister.h"

#include <QApplication>
#include <QTimer>
#include <QJsonObject>

#include <api/callparticipantsmodel.h>

#include <media_const.h>

CallAdapter::CallAdapter(SystemTray* systemTray, LRCInstance* instance, QObject* parent)
    : QmlAdapterBase(instance, parent)
    , systemTray_(systemTray)
{
    participantsModel_.reset(new CallParticipantsModel(lrcInstance_, this));
    QML_REGISTERSINGLETONTYPE_POBJECT(NS_MODELS, participantsModel_.get(), "CallParticipantsModel");
    participantsModelFiltered_.reset(
        new GenericParticipantsFilterModel(lrcInstance_, participantsModel_.get()));
    QML_REGISTERSINGLETONTYPE_POBJECT(NS_MODELS,
                                      participantsModelFiltered_.get(),
                                      "GenericParticipantsFilterModel");
    activeParticipantsModel_.reset(
        new ActiveParticipantsFilterModel(lrcInstance_, participantsModel_.get()));
    QML_REGISTERSINGLETONTYPE_POBJECT(NS_MODELS,
                                      activeParticipantsModel_.get(),
                                      "ActiveParticipantsFilterModel");
    overlayModel_.reset(new CallOverlayModel(lrcInstance_, this));
    QML_REGISTERSINGLETONTYPE_POBJECT(NS_MODELS, overlayModel_.get(), "CallOverlayModel");

    accountId_ = lrcInstance_->get_currentAccountId();
    if (!accountId_.isEmpty())
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
            [this](const QString& accountId, const QString& convUid) {
                acceptACall(accountId, convUid);
                Q_EMIT lrcInstance_->notificationClicked();
                lrcInstance_->selectConversation(convUid, accountId);
                updateCall(convUid, accountId);
                Q_EMIT lrcInstance_->conversationUpdated(convUid, accountId);
            });
    connect(systemTray_,
            &SystemTray::declineCallActivated,
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
        systemTray_->hideNotification(QString("%1;%2").arg(accountId).arg(convInfo.uid));
    } else if (call.status == lrc::api::call::Status::ENDED) {
        // Call ended; close the notification
        if (systemTray_->hideNotification(QString("%1;%2").arg(accountId).arg(convInfo.uid))
            && call.startTime.time_since_epoch().count() == 0) {
            // This was a missed call; show a missed call notification
            auto convAvatar = Utils::conversationAvatar(lrcInstance_,
                                                        convInfo.uid,
                                                        QSize(50, 50),
                                                        accountId);
            auto& accInfo = lrcInstance_->getAccountInfo(accountId);
            auto from = accInfo.conversationModel->title(convInfo.uid);
            auto notifId = QString("%1;%2").arg(accountId).arg(convInfo.uid);
            systemTray_->showNotification(notifId,
                                          tr("Missed call"),
                                          tr("Missed call with %1").arg(from),
                                          NotificationType::CHAT,
                                          Utils::QImageToByteArray(convAvatar));
        }
    }
#else
    Q_UNUSED(accountId)
    Q_UNUSED(callId)
#endif
}

void
CallAdapter::onParticipantAdded(const QString& callId, int index)
{
    auto& accInfo = lrcInstance_->accountModel().getAccountInfo(accountId_);
    auto& callModel = accInfo.callModel;
    try {
        if (lrcInstance_->get_selectedConvUid().isEmpty())
            return;
        const auto& currentConvInfo = accInfo.conversationModel.get()->getConversationForUid(
            lrcInstance_->get_selectedConvUid());
        if (callId != currentConvInfo->get().callId && callId != currentConvInfo->get().confId) {
            qDebug() << "trying to update not current conf";
            return;
        }
        auto infos = getConferencesInfos();
        if (index < infos.size())
            participantsModel_->addParticipant(index, infos[index]);
    } catch (...) {
    }
}

void
CallAdapter::onParticipantRemoved(const QString& callId, int index)
{
    auto& accInfo = lrcInstance_->accountModel().getAccountInfo(accountId_);
    auto& callModel = accInfo.callModel;
    try {
        if (lrcInstance_->get_selectedConvUid().isEmpty())
            return;
        const auto& currentConvInfo = accInfo.conversationModel.get()->getConversationForUid(
            lrcInstance_->get_selectedConvUid());
        if (callId != currentConvInfo->get().callId && callId != currentConvInfo->get().confId) {
            qDebug() << "trying to update not current conf";
            return;
        }
        participantsModel_->removeParticipant(index);
    } catch (...) {
    }
}

void
CallAdapter::onParticipantUpdated(const QString& callId, int index)
{
    auto& accInfo = lrcInstance_->accountModel().getAccountInfo(accountId_);
    auto& callModel = accInfo.callModel;
    try {
        if (lrcInstance_->get_selectedConvUid().isEmpty())
            return;
        const auto& currentConvInfo = accInfo.conversationModel.get()->getConversationForUid(
            lrcInstance_->get_selectedConvUid());
        if (callId != currentConvInfo->get().callId && callId != currentConvInfo->get().confId) {
            qDebug() << "trying to update not current conf";
            return;
        }
        auto infos = getConferencesInfos();
        participantsModel_->updateParticipant(index, infos[index]);
    } catch (...) {
    }
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
            updateCallOverlay(convInfo);
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
            if (currentConvInfo.confId.isEmpty() && currentConfSubcalls_.size() == 2) {
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
            } else {
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
    auto& accInfo = lrcInstance_->accountModel().getAccountInfo(accountId);
    auto& callModel = accInfo.callModel;

    try {
        const auto call = callModel->getCall(callId);
        /*
         * Change status label text.
         */
        const auto& convInfo = lrcInstance_->getConversationFromCallId(callId);
        if (!convInfo.uid.isEmpty()) {
            if (!convInfo.confId.isEmpty() && callId != convInfo.confId) {
                // In this case the conv has a confId, ignore subcalls changes.
                return;
            }
            Q_EMIT callInfosChanged(call.isAudioOnly, accountId, convInfo.uid);
            participantsModel_->setConferenceLayout(static_cast<int>(call.layout), callId);
            updateCallOverlay(convInfo);
        }
    } catch (...) {
    }
}

void
CallAdapter::onRemoteRecordingChanged(const QString& callId,
                                      const QSet<QString>& peerRec,
                                      bool state)
{
    Q_UNUSED(peerRec)
    Q_UNUSED(state)
    const auto currentCallId
        = lrcInstance_->getCallIdForConversationUid(lrcInstance_->get_selectedConvUid(), accountId_);
    if (callId == currentCallId)
        updateRecordingPeers();
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
    auto& accInfo = lrcInstance_->getAccountInfo(convInfo.accountId);
    accInfo.callModel->setCurrentCall(convInfo.callId);
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

    auto callBelongsToSelectedAccount = accountId == lrcInstance_->get_currentAccountId();
    auto accountProperties = lrcInstance_->accountModel().getAccountConfig(accountId);

    // do nothing but update the status UI for incoming calls on RendezVous accounts
    if (accountProperties.isRendezVous && !call.isOutgoing) {
        qInfo() << Q_FUNC_INFO << "The call's associated account is a RendezVous point";
        return;
    }

    auto currentConvId = lrcInstance_->get_selectedConvUid();
    auto isCallSelected = currentConvId == convInfo.uid;

    // pop a notification when:
    // - the window is not focused OR the call is for another account
    // - the call is incoming AND the call's target account is
    //   not a RendezVous point
    // - the call has just transitioned to the INCOMING_RINGING state
    if ((QApplication::focusObject() == nullptr || !callBelongsToSelectedAccount)
        && !call.isOutgoing && !accountProperties.isRendezVous
        && call.status == call::Status::INCOMING_RINGING) {
        // if the window is not focused but the call belongs to the selected account
        // then select the conversation immediately to show the call view
        if (callBelongsToSelectedAccount) {
            if (isCallSelected) {
                Q_EMIT lrcInstance_->conversationUpdated(convInfo.uid, accountId);
            } else {
                lrcInstance_->selectConversation(convInfo.uid);
            }
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
    if (convInfo.uid.isEmpty()) {
        return;
    }

    auto call = lrcInstance_->getCallInfoForConversation(convInfo, forceCallOnly);
    if (!call) {
        return;
    }

    if (convInfo.uid == lrcInstance_->get_selectedConvUid()) {
        auto& accInfo = lrcInstance_->accountModel().getAccountInfo(accountId_);
        if (accInfo.profileInfo.type != lrc::api::profile::Type::SIP) {
            accInfo.callModel->setCurrentCall(call->id);
        }
    }

    updateCallOverlay(convInfo);
    updateRecordingPeers(true);
    participantsModel_->setParticipants(call->id, getConferencesInfos());
    participantsModel_->setConferenceLayout(static_cast<int>(call->layout), call->id);
}

void
CallAdapter::fillParticipantData(QJsonObject& participant) const
{
    participant[lrc::api::ParticipantsInfosStrings::BESTNAME]
        = participant[lrc::api::ParticipantsInfosStrings::URI];
    auto& accInfo = lrcInstance_->accountModel().getAccountInfo(accountId_);
    participant[lrc::api::ParticipantsInfosStrings::ISLOCAL] = false;
    if (participant[lrc::api::ParticipantsInfosStrings::BESTNAME] == accInfo.profileInfo.uri) {
        participant[lrc::api::ParticipantsInfosStrings::BESTNAME] = tr("me");
        participant[lrc::api::ParticipantsInfosStrings::ISLOCAL] = true;
    } else {
        try {
            participant[lrc::api::ParticipantsInfosStrings::BESTNAME]
                = lrcInstance_->getCurrentAccountInfo().contactModel->bestNameForContact(
                    participant[lrc::api::ParticipantsInfosStrings::URI].toString());
        } catch (...) {
        }
    }
}

QVariantList
CallAdapter::getConferencesInfos() const
{
    QVariantList map;
    const auto& convInfo = lrcInstance_->getConversationFromConvUid(
        lrcInstance_->get_selectedConvUid());
    if (convInfo.uid.isEmpty())
        return map;
    auto callId = convInfo.confId.isEmpty() ? convInfo.callId : convInfo.confId;
    if (!callId.isEmpty()) {
        try {
            auto& participantsModel = lrcInstance_->accountModel()
                                          .getAccountInfo(accountId_)
                                          .callModel.get()
                                          ->getParticipantsInfos(callId);
            int index = 0;
            for (int index = 0; index < participantsModel.getParticipants().size(); index++) {
                auto participant = participantsModel.toQJsonObject(index);
                fillParticipantData(participant);
                map.push_back(QVariant(participant));
            }
            return map;
        } catch (...) {
        }
    }
    return map;
}

void
CallAdapter::showNotification(const QString& accountId, const QString& convUid)
{
    auto& accInfo = lrcInstance_->getAccountInfo(accountId);
    auto title = accInfo.conversationModel->title(convUid);

#ifdef Q_OS_LINUX
    auto convAvatar = Utils::conversationAvatar(lrcInstance_, convUid, QSize(50, 50), accountId);
    auto notifId = QString("%1;%2").arg(accountId).arg(convUid);
    systemTray_->showNotification(notifId,
                                  tr("Incoming call"),
                                  tr("%1 is calling you").arg(title),
                                  NotificationType::CALL,
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
    auto& accInfo = lrcInstance_->accountModel().getAccountInfo(accountId);

    connect(accInfo.callModel.get(),
            &CallModel::participantAdded,
            this,
            &CallAdapter::onParticipantAdded,
            Qt::UniqueConnection);

    connect(accInfo.callModel.get(),
            &CallModel::participantRemoved,
            this,
            &CallAdapter::onParticipantRemoved,
            Qt::UniqueConnection);

    connect(accInfo.callModel.get(),
            &CallModel::participantUpdated,
            this,
            &CallAdapter::onParticipantUpdated,
            Qt::UniqueConnection);

    connect(accInfo.callModel.get(),
            &CallModel::callStatusChanged,
            this,
            QOverload<const QString&, int>::of(&CallAdapter::onCallStatusChanged),
            Qt::UniqueConnection);

    connect(accInfo.callModel.get(),
            &CallModel::remoteRecordingChanged,
            this,
            &CallAdapter::onRemoteRecordingChanged,
            Qt::UniqueConnection);

    connect(accInfo.callModel.get(),
            &CallModel::callAddedToConference,
            this,
            &CallAdapter::onCallAddedToConference,
            Qt::UniqueConnection);

    connect(accInfo.callModel.get(),
            &CallModel::callInfosChanged,
            this,
            QOverload<const QString&, const QString&>::of(&CallAdapter::onCallInfosChanged));
}

void
CallAdapter::updateRecordingPeers(bool eraseLabelOnEmpty)
{
    const auto& convInfo = lrcInstance_->getConversationFromConvUid(
        lrcInstance_->get_selectedConvUid());
    auto* call = lrcInstance_->getCallInfoForConversation(convInfo);
    if (!call) {
        return;
    }

    const auto& accInfo = lrcInstance_->getCurrentAccountInfo();
    QStringList peers {};
    for (const auto& uri : call->peerRec) {
        auto bestName = accInfo.contactModel->bestNameForContact(uri);
        if (!bestName.isEmpty()) {
            peers.append(bestName);
        }
    }
    if (!peers.isEmpty())
        Q_EMIT remoteRecordingChanged(peers, true);
    else if (eraseLabelOnEmpty)
        Q_EMIT eraseRemoteRecording();
    else
        Q_EMIT remoteRecordingChanged(peers, false);
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

/*
 * For Call Overlay
 */
void
CallAdapter::updateCallOverlay(const lrc::api::conversation::Info& convInfo)
{
    auto& accInfo = lrcInstance_->accountModel().getAccountInfo(accountId_);
    auto* callModel = accInfo.callModel.get();

    const auto* callInfo = lrcInstance_->getCallInfoForConversation(convInfo);
    const auto currentCallId = lrcInstance_->getCurrentCallId();
    if (!callInfo || callInfo->id != currentCallId)
        return;

    bool isPaused = callInfo->status == lrc::api::call::Status::PAUSED;
    bool isAudioOnly = callInfo->isAudioOnly && !isPaused;
    bool isAudioMuted = callInfo->status == lrc::api::call::Status::PAUSED;
    bool isGrid = callInfo->layout == lrc::api::call::Layout::GRID;
    QString previewId {};
    bool isVideoMuted = false;
    if (callInfo->status != lrc::api::call::Status::ENDED) {
        for (const auto& media : callInfo->mediaList) {
            if (media[DRing::Media::MediaAttributeKey::MEDIA_TYPE]
                == DRing::Media::Details::MEDIA_TYPE_VIDEO) {
                if (media[DRing::Media::MediaAttributeKey::ENABLED] == TRUE_STR
                    && media[DRing::Media::MediaAttributeKey::MUTED] == FALSE_STR) {
                    if (previewId.isEmpty()) {
                        previewId = media[DRing::Media::MediaAttributeKey::SOURCE];
                    }
                    isVideoMuted |= media[DRing::Media::MediaAttributeKey::SOURCE].startsWith(
                        DRing::Media::VideoProtocolPrefix::CAMERA);
                }
            } else if (media[DRing::Media::MediaAttributeKey::LABEL] == "audio_0") {
                isAudioMuted |= media[DRing::Media::MediaAttributeKey::MUTED] == TRUE_STR;
            }
        }
    }

    Q_EMIT updateOverlay(isPaused,
                         isAudioOnly,
                         isAudioMuted,
                         isVideoMuted,
                         accInfo.profileInfo.type == lrc::api::profile::Type::SIP,
                         isGrid,
                         previewId);
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
        auto participants = getConferencesInfos();
        std::vector<QJsonObject> activeParticipants = {};
        bool removeActive = false;
        for (auto part : participants) {
            auto participant = part.toJsonObject();

            auto puri = participant[lrc::api::ParticipantsInfosStrings::URI].toString();
            auto pdeviceId = participant[lrc::api::ParticipantsInfosStrings::DEVICE].toString();
            auto pstreamId = participant[lrc::api::ParticipantsInfosStrings::STREAMID].toString();

            auto isParticipant = puri == uri && pdeviceId == deviceId && pstreamId == streamId;
            auto active = participant[lrc::api::ParticipantsInfosStrings::ACTIVE].toBool();
            if (active && !isParticipant)
                activeParticipants.push_back(participant);

            if (isParticipant) {
                // Else, continue.
                if (!active) {
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
            for (const auto& p : activeParticipants) {
                auto puri = p[lrc::api::ParticipantsInfosStrings::URI].toString();
                auto deviceId = p[lrc::api::ParticipantsInfosStrings::DEVICE].toString();
                auto streamId = p[lrc::api::ParticipantsInfosStrings::STREAMID].toString();
                callModel->setActiveStream(confId, puri, deviceId, streamId, false);
            }
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
        auto participants = getConferencesInfos();
        auto activeParticipants = 0;
        for (auto& part : participants) {
            auto participant = part.toJsonObject();
            if (participant[lrc::api::ParticipantsInfosStrings::ACTIVE].toBool()) {
                activeParticipants += 1;
                if (participant[lrc::api::ParticipantsInfosStrings::URI].toString() == uri
                    && call.layout == lrc::api::call::Layout::ONE_WITH_SMALL) {
                    auto deviceId = participant[lrc::api::ParticipantsInfosStrings::DEVICE]
                                        .toString();
                    auto streamId = participant[lrc::api::ParticipantsInfosStrings::STREAMID]
                                        .toString();
                    callModel->setActiveStream(confId, uri, deviceId, streamId, false);
                }
            }
        }
        if (activeParticipants == 1) {
            // only one active left, we can change the layout.
            if (call.layout == lrc::api::call::Layout::ONE) {
                callModel->setConferenceLayout(confId, lrc::api::call::Layout::ONE_WITH_SMALL);
            } else {
                callModel->setConferenceLayout(confId, lrc::api::call::Layout::GRID);
            }
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
CallAdapter::isModerator(const QString& uri) const
{
    auto* callModel = lrcInstance_->getAccountInfo(accountId_).callModel.get();
    const auto& convInfo = lrcInstance_->getConversationFromConvUid(
        lrcInstance_->get_selectedConvUid());
    auto confId = convInfo.confId;

    if (confId.isEmpty())
        confId = convInfo.callId;
    try {
        return callModel->isModerator(confId, uri);
    } catch (...) {
    }
    return false;
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
    Q_EMIT showOnHoldLabel(true);
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
    if (callModel->hasCall(callId)) {
        const auto callInfo = lrcInstance_->getCurrentCallModel()->getCall(callId);
        auto mute = false;
        for (const auto& m : callInfo.mediaList)
            if (m[DRing::Media::MediaAttributeKey::LABEL] == "audio_0")
                mute = m[DRing::Media::MediaAttributeKey::MUTED] == FALSE_STR;
        callModel->muteMedia(callId, "audio_0", mute);
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
            if (m[DRing::Media::MediaAttributeKey::SOURCE].startsWith(
                    DRing::Media::VideoProtocolPrefix::CAMERA)
                && m[DRing::Media::MediaAttributeKey::MEDIA_TYPE]
                       == DRing::Media::Details::MEDIA_TYPE_VIDEO) {
                mute = m[DRing::Media::MediaAttributeKey::MUTED] == FALSE_STR;
            }
        }

        // Note: here we do not use mute, because for video we can have several inputs, so if we are
        // sharing and showing the camera, we just want to remove the camera
        // TODO Enum
        if (mute)
            callModel->removeMedia(callId,
                                   DRing::Media::Details::MEDIA_TYPE_VIDEO,
                                   DRing::Media::VideoProtocolPrefix::CAMERA,
                                   mute);
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
CallAdapter::preventScreenSaver(bool state)
{
    if (state) {
        if (!screenSaver.isInhibited())
            screenSaver.inhibit();
    } else if (screenSaver.isInhibited()) {
        screenSaver.uninhibit();
    }
};
