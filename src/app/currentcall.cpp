/*
 * Copyright (C) 2022-2024 Savoir-faire Linux Inc.
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

#include "currentcall.h"
#include "qmlregister.h"

#include <api/callparticipantsmodel.h>
#include <api/devicemodel.h>

CurrentCall::CurrentCall(LRCInstance* lrcInstance, QObject* parent)
    : QObject(parent)
    , lrcInstance_(lrcInstance)
{
    participantsModel_.reset(new CallParticipantsModel(lrcInstance_, this));
    QML_REGISTERSINGLETONTYPE_POBJECT(NS_MODELS, participantsModel_.get(), "CallParticipantsModel");

    connect(lrcInstance_,
            &LRCInstance::currentAccountIdChanged,
            this,
            &CurrentCall::onCurrentAccountIdChanged);

    connect(lrcInstance_,
            &LRCInstance::selectedConvUidChanged,
            this,
            &CurrentCall::onCurrentConvIdChanged);

    connect(&lrcInstance_->behaviorController(),
            &BehaviorController::showIncomingCallView,
            this,
            &CurrentCall::onShowIncomingCallView);

    try {
        auto& accInfo = lrcInstance_->getCurrentAccountInfo();
        set_isSIP(accInfo.profileInfo.type == profile::Type::SIP);
    } catch (const std::exception& e) {
        qWarning() << "Can't update current call type" << e.what();
    }

    connectModel();
}

void
CurrentCall::updateId(QString callId)
{
    auto convId = lrcInstance_->get_selectedConvUid();
    auto optConv = lrcInstance_->getCurrentConversationModel()->getConversationForUid(convId);
    if (!optConv.has_value()) {
        return;
    }

    // If the optional parameter callId is empty, then we've just
    // changed conversation selection and need to check the current
    // conv's callId for an existing call.
    // Otherwise, return if callId doesn't belong to this conversation.
    if (callId.isEmpty()) {
        callId = optConv->get().getCallId();
    } else if (optConv->get().getCallId() != callId) {
        return;
    }

    auto& accInfo = lrcInstance_->getCurrentAccountInfo();
    if (accInfo.profileInfo.type != lrc::api::profile::Type::SIP) {
        // Only setCurrentCall if call is actually answered
        try {
            auto callInfo = accInfo.callModel->getCall(callId);
            if (callInfo.status == call::Status::IN_PROGRESS
                || callInfo.status == call::Status::PAUSED)
                accInfo.callModel->setCurrentCall(callId);
        } catch (...) {
        }
    }
    // Set the current id_ if there is a call.
    auto hasCall = accInfo.callModel->hasCall(callId);
    set_id((hasCall ? callId : QString()));

    if (hasCall) {
        try {
            auto callInfo = accInfo.callModel->getCall(callId);
            participantsModel_->setParticipants(id_, getConferencesInfos());
            participantsModel_->setConferenceLayout(static_cast<int>(callInfo.layout), id_);
        } catch (...) {
        }
    }
}

void
CurrentCall::updateCallStatus()
{
    call::Status status {};
    auto callModel = lrcInstance_->getCurrentCallModel();
    if (callModel->hasCall(id_)) {
        auto callInfo = callModel->getCall(id_);
        status = callInfo.status;
    }

    set_status(status);
    set_isActive(status_ == call::Status::CONNECTED || status_ == call::Status::IN_PROGRESS
                 || status_ == call::Status::PAUSED);
    set_isPaused(status_ == call::Status::PAUSED);
}

void
CurrentCall::updateParticipants()
{
    auto callModel = lrcInstance_->getCurrentCallModel();
    QStringList uris;
    auto& participantsModel = callModel->getParticipantsInfos(id_);
    for (int index = 0; index < participantsModel.getParticipants().size(); index++) {
        auto participantInfo = participantsModel.toQJsonObject(index);
        uris.append(participantInfo[ParticipantsInfosStrings::URI].toString());
    }
    set_uris(uris);
    set_isConference(uris.size());
}

void
CurrentCall::onParticipantAdded(const QString& callId, int index)
{
    if (callId != id_)
        return;
    auto infos = getConferencesInfos();
    if (index < infos.size())
        participantsModel_->addParticipant(index, infos[index]);
}

void
CurrentCall::onParticipantRemoved(const QString& callId, int index)
{
    if (callId != id_)
        return;
    participantsModel_->removeParticipant(index);
}

void
CurrentCall::onParticipantUpdated(const QString& callId, int index)
{
    if (callId != id_)
        return;
    auto infos = getConferencesInfos();
    if (index < infos.size())
        participantsModel_->updateParticipant(index, infos[index]);
}

void
CurrentCall::fillParticipantData(QJsonObject& participant) const
{
    // TODO: getCurrentDeviceId should be part of CurrentAccount, and Current<thing>
    //       should be read accessible through LRCInstance ??
    auto getCurrentDeviceId = [](const account::Info& accInfo) -> QString {
        const auto& deviceList = accInfo.deviceModel->getAllDevices();
        auto devIt = std::find_if(std::cbegin(deviceList),
                                  std::cend(deviceList),
                                  [](const Device& dev) { return dev.isCurrent; });
        return devIt != deviceList.cend() ? devIt->id : QString();
    };

    auto& accInfo = lrcInstance_->getCurrentAccountInfo();
    using namespace lrc::api::ParticipantsInfosStrings;

    // If both the URI and the device Id match, we set the "is local" flag
    // used to filter out the participant.
    // TODO:
    //  - This filter should always be applied, and any local streams should render
    //    using local sinks. Local non-preview participants should have proxy participant
    //    items replaced into this model using their local sink Ids.
    //  - The app setting should remain and be used to control whether or not the preview
    //    sink partipcant is rendered.
    auto uri = participant[URI].toString();
    participant[ISLOCAL] = false;
    if (uri == accInfo.profileInfo.uri && participant[DEVICE] == getCurrentDeviceId(accInfo)) {
        participant[BESTNAME] = tr("Me");
        participant[ISLOCAL] = true;
    } else {
        try {
            participant[BESTNAME] = accInfo.contactModel->bestNameForContact(uri);
        } catch (...) {
        }
    }
}

QVariantList
CurrentCall::getConferencesInfos() const
{
    QVariantList map;
    try {
        auto callModel = lrcInstance_->getCurrentCallModel();
        auto& participantsModel = callModel->getParticipantsInfos(id_);
        for (int index = 0; index < participantsModel.getParticipants().size(); index++) {
            auto participant = participantsModel.toQJsonObject(index);
            fillParticipantData(participant);
            map.push_back(QVariant(participant));
        }
    } catch (...) {
    }
    return map;
}

void
CurrentCall::updateCallInfo()
{
    auto callModel = lrcInstance_->getCurrentCallModel();
    if (!callModel->hasCall(id_)) {
        return;
    }

    auto callInfo = callModel->getCall(id_);

    set_isOutgoing(callInfo.isOutgoing);
    set_isGrid(callInfo.layout == call::Layout::GRID);
    set_isAudioOnly(callInfo.isAudioOnly);

    bool isAudioMuted {};
    bool isVideoMuted {};
    bool isSharing {};
    QString sharingSource {};
    bool isCapturing {};
    QString previewId {};
    using namespace libjami::Media;
    if (callInfo.status != lrc::api::call::Status::ENDED) {
        for (const auto& media : callInfo.mediaList) {
            if (media[MediaAttributeKey::MEDIA_TYPE] == Details::MEDIA_TYPE_VIDEO) {
                if (media[MediaAttributeKey::SOURCE].startsWith(VideoProtocolPrefix::DISPLAY)
                    || media[MediaAttributeKey::SOURCE].startsWith(VideoProtocolPrefix::FILE)) {
                    isSharing = true;
                    sharingSource = media[MediaAttributeKey::SOURCE];
                }
                if (media[MediaAttributeKey::ENABLED] == TRUE_STR
                    && media[MediaAttributeKey::MUTED] == FALSE_STR && previewId.isEmpty()) {
                    previewId = media[libjami::Media::MediaAttributeKey::SOURCE];
                }
                if (media[libjami::Media::MediaAttributeKey::SOURCE].startsWith(
                        libjami::Media::VideoProtocolPrefix::CAMERA)) {
                    isVideoMuted |= media[MediaAttributeKey::MUTED] == TRUE_STR;
                    isCapturing = media[MediaAttributeKey::MUTED] == FALSE_STR;
                }
            } else if (media[MediaAttributeKey::MEDIA_TYPE] == Details::MEDIA_TYPE_AUDIO) {
                if (media[MediaAttributeKey::LABEL] == "audio_0") {
                    isAudioMuted |= media[libjami::Media::MediaAttributeKey::MUTED] == TRUE_STR;
                }
            }
        }
    }
    set_previewId(previewId);
    set_isAudioMuted(isAudioMuted);
    set_isVideoMuted(isVideoMuted);
    set_isSharing(isSharing);
    set_sharingSource(sharingSource);
    set_isCapturing(isCapturing);
    set_isHandRaised(callModel->isHandRaised(id_));
    set_isModerator(callModel->isModerator(id_));

    QStringList recorders {};
    if (callModel->hasCall(id_)) {
        auto callInfo = callModel->getCall(id_);
        participantsModel_->setConferenceLayout(static_cast<int>(callInfo.layout), id_);
        recorders = callInfo.recordingPeers;
    }
    updateRecordingState(callModel->isRecording(id_));
    updateRemoteRecorders(recorders);
}

void
CurrentCall::updateRemoteRecorders(const QStringList& recorders)
{
    auto& accInfo = lrcInstance_->getCurrentAccountInfo();
    remoteRecorderNameList_.clear();
    Q_FOREACH (const auto& uri, recorders) {
        auto bestName = accInfo.contactModel->bestNameForContact(uri);
        if (!bestName.isEmpty()) {
            remoteRecorderNameList_.append(bestName);
        }
    }

    // Convenience flag.
    set_isRecordingRemotely(!remoteRecorderNameList_.isEmpty());

    Q_EMIT remoteRecorderNameListChanged();
}

void
CurrentCall::updateRecordingState(bool state)
{
    set_isRecordingLocally(state);
}

void
CurrentCall::connectModel()
{
    auto callModel = lrcInstance_->getCurrentCallModel();
    if (callModel == nullptr) {
        return;
    }

    connect(callModel,
            &CallModel::callStatusChanged,
            this,
            &CurrentCall::onCallStatusChanged,
            Qt::UniqueConnection);
    connect(callModel,
            &CallModel::callInfosChanged,
            this,
            &CurrentCall::onCallInfosChanged,
            Qt::UniqueConnection);
    connect(callModel,
            &CallModel::currentCallChanged,
            this,
            &CurrentCall::onCurrentCallChanged,
            Qt::UniqueConnection);
    connect(callModel,
            &CallModel::participantsChanged,
            this,
            &CurrentCall::onParticipantsChanged,
            Qt::UniqueConnection);
    connect(callModel,
            &CallModel::remoteRecordersChanged,
            this,
            &CurrentCall::onRemoteRecordersChanged,
            Qt::UniqueConnection);
    connect(callModel,
            &CallModel::recordingStateChanged,
            this,
            &CurrentCall::onRecordingStateChanged,
            Qt::UniqueConnection);
    connect(callModel,
            &CallModel::participantAdded,
            this,
            &CurrentCall::onParticipantAdded,
            Qt::UniqueConnection);
    connect(callModel,
            &CallModel::participantRemoved,
            this,
            &CurrentCall::onParticipantRemoved,
            Qt::UniqueConnection);
    connect(callModel,
            &CallModel::participantUpdated,
            this,
            &CurrentCall::onParticipantUpdated,
            Qt::UniqueConnection);
}

void
CurrentCall::onCurrentConvIdChanged()
{
    updateId();
    updateCallStatus();
    updateParticipants();
    updateCallInfo();

    auto callModel = lrcInstance_->getCurrentCallModel();
    QStringList recorders {};
    if (callModel->hasCall(id_)) {
        auto callInfo = callModel->getCall(id_);
        recorders = callInfo.recordingPeers;
    }
    updateRecordingState(callModel->isRecording(id_));
    updateRemoteRecorders(recorders);
}

void
CurrentCall::onCurrentAccountIdChanged()
{
    try {
        auto& accInfo = lrcInstance_->getCurrentAccountInfo();
        set_isSIP(accInfo.profileInfo.type == profile::Type::SIP);
    } catch (const std::exception& e) {
        qWarning() << "Can't update current call type" << e.what();
    }

    connectModel();
}

void
CurrentCall::onCallStatusChanged(const QString& callId, int code)
{
    Q_UNUSED(code)

    if (id_ != callId) {
        return;
    }

    updateCallStatus();
}

void
CurrentCall::onCallInfosChanged(const QString& accountId, const QString& callId)
{
    if (id_ != callId) {
        return;
    }

    updateCallInfo();
}

void
CurrentCall::onCurrentCallChanged(const QString& callId)
{
    // If this status change's callId is not the current, it's possible that
    // the current value of id_ is stale, and needs to be updated after checking
    // the current conversation's getCallId(). Other slots need not do this, as the
    // id_ is updated in CurrentCall::updateId.
    if (id_ == callId) {
        return;
    }

    updateId(callId);
    updateCallStatus();
    updateParticipants();
    updateCallInfo();
}

void
CurrentCall::onParticipantsChanged(const QString& callId)
{
    if (id_ != callId) {
        return;
    }

    updateParticipants();
}

void
CurrentCall::onRemoteRecordersChanged(const QString& callId, const QStringList& recorders)
{
    if (id_ != callId) {
        return;
    }

    updateRemoteRecorders(recorders);
}

void
CurrentCall::onRecordingStateChanged(const QString& callId, bool state)
{
    if (id_ != callId) {
        return;
    }

    updateRecordingState(state);
}

void
CurrentCall::onShowIncomingCallView(const QString& accountId, const QString& convUid)
{
    if (accountId != lrcInstance_->get_currentAccountId()
        || convUid != lrcInstance_->get_selectedConvUid()) {
        return;
    }

    // Update the id in case the current conversation now has a call
    // that matches the current id.
    updateId();
    updateCallStatus();
    updateCallInfo();
}
