/****************************************************************************
 *   Copyright (C) 2017-2025 Savoir-faire Linux Inc.                        *
 *                                                                          *
 *   This library is free software; you can redistribute it and/or          *
 *   modify it under the terms of the GNU Lesser General Public             *
 *   License as published by the Free Software Foundation; either           *
 *   version 2.1 of the License, or (at your option) any later version.     *
 *                                                                          *
 *   This library is distributed in the hope that it will be useful,        *
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of         *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU      *
 *   Lesser General Public License for more details.                        *
 *                                                                          *
 *   You should have received a copy of the GNU General Public License      *
 *   along with this program.  If not, see <http://www.gnu.org/licenses/>.  *
 ***************************************************************************/
#pragma once

// Qt
#include <QObject>

// std
#include <string>
#include <ctime>
#include <chrono>

#include "typedefs.h"
#include <media_const.h>

namespace lrc {

namespace api {

namespace call {
Q_NAMESPACE
Q_CLASSINFO("RegisterEnumClassesUnscoped", "false")

enum class Status {
    INVALID,
    INCOMING_RINGING,
    OUTGOING_RINGING,
    CONNECTING,
    SEARCHING,
    IN_PROGRESS,
    PAUSED,
    INACTIVE,
    ENDED,
    PEER_BUSY,
    TIMEOUT,
    TERMINATING,
    CONNECTED
};
Q_ENUM_NS(Status)

static inline QString
to_string(const call::Status& status)
{
    switch (status) {
    case call::Status::PAUSED:
        return QObject::tr("Hold");
    case call::Status::IN_PROGRESS:
        return QObject::tr("Talking");
    case call::Status::INVALID:
        return QObject::tr("ERROR");
    case call::Status::INCOMING_RINGING:
        return QObject::tr("Incoming");
    case call::Status::OUTGOING_RINGING:
        return QObject::tr("Calling");
    case call::Status::CONNECTING:
        return QObject::tr("Connecting");
    case call::Status::SEARCHING:
        return QObject::tr("Searching");
    case call::Status::INACTIVE:
        return QObject::tr("Inactive");
    case call::Status::ENDED:
        return QObject::tr("Finished");
    case call::Status::TIMEOUT:
        return QObject::tr("Timeout");
    case call::Status::PEER_BUSY:
        return QObject::tr("Peer busy");
    case call::Status::TERMINATING:
        return QObject::tr("Finished");
    case call::Status::CONNECTED:
        return QObject::tr("Communication established");
    default:
        return ""; // to remove a build warning, should not happen
    }
}

/**
 * Convert status from daemon into a Status
 * @warning status is a string from the daemon, not from to_string()
 * @param  status
 * @return
 */
static inline Status
to_status(const QString& status)
{
    if (status == "INCOMING")
        return Status::INCOMING_RINGING;
    else if (status == "CONNECTING")
        return Status::CONNECTING;
    else if (status == "RINGING")
        return Status::OUTGOING_RINGING;
    else if (status == "HUNGUP" || status == "FAILURE")
        return Status::TERMINATING;
    else if (status == "HOLD" || status == "ACTIVE_DETACHED")
        return Status::PAUSED;
    else if (status == "UNHOLD" || status == "CURRENT" || status == "ACTIVE_ATTACHED")
        return Status::IN_PROGRESS;
    else if (status == "PEER_BUSY")
        return Status::PEER_BUSY;
    else if (status == "BUSY")
        return Status::TIMEOUT;
    else if (status == "INACTIVE")
        return Status::INACTIVE;
    else if (status == "OVER")
        return Status::ENDED;
    return Status::INVALID;
}

enum class Type { INVALID, DIALOG, CONFERENCE };
Q_ENUM_NS(Type)

enum class Layout { GRID, ONE_WITH_SMALL, ONE };

struct Info
{
    QString id;
    std::chrono::steady_clock::time_point startTime;
    Status status = Status::INVALID;
    Type type = Type::INVALID;
    QString peerUri;
    bool isOutgoing;
    bool audioMuted = false; // this flag is used to check device audio status
    bool videoMuted = false; // this flag is used to check device video status
    bool isAudioOnly = false;
    Layout layout = Layout::GRID;
    VectorMapStringString mediaList = {};
    QStringList recordingPeers {};

    bool hasMediaWithType(const QString& type, const QString& mediaType) const
    {
        for (const auto& m : mediaList)
            if (m[libjami::Media::MediaAttributeKey::SOURCE].startsWith(type)
                && m[libjami::Media::MediaAttributeKey::MEDIA_TYPE] == mediaType)
                return true;
        return false;
    }

    // Extract some common meta data for this call including:
    // - the video preview ID
    // - audio/video muted status
    // - if the call is sharing (indicating that the preview is a screen share)
    QVariantMap getCallInfoEx() const
    {
        bool isAudioMuted = false;
        bool isVideoMuted = false;
        QString previewId;
        QVariantMap callInfo;
        using namespace libjami::Media;
        if (status == lrc::api::call::Status::ENDED) {
            return {};
        }
        for (const auto& media : mediaList) {
            if (media[MediaAttributeKey::MEDIA_TYPE] == Details::MEDIA_TYPE_VIDEO) {
                if (media[MediaAttributeKey::SOURCE].startsWith(VideoProtocolPrefix::DISPLAY)
                    || media[MediaAttributeKey::SOURCE].startsWith(VideoProtocolPrefix::FILE)) {
                    if (media[MediaAttributeKey::MUTED] == TRUE_STR) {
                        callInfo["is_sharing"] = false;
                    } else {
                        callInfo["is_sharing"] = true;
                        previewId = media[MediaAttributeKey::SOURCE];
                    }
                }
                if (media[MediaAttributeKey::ENABLED] == TRUE_STR
                    && media[MediaAttributeKey::MUTED] == FALSE_STR && previewId.isEmpty()) {
                    previewId = media[libjami::Media::MediaAttributeKey::SOURCE];
                }
                if (media[libjami::Media::MediaAttributeKey::SOURCE].startsWith(
                        libjami::Media::VideoProtocolPrefix::CAMERA)) {
                    isVideoMuted |= media[MediaAttributeKey::MUTED] == TRUE_STR;
                    callInfo["is_capturing"] = media[MediaAttributeKey::MUTED] == FALSE_STR;
                }
            } else if (media[MediaAttributeKey::MEDIA_TYPE] == Details::MEDIA_TYPE_AUDIO) {
                if (media[MediaAttributeKey::LABEL] == "audio_0") {
                    isAudioMuted |= media[libjami::Media::MediaAttributeKey::MUTED] == TRUE_STR;
                }
            }
        }
        callInfo["preview_id"] = previewId;
        callInfo["is_audio_muted"] = isAudioMuted;
        callInfo["is_video_muted"] = isVideoMuted;
        return callInfo;
    }
};

static inline bool
canSendSIPMessage(const Info& call)
{
    switch (call.status) {
    case call::Status::PAUSED:
    case call::Status::IN_PROGRESS:
    case call::Status::INCOMING_RINGING:
    case call::Status::OUTGOING_RINGING:
    case call::Status::CONNECTED:
        return true;
    case call::Status::INVALID:
    case call::Status::CONNECTING:
    case call::Status::SEARCHING:
    case call::Status::INACTIVE:
    case call::Status::ENDED:
    case call::Status::PEER_BUSY:
    case call::Status::TIMEOUT:
    case call::Status::TERMINATING:
    default:
        return false;
    }
}

static inline bool
isTerminating(const Status& status)
{
    switch (status) {
    case call::Status::INVALID:
    case call::Status::INACTIVE:
    case call::Status::ENDED:
    case call::Status::PEER_BUSY:
    case call::Status::TIMEOUT:
    case call::Status::TERMINATING:
        return true;
    case call::Status::PAUSED:
    case call::Status::IN_PROGRESS:
    case call::Status::INCOMING_RINGING:
    case call::Status::OUTGOING_RINGING:
    case call::Status::CONNECTED:
    case call::Status::CONNECTING:
    case call::Status::SEARCHING:
    default:
        return false;
    }
}

} // namespace call
} // namespace api
} // namespace lrc
