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

#pragma once

// std
#include <string>
#include <ctime>
#include <chrono>
#include <mutex>

// Qt
#include <QObject>
#include <QJsonObject>

#include "typedefs.h"
#include "call.h"

namespace lrc {

namespace api {
class CallModel;

namespace ParticipantsInfosStrings {
const QString URI = "uri";
const QString DEVICE = "device";
const QString ACTIVE = "active";
const QString AVATAR = "avatar";
const QString X = "x";
const QString Y = "y";
const QString W = "w";
const QString H = "h";
const QString WIDTH = "width";
const QString HEIGHT = "height";
const QString VIDEOMUTED = "videoMuted";
const QString AUDIOLOCALMUTED = "audioLocalMuted";
const QString AUDIOMODERATORMUTED = "audioModeratorMuted";
const QString ISMODERATOR = "isModerator";
const QString HANDRAISED = "handRaised";
const QString VOICEACTIVITY = "voiceActivity";
const QString ISRECORDING = "recording";
const QString STREAMID = "sinkId"; // TODO update
const QString BESTNAME = "bestName";
const QString ISLOCAL = "isLocal";
const QString ISCONTACT = "isContact";
const QString CALLID = "callId";
} // namespace ParticipantsInfosStrings

struct ParticipantInfos
{
    ParticipantInfos() {}

    ParticipantInfos(const MapStringString& infos, const QString& callId, const QString& peerId)
    {
        uri = infos[ParticipantsInfosStrings::URI];
        if (uri.lastIndexOf("@") > 0)
            uri.truncate(uri.lastIndexOf("@"));
        if (uri.isEmpty())
            uri = peerId;
        device = infos[ParticipantsInfosStrings::DEVICE];
        active = infos[ParticipantsInfosStrings::ACTIVE] == "true";
        x = infos[ParticipantsInfosStrings::X].toInt();
        y = infos[ParticipantsInfosStrings::Y].toInt();
        width = infos[ParticipantsInfosStrings::W].toInt();
        height = infos[ParticipantsInfosStrings::H].toInt();
        videoMuted = infos[ParticipantsInfosStrings::VIDEOMUTED] == "true";
        audioLocalMuted = infos[ParticipantsInfosStrings::AUDIOLOCALMUTED] == "true";
        audioModeratorMuted = infos[ParticipantsInfosStrings::AUDIOMODERATORMUTED] == "true";
        isModerator = infos[ParticipantsInfosStrings::ISMODERATOR] == "true";
        handRaised = infos[ParticipantsInfosStrings::HANDRAISED] == "true";
        voiceActivity = infos[ParticipantsInfosStrings::VOICEACTIVITY] == "true";
        isRecording = infos[ParticipantsInfosStrings::ISRECORDING] == "true";

        if (infos[ParticipantsInfosStrings::STREAMID].isEmpty())
            sinkId = callId + uri + device;
        else
            sinkId = infos[ParticipantsInfosStrings::STREAMID];

        bestName = "";
    }

    QString uri;
    QString device;
    QString sinkId;
    QString bestName;
    QString avatar;
    bool active {false};
    int x = 0;
    int y = 0;
    int width = 0;
    int height = 0;
    bool audioLocalMuted {false};
    bool audioModeratorMuted {false};
    bool videoMuted {false};
    bool isModerator {false};
    bool islocal {false};
    bool isContact {false};
    bool handRaised {false};
    bool voiceActivity {false};
    bool isRecording {false};

    bool operator==(const ParticipantInfos& other) const
    {
        return uri == other.uri && sinkId == other.sinkId && active == other.active
               && audioLocalMuted == other.audioLocalMuted && audioModeratorMuted == other.audioModeratorMuted
               && avatar == other.avatar && bestName == other.bestName && isContact == other.isContact
               && islocal == other.islocal && videoMuted == other.videoMuted && isModerator == other.isModerator
               && voiceActivity == other.voiceActivity && handRaised == other.handRaised
               && isRecording == other.isRecording && device == other.device;
    }
};

/**
 * CallParticipants
 * @brief Client-side model for STREAM-level participant information in conferences.
 *
 * This class manages video/audio stream data received from the daemon's OnConferenceInfosUpdated
 * signal. Data is keyed by streamId (sinkId), not participant URI because a single participant
 * may have multiple streams (e.g., camera + screen share).
 *
 * The data tracked here is primarily for video layout rendering. The class was added in the
 * following patch: https://review.jami.net/c/jami-libclient/+/18614
 *
 * IMPORTANT: Stream count can fluctuate briefly during audio-only ↔ video transitions
 * due to timing in the daemon's VideoMixer. To be precise, when an audio-only participant
 * adds a video source, there may be a short period where the participant is neither considered
 * audio-only nor video-enabled while waiting for the first frame of the video Rtp session.
 * This results in the participant's temporary disappearance from this model.
 * For a stable participant count or list of participant URIs (independent of stream state),
 * use CallManager::getConferenceParticipantsUri() instead.
 * Whether the participant data in this class should be stable or not is TBD.
 *
 * @see CallManager::getConferenceParticipantsUri() for stable participant-level data
 * @see VideoMixer::process for the daemon-side source of this data
 */
class LIB_EXPORT CallParticipants : public QObject
{
    Q_OBJECT

public:
    CallParticipants(const VectorMapStringString& infos, const QString& callId, const CallModel& linked);
    ~CallParticipants() {}

    /**
     * @return The list of participants that should be displayed by the client
     */
    QList<ParticipantInfos> getParticipants() const;

    /**
     * Update the list of candidates and participants based on the infos sent by the daemon
     */
    void update(const VectorMapStringString& infos);

    /**
     * Update conference layout value
     */
    void verifyLayout();

    /**
     * @param uri participant
     * @return True if participant is a moderator
     */
    bool checkModerator(const QString& uri) const;

    /**
     * @return the conference layout
     */
    call::Layout getLayout() const
    {
        return hostLayout_;
    }

    /**
     * @param index participant index
     * @return information of the participant in index
     */
    QJsonObject toQJsonObject(uint index) const;

private:
    /**
     * Build the streamIdToCandidateMap_ and validStreamIds_ attributes from infos sent by the daemon
     * The attributes are built only with candidates that have a URI
     */
    void buildCandidatesAndStreams(const VectorMapStringString& infos);

    void removeParticipant(int index);

    void addParticipant(const ParticipantInfos& participant);

    // Contains all potential participants from the raw daemon data that have a URI
    QMap<QString, ParticipantInfos> streamIdToCandidateMap_;

    // Contains the actual participants being tracked and displayed in the client
    QMap<QString, ParticipantInfos> streamIdToParticipantMap_;

    // Protects changes into the paticipants_ variable
    mutable std::mutex participantsMtx_ {};

    QList<QString> validStreamIds_;
    int idx_ = 0;

    const CallModel& linked_;

    // Protects calls to the update function
    std::mutex updateMtx_ {};

    const QString callId_;
    call::Layout hostLayout_ = call::Layout::GRID;
};
} // end namespace api
} // end namespace lrc
Q_DECLARE_METATYPE(lrc::api::CallParticipants*)
