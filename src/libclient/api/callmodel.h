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

#include "api/behaviorcontroller.h"
#include "api/call.h"
#include "api/account.h"
#include "api/video.h"
#include "typedefs.h"

#include <QObject>

#include <memory>
#include <map>

namespace lrc {

class CallbacksHandler;
class CallModelPimpl;

namespace api {

namespace account {
struct Info;
}
namespace call {
struct Info;

struct PendingConferenceeInfo
{
    QString uri;
    QString callId;
    QString callIdToJoin;
};
} // namespace call
class AccountModel;
class CallParticipants;

/**
 *  @brief Class that manages call information.
 */
class LIB_EXPORT CallModel : public QObject
{
    Q_OBJECT

public:
    using CallInfoMap = std::map<QString, std::shared_ptr<call::Info>>;
    using CallParticipantsModelMap = std::map<QString, std::shared_ptr<CallParticipants>>;

    const account::Info& owner;

    enum class Media { NONE, AUDIO, VIDEO };
    enum class MediaRequestType { FILESHARING, SCREENSHARING, CAMERA };

    CallModel(const account::Info& owner,
              Lrc& lrc,
              const CallbacksHandler& callbacksHandler,
              const BehaviorController& behaviorController);
    ~CallModel();

    /**
     * Create a new call with a contact
     * @param  uri of the contact to call
     * @param  isAudioOnly, set to false by default
     * @return the call uid created. Empty string is returned if call is unable to be created.
     */
    QString createCall(const QString& uri,
                       bool isAudioOnly = false,
                       VectorMapStringString mediaList = {});
    /**
     * Add a new media to the current list
     * @param callId
     * @param source        Of the media
     * @param type          Audio/video
     * @param mute
     * @param shareAudio
     */
    void addMedia(const QString& callId,
                  const QString& source,
                  MediaRequestType type,
                  bool mute = false,
                  bool shareAudio = false);

    /**
     * get list of proposed medias
     * @param mediaList
     * @param callId
     * @param source        Of the media
     * @param type          Audio/video
     * @param mute
     * @param shareAudio
     */
    VectorMapStringString getProposed(VectorMapStringString mediaList,
                                      const QString& callId,
                                      const QString& source,
                                      MediaRequestType type,
                                      bool mute,
                                      bool shareAudio = false);
    /**
     * Mute a media
     * @param callId
     * @param label        Of the media (audio_0, video_0, etc)
     * @param mute
     */
    void muteMedia(const QString& callId, const QString& label, bool mute);
    /**
     * Remove a media from the current list
     * @param callId
     * @param source        Of the media
     * @param type          Audio/video
     * @param mute
     * @param removeAll     Remove Audio/Video
     */
    void removeMedia(const QString& callId,
                     const QString& mediaType,
                     const QString& type,
                     bool muteCamera,
                     bool removeAll);

    /**
     * Get the call from its call id
     * @param  uid
     * @return the callInfo
     * @throw out_of_range exception if not found
     */
    const call::Info& getCall(const QString& uid) const;

    /**
     * Get the call participantsInfos from its call id
     * @param  callId
     * @return the call participantsInfos
     * @throw out_of_range exception if not found
     */
    const CallParticipants& getParticipantsInfos(const QString& callId);

    /**
     * Get the call from the peer uri
     * @param  uri
     * @param  notOver search for a non finished call
     * @return the callInfo
     * @throw out_of_range exception if not found
     */
    const call::Info& getCallFromURI(const QString& uri, bool notOver = false) const;

    /**
     * Get conference from a peer uri
     * @param  uri
     * @return the callInfo
     * @throw out_of_range exception if not found
     */
    const call::Info& getConferenceFromURI(const QString& uri) const;

    /**
     * Helper: get subcalls list for a conference from daemon
     */
    VectorString getConferenceSubcalls(const QString& cid);

    /**
     * @param  callId to test
     * @return true if callId is presend else false.
     */
    bool hasCall(const QString& callId) const;

    /**
     * Send a text message to a SIP call
     * @param callId
     * @param body of the message
     */
    void sendSipMessage(const QString& callId, const QString& body) const;

    /**
     * Accept a call
     * @param callId
     */
    void accept(const QString& callId) const;

    /**
     * Hang up a call
     * @param callId
     */
    void hangUp(const QString& callId) const;

    /**
     * Refuse a call
     * @param callId
     */
    void refuse(const QString& callId) const;

    /**
     * Toggle audio record on a call
     * @param callId
     */
    void toggleAudioRecord(const QString& callId) const;

    /**
     * Play DTMF in a call
     * @param callId
     * @param value to play
     */
    void playDTMF(const QString& callId, const QString& value) const;

    /**
     * Toggle pause on a call.
     * @warn only use this function for SIP calls
     * @param callId
     */
    void togglePause(const QString& callId) const;

    /**
     * Not implemented yet
     */
    void setQuality(const QString& callId, const double quality) const;

    /**
     * Blind transfer. Directly transfer a call to a sip number
     * @param callId: the call to transfer
     * @param to: the sip number (for example: "sip:1412")
     */
    void transfer(const QString& callId, const QString& to) const;

    /**
     * Perform an attended. Transfer a call to another call
     * @param callIdSrc: the call to transfer
     * @param callIdDest: the destination's call
     */
    void transferToCall(const QString& callIdSrc, const QString& callIdDest) const;

    /**
     * Create a conference from 2 calls.
     * @param callIdA uid of the call A
     * @param callIdB uid of the call B
     */
    void joinCalls(const QString& callIdA, const QString& callIdB) const;

    /**
     * Call a participant and add it to a call
     * @param uri       URI of the participant
     * @param callId    Call receiving the participant
     * @param audioOnly If the call is audio only
     * @return id for a new call
     */
    QString callAndAddParticipant(const QString uri, const QString& callId, bool audioOnly);

    /**
     * Not implemented yet
     */
    void removeParticipant(const QString& callId, const QString& participant) const;

    /**
     * @param  callId
     * @return a human readable call duration (M:ss)
     */
    QString getFormattedCallDuration(const QString& callId) const;

    /**
     * Get if a call is recording
     * @param callId
     * @return true if the call is recording else false
     */
    bool isRecording(const QString& callId) const;
    /**
     * Extract Status Message From Status Map
     * @param statusCode
     * @return status message
     */
    static QString getSIPCallStatusString(const short& statusCode);

    /**
     * Set a call as the current call (hold other calls)
     */
    void setCurrentCall(const QString& callId) const;

    /**
     * Set whether the user's video media should be muted
     *
     * @param callId
     * @param videoMuted
     */
    void setVideoMuted(const QString& callId, bool videoMuted);

    /**
     * Change the conference layout
     */
    void setConferenceLayout(const QString& confId, const call::Layout& layout);

    /**
     * Set the shown participant
     * @param confId        The call to change
     * @param accountUri    Peer's uri
     * @param deviceId      Peer's device
     * @param sinkId        Peer's sinkId
     * @param state         new state wanted
     */
    void setActiveStream(const QString& confId,
                         const QString& accountUri,
                         const QString& deviceId,
                         const QString& sinkId,
                         bool state);

    /**
     * Check if a participant is a moderator or not
     * @param confId        The conference to check
     * @param uri           Uri of the participant to check (if empty, check current account)
     * @return if moderator
     */
    bool isModerator(const QString& confId, const QString& uri = "");

    /**
     * Set/unset a moderator
     * @param confId        The conference to change
     * @param peerId        Uri of the participant to change
     * @param state         State of the change (true set moderator / false unset moderator)
     */
    void setModerator(const QString& confId, const QString& peerId, const bool& state);

    /**
     * Check if a participant has raised hand
     * @param confId        The conference to check
     * @param uri           Uri of the participant to check (if empty, check current account)
     * @return if hand is raised
     */
    bool isHandRaised(const QString& confId, const QString& uri = "") noexcept;

    /**
     * Set/unset a moderator
     * @param confId        The conference to change
     * @param accountUri    Uri of the participant to change
     * @param deviceId      DeviceId of the participant to change
     * @param state         State of the change (true set hand raised / false unset hand raised)
     */
    void raiseHand(const QString& confId,
                   const QString& accountUri,
                   const QString& deviceId,
                   bool state);

    /**
     * Mute/unmute sink
     * @param confId        The conference to change
     * @param accountUri    Uri of the participant to mute
     * @param deviceId      Device Id of the participant to mute
     * @param streamId      Stream to mute
     * @param state         State of the change (true mute participant / false unmute participant)
     */
    void muteStream(const QString& confId,
                    const QString& accountUri,
                    const QString& deviceId,
                    const QString& streamId,
                    const bool& state);

    /**
     * Hangup participant from the conference
     * @param confId        The call to change
     * @param accountUri    Uri of the participant to mute
     * @param deviceId      Device Id of the participant to mute
     */
    void hangupParticipant(const QString& confId,
                           const QString& accountUri,
                           const QString& deviceId);

    /**
     * Check if a call is a conference or not
     * @param callId        The call to check
     * @return if conference
     */
    bool isConferenceHost(const QString& callId);

    /**
     * Get the list of lists of pending conferencees callId , contact uri, and join callId
     * @return pending conferencees
     */
    const QList<call::PendingConferenceeInfo>& getPendingConferencees();

    /**
     * Get information on the rendered device
     * @param call_id linked call to the renderer
     * @return the device rendered
     */
    video::RenderedDevice getCurrentRenderedDevice(const QString& call_id) const;

    void replaceDefaultCamera(const QString& callId, const QString& deviceId);
    /**
     * Get the current display resource string
     * @param idx of the display
     * @param x top left of the area
     * @param y top up of the area
     * @param w width of the area
     * @param h height of the area
     */
    QString getDisplay(int idx, int x, int y, int w, int h);
    /**
     * Get the current window resource string
     * @param windowProcessId
     * @param windowId
     */
    QString getDisplay(const QString& windowProcessId,
                       const QString& windowId,
                       const int fps = -1);

    void emplaceConversationConference(const QString& callId);

    /**
     * Get advanced information from every current call
     */
    QList<QVariant> getAdvancedInformation() const;

    MapStringString advancedInformationForCallId(QString callId) const;

    QStringList getCallIds() const;

Q_SIGNALS:

    /**
     * Emitted when a participant video is added to a conference
     * @param callId
     * @param index
     */
    void participantAdded(const QString& callId, int index) const;

    /**
     * Emitted when a participant video is removed from a conference
     * @param callId
     * @param index
     */
    void participantRemoved(const QString& callId, int index) const;

    /**
     * Emitted when, in a conference, participant parameters are changed
     * @param callId
     * @param index
     */
    void participantUpdated(const QString& callId, int index) const;

    /**
     * Emitted when a call state changes
     * @param callId
     */
    void callStatusChanged(const QString& accountId, const QString& callId, int code) const;
    /**
     * Emitted when the rendered image changed
     * @param confId
     */
    void participantsChanged(const QString& confId) const;
    /**
     * Emitted when a call starts
     * @param callId
     */
    void callStarted(const QString& callId) const;
    /**
     * Emitted when a call is over
     * @param callId
     */
    void callEnded(const QString& callId) const;
    /**
     * Emitted when a new call is available
     * @param peerId the peer uri
     * @param callId
     * @param displayname
     * @param isOutgoing
     * @param toUri             Generally account's uri for 1:1 calls, rdv uri for swarm-call
     */
    void newCall(const QString& peerId,
                 const QString& callId,
                 const QString& displayname,
                 bool isOutgoing,
                 const QString& toUri) const;
    /**
     * Emitted when a call is added to a conference
     * @param callId
     * @param conversationId
     * @param confId
     */
    void callAddedToConference(const QString& callId,
                               const QString& conversationId,
                               const QString& confId) const;

    /**
     * Emitted when a voice mail notice arrives
     * @param accountId
     * @param newCount
     * @param oldCount
     * @param urgentCount
     */
    void voiceMailNotify(const QString& accountId,
                         int newCount,
                         int oldCount,
                         int urgentCount) const;

    /**
     * Provides notification of a new set of recording peers once a change has occured,
     * in the form of a list, as QSet<QString> is not directly QML compatible.
     * @param callId
     * @param recorders
     */
    void remoteRecordersChanged(const QString& callId, const QStringList& recorders) const;

    /**
     * Provides notification of change in the local call recording state.,
     * @param callId
     * @param state
     */
    void recordingStateChanged(const QString& callId, bool state) const;

    /*!
     * Emitted before new pending conferences are inserted into the underlying list
     * @param position The starting row of the insertion
     * @param rows The number of items inserted
     */
    void beginInsertPendingConferenceesRows(int position, int rows = 1) const;

    //! Emitted once the insertion of new pending conferences is complete
    void endInsertPendingConferenceesRows() const;

    /*!
     * Emitted before new pending conferences are removed from the underlying list
     * @param position The starting row of the removal
     * @param rows The number of items removed
     */
    void beginRemovePendingConferenceesRows(int position, int rows = 1) const;

    //! Emitted once the removal of new pending conferences is complete
    void endRemovePendingConferenceesRows() const;

    /**
     * Emitted callInfosChanged
     */
    void callInfosChanged(const QString& accountId, const QString& callId) const;

    /**
     * Emit currentCallChanged
     */
    void currentCallChanged(const QString& callId) const;

private:
    std::unique_ptr<CallModelPimpl> pimpl_;
};
} // namespace api
} // namespace lrc
Q_DECLARE_METATYPE(lrc::api::CallModel*)
