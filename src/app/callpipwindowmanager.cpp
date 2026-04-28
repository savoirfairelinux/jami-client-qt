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

#include "callpipwindowmanager.h"
#include "lrcinstance.h"

#include <api/call.h>
#include <api/callmodel.h>
#include <api/callparticipantsmodel.h>
#include <api/conversationmodel.h>

#include <QApplication>
#include <QQmlComponent>
#include <QQmlContext>
#include <QQmlEngine>
#include <QQuickWindow>

CallPipWindowManager::CallPipWindowManager(QQmlEngine* engine, LRCInstance* lrcInstance, QObject* parent)
    : QObject(parent)
    , engine_(engine)
    , lrcInstance_(lrcInstance)
{}

CallPipWindowManager*
CallPipWindowManager::create(QQmlEngine* engine, QJSEngine*)
{
    auto* lrcInstance = qApp->property("LRCInstance").value<LRCInstance*>();
    return new CallPipWindowManager(engine, lrcInstance);
}

QString
CallPipWindowManager::pipPreviewId() const
{
    if (pipCallId_.isEmpty() || pipAccountId_.isEmpty())
        return {};
    try {
        auto& accInfo = lrcInstance_->accountModel().getAccountInfo(pipAccountId_);
        if (accInfo.callModel->hasCall(pipCallId_)) {
            auto callInfo = accInfo.callModel->getCall(pipCallId_);
            return callInfo.getCallInfoEx()[QStringLiteral("preview_id")].toString();
        }
    } catch (const std::exception& e) {
        qWarning() << "CallPipWindowManager::create:" << e.what();
    }
    return {};
}

bool
CallPipWindowManager::convHasActiveCall(const QString& convId, const QString& accountId) const
{
    return !lrcInstance_->getCallIdForConversationUid(convId, accountId).isEmpty();
}

void
CallPipWindowManager::popOutCall(const QString& convId, const QString& accountId)
{
    // If this call is already in PiP, just raise the window.
    if (pipConvId_ == convId && !window_.isNull()) {
        window_->raise();
        window_->requestActivate();
        return;
    }
    // Close any existing PiP window before opening a new one.
    closePip();

    // Retrieve the active call ID for this conversation.
    const QString callId = lrcInstance_->getCallIdForConversationUid(convId, accountId);
    if (callId.isEmpty()) {
        qWarning() << "CallPipWindowManager: no active call for conv" << convId;
        return;
    }

    // Instantiate CallPipWindow.qml.
    QQmlComponent component(engine_, QUrl(QStringLiteral("qrc:/CallPipWindow.qml")));
    if (component.status() != QQmlComponent::Ready) {
        qWarning() << "CallPipWindowManager: component error:" << component.errorString();
        return;
    }

    auto* rootObj = component.createWithInitialProperties({{"pipConvId", convId}, {"pipAccountId", accountId}});
    if (!rootObj) {
        qWarning() << "CallPipWindowManager: failed to create PiP window";
        return;
    }

    QQmlEngine::setObjectOwnership(rootObj, QQmlEngine::CppOwnership);
    auto* win = qobject_cast<QQuickWindow*>(rootObj);
    if (!win) {
        qWarning() << "CallPipWindowManager: root object is not a QQuickWindow";
        rootObj->deleteLater();
        return;
    }

    window_ = QPointer<QQuickWindow>(win);

    pipConvId_ = convId;
    pipAccountId_ = accountId;
    pipCallId_ = callId;

    const auto& accInfo = lrcInstance_->getAccountInfo(pipAccountId_);
    const auto& conferenceParticipants = accInfo.callModel->getParticipantsInfos(pipCallId_);
    const QList<ParticipantInfos>& conferenceParticipantInfos = conferenceParticipants.getParticipants();

    // We check if the call is a conference
    if (conferenceParticipantInfos.size() > 0) {
        pipIsConference_ = true;
        Q_EMIT pipIsConferenceChanged();
    }

    if (conferenceParticipantInfos.size() == 1) {
        pipIsEmptyConference_ = true;
        Q_EMIT pipIsEmptyConferenceChanged();
    }

    // Resolve peer URI from the conversation so the avatar is available immediately.
    pipPeerUri_.clear();
    try {
        auto& accInfo = lrcInstance_->accountModel().getAccountInfo(accountId);
        const QString localUri = accInfo.profileInfo.uri;
        if (auto optConv = accInfo.conversationModel->getConversationForUid(convId)) {
            for (const auto& uri : optConv->get().participantsUris()) {
                if (uri != localUri) {
                    pipPeerUri_ = uri;
                    break;
                }
            }
        }
    } catch (const std::exception& e) {
        qWarning() << "CallPipWindowManager::popOutCall:" << e.what();
    }

    // For conferences only, if 1-to-1 an early return occurs
    updateConferenceVideoState();

    // The updateConferenceVideoState may fail to assign and signal a non-empty
    // uri and sinkId if the conference has more than 3 participants where none
    // are actively speaking. To circumvent showing a black screen in the PIP window,
    // we show the first non-local participant
    if (pipActiveSpeakerUri_.isEmpty() || pipActiveSpeakerSinkId_.isEmpty()) {
        for (const auto& p : conferenceParticipantInfos) {
            if (p.uri != accInfo.profileInfo.uri) {
                pipActiveSpeakerUri_ = p.uri;
                pipActiveSpeakerSinkId_ = p.sinkId;
                break;
            }
        }
    }

    // Clean up when the window is closed.
    connect(win, &QQuickWindow::closing, this, [this, win](QQuickCloseEvent*) {
        pipConvId_.clear();
        pipAccountId_.clear();
        pipCallId_.clear();
        pipIsAudioMuted_ = false;
        pipIsCapturing_ = false;
        pipPeerVideoMuted_ = true;
        pipPeerUri_.clear();
        pipActiveSpeakerUri_.clear();
        pipActiveSpeakerSinkId_.clear();
        pipIsConference_ = false;
        pipIsEmptyConference_ = false;
        disconnectCallModel();
        win->deleteLater();
        Q_EMIT isPipActiveChanged();
        Q_EMIT pipConvIdChanged();
        Q_EMIT pipCallIdChanged();
        Q_EMIT pipAccountIdChanged();
        Q_EMIT pipPreviewIdChanged();
        Q_EMIT pipIsAudioMutedChanged();
        Q_EMIT pipIsCapturingChanged();
        Q_EMIT pipPeerVideoMutedChanged();
        Q_EMIT pipPeerUriChanged();
        Q_EMIT pipActiveSpeakerUriChanged();
        Q_EMIT pipActiveSpeakerSinkIdChanged();
        Q_EMIT pipIsConferenceChanged();
        Q_EMIT pipIsEmptyConferenceChanged();
    });

    // Monitor call status to auto-close the PiP when the call ends.
    connectCallModel(accountId);

    win->show();
    Q_EMIT isPipActiveChanged();
    Q_EMIT pipConvIdChanged();
    Q_EMIT pipCallIdChanged();
    Q_EMIT pipAccountIdChanged();
    Q_EMIT pipPreviewIdChanged();
    Q_EMIT pipIsAudioMutedChanged();
    Q_EMIT pipIsCapturingChanged();
    Q_EMIT pipPeerVideoMutedChanged();
    Q_EMIT pipPeerUriChanged();
    Q_EMIT pipActiveSpeakerUriChanged();
    Q_EMIT pipActiveSpeakerSinkIdChanged();
    Q_EMIT pipIsConferenceChanged();
    Q_EMIT pipIsEmptyConferenceChanged();
}

// TODO: this function should no longer be necessary once ConversationContext is implemented
void
CallPipWindowManager::popOutFirstActiveCall()
{
    if (isPipActive())
        return;
    const auto accountList = lrcInstance_->accountModel().getAccountList();
    for (const auto& accountId : accountList) {
        for (const auto& callId : lrcInstance_->getActiveCalls(accountId)) {
            const auto& convInfo = lrcInstance_->getConversationFromCallId(callId, accountId);
            if (!convInfo.uid.isEmpty()) {
                popOutCall(convInfo.uid, accountId);
                return;
            }
        }
    }
}

void
CallPipWindowManager::reabsorb()
{
    if (pipConvId_.isEmpty())
        return;

    const QString convId = pipConvId_;
    const QString accountId = pipAccountId_;

    // Close PiP window first (will clear pipConvId_ etc. via closing signal).
    closePip();

    // Restore the main window if it is minimised or hidden.
    Q_EMIT lrcInstance_->restoreAppRequested();

    // Select the call conversation in the main window.
    lrcInstance_->selectConversation(convId, accountId);
}

void
CallPipWindowManager::closeAll()
{
    closePip();
}

void
CallPipWindowManager::closeForAccount(const QString& accountId)
{
    if (pipAccountId_ == accountId)
        closePip();
}

#ifdef BUILD_TESTING
void
CallPipWindowManager::setTestPipState(const QString& convId,
                                      const QString& accountId,
                                      const QString& callId)
{
    // Close any existing PiP state first.
    if (!pipConvId_.isEmpty())
        closePip();

    pipConvId_ = convId;
    pipAccountId_ = accountId;
    pipCallId_ = callId.isEmpty()
                     ? lrcInstance_->getCallIdForConversationUid(convId, accountId)
                     : callId;
    testPipActive_ = true;

    if (!pipCallId_.isEmpty())
        connectCallModel(accountId);

    Q_EMIT isPipActiveChanged();
    Q_EMIT pipConvIdChanged();
    Q_EMIT pipCallIdChanged();
    Q_EMIT pipAccountIdChanged();
}
#endif

void
CallPipWindowManager::onCallStatusChanged(const QString& accountId, const QString& callId, int code)
{
    Q_UNUSED(code)
    if (callId != pipCallId_)
        return;

    // Read the actual call status from the model (code is a raw SIP reason
    // code, not a call::Status enum value).
    try {
        auto& accInfo = lrcInstance_->accountModel().getAccountInfo(accountId);
        if (!accInfo.callModel->hasCall(callId)) {
            // Call already removed from model — treat as ended.
            closePip();
            return;
        }
        const auto status = accInfo.callModel->getCall(callId).status;
        if (status == lrc::api::call::Status::ENDED || status == lrc::api::call::Status::TERMINATING
            || status == lrc::api::call::Status::TIMEOUT || status == lrc::api::call::Status::PEER_BUSY) {
            closePip();
        }
    } catch (const std::exception& e) {
        qWarning() << "CallPipWindowManager::onCallStatusChanged:" << e.what();
        closePip();
    }
}

void
CallPipWindowManager::onCallInfosChanged(const QString& accountId, const QString& callId)
{
    Q_UNUSED(accountId)
    if (callId == pipCallId_)
        updateMuteState();
}

void
CallPipWindowManager::updateMuteState()
{
    if (pipCallId_.isEmpty() || pipAccountId_.isEmpty())
        return;
    try {
        auto& accInfo = lrcInstance_->accountModel().getAccountInfo(pipAccountId_);
        if (!accInfo.callModel->hasCall(pipCallId_))
            return;
        const auto callInfoEx = accInfo.callModel->getCall(pipCallId_).getCallInfoEx();
        const bool audioMuted = callInfoEx[QStringLiteral("is_audio_muted")].toBool();
        const bool capturing = callInfoEx[QStringLiteral("is_capturing")].toBool();
        if (audioMuted != pipIsAudioMuted_) {
            pipIsAudioMuted_ = audioMuted;
            Q_EMIT pipIsAudioMutedChanged();
        }
        if (capturing != pipIsCapturing_) {
            pipIsCapturing_ = capturing;
            Q_EMIT pipIsCapturingChanged();
        }
    } catch (const std::exception& e) {
        qWarning() << "CallPipWindowManager::updateMuteState:" << e.what();
    }
}

void
CallPipWindowManager::closePip()
{
    disconnectCallModel();
    if (!window_.isNull()) {
        window_->close();
        // closePip() may be called before the closing signal fires, so clear state now.
        pipConvId_.clear();
        pipAccountId_.clear();
        pipCallId_.clear();
        pipIsAudioMuted_ = false;
        pipIsCapturing_ = false;
        pipPeerVideoMuted_ = true;
        pipPeerUri_.clear();
        pipActiveSpeakerUri_.clear();
        pipActiveSpeakerSinkId_.clear();
        pipIsConference_ = false;
        pipIsEmptyConference_ = false;
        window_->deleteLater();
        window_.clear();
        Q_EMIT isPipActiveChanged();
        Q_EMIT pipConvIdChanged();
        Q_EMIT pipCallIdChanged();
        Q_EMIT pipAccountIdChanged();
        Q_EMIT pipPreviewIdChanged();
        Q_EMIT pipIsAudioMutedChanged();
        Q_EMIT pipIsCapturingChanged();
        Q_EMIT pipPeerVideoMutedChanged();
        Q_EMIT pipPeerUriChanged();
        Q_EMIT pipActiveSpeakerUriChanged();
        Q_EMIT pipActiveSpeakerSinkIdChanged();
        Q_EMIT pipIsConferenceChanged();
        Q_EMIT pipIsEmptyConferenceChanged();
    } else if (!pipConvId_.isEmpty()) {
        // Window was already gone; just clear the state.
        pipConvId_.clear();
        pipAccountId_.clear();
        pipCallId_.clear();
        pipIsAudioMuted_ = false;
        pipIsCapturing_ = false;
        pipPeerVideoMuted_ = true;
        pipPeerUri_.clear();
        pipActiveSpeakerUri_.clear();
        pipActiveSpeakerSinkId_.clear();
        pipIsEmptyConference_ = false;
        pipIsConference_ = false;
#ifdef BUILD_TESTING
        testPipActive_ = false;
#endif
        Q_EMIT isPipActiveChanged();
        Q_EMIT pipConvIdChanged();
        Q_EMIT pipCallIdChanged();
        Q_EMIT pipAccountIdChanged();
        Q_EMIT pipPreviewIdChanged();
        Q_EMIT pipIsAudioMutedChanged();
        Q_EMIT pipIsCapturingChanged();
        Q_EMIT pipPeerVideoMutedChanged();
        Q_EMIT pipPeerUriChanged();
        Q_EMIT pipActiveSpeakerUriChanged();
        Q_EMIT pipActiveSpeakerSinkIdChanged();
        Q_EMIT pipIsConferenceChanged();
        Q_EMIT pipIsEmptyConferenceChanged();
    }
}

void
CallPipWindowManager::connectCallModel(const QString& accountId)
{
    disconnectCallModel();
    try {
        auto& accInfo = lrcInstance_->accountModel().getAccountInfo(accountId);
        callModelConnection_ = connect(accInfo.callModel.get(),
                                       &lrc::api::CallModel::callStatusChanged,
                                       this,
                                       &CallPipWindowManager::onCallStatusChanged);
        callInfosConnection_ = connect(accInfo.callModel.get(),
                                       &lrc::api::CallModel::callInfosChanged,
                                       this,
                                       &CallPipWindowManager::onCallInfosChanged);
        participantsConnection_ = connect(accInfo.callModel.get(),
                                          &lrc::api::CallModel::participantUpdated,
                                          this,
                                          &CallPipWindowManager::onParticipantUpdated);
        conferenceInfosUpdatedConnection_ = connect(accInfo.callModel.get(),
                                                    &lrc::api::CallModel::participantsChanged,
                                                    this,
                                                    &CallPipWindowManager::onConferenceInfosUpdated);
        updateMuteState();
        updatePeerVideoState();
    } catch (const std::exception& e) {
        qWarning() << "CallPipWindowManager: failed to connect callModel:" << e.what();
    }
}

void
CallPipWindowManager::onParticipantUpdated(const QString& callId)
{
    if (callId == pipCallId_)
        updatePeerVideoState();
}

void
CallPipWindowManager::onConferenceInfosUpdated(const QString& confId)
{
    if (confId == pipCallId_)
        updateConferenceVideoState();
}
void
CallPipWindowManager::updatePeerVideoState()
{
    if (pipCallId_.isEmpty() || pipAccountId_.isEmpty())
        return;
    try {
        auto& accInfo = lrcInstance_->accountModel().getAccountInfo(pipAccountId_);
        if (!accInfo.callModel->hasCall(pipCallId_))
            return;
        const auto& participants = accInfo.callModel->getParticipantsInfos(pipCallId_);
        for (const auto& p : participants.getParticipants()) {
            if (p.islocal)
                continue;
            if (!p.uri.isEmpty() && p.uri != pipPeerUri_) {
                pipPeerUri_ = p.uri;
                Q_EMIT pipPeerUriChanged();
            }
            if (p.videoMuted != pipPeerVideoMuted_) {
                pipPeerVideoMuted_ = p.videoMuted;
                Q_EMIT pipPeerVideoMutedChanged();
            }
            return;
        }
    } catch (const std::exception& e) {
        qWarning() << "CallPipWindowManager::updatePeerVideoState:" << e.what();
    }
}

void
CallPipWindowManager::updateConferenceVideoState()
{
    const auto& accInfo = lrcInstance_->getAccountInfo(pipAccountId_);
    const auto& conferenceParticipants = accInfo.callModel->getParticipantsInfos(pipCallId_);
    const QList<ParticipantInfos>& conferenceParticipantInfos = conferenceParticipants.getParticipants();

    if (conferenceParticipantInfos.isEmpty()) {
        // If the number of participants in the conference is 0,
        // then it is not a conference but rather a 1-to-1 call
        return;
    }

    // To hold new values (if any)
    bool isEmptyConference {false};
    QString newSpeakerUri, newSinkId;

    /* Three cases of showing video in the PIP window for conferences:
     * 1. If we are the only participant, we mark it as empty
     * 2. If there are only two participants (including ourselves),
     *    we should only see the other participant (as we would in a one-to-one)
     * 3. If there are more than 3 participants (including ourselves) we should
     *    show the most recent person to have spoken.
     */
    if (conferenceParticipantInfos.size() == 1) {
        isEmptyConference = true;
    } else if (conferenceParticipantInfos.size() == 2) {
        for (const auto& p : conferenceParticipantInfos) {
            qWarning() << "Detected second participant";
            if (p.uri != accInfo.profileInfo.uri) {
                newSpeakerUri = p.uri;
                newSinkId = p.sinkId;
            }
        }
    } else {
        try {
            // We need to check if the current uri and sinkId still exist
            // (i.e. that they haven't left the conference)
            bool isDeadActiveSpeaker {true};

            // Iterate through the accounts that are actively part of the conference
            for (const auto& p : conferenceParticipantInfos) {
                // Check for a valid URI
                if (pipActiveSpeakerUri_ == p.uri) {
                    isDeadActiveSpeaker = false;
                }

                // Check for any new voice activity and that it's not coming from ourselves
                if (p.voiceActivity && p.uri != accInfo.profileInfo.uri) {
                    newSpeakerUri = p.uri;
                    newSinkId = p.sinkId;
                }
            }

            // If there is no new active speaker and the current active speaker has left,
            // we show the first non-local participant of the conference
            if (newSpeakerUri.isEmpty() && isDeadActiveSpeaker) {
                for (const auto& p : conferenceParticipantInfos) {
                    if (p.uri != accInfo.profileInfo.uri) {
                        newSpeakerUri = p.uri;
                        newSinkId = p.sinkId;
                        break;
                    }
                }
            }
        } catch (const std::exception& e) {
            qWarning() << "CallPipWindowManager::updateConferenceVideoState::" << e.what();
        }
    }

    // Assign new values and emit signals only if necessary

    // // If a one-to-one call has transitioned to a conference it should be made known
    if (!pipIsConference_) {
        pipIsConference_ = true;
        Q_EMIT pipIsConferenceChanged();
    }

    // We only want to show a different video/profile picture if the active speaker has changed.
    if (newSpeakerUri != pipActiveSpeakerUri_ && !newSpeakerUri.isEmpty()) {
        pipActiveSpeakerUri_ = newSpeakerUri;
        Q_EMIT pipActiveSpeakerUriChanged();
    }
    if (newSinkId != pipActiveSpeakerSinkId_ && !newSinkId.isEmpty()) {
        pipActiveSpeakerSinkId_ = newSinkId;
        Q_EMIT pipActiveSpeakerSinkIdChanged();
    }

    if (isEmptyConference != pipIsEmptyConference_) {
        pipIsEmptyConference_ = isEmptyConference;
        Q_EMIT pipIsEmptyConferenceChanged();
    }
}

void
CallPipWindowManager::disconnectCallModel()
{
    if (callModelConnection_)
        disconnect(callModelConnection_);
    if (callInfosConnection_)
        disconnect(callInfosConnection_);
    if (participantsConnection_)
        disconnect(participantsConnection_);
}
