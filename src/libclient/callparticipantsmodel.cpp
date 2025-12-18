/*!
 *   Copyright (C) 2022-2026 Savoir-faire Linux Inc.
 *
 *   This library is free software; you can redistribute it and/or
 *   modify it under the terms of the GNU Lesser General Public
 *   License as published by the Free Software Foundation; either
 *   version 2.1 of the License, or (at your option) any later version.
 *
 *   This library is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 *   Lesser General Public License for more details.
 *
 *   You should have received a copy of the GNU General Public License
 *   along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#include "api/callparticipantsmodel.h"

#include "api/account.h"
#include "api/contactmodel.h"
#include "api/contact.h"
#include "api/callmodel.h"
#include "api/accountmodel.h"

namespace lrc {

namespace api {

CallParticipants::CallParticipants(const VectorMapStringString& infos, const QString& callId, const CallModel& linked)
    : linked_(linked)
    , callId_(callId)
{
    update(infos);
}

QList<ParticipantInfos>
CallParticipants::getParticipants() const
{
    std::lock_guard<std::mutex> lk(participantsMtx_);
    return streamIdToParticipantMap_.values();
}

void
CallParticipants::update(const VectorMapStringString& infos)
{
    std::lock_guard<std::mutex> lk(updateMtx_);

    buildCandidatesAndStreams(infos);

    idx_ = 0;

    QList<QString> streamIds {};
    {
        std::lock_guard<std::mutex> lk(participantsMtx_);
        streamIds = streamIdToParticipantMap_.keys();
    }

    for (const auto& streamId : streamIds) {
        auto streamIndex = validStreamIds_.indexOf(streamId);
        if (streamIndex == -1 or streamIndex >= validStreamIds_.size())
            removeParticipant(idx_);
        else
            idx_++;
    }

    idx_ = 0;
    for (const auto& validStreamId : validStreamIds_) {
        addParticipant(streamIdToCandidateMap_[validStreamId]);
        idx_++;
    }

    verifyLayout();
}

void
CallParticipants::verifyLayout()
{
    std::lock_guard<std::mutex> lk(participantsMtx_);
    auto it = std::find_if(streamIdToParticipantMap_.begin(),
                           streamIdToParticipantMap_.end(),
                           [](const lrc::api::ParticipantInfos& participant) -> bool { return participant.active; });
    auto newLayout = call::Layout::GRID;
    if (it != streamIdToParticipantMap_.end())
        if (streamIdToParticipantMap_.size() == 1)
            newLayout = call::Layout::ONE;
        else
            newLayout = call::Layout::ONE_WITH_SMALL;
    else
        newLayout = call::Layout::GRID;
    if (newLayout != hostLayout_)
        hostLayout_ = newLayout;
}

void
CallParticipants::removeParticipant(int index)
{
    {
        std::lock_guard<std::mutex> lk(participantsMtx_);
        auto it = std::next(streamIdToParticipantMap_.begin(), index);
        streamIdToParticipantMap_.erase(it);
    }
    Q_EMIT linked_.participantRemoved(callId_, idx_);
}

void
CallParticipants::addParticipant(const ParticipantInfos& participant)
{
    bool added {false};
    {
        std::lock_guard<std::mutex> lk(participantsMtx_);
        auto it = streamIdToParticipantMap_.find(participant.sinkId);
        if (it == streamIdToParticipantMap_.end()) {
            streamIdToParticipantMap_.insert(std::next(streamIdToParticipantMap_.begin(), idx_),
                                             participant.sinkId,
                                             participant);
            added = true;
        } else {
            if (participant == (*it))
                return;
            (*it) = participant;
        }
    }
    if (added)
        Q_EMIT linked_.participantAdded(callId_, idx_);
    else
        Q_EMIT linked_.participantUpdated(callId_, idx_);
}

void
CallParticipants::buildCandidatesAndStreams(const VectorMapStringString& infos)
{
    std::lock_guard<std::mutex> lk(participantsMtx_);
    validStreamIds_.clear();
    streamIdToCandidateMap_.clear();
    for (const auto& candidate : infos) {
        if (!candidate.contains(ParticipantsInfosStrings::URI))
            continue;
        auto peerId = candidate[ParticipantsInfosStrings::URI];
        peerId.truncate(peerId.lastIndexOf("@"));
        if (peerId.isEmpty()) {
            for (const auto& accId : linked_.owner.accountModel->getAccountList()) {
                try {
                    auto& accountInfo = linked_.owner.accountModel->getAccountInfo(accId);
                    if (accountInfo.callModel->hasCall(callId_)) {
                        peerId = accountInfo.profileInfo.uri;
                    }
                } catch (...) {
                }
            }
        }
        if (candidate[ParticipantsInfosStrings::W].toInt() != 0 && candidate[ParticipantsInfosStrings::H].toInt() != 0) {
            auto streamId = candidate[ParticipantsInfosStrings::STREAMID];
            validStreamIds_.append(streamId);
            streamIdToCandidateMap_.insert(streamId, ParticipantInfos(candidate, callId_, peerId));
        }
    }

    validStreamIds_.sort();
}

bool
CallParticipants::checkModerator(const QString& uri) const
{
    std::lock_guard<std::mutex> lk(participantsMtx_);
    return std::find_if(streamIdToParticipantMap_.cbegin(),
                        streamIdToParticipantMap_.cend(),
                        [&](auto participant) { return participant.uri == uri && participant.isModerator; })
           != streamIdToParticipantMap_.cend();
}

QJsonObject
CallParticipants::toQJsonObject(uint index) const
{
    std::lock_guard<std::mutex> lk(participantsMtx_);
    if (index >= streamIdToParticipantMap_.size())
        return {};

    QJsonObject ret;
    const auto& participant = std::next(streamIdToParticipantMap_.begin(), index);

    ret[ParticipantsInfosStrings::URI] = participant->uri;
    ret[ParticipantsInfosStrings::DEVICE] = participant->device;
    ret[ParticipantsInfosStrings::STREAMID] = participant->sinkId;
    ret[ParticipantsInfosStrings::BESTNAME] = participant->bestName;
    ret[ParticipantsInfosStrings::AVATAR] = participant->avatar;
    ret[ParticipantsInfosStrings::ACTIVE] = participant->active;
    ret[ParticipantsInfosStrings::X] = participant->x;
    ret[ParticipantsInfosStrings::Y] = participant->y;
    ret[ParticipantsInfosStrings::WIDTH] = participant->width;
    ret[ParticipantsInfosStrings::HEIGHT] = participant->height;
    ret[ParticipantsInfosStrings::AUDIOLOCALMUTED] = participant->audioLocalMuted;
    ret[ParticipantsInfosStrings::AUDIOMODERATORMUTED] = participant->audioModeratorMuted;
    ret[ParticipantsInfosStrings::VIDEOMUTED] = participant->videoMuted;
    ret[ParticipantsInfosStrings::ISMODERATOR] = participant->isModerator;
    ret[ParticipantsInfosStrings::ISLOCAL] = participant->islocal;
    ret[ParticipantsInfosStrings::ISCONTACT] = participant->isContact;
    ret[ParticipantsInfosStrings::HANDRAISED] = participant->handRaised;
    ret[ParticipantsInfosStrings::VOICEACTIVITY] = participant->voiceActivity;
    ret[ParticipantsInfosStrings::ISRECORDING] = participant->isRecording;
    ret[ParticipantsInfosStrings::CALLID] = callId_;

    return ret;
}
} // end namespace api
} // end namespace lrc
