/*
 * Copyright (C) 2025 Savoir-faire Linux Inc.
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

#include "apiserver.h"
#include "apitokenmanager.h"
#include "lrcinstance.h"
#include "dbus/configurationmanager.h"
#include <namedirectory.h>

#include <api/accountmodel.h>
#include <api/conversationmodel.h>
#include <api/contactmodel.h>
#include <api/callmodel.h>
#include <api/account.h>
#include <api/call.h>
#include <api/contact.h>
#include <api/conversation.h>
#include <api/datatransfer.h>
#include <api/datatransfermodel.h>
#include <api/devicemodel.h>
#include <api/interaction.h>

#include <QRandomGenerator>
#include <QCryptographicHash>
#include <QDateTime>
#include <QDir>
#include <QEventLoop>
#include <QFile>
#include <QFileInfo>
#include <QMimeDatabase>
#include <QTcpServer>
#include <QTimer>
#include <QTimeZone>
#include <QUrlQuery>

#include <algorithm>

namespace {

QString
boolToString(bool value)
{
    return value ? QStringLiteral("true") : QStringLiteral("false");
}

struct NameLookupResult
{
    enum class State {
        NotAttempted,
        Success,
        Invalid,
        NotFound,
        Error,
        TimedOut,
    };

    State state = State::NotAttempted;
    QString requestedName;
    QString registeredName;
    QString address;
};

struct LookupApiResult
{
    bool started = false;
    bool timedOut = false;
    QString accountId;
    QString query;
    int state = 3;
    QString address;
    QString name;
};

bool
isHexString(const QString& value)
{
    if (value.isEmpty())
        return false;

    return std::all_of(value.cbegin(), value.cend(), [](const QChar& ch) {
        return ch.isDigit() || (ch.toLower() >= QChar(u'a') && ch.toLower() <= QChar(u'f'));
    });
}

bool
shouldResolveRegisteredName(const QString& identifier)
{
    const auto trimmed = identifier.trimmed();
    if (trimmed.isEmpty())
        return false;
    if (trimmed.contains(QLatin1Char(':')))
        return false;
    if ((trimmed.size() == 40 || trimmed.size() == 64) && isHexString(trimmed))
        return false;
    return true;
}

NameLookupResult
resolveRegisteredName(const QString& accountId, const QString& identifier, int timeoutMs = 5000)
{
    NameLookupResult result;
    result.requestedName = identifier;

    if (!shouldResolveRegisteredName(identifier))
        return result;

    QEventLoop loop;
    QTimer timer;
    timer.setSingleShot(true);

    auto& nameDirectory = NameDirectory::instance();
    QMetaObject::Connection nameFoundConnection;
    QMetaObject::Connection timeoutConnection;

    nameFoundConnection = QObject::connect(&nameDirectory,
                                           &NameDirectory::registeredNameFound,
                                           &loop,
                                           [&](NameDirectory::LookupStatus status,
                                               const QString& address,
                                               const QString& registeredName,
                                               const QString& requestedName) {
        if (requestedName != identifier)
            return;

        switch (status) {
        case NameDirectory::LookupStatus::SUCCESS:
            result.state = NameLookupResult::State::Success;
            result.address = address;
            result.registeredName = registeredName;
            break;
        case NameDirectory::LookupStatus::INVALID_NAME:
            result.state = NameLookupResult::State::Invalid;
            break;
        case NameDirectory::LookupStatus::NOT_FOUND:
            result.state = NameLookupResult::State::NotFound;
            break;
        case NameDirectory::LookupStatus::ERROR:
            result.state = NameLookupResult::State::Error;
            break;
        }

        loop.quit();
    });

    timeoutConnection = QObject::connect(&timer, &QTimer::timeout, &loop, [&]() {
        result.state = NameLookupResult::State::TimedOut;
        loop.quit();
    });

    if (!nameDirectory.lookupName(accountId, identifier)) {
        QObject::disconnect(nameFoundConnection);
        QObject::disconnect(timeoutConnection);
        result.state = NameLookupResult::State::Error;
        return result;
    }

    timer.start(timeoutMs);
    loop.exec();

    QObject::disconnect(nameFoundConnection);
    QObject::disconnect(timeoutConnection);
    return result;
}

QHttpServerResponse
nameLookupErrorResponse(NameLookupResult::State state)
{
    auto buildResponse = [](QHttpServerResponse::StatusCode code, const QString& message) {
        QJsonObject obj;
        obj["error"] = message;
        return QHttpServerResponse(obj, code);
    };

    switch (state) {
    case NameLookupResult::State::Invalid:
        return buildResponse(QHttpServerResponse::StatusCode::BadRequest, "Invalid registered name");
    case NameLookupResult::State::NotFound:
        return buildResponse(QHttpServerResponse::StatusCode::NotFound, "Registered name not found");
    case NameLookupResult::State::TimedOut:
        return buildResponse(QHttpServerResponse::StatusCode::RequestTimeout,
                             "Registered name lookup timed out");
    case NameLookupResult::State::Error:
        return buildResponse(QHttpServerResponse::StatusCode::InternalServerError,
                             "Registered name lookup failed");
    case NameLookupResult::State::NotAttempted:
    case NameLookupResult::State::Success:
        break;
    }

    return buildResponse(QHttpServerResponse::StatusCode::InternalServerError,
                         "Registered name lookup failed");
}

LookupApiResult
lookupNameForApi(const QString& accountId, const QString& username, int timeoutMs = 5000)
{
    LookupApiResult result;
    result.accountId = accountId;
    result.query = username;

    QEventLoop loop;
    QTimer timer;
    timer.setSingleShot(true);

    auto& configurationManager = ConfigurationManager::instance();
    QMetaObject::Connection resultConnection;
    QMetaObject::Connection timeoutConnection;

    resultConnection = QObject::connect(&configurationManager,
                                        &ConfigurationManagerInterface::registeredNameFound,
                                        &loop,
                                        [&](const QString& signalAccountId,
                                            const QString& requestedName,
                                            int state,
                                            const QString& address,
                                            const QString& registeredName) {
        if (requestedName != username)
            return;
        if (!accountId.isEmpty() && signalAccountId != accountId)
            return;

        result.started = true;
        result.accountId = signalAccountId;
        result.query = requestedName;
        result.state = state;
        result.address = address;
        result.name = registeredName;
        loop.quit();
    });

    timeoutConnection = QObject::connect(&timer, &QTimer::timeout, &loop, [&]() {
        result.timedOut = true;
        loop.quit();
    });

    if (!configurationManager.lookupName(accountId, QString {}, username)) {
        QObject::disconnect(resultConnection);
        QObject::disconnect(timeoutConnection);
        return result;
    }

    timer.start(timeoutMs);
    loop.exec();

    QObject::disconnect(resultConnection);
    QObject::disconnect(timeoutConnection);
    return result;
}

LookupApiResult
lookupAddressForApi(const QString& accountId, const QString& addressQuery, int timeoutMs = 5000)
{
    LookupApiResult result;
    result.accountId = accountId;
    result.query = addressQuery;

    QEventLoop loop;
    QTimer timer;
    timer.setSingleShot(true);

    auto& configurationManager = ConfigurationManager::instance();
    QMetaObject::Connection resultConnection;
    QMetaObject::Connection timeoutConnection;

    resultConnection = QObject::connect(&configurationManager,
                                        &ConfigurationManagerInterface::registeredNameFound,
                                        &loop,
                                        [&](const QString& signalAccountId,
                                            const QString& requestedAddress,
                                            int state,
                                            const QString& address,
                                            const QString& registeredName) {
        if (requestedAddress != addressQuery)
            return;
        if (!accountId.isEmpty() && signalAccountId != accountId)
            return;

        result.started = true;
        result.accountId = signalAccountId;
        result.query = requestedAddress;
        result.state = state;
        result.address = address;
        result.name = registeredName;
        loop.quit();
    });

    timeoutConnection = QObject::connect(&timer, &QTimer::timeout, &loop, [&]() {
        result.timedOut = true;
        loop.quit();
    });

    if (!configurationManager.lookupAddress(accountId, QString {}, addressQuery)) {
        QObject::disconnect(resultConnection);
        QObject::disconnect(timeoutConnection);
        return result;
    }

    timer.start(timeoutMs);
    loop.exec();

    QObject::disconnect(resultConnection);
    QObject::disconnect(timeoutConnection);
    return result;
}

LookupApiResult
searchUserForApi(const QString& accountId, const QString& username, int timeoutMs = 5000)
{
    LookupApiResult result;
    result.accountId = accountId;
    result.query = username;

    QEventLoop loop;
    QTimer timer;
    timer.setSingleShot(true);

    auto& configurationManager = ConfigurationManager::instance();
    QMetaObject::Connection resultConnection;
    QMetaObject::Connection timeoutConnection;

    resultConnection = QObject::connect(&configurationManager,
                                        &ConfigurationManagerInterface::userSearchEnded,
                                        &loop,
                                        [&](const QString& signalAccountId,
                                            int state,
                                            const QString& query,
                                            const VectorMapStringString& results) {
        if (query != username || signalAccountId != accountId)
            return;

        result.started = true;
        result.accountId = signalAccountId;
        result.query = query;
        result.state = state;
        if (!results.isEmpty()) {
            const auto& firstResult = results.first();
            result.address = firstResult.value(QStringLiteral("id"));
            result.name = firstResult.value(QStringLiteral("username"));
        }
        loop.quit();
    });

    timeoutConnection = QObject::connect(&timer, &QTimer::timeout, &loop, [&]() {
        result.timedOut = true;
        loop.quit();
    });

    if (!configurationManager.searchUser(accountId, username)) {
        QObject::disconnect(resultConnection);
        QObject::disconnect(timeoutConnection);
        return result;
    }

    timer.start(timeoutMs);
    loop.exec();

    QObject::disconnect(resultConnection);
    QObject::disconnect(timeoutConnection);
    return result;
}

QJsonObject
lookupApiResultToJson(const LookupApiResult& result)
{
    QJsonObject obj;
    obj["accountId"] = result.accountId;
    obj["query"] = result.query;
    obj["state"] = result.state;
    obj["address"] = result.address;
    obj["name"] = result.name;
    return obj;
}

QJsonObject
resolvedContactToCompatJson(const QString& identifier,
                            const QString& conversationId,
                            const NameLookupResult& lookup)
{
    QJsonObject obj;
    obj["id"] = lookup.address.isEmpty() ? identifier : lookup.address;
    obj["conversationId"] = conversationId;
    obj["added"] = QStringLiteral("false");
    obj["confirmed"] = QStringLiteral("false");
    obj["banned"] = QStringLiteral("false");
    obj["username"] = lookup.registeredName.isEmpty() ? identifier : lookup.registeredName;
    obj["displayName"] = obj["username"];
    return obj;
}

QHttpServerResponse
noContentResponse()
{
    return QHttpServerResponse(QJsonObject {}, QHttpServerResponse::StatusCode::NoContent);
}

QString
interactionTypeToMime(interaction::Type type)
{
    switch (type) {
    case interaction::Type::TEXT:
        return QStringLiteral("text/plain");
    case interaction::Type::CALL:
        return QStringLiteral("application/call-history+json");
    case interaction::Type::DATA_TRANSFER:
        return QStringLiteral("application/data-transfer+json");
    case interaction::Type::UPDATE_PROFILE:
        return QStringLiteral("application/update-profile");
    case interaction::Type::INITIAL:
        return QStringLiteral("initial");
    case interaction::Type::CONTACT:
        return QStringLiteral("member");
    case interaction::Type::MERGE:
        return QStringLiteral("merge");
    case interaction::Type::VOTE:
        return QStringLiteral("vote");
    default:
        return QStringLiteral("text/plain");
    }
}

int
interactionStatusCode(interaction::Status status)
{
    switch (status) {
    case interaction::Status::SENDING:
        return 1;
    case interaction::Status::SUCCESS:
        return 2;
    case interaction::Status::DISPLAYED:
        return 3;
    default:
        return 0;
    }
}

QString
conversationModeToCompat(const conversation::Info& conv)
{
    const auto mode = conv.infos.value(QStringLiteral("mode"));
    if (!mode.isEmpty())
        return mode;

    switch (conv.mode) {
    case conversation::Mode::ONE_TO_ONE:
    case conversation::Mode::NON_SWARM:
        return QStringLiteral("0");
    default:
        return QStringLiteral("1");
    }
}

QString
memberRoleToCompat(member::Role role)
{
    switch (role) {
    case member::Role::ADMIN:
        return QStringLiteral("admin");
    case member::Role::MEMBER:
        return QStringLiteral("member");
    case member::Role::INVITED:
        return QStringLiteral("invited");
    case member::Role::BANNED:
        return QStringLiteral("banned");
    case member::Role::LEFT:
        return QStringLiteral("left");
    }

    return QStringLiteral("member");
}

QJsonObject
interactionToCompatMessage(const account::Info& accInfo,
                           const QString& messageId,
                           const interaction::Info& interaction)
{
    QJsonObject obj;
    obj["id"] = messageId;
    obj["author"] = interaction.authorUri.isEmpty() ? accInfo.profileInfo.uri : interaction.authorUri;
    obj["timestamp"] = static_cast<qint64>(interaction.timestamp);
    obj["type"] = interactionTypeToMime(interaction.type);
    obj["body"] = interaction.body;
    obj["linearizedParent"] = interaction.parentId;
    obj["parents"] = interaction.parentId;
    QJsonArray reactionsArray;
    for (auto it = interaction.reactions.constBegin(); it != interaction.reactions.constEnd(); ++it) {
        const auto& authorUri = it.key();
        for (const auto& item : it.value().toList()) {
            auto emoji = item.value<interaction::Emoji>();
            QJsonObject reactionObj;
            reactionObj["id"] = emoji.commitId;
            reactionObj["author"] = authorUri;
            reactionObj["body"] = emoji.body;
            reactionsArray.append(reactionObj);
        }
    }
    obj["reactions"] = reactionsArray;

    if (!interaction.parentId.isEmpty())
        obj["reply-to"] = interaction.parentId;

    if (interaction.type == interaction::Type::DATA_TRANSFER) {
        // For file transfers, use the file metadata from the commit, not the author's name
        auto fileDisplayName = interaction.commit.value(QStringLiteral("displayName"));
        if (fileDisplayName.isEmpty()) {
            // Fall back to extracting filename from the body (local file path)
            QFileInfo fi(interaction.body);
            fileDisplayName = fi.fileName();
        }
        if (!fileDisplayName.isEmpty())
            obj["displayName"] = fileDisplayName;

        auto fileId = interaction.commit.value(QStringLiteral("fileId"));
        if (!fileId.isEmpty())
            obj["fileId"] = fileId;

        auto totalSize = interaction.commit.value(QStringLiteral("totalSize"));
        if (!totalSize.isEmpty())
            obj["totalSize"] = totalSize.toLongLong();

        auto sha3sum = interaction.commit.value(QStringLiteral("sha3sum"));
        if (!sha3sum.isEmpty())
            obj["sha3sum"] = sha3sum;
    } else {
        QString displayName;
        if (interaction.authorUri.isEmpty()) {
            displayName = accInfo.profileInfo.alias;
            if (displayName.isEmpty())
                displayName = accInfo.registeredName;
        } else if (accInfo.contactModel) {
            displayName = accInfo.contactModel->bestNameForContact(interaction.authorUri);
        }
        if (!displayName.isEmpty())
            obj["displayName"] = displayName;
    }

    QJsonObject status;
    const auto statusCode = interactionStatusCode(interaction.status);
    if (statusCode > 0)
        status["self"] = statusCode;
    obj["status"] = status;
    return obj;
}

QJsonObject
conversationInfosToCompat(const conversation::Info& conv)
{
    QJsonObject infos;
    infos["avatar"] = conv.infos.value(QStringLiteral("avatar"));
    infos["description"] = conv.infos.value(QStringLiteral("description"));
    infos["mode"] = conversationModeToCompat(conv);
    infos["title"] = conv.infos.value(QStringLiteral("title"));
    return infos;
}

QJsonObject
callToJsonObject(const call::Info& callInfo)
{
    QJsonObject obj = QJsonObject::fromVariantMap(callInfo.getCallInfoEx());
    obj["id"] = callInfo.id;
    obj["peerUri"] = callInfo.peerUri;
    obj["status"] = call::to_string(callInfo.status);
    obj["isOutgoing"] = callInfo.isOutgoing;
    obj["isAudioOnly"] = callInfo.isAudioOnly;
    obj["audioMuted"] = callInfo.audioMuted;
    obj["videoMuted"] = callInfo.videoMuted;
    return obj;
}

} // namespace

Q_LOGGING_CATEGORY(apiLog, "api")

// Helper to parse JSON body from request
static QJsonObject
parseJsonBody(const QHttpServerRequest& request)
{
    return QJsonDocument::fromJson(request.body()).object();
}

// Helper to create an error response
static QHttpServerResponse
errorResponse(QHttpServerResponse::StatusCode code, const QString& message)
{
    QJsonObject obj;
    obj["error"] = message;
    return QHttpServerResponse(obj, code);
}

ApiServer::ApiServer(LRCInstance* instance, QObject* parent)
    : QObject(parent)
    , lrcInstance_(instance)
{
}

ApiServer::~ApiServer()
{
    stop();
}

bool
ApiServer::start(quint16 port)
{
    if (tcpServer_ && tcpServer_->isListening())
        return true;

    if (!tokenManager_ && !externalTokenManager_)
        tokenManager_ = std::make_unique<ApiTokenManager>(this);
    generateApiToken();

    httpServer_ = std::make_unique<QHttpServer>();
    tcpServer_ = new QTcpServer();

    setupAccountRoutes();
    setupConversationRoutes();
    setupContactRoutes();
    setupCallRoutes();
    setupNameserverRoutes();
    setupTokenRoutes();

    if (!tcpServer_->listen(QHostAddress::LocalHost, port)) {
        qCWarning(apiLog) << "ApiServer: failed to listen on port" << port
                          << tcpServer_->errorString();
        delete tcpServer_;
        tcpServer_ = nullptr;
        return false;
    }

    // bind() reparents tcpServer_ to httpServer_, which takes ownership.
    if (!httpServer_->bind(tcpServer_)) {
        qCWarning(apiLog) << "ApiServer: failed to bind HTTP server";
        tcpServer_->close();
        delete tcpServer_;
        tcpServer_ = nullptr;
        return false;
    }

    setupWebSocket();

    auto actualPort = tcpServer_->serverPort();
    qCInfo(apiLog) << "ApiServer: listening on localhost:" << actualPort;
    Q_EMIT started(actualPort);
    return true;
}

void
ApiServer::stop()
{
    for (auto* ws : std::as_const(wsClients_)) {
        ws->close();
        ws->deleteLater();
    }
    wsClients_.clear();

    if (tcpServer_) {
        tcpServer_->close();
    }

    // httpServer_ owns tcpServer_ (via reparenting in bind()), so resetting
    // httpServer_ also deletes tcpServer_.
    httpServer_.reset();
    tcpServer_ = nullptr;

    qCInfo(apiLog) << "ApiServer: stopped";
    Q_EMIT stopped();
}

quint16
ApiServer::port() const
{
    return tcpServer_ && tcpServer_->isListening() ? tcpServer_->serverPort() : 0;
}

QString
ApiServer::apiToken() const
{
    return apiToken_;
}

ApiTokenManager*
ApiServer::tokenManager() const
{
    return externalTokenManager_ ? externalTokenManager_ : tokenManager_.get();
}

void
ApiServer::setTokenManager(ApiTokenManager* manager)
{
    externalTokenManager_ = manager;
}

// ── Authentication ──────────────────────────────────────────────────

void
ApiServer::generateApiToken()
{
    // Generate a cryptographically random 32-byte token with a jm_sk_ prefix.
    QByteArray bytes(32, 0);
    QRandomGenerator::securelySeeded().fillRange(reinterpret_cast<quint32*>(bytes.data()),
                                                  bytes.size() / sizeof(quint32));
    apiToken_ = QStringLiteral("jm_sk_") + QString::fromLatin1(bytes.toHex());
    qCInfo(apiLog) << "ApiServer: token =" << apiToken_;
}

QString
ApiServer::authenticate(const QHttpServerRequest& request, bool& ok) const
{
    ok = false;
    auto authHeader = request.value("Authorization");
    if (!authHeader.startsWith("Bearer "))
        return {};

    auto token = authHeader.mid(7).trimmed();

    // Check master token first (grants access to all accounts)
    if (token == apiToken_) {
        ok = true;
        return {}; // empty = all accounts
    }

    // Check per-account tokens via the token manager
    if (auto* tm = tokenManager()) {
        if (auto* info = tm->validateToken(token)) {
            ok = true;
            return info->accountId;
        }
    }

    return {};
}

QString
ApiServer::authenticateWs(const QString& token, bool& ok) const
{
    ok = false;
    if (token == apiToken_) {
        ok = true;
        return {};
    }
    if (auto* tm = tokenManager()) {
        if (auto* info = tm->validateToken(token)) {
            ok = true;
            return info->accountId;
        }
    }
    return {};
}

// ── JSON Helpers ────────────────────────────────────────────────────

QString
ApiServer::resolveCurrentAccountId(const QString& tokenScope) const
{
    if (!tokenScope.isEmpty())
        return tokenScope;

    const auto currentAccountId = lrcInstance_->get_currentAccountId();
    if (!currentAccountId.isEmpty())
        return currentAccountId;

    const auto accountList = lrcInstance_->accountModel().getAccountList();
    if (!accountList.isEmpty())
        return accountList.first();

    return {};
}

QJsonObject
ApiServer::accountToCompatJson(const QString& accountId) const
{
    try {
        const auto& info = lrcInstance_->accountModel().getAccountInfo(accountId);
        const auto detailsMap = info.confProperties.toDetails();

        QJsonObject details;
        for (auto it = detailsMap.cbegin(); it != detailsMap.cend(); ++it)
            details[it.key()] = it.value();
        // Ensure Account.username (the Jami URI/hash) is always present in details.
        // confProperties.toDetails() may omit it, but consumers like jami-web need it.
        if (!details.contains(QStringLiteral("Account.username")) && !info.profileInfo.uri.isEmpty())
            details[QStringLiteral("Account.username")] = info.profileInfo.uri;

        QJsonObject volatileDetails;
        volatileDetails["Account.active"] = boolToString(info.enabled);
        volatileDetails["Account.deviceAnnounced"] = detailsMap.value(QStringLiteral("Account.deviceAnnounced"));
        volatileDetails["Account.registeredName"] = info.registeredName;

        QString currentDeviceId;
        QJsonObject devices;
        if (info.deviceModel) {
            const auto allDevices = info.deviceModel->getAllDevices();
            for (const auto& device : allDevices) {
                devices[device.id] = device.name;
                if (device.isCurrent)
                    currentDeviceId = device.id;
            }
        }
        volatileDetails["Account.deviceID"] = currentDeviceId;

        QJsonArray defaultModerators;
        for (const auto& moderatorUri : lrcInstance_->accountModel().getDefaultModerators(accountId)) {
            QJsonObject moderator;
            moderator["uri"] = moderatorUri;
            if (info.contactModel) {
                try {
                    const auto registeredName = info.contactModel->getContact(moderatorUri).registeredName;
                    if (!registeredName.isEmpty())
                        moderator["registeredName"] = registeredName;
                } catch (...) {}
            }
            defaultModerators.append(moderator);
        }

        QJsonObject obj;
        obj["id"] = info.id;
        obj["details"] = details;
        obj["volatileDetails"] = volatileDetails;
        obj["defaultModerators"] = defaultModerators;
        obj["devices"] = devices;
        return obj;
    } catch (...) {
        return {};
    }
}

QJsonObject
ApiServer::conversationSummaryToCompatJson(const QString& accountId, const QString& convId) const
{
    try {
        const auto& accInfo = lrcInstance_->accountModel().getAccountInfo(accountId);
        auto* convModel = accInfo.conversationModel.get();
        auto optConv = convModel->getConversationForUid(convId);
        if (!optConv)
            return {};
        const auto& conv = optConv->get();

        QJsonArray membersNames;
        for (const auto& member : conv.participants) {
            const auto bestName = accInfo.contactModel ? accInfo.contactModel->bestNameForContact(member.uri) : QString {};
            membersNames.append(bestName.isEmpty() ? member.uri : bestName);
        }

        QJsonObject obj;
        obj["id"] = conv.uid;
        obj["avatar"] = conv.infos.value(QStringLiteral("avatar"));
        obj["title"] = conv.infos.value(QStringLiteral("title"));
        obj["mode"] = conversationModeToCompat(conv);
        obj["membersNames"] = membersNames;

        QJsonObject lastMessage;
        conv.interactions->withLast([&](const QString& messageId, interaction::Info& interaction) {
            lastMessage = interactionToCompatMessage(accInfo, messageId, interaction);
        });
        if (!lastMessage.isEmpty())
            obj["lastMessage"] = lastMessage;

        return obj;
    } catch (...) {
        return {};
    }
}

QJsonObject
ApiServer::contactToCompatJson(const QString& accountId,
                               const QString& uri,
                               const QString& conversationId) const
{
    try {
        const auto& accInfo = lrcInstance_->accountModel().getAccountInfo(accountId);
        const auto contact = accInfo.contactModel->getContact(uri);

        QJsonObject obj;
        obj["id"] = uri;
        obj["conversationId"] = conversationId;
        obj["added"] = boolToString(contact.isTrusted);
        obj["confirmed"] = boolToString(contact.isTrusted);
        obj["banned"] = boolToString(contact.isBanned);
        obj["username"] = contact.registeredName.isEmpty() ? contact.profileInfo.uri : contact.registeredName;
        const auto displayName = accInfo.contactModel->bestNameForContact(uri);
        obj["displayName"] = displayName.isEmpty() ? contact.profileInfo.alias : displayName;
        return obj;
    } catch (...) {
        if (uri.isEmpty())
            return {};

        QJsonObject obj;
        obj["id"] = uri;
        obj["conversationId"] = conversationId;
        obj["added"] = QStringLiteral("false");
        obj["confirmed"] = QStringLiteral("false");
        obj["banned"] = QStringLiteral("false");
        obj["username"] = uri;
        obj["displayName"] = uri;
        return obj;
    }
}

// ── Account Routes ──────────────────────────────────────────────────

void
ApiServer::setupAccountRoutes()
{
    // GET /api/account - Current account details
    httpServer_->route("/api/account", QHttpServerRequest::Method::Get,
                       [this](const QHttpServerRequest& request) {
        bool ok;
        const auto tokenScope = authenticate(request, ok);
        if (!ok)
            return errorResponse(QHttpServerResponse::StatusCode::Unauthorized, "Invalid token");

        const auto accountId = resolveCurrentAccountId(tokenScope);
        if (accountId.isEmpty())
            return errorResponse(QHttpServerResponse::StatusCode::NotFound, "Account not found");

        const auto obj = accountToCompatJson(accountId);
        if (obj.isEmpty())
            return errorResponse(QHttpServerResponse::StatusCode::NotFound, "Account not found");
        return QHttpServerResponse(obj);
    });
}

// ── Conversation Routes ─────────────────────────────────────────────

void
ApiServer::setupConversationRoutes()
{
    // GET /api/conversations
    httpServer_->route("/api/conversations", QHttpServerRequest::Method::Get,
                       [this](const QHttpServerRequest& request) {
        bool ok;
        const auto tokenScope = authenticate(request, ok);
        if (!ok)
            return errorResponse(QHttpServerResponse::StatusCode::Unauthorized, "Invalid token");

        const auto accountId = resolveCurrentAccountId(tokenScope);
        if (accountId.isEmpty())
            return errorResponse(QHttpServerResponse::StatusCode::NotFound, "Account not found");

        try {
            const auto& accInfo = lrcInstance_->accountModel().getAccountInfo(accountId);
            const auto& conversations = accInfo.conversationModel->getConversations();

            QJsonArray arr;
            for (const auto& conv : conversations)
                arr.append(conversationSummaryToCompatJson(accountId, conv.uid));
            return QHttpServerResponse(arr);
        } catch (...) {
            return errorResponse(QHttpServerResponse::StatusCode::NotFound, "Account not found");
        }
    });

    // POST /api/conversations - jami-web compatible 1:1 conversation creation
    httpServer_->route("/api/conversations", QHttpServerRequest::Method::Post,
                       [this](const QHttpServerRequest& request) {
        bool ok;
        const auto tokenScope = authenticate(request, ok);
        if (!ok)
            return errorResponse(QHttpServerResponse::StatusCode::Unauthorized, "Invalid token");

        const auto accountId = resolveCurrentAccountId(tokenScope);
        if (accountId.isEmpty())
            return errorResponse(QHttpServerResponse::StatusCode::NotFound, "Account not found");

        auto body = parseJsonBody(request);
        const auto members = body["members"].toArray();
        if (members.size() != 1)
            return errorResponse(QHttpServerResponse::StatusCode::BadRequest,
                                 "Exactly one member is required");

        try {
            const auto& accInfo = lrcInstance_->accountModel().getAccountInfo(accountId);
            VectorString uris;
            uris.append(members.first().toString());
            const auto convId = accInfo.conversationModel->createConversation(uris);
            return QHttpServerResponse(contactToCompatJson(accountId, uris.first(), convId));
        } catch (...) {
            return errorResponse(QHttpServerResponse::StatusCode::NotFound, "Member not found");
        }
    });

    // GET /api/conversations/<conversationId>
    httpServer_->route("/api/conversations/<arg>", QHttpServerRequest::Method::Get,
                       [this](const QString& convId, const QHttpServerRequest& request) {
        bool ok;
        const auto tokenScope = authenticate(request, ok);
        if (!ok)
            return errorResponse(QHttpServerResponse::StatusCode::Unauthorized, "Invalid token");

        const auto accountId = resolveCurrentAccountId(tokenScope);
        if (accountId.isEmpty())
            return errorResponse(QHttpServerResponse::StatusCode::NotFound, "Account not found");

        const auto obj = conversationSummaryToCompatJson(accountId, convId);
        if (obj.isEmpty())
            return errorResponse(QHttpServerResponse::StatusCode::NotFound, "Conversation not found");
        return QHttpServerResponse(obj);
    });

    // DELETE /api/conversations/<conversationId>
    httpServer_->route("/api/conversations/<arg>", QHttpServerRequest::Method::Delete,
                       [this](const QString& convId, const QHttpServerRequest& request) {
        bool ok;
        const auto tokenScope = authenticate(request, ok);
        if (!ok)
            return errorResponse(QHttpServerResponse::StatusCode::Unauthorized, "Invalid token");

        const auto accountId = resolveCurrentAccountId(tokenScope);
        if (accountId.isEmpty())
            return errorResponse(QHttpServerResponse::StatusCode::NotFound, "Account not found");

        try {
            const auto& accInfo = lrcInstance_->accountModel().getAccountInfo(accountId);
            accInfo.conversationModel->removeConversation(convId, false, true);
            return noContentResponse();
        } catch (...) {
            return errorResponse(QHttpServerResponse::StatusCode::NotFound, "Conversation not found");
        }
    });

    // GET /api/conversations/<conversationId>/messages
    httpServer_->route("/api/conversations/<arg>/messages", QHttpServerRequest::Method::Get,
                       [this](const QString& convId, const QHttpServerRequest& request) {
        bool ok;
        const auto tokenScope = authenticate(request, ok);
        if (!ok)
            return errorResponse(QHttpServerResponse::StatusCode::Unauthorized, "Invalid token");

        const auto accountId = resolveCurrentAccountId(tokenScope);
        if (accountId.isEmpty())
            return errorResponse(QHttpServerResponse::StatusCode::NotFound, "Account not found");

        try {
            const auto& accInfo = lrcInstance_->accountModel().getAccountInfo(accountId);
            auto optConv = accInfo.conversationModel->getConversationForUid(convId);
            if (!optConv)
                return errorResponse(QHttpServerResponse::StatusCode::NotFound, "Conversation not found");

            QJsonArray arr;
            optConv->get().interactions->forEach([&](const QString& messageId, interaction::Info& interaction) {
                arr.append(interactionToCompatMessage(accInfo, messageId, interaction));
            });
            return QHttpServerResponse(arr);
        } catch (...) {
            return errorResponse(QHttpServerResponse::StatusCode::NotFound, "Conversation not found");
        }
    });

    // POST /api/conversations/<conversationId>/messages
    httpServer_->route("/api/conversations/<arg>/messages", QHttpServerRequest::Method::Post,
                       [this](const QString& convId, const QHttpServerRequest& request) {
        bool ok;
        const auto tokenScope = authenticate(request, ok);
        if (!ok)
            return errorResponse(QHttpServerResponse::StatusCode::Unauthorized, "Invalid token");

        const auto accountId = resolveCurrentAccountId(tokenScope);
        if (accountId.isEmpty())
            return errorResponse(QHttpServerResponse::StatusCode::NotFound, "Account not found");

        auto body = parseJsonBody(request);
        QString messageBody = body["body"].toString();
        QString parentId = body["parentId"].toString();

        if (body.contains("message")) {
            const auto encodedMessage = body["message"].toString();
            if (messageBody.isEmpty() && !encodedMessage.isEmpty()) {
                const auto parsed = QJsonDocument::fromJson(encodedMessage.toUtf8()).object();
                messageBody = parsed["message"].toString(encodedMessage);
                parentId = parsed["replyTo"].toString(parsed["parentId"].toString());
            }
        }

        if (messageBody.isEmpty())
            return errorResponse(QHttpServerResponse::StatusCode::BadRequest, "Missing message in body");

        try {
            const auto& accInfo = lrcInstance_->accountModel().getAccountInfo(accountId);
            accInfo.conversationModel->sendMessage(convId, messageBody, parentId);
            return noContentResponse();
        } catch (...) {
            return errorResponse(QHttpServerResponse::StatusCode::NotFound, "Conversation not found");
        }
    });

    // POST /api/conversations/<conversationId>/reactions - Send a reaction
    httpServer_->route("/api/conversations/<arg>/reactions", QHttpServerRequest::Method::Post,
                       [this](const QString& convId, const QHttpServerRequest& request) {
        bool ok;
        const auto tokenScope = authenticate(request, ok);
        if (!ok)
            return errorResponse(QHttpServerResponse::StatusCode::Unauthorized, "Invalid token");

        const auto accountId = resolveCurrentAccountId(tokenScope);
        if (accountId.isEmpty())
            return errorResponse(QHttpServerResponse::StatusCode::NotFound, "Account not found");

        auto body = parseJsonBody(request);
        const auto emoji = body["emoji"].toString();
        const auto messageId = body["messageId"].toString();
        if (emoji.isEmpty() || messageId.isEmpty())
            return errorResponse(QHttpServerResponse::StatusCode::BadRequest,
                                 "Both 'emoji' and 'messageId' are required");

        try {
            const auto& accInfo = lrcInstance_->accountModel().getAccountInfo(accountId);
            accInfo.conversationModel->reactMessage(convId, emoji, messageId);
            return noContentResponse();
        } catch (...) {
            return errorResponse(QHttpServerResponse::StatusCode::NotFound, "Conversation not found");
        }
    });

    // GET /api/data/<conversationId>/<interactionId>/<fileId> - Download a file
    httpServer_->route("/api/data/<arg>/<arg>/<arg>", QHttpServerRequest::Method::Get,
                       [this](const QString& convId, const QString& interactionId, const QString& fileId, const QHttpServerRequest& request) {
        bool ok;
        const auto tokenScope = authenticate(request, ok);
        if (!ok)
            return errorResponse(QHttpServerResponse::StatusCode::Unauthorized, "Invalid token");

        const auto accountId = resolveCurrentAccountId(tokenScope);
        if (accountId.isEmpty())
            return errorResponse(QHttpServerResponse::StatusCode::NotFound, "Account not found");

        const auto& accInfo = lrcInstance_->accountModel().getAccountInfo(accountId);
        auto* dtModel = accInfo.dataTransferModel.get();

        // Ask the LRC for the file path and transfer progress
        QString path;
        qlonglong totalSize = 0, progress = 0;
        dtModel->fileTransferInfo(accountId, convId, fileId, path, totalSize, progress);

        // If the file is not yet fully downloaded, trigger download and wait for
        // the transferStatusChanged signal (same async pattern as name lookups).
        if (path.isEmpty() || (totalSize > 0 && progress < totalSize) || !QFile::exists(path)) {
            dtModel->download(accountId, convId, interactionId, fileId);

            QEventLoop loop;
            QTimer timer;
            timer.setSingleShot(true);

            auto statusConn = QObject::connect(dtModel,
                                               &lrc::api::DataTransferModel::transferStatusChanged,
                                               &loop,
                                               [&](const QString& uid, lrc::api::datatransfer::Status status) {
                if (uid != fileId)
                    return;
                if (status == lrc::api::datatransfer::Status::success
                    || status == lrc::api::datatransfer::Status::stop_by_peer
                    || status == lrc::api::datatransfer::Status::stop_by_host
                    || status == lrc::api::datatransfer::Status::unjoinable_peer
                    || status == lrc::api::datatransfer::Status::timeout_expired
                    || status == lrc::api::datatransfer::Status::invalid_pathname
                    || status == lrc::api::datatransfer::Status::unsupported) {
                    loop.quit();
                }
            });
            auto timeoutConn = QObject::connect(&timer, &QTimer::timeout, &loop, &QEventLoop::quit);

            timer.start(30000);
            loop.exec();

            QObject::disconnect(statusConn);
            QObject::disconnect(timeoutConn);

            // Re-query the path after download
            dtModel->fileTransferInfo(accountId, convId, fileId, path, totalSize, progress);
        }

        // Resolve symlinks (the daemon may use them)
        QFileInfo fi(path);
        if (fi.isSymLink())
            path = fi.symLinkTarget();

        QFile file(path);
        if (!file.open(QIODevice::ReadOnly)) {
            return errorResponse(QHttpServerResponse::StatusCode::NotFound, "File not available");
        }

        auto data = file.readAll();
        QMimeDatabase mimeDb;
        auto mimeType = mimeDb.mimeTypeForFileNameAndData(path, data);
        return QHttpServerResponse(mimeType.name().toUtf8(), data);
    });

    // POST /api/conversations/<conversationId>/files - Send a file
    httpServer_->route("/api/conversations/<arg>/files", QHttpServerRequest::Method::Post,
                       [this](const QString& convId, const QHttpServerRequest& request) {
        bool ok;
        const auto tokenScope = authenticate(request, ok);
        if (!ok)
            return errorResponse(QHttpServerResponse::StatusCode::Unauthorized, "Invalid token");

        const auto accountId = resolveCurrentAccountId(tokenScope);
        if (accountId.isEmpty())
            return errorResponse(QHttpServerResponse::StatusCode::NotFound, "Account not found");

        auto body = parseJsonBody(request);
        const auto filePath = body["path"].toString();
        auto fileName = body["filename"].toString();
        const auto parentId = body["parentId"].toString();
        if (filePath.isEmpty())
            return errorResponse(QHttpServerResponse::StatusCode::BadRequest, "Missing 'path'");

        if (fileName.isEmpty())
            fileName = QFileInfo(filePath).fileName();

        try {
            const auto& accInfo = lrcInstance_->accountModel().getAccountInfo(accountId);
            accInfo.conversationModel->sendFile(convId, filePath, fileName, parentId);
            return noContentResponse();
        } catch (...) {
            return errorResponse(QHttpServerResponse::StatusCode::NotFound, "Conversation not found");
        }
    });

    // GET /api/conversations/<conversationId>/infos
    httpServer_->route("/api/conversations/<arg>/infos", QHttpServerRequest::Method::Get,
                       [this](const QString& convId, const QHttpServerRequest& request) {
        bool ok;
        const auto tokenScope = authenticate(request, ok);
        if (!ok)
            return errorResponse(QHttpServerResponse::StatusCode::Unauthorized, "Invalid token");

        const auto accountId = resolveCurrentAccountId(tokenScope);
        if (accountId.isEmpty())
            return errorResponse(QHttpServerResponse::StatusCode::NotFound, "Account not found");

        try {
            const auto& accInfo = lrcInstance_->accountModel().getAccountInfo(accountId);
            auto optConv = accInfo.conversationModel->getConversationForUid(convId);
            if (!optConv)
                return errorResponse(QHttpServerResponse::StatusCode::NotFound, "Conversation not found");
            return QHttpServerResponse(conversationInfosToCompat(optConv->get()));
        } catch (...) {
            return errorResponse(QHttpServerResponse::StatusCode::NotFound, "Conversation not found");
        }
    });

    // GET /api/conversations/<conversationId>/members
    httpServer_->route("/api/conversations/<arg>/members", QHttpServerRequest::Method::Get,
                       [this](const QString& convId, const QHttpServerRequest& request) {
        bool ok;
        const auto tokenScope = authenticate(request, ok);
        if (!ok)
            return errorResponse(QHttpServerResponse::StatusCode::Unauthorized, "Invalid token");

        const auto accountId = resolveCurrentAccountId(tokenScope);
        if (accountId.isEmpty())
            return errorResponse(QHttpServerResponse::StatusCode::NotFound, "Account not found");

        try {
            const auto& accInfo = lrcInstance_->accountModel().getAccountInfo(accountId);
            auto optConv = accInfo.conversationModel->getConversationForUid(convId);
            if (!optConv)
                return errorResponse(QHttpServerResponse::StatusCode::NotFound, "Conversation not found");

            QJsonArray arr;
            for (const auto& participant : optConv->get().participants) {
                QJsonObject contact;
                contact["uri"] = participant.uri;
                if (accInfo.contactModel) {
                    try {
                        const auto registeredName = accInfo.contactModel->getContact(participant.uri).registeredName;
                        if (!registeredName.isEmpty())
                            contact["registeredName"] = registeredName;
                    } catch (...) {}
                }

                QJsonObject member;
                member["role"] = memberRoleToCompat(participant.role);
                member["contact"] = contact;
                arr.append(member);
            }
            return QHttpServerResponse(arr);
        } catch (...) {
            return errorResponse(QHttpServerResponse::StatusCode::NotFound, "Conversation not found");
        }
    });

    // GET /api/conversation-requests
    httpServer_->route("/api/conversation-requests", QHttpServerRequest::Method::Get,
                       [this](const QHttpServerRequest& request) {
        bool ok;
        const auto tokenScope = authenticate(request, ok);
        if (!ok)
            return errorResponse(QHttpServerResponse::StatusCode::Unauthorized, "Invalid token");

        const auto accountId = resolveCurrentAccountId(tokenScope);
        if (accountId.isEmpty())
            return errorResponse(QHttpServerResponse::StatusCode::NotFound, "Account not found");

        try {
            const auto& accInfo = lrcInstance_->accountModel().getAccountInfo(accountId);
            const auto& requests = accInfo.conversationModel->getFilteredConversations(lrc::api::FilterType::REQUEST);

            QJsonArray arr;
            for (size_t requestIndex = 0; requestIndex < requests.size(); ++requestIndex) {
                const auto& requestConv = requests.at(requestIndex);
                QString fromUri;
                for (const auto& participant : requestConv.participants) {
                    if (participant.uri != accInfo.profileInfo.uri) {
                        fromUri = participant.uri;
                        break;
                    }
                }

                QJsonObject from;
                from["uri"] = fromUri;
                if (accInfo.contactModel && !fromUri.isEmpty()) {
                    try {
                        const auto contact = accInfo.contactModel->getContact(fromUri);
                        if (!contact.registeredName.isEmpty())
                            from["registeredName"] = contact.registeredName;
                    } catch (...) {}
                }

                QString received;
                requestConv.interactions->withLast([&](const QString&, interaction::Info& interaction) {
                    received = QDateTime::fromSecsSinceEpoch(interaction.timestamp, QTimeZone::UTC)
                                   .toString(Qt::ISODate);
                });
                if (received.isEmpty())
                    received = QDateTime::currentDateTimeUtc().toString(Qt::ISODate);

                QJsonArray membersNames;
                for (const auto& participant : requestConv.participants) {
                    if (participant.uri == accInfo.profileInfo.uri)
                        continue;
                    const auto bestName = accInfo.contactModel ? accInfo.contactModel->bestNameForContact(participant.uri)
                                                               : QString {};
                    membersNames.append(bestName.isEmpty() ? participant.uri : bestName);
                }

                QJsonObject requestObj;
                requestObj["conversationId"] = requestConv.uid;
                requestObj["infos"] = conversationInfosToCompat(requestConv);
                requestObj["from"] = from;
                requestObj["received"] = received;
                requestObj["membersNames"] = membersNames;
                arr.append(requestObj);
            }

            return QHttpServerResponse(arr);
        } catch (...) {
            return errorResponse(QHttpServerResponse::StatusCode::NotFound, "Account not found");
        }
    });

    // POST /api/conversation-requests/<conversationId>
    httpServer_->route("/api/conversation-requests/<arg>", QHttpServerRequest::Method::Post,
                       [this](const QString& convId, const QHttpServerRequest& request) {
        bool ok;
        const auto tokenScope = authenticate(request, ok);
        if (!ok)
            return errorResponse(QHttpServerResponse::StatusCode::Unauthorized, "Invalid token");

        const auto accountId = resolveCurrentAccountId(tokenScope);
        if (accountId.isEmpty())
            return errorResponse(QHttpServerResponse::StatusCode::NotFound, "Account not found");

        try {
            const auto& accInfo = lrcInstance_->accountModel().getAccountInfo(accountId);
            accInfo.conversationModel->acceptConversationRequest(convId);
            const auto summary = conversationSummaryToCompatJson(accountId, convId);
            if (!summary.isEmpty())
                return QHttpServerResponse(summary);
            return noContentResponse();
        } catch (...) {
            return errorResponse(QHttpServerResponse::StatusCode::NotFound, "Conversation not found");
        }
    });

    // DELETE /api/conversation-requests/<conversationId>
    httpServer_->route("/api/conversation-requests/<arg>", QHttpServerRequest::Method::Delete,
                       [this](const QString& convId, const QHttpServerRequest& request) {
        bool ok;
        const auto tokenScope = authenticate(request, ok);
        if (!ok)
            return errorResponse(QHttpServerResponse::StatusCode::Unauthorized, "Invalid token");

        const auto accountId = resolveCurrentAccountId(tokenScope);
        if (accountId.isEmpty())
            return errorResponse(QHttpServerResponse::StatusCode::NotFound, "Account not found");

        try {
            const auto& accInfo = lrcInstance_->accountModel().getAccountInfo(accountId);
            accInfo.conversationModel->removeConversation(convId, false);
            return noContentResponse();
        } catch (...) {
            return errorResponse(QHttpServerResponse::StatusCode::NotFound, "Conversation not found");
        }
    });

    // POST /api/conversation-requests/<conversationId>/block
    httpServer_->route("/api/conversation-requests/<arg>/block", QHttpServerRequest::Method::Post,
                       [this](const QString& convId, const QHttpServerRequest& request) {
        bool ok;
        const auto tokenScope = authenticate(request, ok);
        if (!ok)
            return errorResponse(QHttpServerResponse::StatusCode::Unauthorized, "Invalid token");

        const auto accountId = resolveCurrentAccountId(tokenScope);
        if (accountId.isEmpty())
            return errorResponse(QHttpServerResponse::StatusCode::NotFound, "Account not found");

        try {
            const auto& accInfo = lrcInstance_->accountModel().getAccountInfo(accountId);
            accInfo.conversationModel->removeConversation(convId, true);
            return noContentResponse();
        } catch (...) {
            return errorResponse(QHttpServerResponse::StatusCode::NotFound, "Conversation not found");
        }
    });
}

// ── Contact Routes ──────────────────────────────────────────────────

void
ApiServer::setupContactRoutes()
{
    // GET /api/contacts
    httpServer_->route("/api/contacts", QHttpServerRequest::Method::Get,
                       [this](const QHttpServerRequest& request) {
        bool ok;
        const auto tokenScope = authenticate(request, ok);
        if (!ok)
            return errorResponse(QHttpServerResponse::StatusCode::Unauthorized, "Invalid token");

        const auto accountId = resolveCurrentAccountId(tokenScope);
        if (accountId.isEmpty())
            return errorResponse(QHttpServerResponse::StatusCode::NotFound, "Account not found");

        try {
            const auto& accInfo = lrcInstance_->accountModel().getAccountInfo(accountId);
            const auto& contacts = accInfo.contactModel->getAllContacts();

            QJsonArray arr;
            for (auto it = contacts.constBegin(); it != contacts.constEnd(); ++it)
                arr.append(contactToCompatJson(accountId, it.key()));
            return QHttpServerResponse(arr);
        } catch (...) {
            return errorResponse(QHttpServerResponse::StatusCode::NotFound, "Account not found");
        }
    });

    // GET /api/contacts/<contactId>
    httpServer_->route("/api/contacts/<arg>", QHttpServerRequest::Method::Get,
                       [this](const QString& contactUri, const QHttpServerRequest& request) {
        bool ok;
        const auto tokenScope = authenticate(request, ok);
        if (!ok)
            return errorResponse(QHttpServerResponse::StatusCode::Unauthorized, "Invalid token");

        const auto accountId = resolveCurrentAccountId(tokenScope);
        if (accountId.isEmpty())
            return errorResponse(QHttpServerResponse::StatusCode::NotFound, "Account not found");

        auto obj = contactToCompatJson(accountId, contactUri);
        if (obj["username"].toString() == contactUri && obj["id"].toString() == contactUri) {
            const auto lookup = resolveRegisteredName(accountId, contactUri);
            if (lookup.state == NameLookupResult::State::Success)
                obj = resolvedContactToCompatJson(contactUri, QString {}, lookup);
            else if (lookup.state != NameLookupResult::State::NotAttempted)
                return nameLookupErrorResponse(lookup.state);
        }
        if (obj.isEmpty())
            return errorResponse(QHttpServerResponse::StatusCode::NotFound, "Contact not found");
        return QHttpServerResponse(obj);
    });

    // PUT /api/contacts/<contactId>
    httpServer_->route("/api/contacts/<arg>", QHttpServerRequest::Method::Put,
                       [this](const QString& contactUri, const QHttpServerRequest& request) {
        bool ok;
        const auto tokenScope = authenticate(request, ok);
        if (!ok)
            return errorResponse(QHttpServerResponse::StatusCode::Unauthorized, "Invalid token");

        const auto accountId = resolveCurrentAccountId(tokenScope);
        if (accountId.isEmpty())
            return errorResponse(QHttpServerResponse::StatusCode::NotFound, "Account not found");

        try {
            const auto& accInfo = lrcInstance_->accountModel().getAccountInfo(accountId);
            contact::Info contactInfo;
            contactInfo.profileInfo.uri = contactUri;
            contactInfo.profileInfo.type = profile::Type::TEMPORARY;
            accInfo.contactModel->addContact(contactInfo);
            return QHttpServerResponse(contactToCompatJson(accountId, contactUri));
        } catch (...) {
            return errorResponse(QHttpServerResponse::StatusCode::NotFound, "Contact not found");
        }
    });

    // DELETE /api/contacts/<contactId>
    httpServer_->route("/api/contacts/<arg>", QHttpServerRequest::Method::Delete,
                       [this](const QString& contactUri, const QHttpServerRequest& request) {
        bool ok;
        const auto tokenScope = authenticate(request, ok);
        if (!ok)
            return errorResponse(QHttpServerResponse::StatusCode::Unauthorized, "Invalid token");

        const auto accountId = resolveCurrentAccountId(tokenScope);
        if (accountId.isEmpty())
            return errorResponse(QHttpServerResponse::StatusCode::NotFound, "Account not found");

        try {
            const auto& accInfo = lrcInstance_->accountModel().getAccountInfo(accountId);
            accInfo.contactModel->removeContact(contactUri);
            return noContentResponse();
        } catch (...) {
            return errorResponse(QHttpServerResponse::StatusCode::NotFound, "Contact not found");
        }
    });
}

// ── Call Routes ─────────────────────────────────────────────────────

void
ApiServer::setupCallRoutes()
{
    // GET /api/calls
    httpServer_->route("/api/calls", QHttpServerRequest::Method::Get,
                       [this](const QHttpServerRequest& request) {
        bool ok;
        const auto tokenScope = authenticate(request, ok);
        if (!ok)
            return errorResponse(QHttpServerResponse::StatusCode::Unauthorized, "Invalid token");

        const auto accountId = resolveCurrentAccountId(tokenScope);
        if (accountId.isEmpty())
            return errorResponse(QHttpServerResponse::StatusCode::NotFound, "Account not found");

        try {
            const auto& accInfo = lrcInstance_->accountModel().getAccountInfo(accountId);
            QJsonArray arr;
            for (const auto& callId : accInfo.callModel->getCallIds())
                arr.append(callId);
            return QHttpServerResponse(arr);
        } catch (...) {
            return errorResponse(QHttpServerResponse::StatusCode::NotFound, "Account not found");
        }
    });

    // GET /api/calls/<callId>
    httpServer_->route("/api/calls/<arg>", QHttpServerRequest::Method::Get,
                       [this](const QString& callId, const QHttpServerRequest& request) {
        bool ok;
        const auto tokenScope = authenticate(request, ok);
        if (!ok)
            return errorResponse(QHttpServerResponse::StatusCode::Unauthorized, "Invalid token");

        const auto accountId = resolveCurrentAccountId(tokenScope);
        if (accountId.isEmpty())
            return errorResponse(QHttpServerResponse::StatusCode::NotFound, "Call not found");

        if (const auto* callInfo = lrcInstance_->getCallInfo(callId, accountId))
            return QHttpServerResponse(callToJsonObject(*callInfo));
        return errorResponse(QHttpServerResponse::StatusCode::NotFound, "Call not found");
    });
}

// ── Token Routes ────────────────────────────────────────────────────

void
ApiServer::setupTokenRoutes()
{
    // POST /api/tokens
    httpServer_->route("/api/tokens", QHttpServerRequest::Method::Post,
                       [this](const QHttpServerRequest& request) {
        bool ok;
        const auto tokenScope = authenticate(request, ok);
        if (!ok)
            return errorResponse(QHttpServerResponse::StatusCode::Unauthorized, "Invalid token");

        const auto accountId = resolveCurrentAccountId(tokenScope);
        if (accountId.isEmpty())
            return errorResponse(QHttpServerResponse::StatusCode::NotFound, "Account not found");

        const auto body = parseJsonBody(request);
        const auto name = body["name"].toString(body["label"].toString());
        if (name.trimmed().isEmpty())
            return errorResponse(QHttpServerResponse::StatusCode::BadRequest, "Missing or invalid token name");

        QStringList scopes;
        for (const auto& scope : body["scopes"].toArray())
            scopes.append(scope.toString());

        const auto expiresIn = body["expiresIn"].toInt(0);
        const auto result = tokenManager()->createTokenWithLifetimeSeconds(accountId, name, scopes, expiresIn);

        QJsonObject info;
        info["id"] = result.info.id;
        info["prefix"] = result.info.prefix;
        info["accountId"] = result.info.accountId;
        info["scopes"] = QJsonArray::fromStringList(result.info.scopes);
        info["name"] = result.info.label;
        info["createdAt"] = result.info.createdAt.toString(Qt::ISODateWithMs);
        if (result.info.expiresAt.isValid())
            info["expiresAt"] = result.info.expiresAt.toString(Qt::ISODateWithMs);

        QJsonObject response;
        response["token"] = result.rawToken;
        response["info"] = info;
        return QHttpServerResponse(response, QHttpServerResponse::StatusCode::Created);
    });

    // GET /api/tokens - jami-web compatible current-account route
    httpServer_->route("/api/tokens", QHttpServerRequest::Method::Get,
                       [this](const QHttpServerRequest& request) {
        bool ok;
        const auto tokenScope = authenticate(request, ok);
        if (!ok)
            return errorResponse(QHttpServerResponse::StatusCode::Unauthorized, "Invalid token");

        const auto accountId = resolveCurrentAccountId(tokenScope);
        if (accountId.isEmpty())
            return errorResponse(QHttpServerResponse::StatusCode::NotFound, "Account not found");

        QJsonArray arr;
        for (const auto& info : tokenManager()->listTokens(accountId)) {
            QJsonObject compatInfo;
            compatInfo["id"] = info.id;
            compatInfo["prefix"] = info.prefix;
            compatInfo["accountId"] = info.accountId;
            compatInfo["scopes"] = QJsonArray::fromStringList(info.scopes);
            compatInfo["name"] = info.label;
            compatInfo["createdAt"] = info.createdAt.toString(Qt::ISODateWithMs);
            if (info.expiresAt.isValid())
                compatInfo["expiresAt"] = info.expiresAt.toString(Qt::ISODateWithMs);
            arr.append(compatInfo);
        }
        return QHttpServerResponse(arr);
    });

    // DELETE /api/tokens/<tokenId> - jami-web compatible revoke
    httpServer_->route("/api/tokens/<arg>", QHttpServerRequest::Method::Delete,
                       [this](const QString& tokenId, const QHttpServerRequest& request) {
        bool ok;
        authenticate(request, ok);
        if (!ok)
            return errorResponse(QHttpServerResponse::StatusCode::Unauthorized, "Invalid token");

        if (!tokenManager()->revokeToken(tokenId))
            return errorResponse(QHttpServerResponse::StatusCode::NotFound, "Token not found");

        return noContentResponse();
    });
}

// ── Nameserver Routes ──────────────────────────────────────────────

void
ApiServer::setupNameserverRoutes()
{
    auto authenticateOptionalRequest = [this](const QHttpServerRequest& request, bool& ok) {
        const auto authHeader = request.value("Authorization");
        if (authHeader.isEmpty()) {
            ok = true;
            return QString {};
        }
        return authenticate(request, ok);
    };

    auto lookupNameHandler = [this, authenticateOptionalRequest](const QString& username,
                                                                 const QHttpServerRequest& request,
                                                                 bool headOnly) {
        bool ok;
        const auto tokenScope = authenticateOptionalRequest(request, ok);
        if (!ok)
            return errorResponse(QHttpServerResponse::StatusCode::Unauthorized, "Invalid token");

        const auto result = lookupNameForApi(tokenScope, username);
        if (result.timedOut)
            return errorResponse(QHttpServerResponse::StatusCode::RequestTimeout,
                                 "Registered name lookup timed out");
        if (!result.started)
            return errorResponse(QHttpServerResponse::StatusCode::InternalServerError,
                                 "Registered name lookup failed");

        switch (result.state) {
        case 0:
            return headOnly ? QHttpServerResponse(QHttpServerResponse::StatusCode::Ok)
                            : QHttpServerResponse(lookupApiResultToJson(result));
        case 1:
            return headOnly
                       ? QHttpServerResponse(QHttpServerResponse::StatusCode::BadRequest)
                       : errorResponse(QHttpServerResponse::StatusCode::BadRequest, "Invalid username");
        default:
            return headOnly
                       ? QHttpServerResponse(QHttpServerResponse::StatusCode::NotFound)
                       : errorResponse(QHttpServerResponse::StatusCode::NotFound, "No such username found");
        }
    };

    httpServer_->route("/api/ns/name/<arg>", QHttpServerRequest::Method::Get,
                       [lookupNameHandler](const QString& username, const QHttpServerRequest& request) {
        return lookupNameHandler(username, request, false);
    });

    httpServer_->route("/api/ns/name/<arg>", QHttpServerRequest::Method::Head,
                       [lookupNameHandler](const QString& username, const QHttpServerRequest& request) {
        return lookupNameHandler(username, request, true);
    });

    httpServer_->route("/api/ns/address/<arg>", QHttpServerRequest::Method::Get,
                       [this, authenticateOptionalRequest](const QString& address,
                                                           const QHttpServerRequest& request) {
        bool ok;
        const auto tokenScope = authenticateOptionalRequest(request, ok);
        if (!ok)
            return errorResponse(QHttpServerResponse::StatusCode::Unauthorized, "Invalid token");

        const auto result = lookupAddressForApi(tokenScope, address);
        if (result.timedOut)
            return errorResponse(QHttpServerResponse::StatusCode::RequestTimeout,
                                 "Address lookup timed out");
        if (!result.started)
            return errorResponse(QHttpServerResponse::StatusCode::InternalServerError,
                                 "Address lookup failed");

        switch (result.state) {
        case 0:
            return QHttpServerResponse(lookupApiResultToJson(result));
        case 1:
            return errorResponse(QHttpServerResponse::StatusCode::BadRequest, "Invalid address");
        default:
            return errorResponse(QHttpServerResponse::StatusCode::NotFound, "No such address found");
        }
    });

    httpServer_->route("/api/ns/jams/<arg>", QHttpServerRequest::Method::Get,
                       [this, authenticateOptionalRequest](const QString& username,
                                                           const QHttpServerRequest& request) {
        bool ok;
        const auto tokenScope = authenticateOptionalRequest(request, ok);
        if (!ok)
            return errorResponse(QHttpServerResponse::StatusCode::Unauthorized, "Invalid token");

        const auto accountId = resolveCurrentAccountId(tokenScope);
        if (accountId.isEmpty())
            return errorResponse(QHttpServerResponse::StatusCode::InternalServerError,
                                 "No account available for JAMS lookup");

        const auto result = searchUserForApi(accountId, username);
        if (result.timedOut)
            return errorResponse(QHttpServerResponse::StatusCode::RequestTimeout,
                                 "JAMS lookup timed out");
        if (!result.started)
            return errorResponse(QHttpServerResponse::StatusCode::InternalServerError,
                                 "JAMS lookup failed");

        switch (result.state) {
        case 0:
            return QHttpServerResponse(lookupApiResultToJson(result));
        case 1:
            return errorResponse(QHttpServerResponse::StatusCode::BadRequest, "Invalid username");
        default:
            return errorResponse(QHttpServerResponse::StatusCode::NotFound, "No such username found");
        }
    });
}

// ── WebSocket ───────────────────────────────────────────────────────

void
ApiServer::setupWebSocket()
{
    httpServer_->addWebSocketUpgradeVerifier(this, [this](const QHttpServerRequest& request) {
        if (request.url().path() != QStringLiteral("/api"))
            return QHttpServerWebSocketUpgradeResponse::passToNext();

        auto query = QUrlQuery(request.url());
        const auto queryToken = query.queryItemValue(QStringLiteral("accessToken"));

        bool ok = false;
        authenticateWs(queryToken, ok);
        return ok ? QHttpServerWebSocketUpgradeResponse::accept()
                  : QHttpServerWebSocketUpgradeResponse::deny(401, QByteArrayLiteral("Unauthorized"));
    });

    connect(httpServer_.get(), &QAbstractHttpServer::newWebSocketConnection,
            this, &ApiServer::onNewWebSocketConnection);

    qCInfo(apiLog) << "ApiServer: WebSocket upgrades enabled on localhost:" << tcpServer_->serverPort();

    // Connect libclient signals to broadcast events (only if LRC is available)
    if (!lrcInstance_)
        return;

    auto& accountModel = lrcInstance_->accountModel();

    connect(&accountModel, &AccountModel::accountStatusChanged, this,
            [this](const QString& accountId) {
        QJsonObject data;
        data["accountId"] = accountId;
        broadcastEvent("accountStatusChanged", data);
    });

    connect(&accountModel, &AccountModel::profileUpdated, this,
            [this](const QString& accountId) {
        QJsonObject data;
        data["accountId"] = accountId;
        broadcastEvent("profileUpdated", data);
    });

    // Per-account signals are connected when accounts are available
    for (const auto& accountId : accountModel.getAccountList()) {
        try {
            const auto& accInfo = accountModel.getAccountInfo(accountId);

            if (auto* convModel = accInfo.conversationModel.get()) {
                connect(convModel, &ConversationModel::newConversation, this,
                        [this, accountId](const QString& convId) {
                    QJsonObject data;
                    data["accountId"] = accountId;
                    data["conversationId"] = convId;
                    broadcastEvent("newConversation", data);

                    try {
                        const auto& accInfo = lrcInstance_->accountModel().getAccountInfo(accountId);
                        auto optConv = accInfo.conversationModel->getConversationForUid(convId);
                        if (optConv && optConv->get().isRequest) {
                            QString fromUri;
                            for (const auto& participant : optConv->get().participants) {
                                if (participant.uri != accInfo.profileInfo.uri) {
                                    fromUri = participant.uri;
                                    break;
                                }
                            }

                            QJsonObject from;
                            from["uri"] = fromUri;
                            if (accInfo.contactModel && !fromUri.isEmpty()) {
                                try {
                                    const auto contact = accInfo.contactModel->getContact(fromUri);
                                    if (!contact.registeredName.isEmpty())
                                        from["registeredName"] = contact.registeredName;
                                } catch (...) {}
                            }

                            QJsonArray membersNames;
                            for (const auto& participant : optConv->get().participants) {
                                if (participant.uri == accInfo.profileInfo.uri)
                                    continue;
                                const auto bestName = accInfo.contactModel
                                                          ? accInfo.contactModel->bestNameForContact(participant.uri)
                                                          : QString {};
                                membersNames.append(bestName.isEmpty() ? participant.uri : bestName);
                            }

                            QString received;
                            optConv->get().interactions->withLast([&](const QString&, interaction::Info& interaction) {
                                received = QDateTime::fromSecsSinceEpoch(interaction.timestamp, QTimeZone::UTC)
                                               .toString(Qt::ISODate);
                            });
                            if (received.isEmpty())
                                received = QDateTime::currentDateTimeUtc().toString(Qt::ISODate);

                            QJsonObject requestData;
                            requestData["conversationId"] = convId;
                            requestData["infos"] = conversationInfosToCompat(optConv->get());
                            requestData["from"] = from;
                            requestData["received"] = received;
                            requestData["membersNames"] = membersNames;
                            broadcastEvent(QStringLiteral("conversation-request"), requestData);
                        }
                    } catch (...) {}
                });

                connect(convModel, &ConversationModel::conversationReady, this,
                        [this, accountId](const QString& convId, const QString& participantURI) {
                    QJsonObject data;
                    data["accountId"] = accountId;
                    data["conversationId"] = convId;
                    data["participantURI"] = participantURI;
                    broadcastEvent("conversation-ready", data);
                });

                connect(convModel, &ConversationModel::conversationRemoved, this,
                        [this, accountId](const QString& convId) {
                    QJsonObject data;
                    data["accountId"] = accountId;
                    data["conversationId"] = convId;
                    broadcastEvent("conversationRemoved", data);
                });

                connect(convModel, &ConversationModel::conversationUpdated, this,
                        [this, accountId](const QString& convId) {
                    QJsonObject data;
                    data["accountId"] = accountId;
                    data["conversationId"] = convId;
                    broadcastEvent("conversationUpdated", data);
                });

                connect(convModel, &ConversationModel::newInteraction, this,
                        [this, accountId](const QString& convId,
                                          QString& interactionId,
                                          const interaction::Info& interaction) {
                    QJsonObject data;
                    data["accountId"] = accountId;
                    data["conversationId"] = convId;
                    data["interactionId"] = interactionId;
                    broadcastEvent("newInteraction", data);

                    try {
                        const auto& accInfo = lrcInstance_->accountModel().getAccountInfo(accountId);
                        QJsonObject compatData;
                        compatData["conversationId"] = convId;
                        compatData["message"] = interactionToCompatMessage(accInfo, interactionId, interaction);
                        broadcastEvent(QStringLiteral("conversation-message"), compatData);
                    } catch (...) {}
                });
            }

            if (auto* callModel = accInfo.callModel.get()) {
                connect(callModel, &CallModel::callStatusChanged, this,
                        [this](const QString& accountId, const QString& callId, int code) {
                    Q_UNUSED(code)
                    QJsonObject data;
                    data["accountId"] = accountId;
                    data["callId"] = callId;
                    broadcastEvent("callStatusChanged", data);
                });

                connect(callModel, &CallModel::newCall, this,
                        [this](const QString& peerId, const QString& callId,
                               const QString& displayname, bool isOutgoing, const QString& toUri) {
                    Q_UNUSED(displayname)
                    Q_UNUSED(toUri)
                    QJsonObject data;
                    data["peerId"] = peerId;
                    data["callId"] = callId;
                    data["isOutgoing"] = isOutgoing;
                    broadcastEvent("newCall", data);
                });
            }

            if (auto* contactModel = accInfo.contactModel.get()) {
                connect(contactModel, &ContactModel::contactAdded, this,
                        [this, accountId](const QString& uri) {
                    QJsonObject data;
                    data["accountId"] = accountId;
                    data["uri"] = uri;
                    broadcastEvent("contactAdded", data);
                });

                connect(contactModel, &ContactModel::contactRemoved, this,
                        [this, accountId](const QString& uri) {
                    QJsonObject data;
                    data["accountId"] = accountId;
                    data["uri"] = uri;
                    broadcastEvent("contactRemoved", data);
                });
            }
        } catch (...) {
            continue;
        }
    }
}

void
ApiServer::onNewWebSocketConnection()
{
    while (httpServer_->hasPendingWebSocketConnections()) {
        auto socket = httpServer_->nextPendingWebSocketConnection();
        if (!socket)
            continue;

        auto* rawSocket = socket.release();
        rawSocket->setParent(this);
        wsClients_.append(rawSocket);

        connect(rawSocket, &QWebSocket::disconnected, this, [this, rawSocket]() {
            wsClients_.removeAll(rawSocket);
            rawSocket->deleteLater();
        });
    }
}

void
ApiServer::broadcastEvent(const QString& type, const QJsonObject& data)
{
    QJsonObject message;
    message["type"] = type;
    message["data"] = data;
    auto payload = QJsonDocument(message).toJson(QJsonDocument::Compact);

    for (auto* client : std::as_const(wsClients_)) {
        client->sendTextMessage(QString::fromUtf8(payload));
    }
}
