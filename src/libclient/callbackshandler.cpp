/****************************************************************************
 *    Copyright (C) 2017-2023 Savoir-faire Linux Inc.                       *
 *   Author: Nicolas Jäger <nicolas.jager@savoirfairelinux.com>             *
 *   Author: Sébastien Blin <sebastien.blin@savoirfairelinux.com>           *
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
#include "callbackshandler.h"

// Models and database
#include "api/account.h"
#include "api/lrc.h"
#include "api/accountmodel.h"
#include "api/datatransfer.h"
#include "api/datatransfermodel.h"
#include "api/behaviorcontroller.h"

// Lrc
#include "dbus/callmanager.h"
#include "dbus/configurationmanager.h"
#include "dbus/presencemanager.h"
#include "dbus/videomanager.h"

#include "typedefs.h"

// libjami
#include <datatransfer_interface.h>

#include <QFileInfo>
#include <QUrl>
#include <QRegularExpression>

#ifdef ENABLE_LIBWRAP
// For the debugMessageReceived connection that queues const std::string refs
// when not using dbus
Q_DECLARE_METATYPE(std::string)
#endif

namespace lrc {

using namespace api;

static inline datatransfer::Status
convertDataTransferEvent(libjami::DataTransferEventCode event)
{
    switch (event) {
    case libjami::DataTransferEventCode::invalid:
        return datatransfer::Status::INVALID;
    case libjami::DataTransferEventCode::created:
        return datatransfer::Status::on_connection;
    case libjami::DataTransferEventCode::unsupported:
        return datatransfer::Status::unsupported;
    case libjami::DataTransferEventCode::wait_peer_acceptance:
        return datatransfer::Status::on_connection;
    case libjami::DataTransferEventCode::wait_host_acceptance:
        return datatransfer::Status::on_connection;
    case libjami::DataTransferEventCode::ongoing:
        return datatransfer::Status::on_progress;
    case libjami::DataTransferEventCode::finished:
        return datatransfer::Status::success;
    case libjami::DataTransferEventCode::closed_by_host:
        return datatransfer::Status::stop_by_host;
    case libjami::DataTransferEventCode::closed_by_peer:
        return datatransfer::Status::stop_by_peer;
    case libjami::DataTransferEventCode::invalid_pathname:
        return datatransfer::Status::invalid_pathname;
    case libjami::DataTransferEventCode::unjoinable_peer:
        return datatransfer::Status::unjoinable_peer;
    case libjami::DataTransferEventCode::timeout_expired:
        return datatransfer::Status::timeout_expired;
    }
    throw std::runtime_error("BUG: broken convertDataTransferEvent() switch");
}

CallbacksHandler::CallbacksHandler(const Lrc& parent)
    : QObject()
    , parent(parent)
{
    // Get signals from daemon
    connect(&ConfigurationManager::instance(),
            &ConfigurationManagerInterface::incomingAccountMessage,
            this,
            &CallbacksHandler::slotNewAccountMessage,
            Qt::QueuedConnection);

    connect(&PresenceManager::instance(),
            &PresenceManagerInterface::newBuddyNotification,
            this,
            &CallbacksHandler::slotNewBuddySubscription,
            Qt::QueuedConnection);

    connect(&PresenceManager::instance(),
            &PresenceManagerInterface::nearbyPeerNotification,
            this,
            &CallbacksHandler::slotNearbyPeerSubscription,
            Qt::QueuedConnection);

    connect(&ConfigurationManager::instance(),
            &ConfigurationManagerInterface::contactAdded,
            this,
            &CallbacksHandler::slotContactAdded,
            Qt::QueuedConnection);

    connect(&ConfigurationManager::instance(),
            &ConfigurationManagerInterface::contactRemoved,
            this,
            &CallbacksHandler::slotContactRemoved,
            Qt::QueuedConnection);

    connect(&ConfigurationManager::instance(),
            &ConfigurationManagerInterface::accountMessageStatusChanged,
            this,
            &CallbacksHandler::slotAccountMessageStatusChanged,
            Qt::QueuedConnection);

    connect(&ConfigurationManager::instance(),
            &ConfigurationManagerInterface::needsHost,
            this,
            &CallbacksHandler::slotNeedsHost,
            Qt::QueuedConnection);

    connect(&ConfigurationManager::instance(),
            &ConfigurationManagerInterface::accountDetailsChanged,
            this,
            &CallbacksHandler::slotAccountDetailsChanged,
            Qt::QueuedConnection);

    connect(&ConfigurationManager::instance(),
            &ConfigurationManagerInterface::volatileAccountDetailsChanged,
            this,
            &CallbacksHandler::slotVolatileAccountDetailsChanged,
            Qt::QueuedConnection);

    connect(&ConfigurationManager::instance(),
            &ConfigurationManagerInterface::accountsChanged,
            this,
            &CallbacksHandler::slotAccountsChanged);

    connect(&ConfigurationManager::instance(),
            &ConfigurationManagerInterface::registrationStateChanged,
            this,
            &CallbacksHandler::slotRegistrationStateChanged,
            Qt::QueuedConnection);

    connect(&CallManager::instance(),
            &CallManagerInterface::mediaChangeRequested,
            this,
            &CallbacksHandler::slotMediaChangeRequested,
            Qt::QueuedConnection);

    connect(&CallManager::instance(),
            &CallManagerInterface::callStateChanged,
            this,
            &CallbacksHandler::slotCallStateChanged,
            Qt::QueuedConnection);

    connect(&CallManager::instance(),
            &CallManagerInterface::mediaNegotiationStatus,
            this,
            &CallbacksHandler::slotMediaNegotiationStatus,
            Qt::QueuedConnection);

    connect(&CallManager::instance(),
            &CallManagerInterface::conferenceCreated,
            this,
            &CallbacksHandler::slotConferenceCreated,
            Qt::QueuedConnection);

    connect(&CallManager::instance(),
            &CallManagerInterface::conferenceRemoved,
            this,
            &CallbacksHandler::slotConferenceRemoved,
            Qt::QueuedConnection);

    connect(&CallManager::instance(),
            &CallManagerInterface::conferenceChanged,
            this,
            &CallbacksHandler::slotConferenceChanged,
            Qt::QueuedConnection);

    connect(&CallManager::instance(),
            &CallManagerInterface::recordingStateChanged,
            this,
            &CallbacksHandler::recordingStateChanged,
            Qt::QueuedConnection);

    connect(&CallManager::instance(),
            &CallManagerInterface::incomingMessage,
            this,
            &CallbacksHandler::slotIncomingMessage,
            Qt::QueuedConnection);

    connect(&CallManager::instance(),
            &CallManagerInterface::recordPlaybackStopped,
            this,
            &CallbacksHandler::slotRecordPlaybackStopped,
            Qt::QueuedConnection);

    connect(&CallManager::instance(),
            &CallManagerInterface::voiceMailNotify,
            this,
            &CallbacksHandler::slotVoiceMailNotify,
            Qt::QueuedConnection);

    connect(&CallManager::instance(),
            &CallManagerInterface::remoteRecordingChanged,
            this,
            &CallbacksHandler::slotRemoteRecordingChanged,
            Qt::QueuedConnection);

    connect(&ConfigurationManager::instance(),
            &ConfigurationManagerInterface::dataTransferEvent,
            this,
            &CallbacksHandler::slotDataTransferEvent,
            Qt::QueuedConnection);

    connect(&ConfigurationManager::instance(),
            &ConfigurationManagerInterface::knownDevicesChanged,
            this,
            &CallbacksHandler::slotKnownDevicesChanged,
            Qt::QueuedConnection);

    connect(&ConfigurationManager::instance(),
            &ConfigurationManagerInterface::deviceRevocationEnded,
            this,
            &CallbacksHandler::slotDeviceRevokationEnded,
            Qt::QueuedConnection);

    connect(&ConfigurationManager::instance(),
            &ConfigurationManagerInterface::accountProfileReceived,
            this,
            &CallbacksHandler::slotAccountProfileReceived,
            Qt::QueuedConnection);

    connect(&ConfigurationManager::instance(),
            &ConfigurationManagerInterface::exportOnRingEnded,
            this,
            &CallbacksHandler::slotExportOnRingEnded,
            Qt::QueuedConnection);

    connect(&ConfigurationManager::instance(),
            &ConfigurationManagerInterface::nameRegistrationEnded,
            this,
            &CallbacksHandler::slotNameRegistrationEnded,
            Qt::QueuedConnection);

    connect(&ConfigurationManager::instance(),
            &ConfigurationManagerInterface::registeredNameFound,
            this,
            &CallbacksHandler::slotRegisteredNameFound,
            Qt::QueuedConnection);

    connect(&ConfigurationManager::instance(),
            &ConfigurationManagerInterface::migrationEnded,
            this,
            &CallbacksHandler::slotMigrationEnded,
            Qt::QueuedConnection);

    connect(&VideoManager::instance(),
            &VideoManagerInterface::decodingStarted,
            this,
            &CallbacksHandler::decodingStarted,
            Qt::DirectConnection);

    connect(&VideoManager::instance(),
            &VideoManagerInterface::decodingStopped,
            this,
            &CallbacksHandler::decodingStopped,
            Qt::DirectConnection);

    connect(&VideoManager::instance(),
            &VideoManagerInterface::deviceEvent,
            this,
            &CallbacksHandler::deviceEvent,
            Qt::QueuedConnection);
    connect(&VideoManager::instance(),
            &VideoManagerInterface::fileOpened,
            this,
            &CallbacksHandler::fileOpened,
            Qt::DirectConnection);

    connect(&ConfigurationManager::instance(),
            &ConfigurationManagerInterface::audioDeviceEvent,
            this,
            &CallbacksHandler::slotAudioDeviceEvent,
            Qt::QueuedConnection);
    connect(&ConfigurationManager::instance(),
            &ConfigurationManagerInterface::audioMeter,
            this,
            &CallbacksHandler::slotAudioMeterReceived,
            Qt::QueuedConnection);
    connect(&ConfigurationManager::instance(),
            &ConfigurationManagerInterface::swarmLoaded,
            this,
            &CallbacksHandler::slotSwarmLoaded,
            Qt::QueuedConnection);
    connect(&ConfigurationManager::instance(),
            &ConfigurationManagerInterface::messagesFound,
            this,
            &CallbacksHandler::slotMessagesFound,
            Qt::QueuedConnection);
    connect(&ConfigurationManager::instance(),
            &ConfigurationManagerInterface::swarmMessageReceived,
            this,
            &CallbacksHandler::slotMessageReceived,
            Qt::QueuedConnection);
    connect(&ConfigurationManager::instance(),
            &ConfigurationManagerInterface::swarmMessageUpdated,
            this,
            &CallbacksHandler::slotMessageUpdated,
            Qt::QueuedConnection);
    connect(&ConfigurationManager::instance(),
            &ConfigurationManagerInterface::reactionAdded,
            this,
            &CallbacksHandler::slotReactionAdded,
            Qt::QueuedConnection);
    connect(&ConfigurationManager::instance(),
            &ConfigurationManagerInterface::reactionRemoved,
            this,
            &CallbacksHandler::slotReactionRemoved,
            Qt::QueuedConnection);
    connect(&ConfigurationManager::instance(),
            &ConfigurationManagerInterface::conversationProfileUpdated,
            this,
            &CallbacksHandler::slotConversationProfileUpdated,
            Qt::QueuedConnection);
    connect(&ConfigurationManager::instance(),
            &ConfigurationManagerInterface::conversationRequestReceived,
            this,
            &CallbacksHandler::slotConversationRequestReceived,
            Qt::QueuedConnection);
    connect(&ConfigurationManager::instance(),
            &ConfigurationManagerInterface::conversationRequestDeclined,
            this,
            &CallbacksHandler::slotConversationRequestDeclined,
            Qt::QueuedConnection);
    connect(&ConfigurationManager::instance(),
            &ConfigurationManagerInterface::conversationReady,
            this,
            &CallbacksHandler::slotConversationReady,
            Qt::QueuedConnection);
    connect(&ConfigurationManager::instance(),
            &ConfigurationManagerInterface::conversationRemoved,
            this,
            &CallbacksHandler::slotConversationRemoved,
            Qt::QueuedConnection);
    connect(&ConfigurationManager::instance(),
            &ConfigurationManagerInterface::conversationMemberEvent,
            this,
            &CallbacksHandler::slotConversationMemberEvent,
            Qt::QueuedConnection);
    connect(&ConfigurationManager::instance(),
            &ConfigurationManagerInterface::onConversationError,
            this,
            &CallbacksHandler::slotOnConversationError,
            Qt::QueuedConnection);
    connect(&ConfigurationManager::instance(),
            &ConfigurationManagerInterface::activeCallsChanged,
            this,
            &CallbacksHandler::slotActiveCallsChanged,
            Qt::QueuedConnection);
    connect(&ConfigurationManager::instance(),
            &ConfigurationManagerInterface::conversationPreferencesUpdated,
            this,
            &CallbacksHandler::slotConversationPreferencesUpdated,
            Qt::QueuedConnection);
}

CallbacksHandler::~CallbacksHandler() {}

void
CallbacksHandler::subscribeToDebugReceived()
{
    connect(&ConfigurationManager::instance(),
            &ConfigurationManagerInterface::messageSend,
            this,
            &CallbacksHandler::slotDebugMessageReceived,
            Qt::QueuedConnection);
}

void
CallbacksHandler::slotNewAccountMessage(const QString& accountId,
                                        const QString& peerId,
                                        const QString& msgId,
                                        const MapStringString& payloads)
{
    auto peerId2 = QString(peerId).replace("@ring.dht", "");
    for (const auto& payload : payloads.keys()) {
        if (payload.contains(APPLICATION_GEO)) {
            Q_EMIT newPosition(accountId, peerId, payloads.value(payload), 0, msgId);
            return;
        }
    }
    Q_EMIT newAccountMessage(accountId, peerId2, msgId, payloads);
}

void
CallbacksHandler::slotNewBuddySubscription(const QString& accountId,
                                           const QString& uri,
                                           bool status,
                                           const QString& message)
{
    Q_UNUSED(status)
    Q_UNUSED(message)
    Q_EMIT newBuddySubscription(accountId, uri, status);
}

void
CallbacksHandler::slotNearbyPeerSubscription(const QString& accountId,
                                             const QString& contactUri,
                                             int state,
                                             const QString& displayname)
{
    Q_EMIT newPeerSubscription(accountId, contactUri, state, displayname);
}

void
CallbacksHandler::slotVoiceMailNotify(const QString& accountId,
                                      int newCount,
                                      int oldCount,
                                      int urgentCount)
{
    Q_EMIT voiceMailNotify(accountId, newCount, oldCount, urgentCount);
}

void
CallbacksHandler::slotRecordPlaybackStopped(const QString& filePath)
{
    Q_EMIT recordPlaybackStopped(filePath);
}

void
CallbacksHandler::slotContactAdded(const QString& accountId,
                                   const QString& contactUri,
                                   bool confirmed)
{
    Q_EMIT contactAdded(accountId, contactUri, confirmed);
}

void
CallbacksHandler::slotContactRemoved(const QString& accountId,
                                     const QString& contactUri,
                                     bool banned)
{
    Q_EMIT contactRemoved(accountId, contactUri, banned);
}

void
CallbacksHandler::slotMediaChangeRequested(const QString& accountId,
                                           const QString& callId,
                                           const VectorMapStringString& mediaList)
{
    Q_EMIT mediaChangeRequested(accountId, callId, mediaList);
}

void
CallbacksHandler::slotCallStateChanged(const QString& accountId,
                                       const QString& callId,
                                       const QString& state,
                                       int code)
{
    Q_EMIT callStateChanged(accountId, callId, state, code);
}

void
CallbacksHandler::slotMediaNegotiationStatus(const QString& callId,
                                             const QString& event,
                                             const VectorMapStringString& mediaList)
{
    Q_EMIT mediaNegotiationStatus(callId, event, mediaList);
}

void
CallbacksHandler::slotAccountDetailsChanged(const QString& accountId, const MapStringString& details)
{
    Q_EMIT accountDetailsChanged(accountId, details);
}

void
CallbacksHandler::slotVolatileAccountDetailsChanged(const QString& accountId,
                                                    const MapStringString& details)
{
    Q_EMIT volatileAccountDetailsChanged(accountId, details);
}

void
CallbacksHandler::slotAccountsChanged()
{
    Q_EMIT accountsChanged();
}

void
CallbacksHandler::slotRegistrationStateChanged(const QString& accountId,
                                               const QString& registration_state,
                                               unsigned detail_code,
                                               const QString& detail_str)
{
    (void) detail_code;
    (void) detail_str;
    Q_EMIT accountStatusChanged(accountId, lrc::api::account::to_status(registration_state));
}

void
CallbacksHandler::slotIncomingMessage(const QString& accountId,
                                      const QString& callId,
                                      const QString& from,
                                      const MapStringString& interaction)
{
    QString from2;
    if (from.contains("@ring.dht")) {
        from2 = QString(from).replace("@ring.dht", "");
    } else {
        auto left = from.indexOf(":") + 1;
        auto right = from.indexOf("@");
        from2 = from.mid(left, right - left);
    }

    for (auto& e : interaction.toStdMap()) {
        if (e.first.contains("x-ring/ring.profile.vcard")) {
            auto decodedHead = QUrl::fromPercentEncoding(e.first.toLatin1());
            QRegularExpression re(
                "x-ring/ring.profile.vcard;id=([A-z0-9]+),part=([0-9]+),of=([0-9]+)");
            auto match = re.match(decodedHead);

            if (!match.hasMatch())
                continue;

            Q_EMIT incomingVCardChunk(accountId,
                                      callId,
                                      from2,
                                      match.captured(2).toInt(),
                                      match.captured(3).toInt(),
                                      e.second);
        } else if (e.first.contains(TEXT_PLAIN)) { // we consider it as an usual message interaction
            Q_EMIT incomingCallMessage(accountId, callId, from2, e.second);
        }
    }
}

void
CallbacksHandler::slotConferenceCreated(const QString& accountId, const QString& callId)
{
    Q_EMIT conferenceCreated(accountId, callId);
}

void
CallbacksHandler::slotConferenceRemoved(const QString& accountId, const QString& callId)
{
    Q_EMIT conferenceRemoved(accountId, callId);
}

void
CallbacksHandler::slotConferenceChanged(const QString& accountId,
                                        const QString& callId,
                                        const QString& state)
{
    Q_EMIT conferenceChanged(accountId, callId, state);
    slotCallStateChanged(accountId, callId, state, 0);
}

void
CallbacksHandler::slotAccountMessageStatusChanged(const QString& accountId,
                                                  const QString& conversationId,
                                                  const QString& peer,
                                                  const QString& messageId,
                                                  int status)
{
    Q_EMIT accountMessageStatusChanged(accountId, conversationId, peer, messageId, status);
}

void
CallbacksHandler::slotNeedsHost(const QString& accountId, const QString& conversationId)
{
    Q_EMIT needsHost(accountId, conversationId);
}

void
CallbacksHandler::slotDataTransferEvent(const QString& accountId,
                                        const QString& conversationId,
                                        const QString&,
                                        const QString& fileId,
                                        uint codeStatus)
{
    auto event = libjami::DataTransferEventCode(codeStatus);

    api::datatransfer::Info info;
    if (conversationId.isEmpty()) {
        return;
    } else {
        info.uid = fileId;
        info.status = convertDataTransferEvent(event);
        info.conversationId = conversationId;
        info.accountId = accountId;
        qlonglong totalSize, progress;
        QString path;
        try {
            parent.getAccountModel().getAccountInfo(accountId).dataTransferModel->fileTransferInfo(
                accountId, conversationId, fileId, path, totalSize, progress);
        } catch (...) {
            return;
        }
        auto fi = QFileInfo(path);
        if (fi.isSymLink()) {
            path = fi.symLinkTarget();
        }
        info.path = path;
        info.totalSize = totalSize;
        info.progress = progress;
    }

    // WARNING: info.status could be INVALID in case of async signaling
    // So listeners must only take account of fileId in such case.
    // Is useful for "termination" status like unjoinable_peer.

    switch (event) {
    case libjami::DataTransferEventCode::created:
        Q_EMIT transferStatusCreated(fileId, info);
        break;
    case libjami::DataTransferEventCode::closed_by_host:
    case libjami::DataTransferEventCode::closed_by_peer:
        Q_EMIT transferStatusCanceled(fileId, info);
        break;
    case libjami::DataTransferEventCode::wait_peer_acceptance:
        Q_EMIT transferStatusAwaitingPeer(fileId, info);
        break;
    case libjami::DataTransferEventCode::wait_host_acceptance:
        Q_EMIT transferStatusAwaitingHost(fileId, info);
        break;
    case libjami::DataTransferEventCode::ongoing:
        Q_EMIT transferStatusOngoing(fileId, info);
        break;
    case libjami::DataTransferEventCode::finished:
        Q_EMIT transferStatusFinished(fileId, info);
        break;
    case libjami::DataTransferEventCode::invalid_pathname:
    case libjami::DataTransferEventCode::unsupported:
        Q_EMIT transferStatusError(fileId, info);
        break;
    case libjami::DataTransferEventCode::timeout_expired:
        Q_EMIT transferStatusTimeoutExpired(fileId, info);
        break;
    case libjami::DataTransferEventCode::unjoinable_peer:
        Q_EMIT transferStatusUnjoinable(fileId, info);
        break;
    case libjami::DataTransferEventCode::invalid:
        break;
    }
}

void
CallbacksHandler::slotKnownDevicesChanged(const QString& accountId, const MapStringString& devices)
{
    Q_EMIT knownDevicesChanged(accountId, devices);
}

void
CallbacksHandler::slotDeviceRevokationEnded(const QString& accountId,
                                            const QString& deviceId,
                                            const int status)
{
    Q_EMIT deviceRevocationEnded(accountId, deviceId, status);
}

void
CallbacksHandler::slotAccountProfileReceived(const QString& accountId,
                                             const QString& displayName,
                                             const QString& userPhoto)
{
    Q_EMIT accountProfileReceived(accountId, displayName, userPhoto);
}

void
CallbacksHandler::slotExportOnRingEnded(const QString& accountId, int status, const QString& pin)
{
    Q_EMIT exportOnRingEnded(accountId, status, pin);
}

void
CallbacksHandler::slotNameRegistrationEnded(const QString& accountId,
                                            int status,
                                            const QString& name)
{
    Q_EMIT nameRegistrationEnded(accountId, status, name);
}

void
CallbacksHandler::slotRegisteredNameFound(const QString& accountId,
                                          int status,
                                          const QString& address,
                                          const QString& name)
{
    Q_EMIT registeredNameFound(accountId, status, address, name);
}

void
CallbacksHandler::slotMigrationEnded(const QString& accountId, const QString& status)
{
    Q_EMIT migrationEnded(accountId, status == "SUCCESS");
}

void
CallbacksHandler::slotDebugMessageReceived(const QString& message)
{
    Q_EMIT parent.getBehaviorController().debugMessageReceived(message);
}

void
CallbacksHandler::slotAudioDeviceEvent()
{
    Q_EMIT audioDeviceEvent();
}

void
CallbacksHandler::slotAudioMeterReceived(const QString& id, float level)
{
    Q_EMIT audioMeter(id, level);
}

void
CallbacksHandler::slotRemoteRecordingChanged(const QString& callId,
                                             const QString& peerNumber,
                                             bool state)
{
    Q_EMIT remoteRecordingChanged(callId, peerNumber, state);
}

void
CallbacksHandler::slotSwarmLoaded(uint32_t requestId,
                                  const QString& accountId,
                                  const QString& conversationId,
                                  const VectorSwarmMessage& messages)
{
    Q_EMIT swarmLoaded(requestId, accountId, conversationId, messages);
}

void
CallbacksHandler::slotMessagesFound(uint32_t requestId,
                                    const QString& accountId,
                                    const QString& conversationId,
                                    const VectorMapStringString& messages)
{
    Q_EMIT messagesFound(requestId, accountId, conversationId, messages);
}

void
CallbacksHandler::slotMessageReceived(const QString& accountId,
                                      const QString& conversationId,
                                      const SwarmMessage& message)
{
    Q_EMIT messageReceived(accountId, conversationId, message);
}

void
CallbacksHandler::slotMessageUpdated(const QString& accountId,
                                     const QString& conversationId,
                                     const SwarmMessage& message)
{
    Q_EMIT messageUpdated(accountId, conversationId, message);
}

void
CallbacksHandler::slotReactionAdded(const QString& accountId,
                                    const QString& conversationId,
                                    const QString& messageId,
                                    const MapStringString& reaction)
{
    Q_EMIT reactionAdded(accountId, conversationId, messageId, reaction);
}

void
CallbacksHandler::slotReactionRemoved(const QString& accountId,
                                      const QString& conversationId,
                                      const QString& messageId,
                                      const QString& reactionId)
{
    Q_EMIT reactionRemoved(accountId, conversationId, messageId, reactionId);
}

void
CallbacksHandler::slotConversationProfileUpdated(const QString& accountId,
                                                 const QString& conversationId,
                                                 const MapStringString& profile)
{
    Q_EMIT conversationProfileUpdated(accountId, conversationId, profile);
}

void
CallbacksHandler::slotConversationRequestReceived(const QString& accountId,
                                                  const QString& conversationId,
                                                  const MapStringString& metadatas)
{
    Q_EMIT conversationRequestReceived(accountId, conversationId, metadatas);
}

void
CallbacksHandler::slotConversationRequestDeclined(const QString& accountId,
                                                  const QString& conversationId)
{
    Q_EMIT conversationRequestDeclined(accountId, conversationId);
}

void
CallbacksHandler::slotConversationReady(const QString& accountId, const QString& conversationId)
{
    Q_EMIT conversationReady(accountId, conversationId);
}

void
CallbacksHandler::slotConversationRemoved(const QString& accountId, const QString& conversationId)
{
    Q_EMIT conversationRemoved(accountId, conversationId);
}

void
CallbacksHandler::slotConversationMemberEvent(const QString& accountId,
                                              const QString& conversationId,
                                              const QString& memberId,
                                              int event)
{
    Q_EMIT conversationMemberEvent(accountId, conversationId, memberId, event);
}

void
CallbacksHandler::slotOnConversationError(const QString& accountId,
                                          const QString& conversationId,
                                          int code,
                                          const QString& what)
{
    Q_EMIT conversationError(accountId, conversationId, code, what);
}

void
CallbacksHandler::slotActiveCallsChanged(const QString& accountId,
                                         const QString& conversationId,
                                         const VectorMapStringString& activeCalls)
{
    Q_EMIT activeCallsChanged(accountId, conversationId, activeCalls);
}

void
CallbacksHandler::slotConversationPreferencesUpdated(const QString& accountId,
                                                     const QString& conversationId,
                                                     const MapStringString& preferences)
{
    Q_EMIT conversationPreferencesUpdated(accountId, conversationId, preferences);
}

} // namespace lrc
