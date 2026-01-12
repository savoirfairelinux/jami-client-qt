/****************************************************************************
 *   Copyright (C) 2017-2026 Savoir-faire Linux Inc.                        *
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

#include "profile.h"

#include "typedefs.h"

#include <memory>

#include <QString>
#include <QJsonObject>

namespace lrc {

namespace api {

class ContactModel;
class ConversationModel;
class CallModel;
class AccountModel;
class DeviceModel;
class CodecModel;
class PeerDiscoveryModel;
class DataTransferModel;

namespace account {
Q_NAMESPACE
Q_CLASSINFO("RegisterEnumClassesUnscoped", "false")

enum class Type { TYPE_INVALID, JAMI, SIP };
Q_ENUM_NS(Type)

#pragma push_macro("REGISTERED")
#undef REGISTERED

enum class Status { STATUS_INVALID, ERROR_NEED_MIGRATION, INITIALIZING, UNREGISTERED, TRYING, REGISTERED };
Q_ENUM_NS(Status)

static inline account::Status
to_status(const QString& type)
{
    if (type == "INITIALIZING")
        return account::Status::INITIALIZING;
    else if (type == "UNREGISTERED")
        return account::Status::UNREGISTERED;
    else if (type == "TRYING")
        return account::Status::TRYING;
    else if (type == "REGISTERED" || type == "READY")
        return account::Status::REGISTERED;
    else if (type == "ERROR_NEED_MIGRATION")
        return account::Status::ERROR_NEED_MIGRATION;
    else
        return account::Status::STATUS_INVALID;
}

#pragma pop_macro("REGISTERED")

enum class KeyExchangeProtocol { NONE, SDES };
Q_ENUM_NS(KeyExchangeProtocol)

struct ConfProperties_t
{
    QString mailbox;
    QString dtmfType;
    bool autoAnswer;
    bool denySecondCall;
    bool sendReadReceipt;
    bool sendComposing;
    bool isRendezVous;
    int activeCallLimit;
    QString hostname;
    QString username;
    QString routeset;
    QString password;
    QString realm;
    QString localInterface;
    QString deviceId;
    QString deviceName;
    QString managerUri;
    QString managerUsername;
    bool publishedSameAsLocal;
    int localPort;
    int publishedPort;
    QString publishedAddress;
    QString userAgent;
    bool upnpEnabled;
    bool hasCustomUserAgent;
    bool allowIncoming;
    bool allowIPAutoRewrite;
    QString archivePassword;
    bool archiveHasPassword;
    QString archivePath;
    QString archivePin;
    bool proxyEnabled;
    QString proxyServer;
    QString currentProxyServer;
    QString proxyPushToken;
    bool peerDiscovery;
    int dhtPort;
    bool accountDiscovery;
    bool accountPublish;
    int registrationExpire;
    bool keepAliveEnabled;
    QString bootstrapListUrl;
    QString dhtProxyListUrl;
    bool proxyListEnabled;
    QString defaultModerators;
    bool localModeratorsEnabled;
    VectorMapStringString credentials;
    QJsonObject uiCustomization;
    struct Audio_t
    {
        int audioPortMax;
        int audioPortMin;
    } Audio;
    struct Video_t
    {
        bool videoEnabled;
        int videoPortMax;
        int videoPortMin;
    } Video;
    struct STUN_t
    {
        QString server;
        bool enable;
    } STUN;
    struct TURN_t
    {
        QString server;
        bool enable;
        QString username;
        QString password;
        QString realm;
    } TURN;
    struct Presence_t
    {
        bool presencePublishSupported;
        bool presenceSubscribeSupported;
        bool presenceEnabled;
    } Presence;
    struct Ringtone_t
    {
        QString ringtonePath;
        bool ringtoneEnabled;
    } Ringtone;
    struct SRTP_t
    {
        KeyExchangeProtocol keyExchange;
        bool enable;
    } SRTP;
    struct TLS_t
    {
        int listenerPort;
        bool enable;
        int port;
        QString certificateListFile;
        QString certificateFile;
        QString privateKeyFile;
        QString password;
        bool verifyServer;
        bool verifyClient;
        bool requireClientCertificate;
        bool disableSecureDlgCheck;
    } TLS;
    struct DHT_t
    {
        bool PublicInCalls;
        bool AllowFromTrusted;
    } DHT;
    struct Nameserver_t
    {
        QString uri;
        QString account;
    } Nameserver;

    MapStringString toDetails() const;
};

// The following statuses are used to track the status of
// device-linking and account-import
enum class DeviceAuthState {
    INIT = 0,
    TOKEN_AVAILABLE = 1,
    CONNECTING = 2,
    AUTHENTICATING = 3,
    IN_PROGRESS = 4,
    DONE = 5
};
Q_ENUM_NS(DeviceAuthState)

enum class DeviceLinkError {
    WRONG_DEVICE_PASSWORD, // auth_error, invalid_credentials
    NETWORK,               // network
    TIMEOUT,               // timeout
    STATE,                 // state
    CANCELED,              // canceled
    UNKNOWN                // fallback
};

Q_ENUM_NS(DeviceLinkError)

inline DeviceLinkError
mapLinkDeviceError(const std::string& error)
{
    if (error == "auth_error" || error == "invalid_credentials")
        return DeviceLinkError::WRONG_DEVICE_PASSWORD;
    if (error == "network")
        return DeviceLinkError::NETWORK;
    if (error == "timeout")
        return DeviceLinkError::TIMEOUT;
    if (error == "state")
        return DeviceLinkError::STATE;
    if (error == "canceled")
        return DeviceLinkError::CANCELED;
    return DeviceLinkError::UNKNOWN;
}

inline QString
getLinkDeviceString(DeviceLinkError error)
{
    switch (error) {
    case DeviceLinkError::WRONG_DEVICE_PASSWORD:
        return QObject::tr(
            "An authentication error occurred while linking the device. Please check credentials and try again.");
    case DeviceLinkError::NETWORK:
        return QObject::tr(
            "A network error occurred while linking the account. Please verify your connection and try again.");
    case DeviceLinkError::TIMEOUT:
        return QObject::tr("The operation timed out. Please try again.");
    case DeviceLinkError::STATE:
        return QObject::tr("An error occurred while exporting the account. Please try again.");
    case DeviceLinkError::CANCELED:
        return QObject::tr("The operation was canceled by the user.");
    case DeviceLinkError::UNKNOWN:
    default:
        return QObject::tr("An unexpected error occurred while linking the device. Please try again.");
    }
}

enum class RegisterNameStatus {
    SUCCESS = 0,
    WRONG_PASSWORD = 1,
    RNS_INVALID_NAME = 2,
    ALREADY_TAKEN = 3,
    NETWORK_ERROR = 4,
    RNS_INVALID
};
Q_ENUM_NS(RegisterNameStatus)

enum class LookupStatus { SUCCESS = 0, LOOKUP_INVALID_NAME = 1, NOT_FOUND = 2, ERROR = 3, LOOKUP_INVALID };
Q_ENUM_NS(LookupStatus)

struct Info
{
    QString registeredName;
    Status status = account::Status::STATUS_INVALID;
    std::unique_ptr<lrc::api::CallModel> callModel;
    std::unique_ptr<lrc::api::ContactModel> contactModel;
    std::unique_ptr<lrc::api::ConversationModel> conversationModel;
    std::unique_ptr<lrc::api::DeviceModel> deviceModel;
    std::unique_ptr<lrc::api::CodecModel> codecModel;
    std::unique_ptr<lrc::api::PeerDiscoveryModel> peerDiscoveryModel;
    std::unique_ptr<DataTransferModel> dataTransferModel;
    AccountModel* accountModel {nullptr};

    // daemon config
    QString id;
    profile::Info profileInfo; // contains: type, alias
    bool enabled;
    ConfProperties_t confProperties;

    // load/save
    void fromDetails(const MapStringString& details);
};

} // namespace account
} // namespace api
} // namespace lrc
