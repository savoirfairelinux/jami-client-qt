/****************************************************************************
 *    Copyright (C) 2017-2024 Savoir-faire Linux Inc.                       *
 *   Author : Nicolas Jäger <nicolas.jager@savoirfairelinux.com>            *
 *   Author : Sébastien Blin <sebastien.blin@savoirfairelinux.com>          *
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

#include "api/callmodel.h"

// Lrc
#include "callbackshandler.h"
#include "api/avmodel.h"
#include "api/behaviorcontroller.h"
#include "api/conversationmodel.h"
#include "api/codecmodel.h"

#include "api/contact.h"
#include "api/contactmodel.h"
#include "api/pluginmodel.h"
#include "api/callparticipantsmodel.h"
#include "api/lrc.h"
#include "api/accountmodel.h"
#include "authority/storagehelper.h"
#include "dbus/callmanager.h"
#include "dbus/videomanager.h"
#include "vcard.h"
#include "renderer.h"
#include "typedefs.h"
#include "uri.h"

// Ring daemon
#include <media_const.h>
#include <account_const.h>

// Qt
#include <QObject>
#include <QString>
#include <QUrl>
#include <QSize>

// std
#include <chrono>
#include <random>
#include <map>

#ifdef WIN32
#define NOMINMAX
#include "Windows.h"
#endif

using namespace libjami::Media;

constexpr static const char HARDWARE_ACCELERATION[] = "HARDWARE_ACCELERATION";
constexpr static const char AUDIO_CODEC[] = "AUDIO_CODEC";
constexpr static const char CALL_ID[] = "CALL_ID";

static std::uniform_int_distribution<int> dis {0, std::numeric_limits<int>::max()};
static const std::map<short, QString>

    sip_call_status_code_map {{0, QObject::tr("Null")},
                              {100, QObject::tr("Trying")},
                              {180, QObject::tr("Ringing")},
                              {181, QObject::tr("Being Forwarded")},
                              {182, QObject::tr("Queued")},
                              {183, QObject::tr("Progress")},
                              {200, QObject::tr("OK")},
                              {202, QObject::tr("Accepted")},
                              {300, QObject::tr("Multiple Choices")},
                              {301, QObject::tr("Moved Permanently")},
                              {302, QObject::tr("Moved Temporarily")},
                              {305, QObject::tr("Use Proxy")},
                              {380, QObject::tr("Alternative Service")},
                              {400, QObject::tr("Bad Request")},
                              {401, QObject::tr("Unauthorized")},
                              {402, QObject::tr("Payment Required")},
                              {403, QObject::tr("Forbidden")},
                              {404, QObject::tr("Not Found")},
                              {405, QObject::tr("Method Not Allowed")},
                              {406, QObject::tr("Not Acceptable")},
                              {407, QObject::tr("Proxy Authentication Required")},
                              {408, QObject::tr("Request Timeout")},
                              {410, QObject::tr("Gone")},
                              {413, QObject::tr("Request Entity Too Large")},
                              {414, QObject::tr("Request URI Too Long")},
                              {415, QObject::tr("Unsupported Media Type")},
                              {416, QObject::tr("Unsupported URI Scheme")},
                              {420, QObject::tr("Bad Extension")},
                              {421, QObject::tr("Extension Required")},
                              {422, QObject::tr("Session Timer Too Small")},
                              {423, QObject::tr("Interval Too Brief")},
                              {480, QObject::tr("Temporarily Unavailable")},
                              {481, QObject::tr("Call TSX Does Not Exist")},
                              {482, QObject::tr("Loop Detected")},
                              {483, QObject::tr("Too Many Hops")},
                              {484, QObject::tr("Address Incomplete")},
                              {485, QObject::tr("Ambiguous")},
                              {486, QObject::tr("Busy")},
                              {487, QObject::tr("Request Terminated")},
                              {488, QObject::tr("Not Acceptable")},
                              {489, QObject::tr("Bad Event")},
                              {490, QObject::tr("Request Updated")},
                              {491, QObject::tr("Request Pending")},
                              {493, QObject::tr("Undecipherable")},
                              {500, QObject::tr("Internal Server Error")},
                              {501, QObject::tr("Not Implemented")},
                              {502, QObject::tr("Bad Gateway")},
                              {503, QObject::tr("Service Unavailable")},
                              {504, QObject::tr("Server Timeout")},
                              {505, QObject::tr("Version Not Supported")},
                              {513, QObject::tr("Message Too Large")},
                              {580, QObject::tr("Precondition Failure")},
                              {600, QObject::tr("Busy Everywhere")},
                              {603, QObject::tr("Call Refused")},
                              {604, QObject::tr("Does Not Exist Anywhere")},
                              {606, QObject::tr("Not Acceptable Anywhere")}};

namespace lrc {

using namespace api;

class CallModelPimpl : public QObject
{
    Q_OBJECT
public:
    CallModelPimpl(const CallModel& linked,
                   Lrc& lrc,
                   const CallbacksHandler& callbacksHandler,
                   const BehaviorController& behaviorController);
    ~CallModelPimpl();

    QVariantList callAdvancedInformation();
    MapStringString advancedInformationForCallId(QString callId);

    QStringList getCallIds();

    /**
     * Send the profile VCard into a call
     * @param callId
     */
    void sendProfile(const QString& callId);

    CallModel::CallInfoMap calls;
    CallModel::CallParticipantsModelMap participantsModel;
    const CallbacksHandler& callbacksHandler;
    const CallModel& linked;
    const BehaviorController& behaviorController;

    /**
     * key = peer's uri
     * vector = chunks
     * @note chunks are counted from 1 to number of parts. We use 0 to store the actual number of
     * parts stored
     */
    std::map<QString, VectorString> vcardsChunks;

    /**
     * Retrieve active calls from the daemon and init the model
     */
    void initCallFromDaemon();

    /**
     * Retrieve active conferences from the daemon and init the model
     */
    void initConferencesFromDaemon();

    /**
     * Check if media device is muted
     */
    bool checkMediaDeviceMuted(const MapStringString& mediaAttributes);

    bool manageCurrentCall_ {true};
    QString currentCall_ {};

    Lrc& lrc;

    QList<call::PendingConferenceeInfo> pendingConferencees_;

public Q_SLOTS:
    /**
     * Connect this signal to know when a call arrives
     * @param accountId the one who receives the call
     * @param callId the call id
     * @param mediaList new media received
     */
    void slotMediaChangeRequested(const QString& accountId,
                                  const QString& callId,
                                  const VectorMapStringString& mediaList);
    /**
     * Listen from CallbacksHandler when a call got a new state
     * @param accountId
     * @param callId
     * @param state the new state
     * @param code unused
     */
    void slotCallStateChanged(const QString& accountId,
                              const QString& callId,
                              const QString& state,
                              int code);
    /**
     * Listen from CallbacksHandler when a call medias are ready
     * @param callId
     * @param event
     * @param mediaList
     */
    void slotMediaNegotiationStatus(const QString& callId,
                                    const QString& event,
                                    const VectorMapStringString& mediaList);
    /**
     * Listen from CallbacksHandler when a VCard chunk is incoming
     * @param accountId
     * @param callId
     * @param from
     * @param part
     * @param numberOfParts
     * @param payload
     */
    void slotincomingVCardChunk(const QString& accountId,
                                const QString& callId,
                                const QString& from,
                                int part,
                                int numberOfParts,
                                const QString& payload);
    /**
     * Listen from CallbacksHandler when a conference is created.
     * @param callId
     */
    void slotConferenceCreated(const QString& accountId, const QString& callId);
    void slotConferenceChanged(const QString& accountId,
                               const QString& callId,
                               const QString& state);
    /**
     * Listen from CallbacksHandler when a voice mail notice is incoming
     * @param accountId
     * @param newCount
     * @param oldCount
     * @param urgentCount
     */
    void slotVoiceMailNotify(const QString& accountId, int newCount, int oldCount, int urgentCount);
    /**
     * Listen from CallManager when a conference layout is updated
     * @param confId
     * @param infos
     */
    void slotOnConferenceInfosUpdated(const QString& confId, const VectorMapStringString& infos);
    /**
     * Listen from CallbacksHandler when the peer start recording
     * @param callId
     * @param peerUri
     * @param state the new state
     */
    void onRemoteRecordingChanged(const QString& callId, const QString& peerUri, bool state);
    /**
     * Listen from CallbacksHandler when we start/stop recording
     * @param callId
     * @param state the new state
     */
    void onRecordingStateChanged(const QString& callId, bool state);
};

CallModel::CallModel(const account::Info& owner,
                     Lrc& lrc,
                     const CallbacksHandler& callbacksHandler,
                     const BehaviorController& behaviorController)
    : QObject(nullptr)
    , owner(owner)
    , pimpl_(std::make_unique<CallModelPimpl>(*this, lrc, callbacksHandler, behaviorController))
{}

CallModel::~CallModel() {}

const call::Info&
CallModel::getCallFromURI(const QString& uri, bool notOver) const
{
    // For a NON SIP account the scheme can be ring:. Sometimes it can miss, and will be certainly
    // replaced by jami://.
    // Just make the comparaison ignoring the scheme and check the rest.
    auto uriObj = URI(uri);
    for (const auto& call : pimpl_->calls) {
        auto contactUri = URI(call.second->peerUri);
        if (uriObj.userinfo() == contactUri.userinfo()
            and uriObj.hostname() == contactUri.hostname()) {
            if (!notOver || !call::isTerminating(call.second->status))
                return *call.second;
        }
    }
    throw std::out_of_range("No call at URI " + uri.toStdString());
}

const call::Info&
CallModel::getConferenceFromURI(const QString& uri) const
{
    for (const auto& call : pimpl_->calls) {
        if (call.second->type == call::Type::CONFERENCE) {
            QStringList callList = CallManager::instance().getParticipantList(owner.id, call.first);
            Q_FOREACH (const auto& callId, callList) {
                try {
                    if (pimpl_->calls.find(callId) != pimpl_->calls.end()
                        && pimpl_->calls[callId]->peerUri == uri) {
                        return *call.second;
                    }
                } catch (...) {
                }
            }
        }
    }
    throw std::out_of_range("No call at URI " + uri.toStdString());
}

VectorString
CallModel::getConferenceSubcalls(const QString& confId)
{
    QStringList callList = CallManager::instance().getParticipantList(owner.id, confId);
    VectorString result;
    result.reserve(callList.size());
    Q_FOREACH (const auto& callId, callList) {
        result.push_back(callId);
    }
    return result;
}

const call::Info&
CallModel::getCall(const QString& uid) const
{
    return *pimpl_->calls.at(uid);
}

const CallParticipants&
CallModel::getParticipantsInfos(const QString& callId)
{
    if (pimpl_->participantsModel.find(callId) == pimpl_->participantsModel.end()) {
        VectorMapStringString infos = {};
        pimpl_->participantsModel
            .emplace(callId, std::make_shared<CallParticipants>(infos, callId, pimpl_->linked));
    }
    return *pimpl_->participantsModel.at(callId);
}

void
CallModel::updateCallMediaList(const QString& callId, bool acceptVideo)
{
    try {
        auto callInfos = pimpl_->calls.find(callId);
        if (callInfos != pimpl_->calls.end()) {
            for (auto it = callInfos->second->mediaList.begin();
                 it != callInfos->second->mediaList.end();
                 it++) {
                if ((*it)[MediaAttributeKey::MEDIA_TYPE] == MediaAttributeValue::VIDEO
                    && !acceptVideo) {
                    (*it)[MediaAttributeKey::ENABLED] = TRUE_STR;
                    (*it)[MediaAttributeKey::MUTED] = TRUE_STR;
                    callInfos->second->videoMuted = !acceptVideo;
                }
            }
        }
    } catch (...) {
    }
}

QString
CallModel::createCall(const QString& uri, bool isAudioOnly, VectorMapStringString mediaList)
{
    if (mediaList.isEmpty()) {
        MapStringString mediaAttribute = {{MediaAttributeKey::MEDIA_TYPE,
                                           MediaAttributeValue::AUDIO},
                                          {MediaAttributeKey::ENABLED, TRUE_STR},
                                          {MediaAttributeKey::MUTED, FALSE_STR},
                                          {MediaAttributeKey::SOURCE, ""},
                                          {MediaAttributeKey::LABEL, "audio_0"}};
        mediaList.push_back(mediaAttribute);
        if (!isAudioOnly) {
            mediaAttribute[MediaAttributeKey::MEDIA_TYPE] = MediaAttributeValue::VIDEO;
            mediaAttribute[MediaAttributeKey::LABEL] = "video_0";
            mediaList.push_back(mediaAttribute);
        }
    }
#ifdef ENABLE_LIBWRAP
    auto callId = CallManager::instance().placeCallWithMedia(owner.id, uri, mediaList);
#else  // dbus
    // do not use auto here (QDBusPendingReply<QString>)
    QString callId = CallManager::instance().placeCallWithMedia(owner.id, uri, mediaList);
#endif // ENABLE_LIBWRAP

    if (callId.isEmpty()) {
        qDebug() << "no call placed between (account: " << owner.id << ", contact: " << uri << ")";
        return "";
    }

    auto callInfo = std::make_shared<call::Info>();
    callInfo->id = callId;
    callInfo->peerUri = uri;
    callInfo->isOutgoing = true;
    callInfo->status = call::Status::SEARCHING;
    callInfo->type = call::Type::DIALOG;
    callInfo->isAudioOnly = isAudioOnly;
    callInfo->videoMuted = isAudioOnly;
    callInfo->mediaList = mediaList;
    pimpl_->calls.emplace(callId, std::move(callInfo));

    return callId;
}

QList<QVariant>
CallModel::getAdvancedInformation() const
{
    return pimpl_->callAdvancedInformation();
}

MapStringString
CallModel::advancedInformationForCallId(QString callId) const
{
    return pimpl_->advancedInformationForCallId(callId);
}

QStringList
CallModel::getCallIds() const
{
    return pimpl_->getCallIds();
}

void
CallModel::emplaceConversationConference(const QString& confId)
{
    if (hasCall(confId))
        return;

    auto callInfo = std::make_shared<call::Info>();
    callInfo->id = confId;
    callInfo->isOutgoing = false;
    callInfo->status = call::Status::SEARCHING;
    callInfo->type = call::Type::CONFERENCE;
    callInfo->isAudioOnly = false;
    callInfo->videoMuted = false;
    callInfo->mediaList = {};
    pimpl_->calls.emplace(confId, std::move(callInfo));
}

void
CallModel::muteMedia(const QString& callId, const QString& label, bool mute)
{
    auto& callInfo = pimpl_->calls[callId];
    if (!callInfo)
        return;

    auto proposedList = callInfo->mediaList;
    if (proposedList.isEmpty())
        return;
    for (auto& media : proposedList)
        if (media[MediaAttributeKey::LABEL] == label)
            media[MediaAttributeKey::MUTED] = mute ? TRUE_STR : FALSE_STR;
    CallManager::instance().requestMediaChange(owner.id, callId, proposedList);
}

void
CallModel::replaceDefaultCamera(const QString& callId, const QString& deviceId)
{
    auto& callInfo = pimpl_->calls[callId];
    if (!callInfo)
        return;

    VectorMapStringString proposedList = callInfo->mediaList;
    QString oldPreview, newPreview;
    for (auto& media : proposedList) {
        if (media[MediaAttributeKey::MEDIA_TYPE] == MediaAttributeValue::VIDEO
            && media[MediaAttributeKey::SOURCE].startsWith(
                libjami::Media::VideoProtocolPrefix::CAMERA)) {
            oldPreview = media[MediaAttributeKey::SOURCE];
            QString resource = QString("%1%2%3")
                                   .arg(libjami::Media::VideoProtocolPrefix::CAMERA)
                                   .arg(libjami::Media::VideoProtocolPrefix::SEPARATOR)
                                   .arg(deviceId);
            media[MediaAttributeKey::SOURCE] = resource;
            newPreview = resource;
            break;
        }
    }

    if (!newPreview.isEmpty()) {
        pimpl_->lrc.getAVModel().stopPreview(oldPreview);
        pimpl_->lrc.getAVModel().startPreview(newPreview);
    }

    CallManager::instance().requestMediaChange(owner.id, callId, proposedList);
}

VectorMapStringString
CallModel::getProposed(VectorMapStringString mediaList,
                       const QString& callId,
                       const QString& source,
                       MediaRequestType type,
                       bool mute,
                       bool shareAudio)
{
    auto& callInfo = pimpl_->calls[callId];
    if (!callInfo || source.isEmpty())
        return {};

    QString resource {};
    auto aid = 0;
    auto vid = 0;
    for (const auto& media : mediaList) {
        if (media[MediaAttributeKey::SOURCE] == source)
            break;
        if (media[MediaAttributeKey::MEDIA_TYPE] == MediaAttributeValue::AUDIO)
            aid++;
        if (media[MediaAttributeKey::MEDIA_TYPE] == MediaAttributeValue::VIDEO)
            vid++;
    }
    QString alabel = QString("audio_%1").arg(aid);
    QString vlabel = QString("video_%1").arg(vid);
    QString sep = libjami::Media::VideoProtocolPrefix::SEPARATOR;
    MapStringString audioMediaAttribute {};
    switch (type) {
    case MediaRequestType::FILESHARING: {
        // File sharing
        resource = !source.isEmpty() ? QString("%1%2%3")
                                           .arg(libjami::Media::VideoProtocolPrefix::FILE)
                                           .arg(sep)
                                           .arg(QUrl(source).toLocalFile())
                                     : libjami::Media::VideoProtocolPrefix::NONE;
        if (shareAudio)
            audioMediaAttribute = {{MediaAttributeKey::MEDIA_TYPE, MediaAttributeValue::AUDIO},
                                   {MediaAttributeKey::ENABLED, TRUE_STR},
                                   {MediaAttributeKey::MUTED, mute ? TRUE_STR : FALSE_STR},
                                   {MediaAttributeKey::SOURCE, resource},
                                   {MediaAttributeKey::LABEL, alabel}};
        break;
    }
    case MediaRequestType::SCREENSHARING: {
        // Screen/window sharing
        resource = source;
        break;
    }
    case MediaRequestType::CAMERA: {
        // Camera device
        resource = not source.isEmpty() ? QString("%1%2%3")
                                              .arg(libjami::Media::VideoProtocolPrefix::CAMERA)
                                              .arg(sep)
                                              .arg(source)
                                        : libjami::Media::VideoProtocolPrefix::NONE;
        break;
    }
    default:
        return {};
    }

    VectorMapStringString proposedList {};
    MapStringString videoMediaAttribute = {{MediaAttributeKey::MEDIA_TYPE,
                                            MediaAttributeValue::VIDEO},
                                           {MediaAttributeKey::ENABLED, TRUE_STR},
                                           {MediaAttributeKey::MUTED, mute ? TRUE_STR : FALSE_STR},
                                           {MediaAttributeKey::SOURCE, resource},
                                           {MediaAttributeKey::LABEL, vlabel}};
    // if we're in a 1:1, we only show one preview, so, limit to 1 video (the new one)
    auto participantsModel = pimpl_->participantsModel.find(callId);
    auto isConf = participantsModel != pimpl_->participantsModel.end()
                  && participantsModel->second->getParticipants().size() != 0;

    auto replaced = false;
    for (auto& media : mediaList) {
        auto replace = media[MediaAttributeKey::MEDIA_TYPE] == MediaAttributeValue::VIDEO;
        // In a 1:1 we replace the first video, in a conference we replace only if it's a muted
        // video or if a new sharing is requested
        if (isConf) {
            replace &= media[MediaAttributeKey::MUTED] == TRUE_STR;
            replace |= (media[MediaAttributeKey::SOURCE].startsWith(
                            libjami::Media::VideoProtocolPrefix::FILE)
                        || media[MediaAttributeKey::SOURCE].startsWith(
                            libjami::Media::VideoProtocolPrefix::DISPLAY))
                       && (type == MediaRequestType::FILESHARING
                           || type == MediaRequestType::SCREENSHARING);
        }
        if (replace) {
            videoMediaAttribute[MediaAttributeKey::LABEL] = media[MediaAttributeKey::LABEL];
            media = videoMediaAttribute;
            replaced = true;
        }
        if (!(media[MediaAttributeKey::SOURCE].startsWith(libjami::Media::VideoProtocolPrefix::FILE)
              && type == MediaRequestType::CAMERA)) {
            proposedList.emplace_back(media);
        }
    }
    if (!replaced)
        proposedList.push_back(videoMediaAttribute);
    if (!audioMediaAttribute.isEmpty())
        proposedList.emplace_back(audioMediaAttribute);

    return proposedList;
}

void
CallModel::addMedia(
    const QString& callId, const QString& source, MediaRequestType type, bool mute, bool shareAudio)
{
    auto& callInfo = pimpl_->calls[callId];
    if (!callInfo || source.isEmpty())
        return;

    auto proposedList = getProposed(callInfo->mediaList, callId, source, type, mute, shareAudio);

    CallManager::instance().requestMediaChange(owner.id, callId, proposedList);
    callInfo->mediaList = proposedList;
    if (callInfo->status == call::Status::IN_PROGRESS)
        Q_EMIT callInfosChanged(owner.id, callId);
}

void
CallModel::removeMedia(const QString& callId,
                       const QString& mediaType,
                       const QString& type,
                       bool muteCamera,
                       bool removeAll)
{
    auto& callInfo = pimpl_->calls[callId];
    if (!callInfo)
        return;
    auto isVideo = mediaType == MediaAttributeValue::VIDEO;
    auto newIdx = 0;
    auto replaceIdx = false, hasVideo = false;
    VectorMapStringString proposedList;
    QString label;
    for (const auto& media : callInfo->mediaList) {
        if (media[MediaAttributeKey::MEDIA_TYPE] == mediaType
            && media[MediaAttributeKey::SOURCE].startsWith(type)) {
            replaceIdx = true;
            label = media[MediaAttributeKey::LABEL];
        } else {
            if (!removeAll || !media[MediaAttributeKey::SOURCE].startsWith(type)) {
                if (media[MediaAttributeKey::MEDIA_TYPE] == mediaType) {
                    auto newMedia = media;
                    if (replaceIdx) {
                        QString idxStr = QString::number(newIdx);
                        newMedia[MediaAttributeKey::LABEL] = isVideo ? "video_" + idxStr
                                                                     : "audio_" + idxStr;
                    }
                    proposedList.push_back(newMedia);
                    newIdx++;
                } else {
                    proposedList.push_back(media);
                }
            }
            hasVideo |= media[MediaAttributeKey::MEDIA_TYPE] == MediaAttributeValue::VIDEO;
        }
    }

    auto participantsModel = pimpl_->participantsModel.find(callId);
    auto isConf = participantsModel != pimpl_->participantsModel.end()
                  && participantsModel->second->getParticipants().size() != 0;
    if (!isConf) {
        // 1:1 call, in this case we only show one preview, and switch between sharing and camera
        // preview So, if no video, replace by camera
        if (!hasVideo) {
            proposedList = getProposed(proposedList,
                                       callInfo->id,
                                       pimpl_->lrc.getAVModel().getCurrentVideoCaptureDevice(),
                                       MediaRequestType::CAMERA,
                                       muteCamera);
        }
    } else if (!hasVideo) {
        // To receive the remote video, we need a muted camera
        proposedList.push_back(MapStringString {
            {MediaAttributeKey::MEDIA_TYPE, MediaAttributeValue::VIDEO},
            {MediaAttributeKey::ENABLED, TRUE_STR},
            {MediaAttributeKey::MUTED, TRUE_STR},
            {MediaAttributeKey::SOURCE,
             pimpl_->lrc.getAVModel()
                 .getCurrentVideoCaptureDevice()}, // not needed to set the source. Daemon should be
                                                   // able to check it
            {MediaAttributeKey::LABEL, label.isEmpty() ? "video_0" : label}});
    }

    if (isVideo && !label.isEmpty())
        pimpl_->lrc.getAVModel().stopPreview(label);

    CallManager::instance().requestMediaChange(owner.id, callId, proposedList);
    callInfo->mediaList = proposedList;
    if (callInfo->status == call::Status::IN_PROGRESS)
        Q_EMIT callInfosChanged(owner.id, callId);
}

void
CallModel::accept(const QString& callId) const
{
    try {
        auto& callInfo = pimpl_->calls[callId];
        if (!callInfo)
            return;
        if (callInfo->mediaList.empty())
            CallManager::instance().accept(owner.id, callId);
        else
            CallManager::instance().acceptWithMedia(owner.id, callId, callInfo->mediaList);
    } catch (...) {
    }
}

void
CallModel::hangUp(const QString& callId) const
{
    if (!hasCall(callId))
        return;
    auto& call = pimpl_->calls[callId];

    if (call->status == call::Status::INCOMING_RINGING) {
        CallManager::instance().refuse(owner.id, callId);
        return;
    }

    switch (call->type) {
    case call::Type::DIALOG:
        CallManager::instance().hangUp(owner.id, callId);
        break;
    case call::Type::CONFERENCE:
        CallManager::instance().hangUpConference(owner.id, callId);
        break;
    case call::Type::INVALID:
    default:
        break;
    }
}

void
CallModel::refuse(const QString& callId) const
{
    if (!hasCall(callId))
        return;
    CallManager::instance().refuse(owner.id, callId);
}

void
CallModel::toggleAudioRecord(const QString& callId) const
{
    CallManager::instance().toggleRecording(owner.id, callId);
}

void
CallModel::playDTMF(const QString& callId, const QString& value) const
{
    if (!hasCall(callId))
        return;
    if (pimpl_->calls[callId]->status != call::Status::IN_PROGRESS)
        return;
    CallManager::instance().playDTMF(value);
}

void
CallModel::togglePause(const QString& callId) const
{
    // function should now only serves for SIP accounts
    if (!hasCall(callId))
        return;
    auto& call = pimpl_->calls[callId];

    if (call->status == call::Status::PAUSED) {
        if (call->type == call::Type::DIALOG) {
            CallManager::instance().unhold(owner.id, callId);
        } else {
            CallManager::instance().unholdConference(owner.id, callId);
        }
    } else if (call->status == call::Status::IN_PROGRESS) {
        if (call->type == call::Type::DIALOG)
            CallManager::instance().hold(owner.id, callId);
        else {
            CallManager::instance().holdConference(owner.id, callId);
        }
    }
}

void
CallModel::setQuality(const QString& callId, const double quality) const
{
    Q_UNUSED(callId)
    Q_UNUSED(quality)
    qDebug() << "setQuality isn't implemented yet";
}

void
CallModel::transfer(const QString& callId, const QString& to) const
{
    CallManager::instance().transfer(owner.id, callId, to);
}

void
CallModel::transferToCall(const QString& callId, const QString& callIdDest) const
{
    CallManager::instance().attendedTransfer(owner.id, callId, callIdDest);
}

void
CallModel::joinCalls(const QString& callIdA, const QString& callIdB) const
{
    // Get call informations
    call::Info call1, call2;
    QString accountIdCall1 = {}, accountIdCall2 = {};
    for (const auto& account_id : owner.accountModel->getAccountList()) {
        try {
            auto& accountInfo = owner.accountModel->getAccountInfo(account_id);
            if (accountInfo.callModel->hasCall(callIdA)) {
                call1 = accountInfo.callModel->getCall(callIdA);
                accountIdCall1 = account_id;
            }
            if (accountInfo.callModel->hasCall(callIdB)) {
                call2 = accountInfo.callModel->getCall(callIdB);
                accountIdCall2 = account_id;
            }
            if (!accountIdCall1.isEmpty() && !accountIdCall2.isEmpty())
                break;
        } catch (...) {
        }
    }
    if (accountIdCall1.isEmpty() || accountIdCall2.isEmpty()) {
        qWarning() << "Can't join inexistent calls.";
        return;
    }

    if (call1.type == call::Type::CONFERENCE && call2.type == call::Type::CONFERENCE) {
        bool joined = CallManager::instance().joinConference(accountIdCall1,
                                                             callIdA,
                                                             accountIdCall2,
                                                             callIdB);

        if (!joined) {
            qWarning() << "Conference: " << callIdA << " couldn't join conference " << callIdB;
            return;
        }
        if (accountIdCall1 != owner.id) {
            // If the conference is added from another account
            try {
                auto& accountInfo = owner.accountModel->getAccountInfo(accountIdCall1);
                if (accountInfo.callModel->hasCall(callIdA)) {
                    Q_EMIT accountInfo.callModel->callAddedToConference(callIdA, callIdB);
                }
            } catch (...) {
            }
        } else {
            Q_EMIT callAddedToConference(callIdA, callIdB);
        }
    } else if (call1.type == call::Type::CONFERENCE || call2.type == call::Type::CONFERENCE) {
        auto call = call1.type == call::Type::CONFERENCE ? callIdB : callIdA;
        auto conf = call1.type == call::Type::CONFERENCE ? callIdA : callIdB;
        // Unpause conference if conference was not active
        CallManager::instance().unholdConference(owner.id, conf);
        auto accountCall = call1.type == call::Type::CONFERENCE ? accountIdCall2 : accountIdCall1;

        bool joined = CallManager::instance().addParticipant(accountCall, call, accountCall, conf);
        if (!joined) {
            qWarning() << "Call: " << call << " couldn't join conference " << conf;
            return;
        }
        if (accountCall != owner.id) {
            // If the call is added from another account
            try {
                auto& accountInfo = owner.accountModel->getAccountInfo(accountCall);
                if (accountInfo.callModel->hasCall(call)) {
                    accountInfo.callModel->pimpl_->slotConferenceCreated(owner.id, conf);
                }
            } catch (...) {
            }
        } else
            Q_EMIT callAddedToConference(call, conf);

        // Remove from pendingConferences_
        for (int i = 0; i < pimpl_->pendingConferencees_.size(); ++i) {
            if (pimpl_->pendingConferencees_.at(i).callId == call) {
                Q_EMIT beginRemovePendingConferenceesRows(i);
                pimpl_->pendingConferencees_.removeAt(i);
                Q_EMIT endRemovePendingConferenceesRows();
                break;
            }
        }
    } else {
        CallManager::instance().joinParticipant(accountIdCall1, callIdA, accountIdCall2, callIdB);
        // NOTE: This will trigger slotConferenceCreated.
    }
}

QString
CallModel::callAndAddParticipant(const QString uri, const QString& callId, bool audioOnly)
{
    auto newCallId = createCall(uri, audioOnly, pimpl_->calls[callId]->mediaList);
    Q_EMIT beginInsertPendingConferenceesRows(0);
    pimpl_->pendingConferencees_.prepend({uri, newCallId, callId});
    Q_EMIT endInsertPendingConferenceesRows();
    return newCallId;
}

void
CallModel::removeParticipant(const QString& callId, const QString& participant) const
{
    Q_UNUSED(callId)
    Q_UNUSED(participant)
    qDebug() << "removeParticipant() isn't implemented yet";
}

QString
CallModel::getFormattedCallDuration(const QString& callId) const
{
    if (!hasCall(callId))
        return "00:00";
    auto& startTime = pimpl_->calls[callId]->startTime;
    if (startTime.time_since_epoch().count() == 0)
        return "00:00";
    auto now = std::chrono::steady_clock::now();
    auto d = std::chrono::duration_cast<std::chrono::seconds>(now.time_since_epoch()
                                                              - startTime.time_since_epoch())
                 .count();
    return interaction::getFormattedCallDuration(d);
}

bool
CallModel::isRecording(const QString& callId) const
{
    if (!hasCall(callId))
        return false;
    return CallManager::instance().getIsRecording(owner.id, callId);
}

QString
CallModel::getSIPCallStatusString(const short& statusCode)
{
    auto element = sip_call_status_code_map.find(statusCode);
    if (element != sip_call_status_code_map.end()) {
        return element->second;
    }
    return "";
}

const QList<call::PendingConferenceeInfo>&
CallModel::getPendingConferencees()
{
    return pimpl_->pendingConferencees_;
}

api::video::RenderedDevice
CallModel::getCurrentRenderedDevice(const QString& call_id) const
{
    video::RenderedDevice result;
    MapStringString callDetails;
    QStringList conferences = CallManager::instance().getConferenceList(owner.id);
    if (conferences.indexOf(call_id) != -1) {
        callDetails = CallManager::instance().getConferenceDetails(owner.id, call_id);
    } else {
        callDetails = CallManager::instance().getCallDetails(owner.id, call_id);
    }
    if (!callDetails.contains("VIDEO_SOURCE")) {
        return result;
    }
    auto source = callDetails["VIDEO_SOURCE"];
    auto sourceSize = source.size();
    if (source.startsWith("camera://")) {
        result.type = video::DeviceType::CAMERA;
        result.name = source.right(sourceSize - QString("camera://").size());
    } else if (source.startsWith("file://")) {
        result.type = video::DeviceType::FILE;
        result.name = source.right(sourceSize - QString("file://").size());
    } else if (source.startsWith("display://")) {
        result.type = video::DeviceType::DISPLAY;
        result.name = source.right(sourceSize - QString("display://").size());
    }
    return result;
}

QString
CallModel::getDisplay(int idx, int x, int y, int w, int h)
{
    QString sep = libjami::Media::VideoProtocolPrefix::SEPARATOR;
    return QString("%1%2:%3+%4,%5 %6x%7")
        .arg(libjami::Media::VideoProtocolPrefix::DISPLAY)
        .arg(sep)
        .arg(idx)
        .arg(x)
        .arg(y)
        .arg(w)
        .arg(h);
}

QString
CallModel::getDisplay(const QString& windowProcessId, const QString& windowId)
{
    QString sep = libjami::Media::VideoProtocolPrefix::SEPARATOR;
    QString ret {};
#if (defined(Q_OS_UNIX) && !defined(__APPLE__))
    Q_UNUSED(windowId);
    ret = QString("%1%2:+0,0 window-id:%3")
              .arg(libjami::Media::VideoProtocolPrefix::DISPLAY)
              .arg(sep)
              .arg(windowProcessId);
#endif
#ifdef WIN32
    ret = QString("%1%2:+0,0 window-id:hwnd=%3")
              .arg(libjami::Media::VideoProtocolPrefix::DISPLAY)
              .arg(sep)
              .arg(windowProcessId);
#endif
    return ret;
}

CallModelPimpl::CallModelPimpl(const CallModel& linked,
                               Lrc& lrc,
                               const CallbacksHandler& callbacksHandler,
                               const BehaviorController& behaviorController)
    : linked(linked)
    , lrc(lrc)
    , callbacksHandler(callbacksHandler)
    , behaviorController(behaviorController)
{
    connect(&callbacksHandler,
            &CallbacksHandler::mediaChangeRequested,
            this,
            &CallModelPimpl::slotMediaChangeRequested);
    connect(&callbacksHandler,
            &CallbacksHandler::callStateChanged,
            this,
            &CallModelPimpl::slotCallStateChanged);
    connect(&callbacksHandler,
            &CallbacksHandler::mediaNegotiationStatus,
            this,
            &CallModelPimpl::slotMediaNegotiationStatus);
    connect(&callbacksHandler,
            &CallbacksHandler::incomingVCardChunk,
            this,
            &CallModelPimpl::slotincomingVCardChunk);
    connect(&callbacksHandler,
            &CallbacksHandler::conferenceCreated,
            this,
            &CallModelPimpl::slotConferenceCreated);
    connect(&callbacksHandler,
            &CallbacksHandler::conferenceChanged,
            this,
            &CallModelPimpl::slotConferenceChanged);
    connect(&callbacksHandler,
            &CallbacksHandler::voiceMailNotify,
            this,
            &CallModelPimpl::slotVoiceMailNotify);
    connect(&CallManager::instance(),
            &CallManagerInterface::onConferenceInfosUpdated,
            this,
            &CallModelPimpl::slotOnConferenceInfosUpdated);
    connect(&callbacksHandler,
            &CallbacksHandler::remoteRecordingChanged,
            this,
            &CallModelPimpl::onRemoteRecordingChanged);
    connect(&callbacksHandler,
            &CallbacksHandler::recordingStateChanged,
            this,
            &CallModelPimpl::onRecordingStateChanged);

#ifndef ENABLE_LIBWRAP
    // Only necessary with dbus since the daemon runs separately
    initCallFromDaemon();
    initConferencesFromDaemon();
#endif
}

CallModelPimpl::~CallModelPimpl() {}

QVariantList
CallModelPimpl::callAdvancedInformation()
{
    QVariantList advancedInformationList;

    QStringList callList = CallManager::instance().getCallList(linked.owner.id);
    for (const auto& callId : callList) {
        MapStringString mapStringDetailsList = CallManager::instance()
                                                   .getCallDetails(linked.owner.id, callId);
        QVariantMap detailsList = mapStringStringToQVariantMap(mapStringDetailsList);

        detailsList.insert(CALL_ID, callId);
        detailsList.insert(HARDWARE_ACCELERATION, lrc.getAVModel().getHardwareAcceleration());
        advancedInformationList.append(detailsList);
    }

    return advancedInformationList;
}

MapStringString
CallModelPimpl::advancedInformationForCallId(QString callId)
{
    MapStringString infoMap = CallManager::instance().getCallDetails(linked.owner.id, callId);
    if (lrc.getAVModel().getHardwareAcceleration())
        infoMap[HARDWARE_ACCELERATION] = "True";
    else
        infoMap[HARDWARE_ACCELERATION] = "False";
    return infoMap;
}

QStringList
CallModelPimpl::getCallIds()
{
    return CallManager::instance().getCallList(linked.owner.id);
}

void
CallModelPimpl::initCallFromDaemon()
{
    QStringList callList = CallManager::instance().getCallList(linked.owner.id);
    for (const auto& callId : callList) {
        MapStringString details = CallManager::instance().getCallDetails(linked.owner.id, callId);
        auto callInfo = std::make_shared<call::Info>();
        callInfo->id = callId;
        auto now = std::chrono::steady_clock::now();
        auto system_now = std::chrono::system_clock::to_time_t(std::chrono::system_clock::now());
        auto diff = static_cast<int64_t>(system_now)
                    - std::stol(details["TIMESTAMP_START"].toStdString());
        callInfo->startTime = now - std::chrono::seconds(diff);
        callInfo->status = call::to_status(details["CALL_STATE"]);
        auto endId = details["PEER_NUMBER"].indexOf("@");
        callInfo->peerUri = details["PEER_NUMBER"].left(endId);
        if (linked.owner.profileInfo.type == lrc::api::profile::Type::JAMI) {
            callInfo->peerUri = "ring:" + callInfo->peerUri;
        }
        callInfo->videoMuted = details["VIDEO_MUTED"] == TRUE_STR;
        callInfo->audioMuted = details["AUDIO_MUTED"] == TRUE_STR;
        callInfo->type = call::Type::DIALOG;
        VectorMapStringString infos = CallManager::instance().getConferenceInfos(linked.owner.id,
                                                                                 callId);
        auto participantsPtr = std::make_shared<CallParticipants>(infos, callId, linked);
        callInfo->layout = participantsPtr->getLayout();
        participantsModel.emplace(callId, std::move(participantsPtr));
        calls.emplace(callId, std::move(callInfo));
        // NOTE/BUG: the videorenderer can't know that the client has restarted
        // So, for now, a user will have to manually restart the medias until
        // this renderer is not redesigned.
    }
}

bool
CallModelPimpl::checkMediaDeviceMuted(const MapStringString& mediaAttributes)
{
    return mediaAttributes[MediaAttributeKey::SOURCE].startsWith("camera:")
           && (mediaAttributes[MediaAttributeKey::ENABLED] == FALSE_STR
               || mediaAttributes[MediaAttributeKey::MUTED] == TRUE_STR);
}

void
CallModelPimpl::initConferencesFromDaemon()
{
    QStringList callList = CallManager::instance().getConferenceList(linked.owner.id);
    for (const auto& callId : callList) {
        QMap<QString, QString> details = CallManager::instance()
                                             .getConferenceDetails(linked.owner.id, callId);
        auto callInfo = std::make_shared<call::Info>();
        callInfo->id = callId;
        QStringList callList = CallManager::instance().getParticipantList(linked.owner.id, callId);
        Q_FOREACH (const auto& call, callList) {
            MapStringString callDetails = CallManager::instance().getCallDetails(linked.owner.id,
                                                                                 call);
            auto now = std::chrono::steady_clock::now();
            auto system_now = std::chrono::system_clock::to_time_t(std::chrono::system_clock::now());
            auto diff = static_cast<int64_t>(system_now)
                        - std::stol(callDetails["TIMESTAMP_START"].toStdString());
            callInfo->status = details["CONF_STATE"] == "ACTIVE_ATTACHED"
                                   ? call::Status::IN_PROGRESS
                                   : call::Status::PAUSED;
            callInfo->startTime = now - std::chrono::seconds(diff);
            Q_EMIT linked.callAddedToConference(call, callId);
        }
        callInfo->type = call::Type::CONFERENCE;
        VectorMapStringString infos = CallManager::instance().getConferenceInfos(linked.owner.id,
                                                                                 callId);
        auto participantsPtr = std::make_shared<CallParticipants>(infos, callId, linked);
        callInfo->layout = participantsPtr->getLayout();
        participantsModel.emplace(callId, std::move(participantsPtr));

        calls.emplace(callId, std::move(callInfo));
    }
}

void
CallModel::setCurrentCall(const QString& callId) const
{
    if (!pimpl_->manageCurrentCall_)
        return;
    auto it = std::find_if(pimpl_->pendingConferencees_.begin(),
                           pimpl_->pendingConferencees_.end(),
                           [callId](const lrc::api::call::PendingConferenceeInfo& info) -> bool {
                               return info.callId == callId;
                           });

    // Set current call only if not adding this call
    // to a current conference
    if (it != pimpl_->pendingConferencees_.end())
        return;
    if (!hasCall(callId))
        return;

    // The client should be able to set the current call multiple times
    if (pimpl_->currentCall_ == callId)
        return;
    pimpl_->currentCall_ = callId;

    // Unhold call
    auto& call = pimpl_->calls[callId];
    if (call->status == call::Status::PAUSED) {
        auto& call = pimpl_->calls[callId];
        if (call->type == call::Type::DIALOG) {
            CallManager::instance().unhold(owner.id, callId);
        } else {
            CallManager::instance().unholdConference(owner.id, callId);
        }
    }

    QStringList accountList = pimpl_->lrc.getAccountModel().getAccountList();
    // If we are setting a current call in the UI, we want to hold all other calls,
    // across accounts, to avoid sending our local media streams while another call
    // is in focus.
    for (const auto& acc : accountList) {
        VectorString filterCalls;
        // For each account, we should not hold calls linked to a conference
        QStringList conferences = CallManager::instance().getConferenceList(acc);
        for (const auto& confId : conferences) {
            QStringList callList = CallManager::instance().getParticipantList(acc, confId);
            Q_FOREACH (const auto& cid, callList) {
                filterCalls.push_back(cid);
            }
        }

        for (const auto& cid : Lrc::activeCalls(acc)) {
            auto filtered = std::find(filterCalls.begin(), filterCalls.end(), cid)
                            != filterCalls.end();
            if (cid != callId && !filtered) {
                // Only hold calls for a non rendez-vous point
                CallManager::instance().hold(acc, cid);
            }
        }

        if (!lrc::api::Lrc::holdConferences) {
            continue;
        }
        // If the account is the host and it is attached to the conference,
        // then we should hold it.
        for (const auto& confId : conferences) {
            if (callId != confId) {
                MapStringString confDetails = CallManager::instance().getConferenceDetails(acc,
                                                                                           confId);
                // Only hold conference if attached
                if (confDetails["CALL_STATE"] == "ACTIVE_DETACHED")
                    continue;
                QStringList callList = CallManager::instance().getParticipantList(acc, confId);
                if (callList.indexOf(callId) == -1)
                    CallManager::instance().holdConference(acc, confId);
            }
        }
    }

    Q_EMIT currentCallChanged(callId);
}

void
CallModel::setConferenceLayout(const QString& confId, const call::Layout& layout)
{
    auto call = pimpl_->calls.find(confId);
    if (call != pimpl_->calls.end()) {
        switch (layout) {
        case call::Layout::GRID:
            CallManager::instance().setConferenceLayout(owner.id, confId, 0);
            break;
        case call::Layout::ONE_WITH_SMALL:
            CallManager::instance().setConferenceLayout(owner.id, confId, 1);
            break;
        case call::Layout::ONE:
            CallManager::instance().setConferenceLayout(owner.id, confId, 2);
            break;
        }
        call->second->layout = layout;
    }
}

void
CallModel::setActiveStream(const QString& confId,
                           const QString& accountUri,
                           const QString& deviceId,
                           const QString& streamId,
                           bool state)
{
    CallManager::instance().setActiveStream(owner.id, confId, accountUri, deviceId, streamId, state);
}

bool
CallModel::isModerator(const QString& confId, const QString& uri)
{
    auto call = pimpl_->calls.find(confId);
    if (call == pimpl_->calls.end() or not call->second)
        return false;
    auto participantsModel = pimpl_->participantsModel.find(confId);
    if (participantsModel == pimpl_->participantsModel.end()
        or participantsModel->second->getParticipants().size() == 0)
        return true;
    auto ownerUri = owner.profileInfo.uri;
    auto uriToCheck = uri;
    if (uriToCheck.isEmpty()) {
        uriToCheck = ownerUri;
    }
    auto isModerator = uriToCheck == ownerUri
                           ? call->second->type == lrc::api::call::Type::CONFERENCE
                           : false;
    if (!isModerator && participantsModel->second->getParticipants().size() != 0) {
        if (!uri.isEmpty())
            isModerator = participantsModel->second->checkModerator(uri);
        else
            isModerator = participantsModel->second->checkModerator(owner.profileInfo.uri);
    }
    return isModerator;
}

void
CallModel::setModerator(const QString& confId, const QString& peerId, const bool& state)
{
    CallManager::instance().setModerator(owner.id, confId, peerId, state);
}

bool
CallModel::isHandRaised(const QString& confId, const QString& uri) noexcept
{
    auto call = pimpl_->calls.find(confId);
    if (call == pimpl_->calls.end() or not call->second)
        return false;

    auto participantsModel = pimpl_->participantsModel.find(confId);
    if (participantsModel == pimpl_->participantsModel.end())
        return false;

    auto ownerUri = owner.profileInfo.uri;
    auto uriToCheck = uri;
    if (uriToCheck.isEmpty()) {
        uriToCheck = ownerUri;
    }
    auto handRaised = false;
    for (const auto& participant : participantsModel->second->getParticipants()) {
        if (participant.uri == uriToCheck) {
            handRaised = participant.handRaised;
            break;
        }
    }
    return handRaised;
}

void
CallModel::raiseHand(const QString& confId,
                     const QString& accountUri,
                     const QString& deviceId,
                     bool state)
{
    CallManager::instance().raiseHand(owner.id, confId, accountUri, deviceId, state);
}

void
CallModel::muteStream(const QString& confId,
                      const QString& accountUri,
                      const QString& deviceId,
                      const QString& streamId,
                      const bool& state)
{
    CallManager::instance().muteStream(owner.id, confId, accountUri, deviceId, streamId, state);
}

void
CallModel::hangupParticipant(const QString& confId,
                             const QString& accountUri,
                             const QString& deviceId)
{
    CallManager::instance().hangupParticipant(owner.id, confId, accountUri, deviceId);
}

void
CallModel::sendSipMessage(const QString& callId, const QString& body) const
{
    MapStringString payloads;
    payloads[TEXT_PLAIN] = body;

    CallManager::instance().sendTextMessage(owner.id, callId, payloads, true /* not used */);
}

bool
CallModel::isConferenceHost(const QString& callId)
{
    auto call = pimpl_->calls.find(callId);
    if (call == pimpl_->calls.end() or not call->second)
        return false;
    else
        return call->second->type == lrc::api::call::Type::CONFERENCE;
}

void
CallModelPimpl::slotMediaChangeRequested(const QString& accountId,
                                         const QString& callId,
                                         const VectorMapStringString& mediaList)
{
    if (linked.owner.id != accountId) {
        return;
    }

    if (mediaList.empty())
        return;

    auto& callInfo = calls[callId];
    if (!callInfo)
        return;

    QList<QString> currentMediaLabels {};
    for (auto& currentItem : callInfo->mediaList)
        currentMediaLabels.append(currentItem[MediaAttributeKey::LABEL]);

    auto answerMedia = QList<MapStringString>::fromVector(mediaList);

    for (auto& item : answerMedia) {
        int index = currentMediaLabels.indexOf(item[MediaAttributeKey::LABEL]);
        if (index >= 0) {
            item[MediaAttributeKey::MUTED] = callInfo->mediaList[index][MediaAttributeKey::MUTED];
            item[MediaAttributeKey::ENABLED] = callInfo->mediaList[index][MediaAttributeKey::ENABLED];
        } else {
            item[MediaAttributeKey::MUTED] = TRUE_STR;
            item[MediaAttributeKey::ENABLED] = TRUE_STR;
        }
    }
    CallManager::instance().answerMediaChangeRequest(linked.owner.id,
                                                     callId,
                                                     QVector<MapStringString>::fromList(
                                                         answerMedia));
}

void
CallModelPimpl::slotCallStateChanged(const QString& accountId,
                                     const QString& callId,
                                     const QString& state,
                                     int code)
{
    if (accountId != linked.owner.id)
        return;

    if (!linked.hasCall(callId)) {
        auto callInfo = std::make_shared<call::Info>();
        callInfo->id = callId;
        MapStringString details = CallManager::instance().getCallDetails(linked.owner.id, callId);
        qDebug() << details;

        auto endId = details["PEER_NUMBER"].indexOf("@");
        callInfo->peerUri = details["PEER_NUMBER"].left(endId);
        callInfo->isOutgoing = details["CALL_TYPE"] == "1";
        callInfo->status = call::to_status(state);
        callInfo->type = call::Type::DIALOG;
        callInfo->isAudioOnly = details["AUDIO_ONLY"] == TRUE_STR;
        callInfo->videoMuted = details["VIDEO_MUTED"] == TRUE_STR;
        callInfo->mediaList = {};
        calls.emplace(callId, std::move(callInfo));

        if (!(details["CALL_TYPE"] == "1") && !linked.owner.confProperties.allowIncoming
            && linked.owner.profileInfo.type == profile::Type::JAMI) {
            linked.refuse(callId);
            return;
        }

        QString displayname = details["DISPLAY_NAME"];
        QString peerId;
        QString peerUri = details["PEER_NUMBER"];
        if (peerUri.contains("ring.dht")) {
            peerId = peerUri.right(50);
            peerId = peerId.left(40);
            if (displayname.isEmpty())
                displayname = details["REGISTERED_NAME"];
        } else {
            auto left = std::max(peerUri.indexOf("<"), peerUri.indexOf(":")) + 1;
            auto right = peerUri.indexOf("@");
            right = std::max(right, peerUri.indexOf(">"));
            peerId = peerUri.mid(left, right - left);
            if (displayname.isEmpty())
                displayname = peerId;
        }
        qDebug() << displayname;
        qDebug() << peerId;

        Q_EMIT linked.newCall(peerId,
                              callId,
                              displayname,
                              details["CALL_TYPE"] == "1",
                              details["TO_USERNAME"]);

        // NOTE: signal emission order matters, always emit CallStatusChanged before CallEnded
        Q_EMIT linked.callStatusChanged(callId, code);
        Q_EMIT behaviorController.callStatusChanged(linked.owner.id, callId);
    }

    auto status = call::to_status(state);
    auto& call = calls[callId];
    if (!call)
        return;

    if (status == call::Status::ENDED && !call::isTerminating(call->status)) {
        call->status = call::Status::TERMINATING;
        Q_EMIT linked.callStatusChanged(callId, code);
        Q_EMIT behaviorController.callStatusChanged(linked.owner.id, callId);
    }

    // proper state transition
    auto previousStatus = call->status;
    call->status = status;

    if (previousStatus == call->status) {
        // call state didn't change, simply ignore signal
        return;
    }

    qDebug() << QString("slotCallStateChanged (call: %1), from %2 to %3")
                    .arg(callId)
                    .arg(call::to_string(previousStatus))
                    .arg(call::to_string(status));

    // NOTE: signal emission order matters, always emit CallStatusChanged before CallEnded
    Q_EMIT linked.callStatusChanged(callId, code);
    Q_EMIT behaviorController.callStatusChanged(linked.owner.id, callId);

    if (call->status == call::Status::ENDED) {
        Q_EMIT linked.callEnded(callId);

        // Remove from pendingConferences_
        for (int i = 0; i < pendingConferencees_.size(); ++i) {
            if (pendingConferencees_.at(i).callId == callId) {
                Q_EMIT linked.beginRemovePendingConferenceesRows(i);
                pendingConferencees_.removeAt(i);
                Q_EMIT linked.endRemovePendingConferenceesRows();
                break;
            }
        }
    } else if (call->status == call::Status::IN_PROGRESS) {
        if (previousStatus == call::Status::INCOMING_RINGING
            || previousStatus == call::Status::OUTGOING_RINGING) {
            call->startTime = std::chrono::steady_clock::now();
            Q_EMIT linked.callStarted(callId);
            sendProfile(callId);
        }
        // Add to calls if in pendingConferences_
        for (int i = 0; i < pendingConferencees_.size(); ++i) {
            if (pendingConferencees_.at(i).callId == callId) {
                linked.joinCalls(pendingConferencees_.at(i).callIdToJoin,
                                 pendingConferencees_.at(i).callId);
                break;
            }
        }
    } else if (call->status == call::Status::PAUSED) {
        currentCall_ = "";
    }
}

void
CallModelPimpl::slotMediaNegotiationStatus(const QString& callId,
                                           const QString&,
                                           const VectorMapStringString& mediaList)
{
    if (!linked.hasCall(callId)) {
        return;
    }

    auto& callInfo = calls[callId];
    if (!callInfo) {
        return;
    }

    callInfo->isAudioOnly = true;
    callInfo->videoMuted = true;
    for (const auto& item : mediaList) {
        if (item[MediaAttributeKey::MEDIA_TYPE] == MediaAttributeValue::VIDEO) {
            if (item[MediaAttributeKey::ENABLED] == TRUE_STR) {
                callInfo->isAudioOnly = false;
            }
            callInfo->videoMuted = checkMediaDeviceMuted(item);
        }
        if (item[MediaAttributeKey::MEDIA_TYPE] == MediaAttributeValue::AUDIO) {
            callInfo->audioMuted = checkMediaDeviceMuted(item);
        }
    }
    callInfo->mediaList = mediaList;
    if (callInfo->status == call::Status::IN_PROGRESS)
        Q_EMIT linked.callInfosChanged(linked.owner.id, callId);
}

void
CallModelPimpl::slotincomingVCardChunk(const QString& accountId,
                                       const QString& callId,
                                       const QString& from,
                                       int part,
                                       int numberOfParts,
                                       const QString& payload)
{
    if (accountId != linked.owner.id || !linked.hasCall(callId))
        return;

    auto it = vcardsChunks.find(from);
    if (it != vcardsChunks.end()) {
        vcardsChunks[from][part - 1] = payload;

        if (not std::any_of(vcardsChunks[from].begin(),
                            vcardsChunks[from].end(),
                            [](const auto& s) { return s.isEmpty(); })) {
            profile::Info profileInfo;
            profileInfo.uri = from;
            profileInfo.type = profile::Type::JAMI;

            QString vcardPhoto;

            for (auto& chunk : vcardsChunks[from])
                vcardPhoto += chunk;

            for (auto& e : QString(vcardPhoto).split("\n"))
                if (e.contains("PHOTO"))
                    profileInfo.avatar = e.split(":")[1];
                else if (e.contains("FN"))
                    profileInfo.alias = e.split(":")[1];

            contact::Info contactInfo;
            contactInfo.profileInfo = profileInfo;

            linked.owner.contactModel->addContact(contactInfo);
            contactInfo.profileInfo.avatar.clear(); // Do not want avatar in memory here
            vcardsChunks.erase(from); // Transfer is finish, we don't want to reuse this entry.
        }
    } else {
        vcardsChunks[from] = VectorString(numberOfParts);
        vcardsChunks[from][part - 1] = payload;
    }
}

void
CallModelPimpl::slotVoiceMailNotify(const QString& accountId,
                                    int newCount,
                                    int oldCount,
                                    int urgentCount)
{
    Q_EMIT linked.voiceMailNotify(accountId, newCount, oldCount, urgentCount);
}

void
CallModelPimpl::slotOnConferenceInfosUpdated(const QString& confId,
                                             const VectorMapStringString& infos)
{
    auto it = calls.find(confId);
    if (it == calls.end() or not it->second)
        return;

    // TODO: remove when the rendez-vous UI will be done
    // For now, the rendez-vous account can see ongoing calls
    // And must be notified when a new
    QStringList callList = CallManager::instance().getParticipantList(linked.owner.id, confId);
    Q_FOREACH (const auto& call, callList) {
        Q_EMIT linked.callAddedToConference(call, confId);
        if (calls.find(call) == calls.end()) {
            qWarning() << "Call not found";
        } else {
            calls[call]->videoMuted = it->second->videoMuted;
            calls[call]->audioMuted = it->second->audioMuted;
            Q_EMIT linked.callInfosChanged(linked.owner.id, call);
        }
    }

    auto participantIt = participantsModel.find(confId);
    if (participantIt == participantsModel.end())
        participantIt = participantsModel
                            .emplace(confId,
                                     std::make_shared<CallParticipants>(infos, confId, linked))
                            .first;
    else
        participantIt->second->update(infos);
    it->second->layout = participantIt->second->getLayout();

    // if Jami, remove @ring.dht
    for (auto& i : participantIt->second->getParticipants()) {
        i.uri.replace("@ring.dht", "");
        if (i.uri.isEmpty()) {
            if (it->second->type == call::Type::CONFERENCE) {
                i.uri = linked.owner.profileInfo.uri;
            } else {
                i.uri = it->second->peerUri.replace("ring:", "");
            }
        }
    }

    for (auto& info : infos) {
        if (info["uri"].isEmpty()) {
            it->second->videoMuted = info["videoMuted"] == TRUE_STR;
            it->second->audioMuted = info["audioLocalMuted"] == TRUE_STR;
        }
    }

    Q_EMIT linked.callInfosChanged(linked.owner.id, confId);
    Q_EMIT linked.participantsChanged(confId);
}

bool
CallModel::hasCall(const QString& callId) const
{
    return pimpl_->calls.find(callId) != pimpl_->calls.end();
}

void
CallModelPimpl::slotConferenceCreated(const QString& accountId, const QString& confId)
{
    if (accountId != linked.owner.id)
        return;
    QStringList callList = CallManager::instance().getParticipantList(linked.owner.id, confId);

    auto callInfo = std::make_shared<call::Info>();
    callInfo->id = confId;
    callInfo->status = call::Status::IN_PROGRESS;
    callInfo->type = call::Type::CONFERENCE;
    callInfo->startTime = std::chrono::steady_clock::now();

    VectorMapStringString infos = CallManager::instance().getConferenceInfos(linked.owner.id,
                                                                             confId);
    auto participantsPtr = std::make_shared<CallParticipants>(infos, confId, linked);
    callInfo->layout = participantsPtr->getLayout();
    VectorMapStringString mediaList = CallManager::instance().currentMediaList(linked.owner.id,
                                                                               confId);
    callInfo->mediaList = mediaList;
    participantsModel[confId] = participantsPtr;

    calls[confId] = callInfo;

    QString currentCallId = currentCall_;
    Q_FOREACH (const auto& call, callList) {
        Q_EMIT linked.callAddedToConference(call, confId);
        // Remove call from pendingConferences_
        for (int i = 0; i < pendingConferencees_.size(); ++i) {
            if (pendingConferencees_.at(i).callId == call) {
                Q_EMIT linked.beginRemovePendingConferenceesRows(i);
                pendingConferencees_.removeAt(i);
                Q_EMIT linked.endRemovePendingConferenceesRows();
                break;
            }
        }
        if (call == currentCall_)
            currentCall_ = confId;
    }
    if (currentCallId != currentCall_)
        Q_EMIT linked.currentCallChanged(confId);
}

void
CallModelPimpl::slotConferenceChanged(const QString& accountId,
                                      const QString& confId,
                                      const QString&)
{
    if (accountId != linked.owner.id)
        return;
    // Detect if conference is created for this account
    QStringList callList = CallManager::instance().getParticipantList(linked.owner.id, confId);
    QString currentCallId = currentCall_;
    Q_FOREACH (const auto& call, callList) {
        Q_EMIT linked.callAddedToConference(call, confId);
        if (call == currentCall_)
            currentCall_ = confId;
    }
    Q_EMIT linked.currentCallChanged(currentCall_);
}

void
CallModelPimpl::sendProfile(const QString& callId)
{
    auto vCard = linked.owner.accountModel->accountVCard(linked.owner.id);

    std::random_device rdev;
    auto key = std::to_string(dis(rdev));

    int i = 0;
    int total = vCard.size() / 1000 + (vCard.size() % 1000 ? 1 : 0);
    while (vCard.size()) {
        auto sizeLimit = std::min(1000, static_cast<int>(vCard.size()));
        MapStringString chunk;
        chunk[QString("%1; id=%2,part=%3,of=%4")
                  .arg(lrc::vCard::PROFILE_VCF)
                  .arg(key.c_str())
                  .arg(QString::number(i + 1))
                  .arg(QString::number(total))]
            = vCard.left(sizeLimit);
        vCard.remove(0, sizeLimit);
        ++i;
        CallManager::instance().sendTextMessage(linked.owner.id, callId, chunk, false);
    }
}

void
CallModelPimpl::onRemoteRecordingChanged(const QString& callId, const QString& peerUri, bool state)
{
    auto it = calls.find(callId);
    if (it == calls.end() or !it->second) {
        return;
    }

    auto uri = peerUri;

    if (uri.contains("ring:"))
        uri.remove("ring:");
    if (uri.contains("jami:"))
        uri.remove("jami:");
    if (uri.contains("@ring.dht"))
        uri.remove("@ring.dht");

    // Add/remove peer to recordingPeers, preventing duplicates.
    if (state && !it->second->recordingPeers.contains(uri))
        it->second->recordingPeers.append(uri);
    else if (!state && it->second->recordingPeers.contains(uri))
        it->second->recordingPeers.removeAll(uri);

    Q_EMIT linked.remoteRecordersChanged(callId, it->second->recordingPeers);
}

void
CallModelPimpl::onRecordingStateChanged(const QString& callId, bool state)
{
    Q_EMIT linked.recordingStateChanged(callId, state);
}

} // namespace lrc

#include "api/moc_callmodel.cpp"
#include "callmodel.moc"
