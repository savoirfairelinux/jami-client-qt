/*
 * Copyright (C) 2026 Savoir-faire Linux Inc.
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

#include "exposedservicesadapter.h"

#include "lrcinstance.h"

#include "dbus/networkservicemanager.h"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QHostAddress>
#include <QHttpServer>
#include <QHttpServerRequest>
#include <QHttpServerResponder>
#include <QHttpServerResponse>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QLocale>
#include <QMap>
#include <QMetaType>
#include <QMimeDatabase>
#include <QSet>
#include <QString>
#include <QTcpServer>
#include <QTimer>
#include <QUrl>

#include <utility>

namespace {

constexpr const char* TYPE_KEY = "type";
constexpr const char* TYPE_CUSTOM = "custom";
constexpr const char* TYPE_EMBEDDED = "embedded";
constexpr const char* DIRECTORY_KEY = "directory";
constexpr const char* LOCAL_HOST_KEY = "localHost";
constexpr const char* LOCAL_PORT_KEY = "localPort";
constexpr const char* SCHEME_KEY = "scheme";
constexpr const char* ENABLED_KEY = "enabled";
constexpr const char* ID_KEY = "id";
constexpr const char* LOCALHOST = "localhost";

QVariantMap
mapToVariant(const MapStringString& m)
{
    QVariantMap out;
    for (auto it = m.cbegin(); it != m.cend(); ++it)
        out.insert(it.key(), it.value());
    return out;
}

MapStringString
variantToMap(const QVariantMap& v)
{
    MapStringString out;
    for (auto it = v.cbegin(); it != v.cend(); ++it)
        out.insert(it.key(), it.value().toString());
    return out;
}

QString
normalizedServiceType(const QVariantMap& service)
{
    const auto type = service.value(TYPE_KEY, TYPE_CUSTOM).toString();
    return type.isEmpty() ? QString(TYPE_CUSTOM) : type;
}

bool
isEmbeddedService(const QVariantMap& service)
{
    return normalizedServiceType(service) == TYPE_EMBEDDED;
}

bool
isServiceEnabled(const QVariantMap& service)
{
    const auto enabled = service.value(ENABLED_KEY, QStringLiteral("true"));
    if (enabled.metaType().id() == QMetaType::Bool)
        return enabled.toBool();
    const auto enabledString = enabled.toString().toLower();
    return enabledString == "true" || enabledString == "1";
}

quint16
servicePort(const QVariant& value)
{
    bool ok = false;
    const auto port = value.toString().toUShort(&ok);
    return ok ? port : 0;
}

QString
canonicalDirectoryPath(const QString& directory)
{
    const QFileInfo directoryInfo(directory);
    if (!directoryInfo.exists() || !directoryInfo.isDir())
        return {};
    auto canonicalPath = directoryInfo.canonicalFilePath();
    if (canonicalPath.isEmpty())
        canonicalPath = directoryInfo.absoluteFilePath();
    return QDir::cleanPath(canonicalPath);
}

QByteArray
generateDirectoryListing(const QString& rootPath, const QString& dirPath, const QString& urlPath)
{
    QDir dir(dirPath);
    const auto entries = dir.entryInfoList(QDir::Dirs | QDir::Files | QDir::NoDotAndDotDot,
                                           QDir::DirsFirst | QDir::Name | QDir::IgnoreCase);

    const auto displayPath = urlPath.isEmpty() ? QStringLiteral("/") : QStringLiteral("/") + urlPath;
    QByteArray html;
    html.append("<!DOCTYPE html><html><head><meta charset=\"utf-8\">"
                "<title>Index of ");
    html.append(displayPath.toUtf8().toPercentEncoding("/"));
    html.append("</title><style>"
                "body{font-family:sans-serif;margin:2em}"
                "a{text-decoration:none;color:#0366d6}"
                "a:hover{text-decoration:underline}"
                "table{border-collapse:collapse;width:100%}"
                "th,td{text-align:left;padding:4px 12px}"
                "tr:hover{background:#f6f8fa}"
                "</style></head><body><h1>Index of ");
    html.append(displayPath.toHtmlEscaped().toUtf8());
    html.append("</h1><table><tr><th>Name</th><th>Size</th></tr>");

    if (!urlPath.isEmpty()) {
        auto parentPath = urlPath;
        if (parentPath.endsWith('/'))
            parentPath.chop(1);
        const auto lastSlash = parentPath.lastIndexOf('/');
        const auto parent = lastSlash >= 0 ? parentPath.left(lastSlash + 1) : QString();
        html.append("<tr><td><a href=\"/");
        html.append(parent.toUtf8());
        html.append("\">..</a></td><td></td></tr>");
    }

    const auto urlPrefix = urlPath.isEmpty() ? QStringLiteral("/")
                                             : QStringLiteral("/") + urlPath + (urlPath.endsWith('/') ? QString() : QStringLiteral("/"));
    for (const auto& entry : entries) {
        const auto name = entry.fileName();
        const auto isDir = entry.isDir();
        const auto href = urlPrefix + QUrl::toPercentEncoding(name) + (isDir ? "/" : "");
        html.append("<tr><td><a href=\"");
        html.append(href.toUtf8());
        html.append("\">");
        html.append(name.toHtmlEscaped().toUtf8());
        if (isDir)
            html.append("/");
        html.append("</a></td><td>");
        if (!isDir)
            html.append(QLocale().formattedDataSize(entry.size()).toUtf8());
        html.append("</td></tr>");
    }

    html.append("</table></body></html>");
    return html;
}

QHttpServerResponse
serveDirectoryFile(const QString& rootPath, const QHttpServerRequest& request)
{
    using StatusCode = QHttpServerResponse::StatusCode;

    if (request.method() != QHttpServerRequest::Method::Get && request.method() != QHttpServerRequest::Method::Head) {
        return QHttpServerResponse(StatusCode::MethodNotAllowed);
    }

    auto requestPath = request.url().path(QUrl::FullyDecoded);
    while (requestPath.startsWith('/'))
        requestPath.remove(0, 1);

    auto normalizedRootPath = QDir::cleanPath(rootPath);
    const auto rootPrefix = normalizedRootPath.endsWith('/') ? normalizedRootPath : normalizedRootPath + '/';

    // Determine if the target is a directory.
    const auto resolvedPath = requestPath.isEmpty() ? rootPath : QDir(rootPath).filePath(requestPath);
    QFileInfo targetInfo(resolvedPath);

    if (targetInfo.isDir()) {
        // Verify directory is within root.
        auto canonicalDir = targetInfo.canonicalFilePath();
        if (canonicalDir.isEmpty())
            return QHttpServerResponse(StatusCode::NotFound);
        canonicalDir = QDir::cleanPath(canonicalDir);
        if (canonicalDir != normalizedRootPath && !canonicalDir.startsWith(rootPrefix))
            return QHttpServerResponse(StatusCode::Forbidden);

        // Try index.html first.
        QFileInfo indexInfo(QDir(canonicalDir).filePath(QStringLiteral("index.html")));
        if (indexInfo.isFile() && indexInfo.isReadable()) {
            QFile file(indexInfo.canonicalFilePath());
            if (file.open(QIODevice::ReadOnly)) {
                auto data = request.method() == QHttpServerRequest::Method::Head ? QByteArray {} : file.readAll();
                return QHttpServerResponse("text/html", std::move(data));
            }
        }

        // Generate directory listing.
        auto listing = request.method() == QHttpServerRequest::Method::Head
                           ? QByteArray {}
                           : generateDirectoryListing(normalizedRootPath, canonicalDir, requestPath);
        return QHttpServerResponse("text/html", std::move(listing));
    }

    // Serve a regular file.
    if (requestPath.isEmpty())
        return QHttpServerResponse(StatusCode::NotFound);

    auto canonicalFilePath = targetInfo.canonicalFilePath();
    if (canonicalFilePath.isEmpty())
        return QHttpServerResponse(StatusCode::NotFound);

    canonicalFilePath = QDir::cleanPath(canonicalFilePath);
    if (canonicalFilePath != normalizedRootPath && !canonicalFilePath.startsWith(rootPrefix))
        return QHttpServerResponse(StatusCode::Forbidden);

    targetInfo.setFile(canonicalFilePath);
    if (!targetInfo.isFile() || !targetInfo.isReadable())
        return QHttpServerResponse(StatusCode::NotFound);

    QFile file(canonicalFilePath);
    if (!file.open(QIODevice::ReadOnly))
        return QHttpServerResponse(StatusCode::NotFound);

    QMimeDatabase mimeDatabase;
    const auto mimeType = mimeDatabase.mimeTypeForFile(canonicalFilePath);
    auto data = request.method() == QHttpServerRequest::Method::Head ? QByteArray {} : file.readAll();
    return QHttpServerResponse(mimeType.name().toUtf8(), std::move(data));
}

QVariantMap
existingServiceMap(const QString& accountId, const QString& serviceId)
{
    if (serviceId.isEmpty())
        return {};
    const auto records = NetworkServiceManager::instance().getExposedServices(accountId);
    for (const auto& record : records) {
        if (record.value(ID_KEY) == serviceId)
            return mapToVariant(record);
    }
    return {};
}

} // namespace

struct ExposedServicesAdapter::EmbeddedServer
{
    QString accountId;
    QString serviceId;
    QString rootPath;
    quint16 port {0};
    std::unique_ptr<QHttpServer> httpServer;
    QTcpServer* tcpServer {nullptr};
};

ExposedServicesAdapter*
ExposedServicesAdapter::create(QQmlEngine*, QJSEngine*)
{
    return new ExposedServicesAdapter(qApp->property("LRCInstance").value<LRCInstance*>());
}

ExposedServicesAdapter::ExposedServicesAdapter(LRCInstance* instance, QObject* parent)
    : QmlAdapterBase(instance, parent)
{
    auto& nsm = NetworkServiceManager::instance();

    connect(&nsm,
            &NetworkServiceManagerInterface::peerServicesReceived,
            this,
            [this](quint32 requestId,
                   const QString& accountId,
                   const QString& peerId,
                   int status,
                   const QString& servicesJson) {
                QVariantList services;
                QJsonParseError err;
                auto doc = QJsonDocument::fromJson(servicesJson.toUtf8(), &err);
                if (err.error == QJsonParseError::NoError && doc.isArray()) {
                    const auto arr = doc.array();
                    services.reserve(arr.size());
                    for (const auto& v : arr)
                        services.append(v.toObject().toVariantMap());
                }
                Q_EMIT peerServicesReceived(requestId, accountId, peerId, status, services);
            });

    connect(&nsm,
            &NetworkServiceManagerInterface::serviceTunnelOpened,
            this,
            [this](const QString& accountId, const QString& tunnelId, quint16 localPort) {
                Q_EMIT tunnelOpened(accountId, tunnelId, localPort);
            });

    connect(&nsm,
            &NetworkServiceManagerInterface::serviceTunnelClosed,
            this,
            [this](const QString& accountId, const QString& tunnelId, const QString& reason) {
                Q_EMIT tunnelClosed(accountId, tunnelId, reason);
            });

    if (lrcInstance_) {
        auto& accountModel = lrcInstance_->accountModel();
        connect(&accountModel, &lrc::api::AccountModel::accountAdded, this, [this](const QString& accountId) {
            syncEmbeddedServers(accountId);
        });
        connect(&accountModel, &lrc::api::AccountModel::accountStatusChanged, this, [this](const QString& accountId) {
            syncEmbeddedServers(accountId);
        });
        connect(&accountModel, &lrc::api::AccountModel::accountRemoved, this, [this](const QString& accountId) {
            stopEmbeddedServersForAccount(accountId);
        });
        QTimer::singleShot(0, this, [this] { syncAllEmbeddedServers(); });
    }
}

ExposedServicesAdapter::~ExposedServicesAdapter() = default;

QString
ExposedServicesAdapter::resolveAccountId(const QString& accountId) const
{
    if (!accountId.isEmpty())
        return accountId;
    if (lrcInstance_)
        return lrcInstance_->get_currentAccountId();
    return {};
}

QVariantList
ExposedServicesAdapter::getExposedServices(const QString& accountId)
{
    QVariantList out;
    const auto id = resolveAccountId(accountId);
    if (id.isEmpty())
        return out;
    syncEmbeddedServers(id);
    const auto records = NetworkServiceManager::instance().getExposedServices(id);
    out.reserve(records.size());
    for (const auto& m : records)
        out.append(mapToVariant(m));
    return out;
}

QString
ExposedServicesAdapter::addExposedService(const QString& accountId, const QVariantMap& service)
{
    const auto id = resolveAccountId(accountId);
    if (id.isEmpty())
        return {};

    auto serviceForStorage = service;
    std::unique_ptr<EmbeddedServer> replacementServer;
    if (!prepareServiceForStorage(id, serviceForStorage, replacementServer))
        return {};

    const auto serviceId = NetworkServiceManager::instance().addExposedService(id, variantToMap(serviceForStorage));
    if (serviceId.isEmpty())
        return {};

    if (replacementServer) {
        replacementServer->serviceId = serviceId;
        embeddedServers_[embeddedServerKey(id, serviceId)] = std::move(replacementServer);
    }
    syncEmbeddedServers(id);

    Q_EMIT refreshExposedServices();
    return serviceId;
}

bool
ExposedServicesAdapter::updateExposedService(const QString& accountId, const QVariantMap& service)
{
    const auto id = resolveAccountId(accountId);
    if (id.isEmpty())
        return false;

    auto serviceForStorage = service;
    const auto serviceId = serviceForStorage.value(ID_KEY).toString();
    std::unique_ptr<EmbeddedServer> replacementServer;
    if (!prepareServiceForStorage(id, serviceForStorage, replacementServer))
        return false;

    const auto updated = NetworkServiceManager::instance().updateExposedService(id, variantToMap(serviceForStorage));
    if (!updated)
        return false;

    if (replacementServer) {
        replacementServer->serviceId = serviceId;
        stopEmbeddedServer(id, serviceId);
        embeddedServers_[embeddedServerKey(id, serviceId)] = std::move(replacementServer);
    } else if (!isEmbeddedService(serviceForStorage) || !isServiceEnabled(serviceForStorage)) {
        stopEmbeddedServer(id, serviceId);
    }
    syncEmbeddedServers(id);
    Q_EMIT refreshExposedServices();
    return true;
}

bool
ExposedServicesAdapter::removeExposedService(const QString& accountId, const QString& serviceId)
{
    const auto id = resolveAccountId(accountId);
    if (id.isEmpty() || serviceId.isEmpty())
        return false;
    const auto removed = NetworkServiceManager::instance().removeExposedService(id, serviceId);
    if (removed) {
        stopEmbeddedServer(id, serviceId);
        Q_EMIT refreshExposedServices();
    }
    return removed;
}

QString
ExposedServicesAdapter::embeddedServerKey(const QString& accountId, const QString& serviceId) const
{
    return accountId + '\n' + serviceId;
}

bool
ExposedServicesAdapter::prepareServiceForStorage(const QString& accountId,
                                                 QVariantMap& service,
                                                 std::unique_ptr<EmbeddedServer>& replacementServer)
{
    const auto type = normalizedServiceType(service);
    service[TYPE_KEY] = type;

    if (type != TYPE_EMBEDDED) {
        auto localHost = service.value(LOCAL_HOST_KEY).toString().trimmed();
        service[LOCAL_HOST_KEY] = localHost.isEmpty() ? QString(LOCALHOST) : localHost;
        return true;
    }

    const auto rootPath = canonicalDirectoryPath(service.value(DIRECTORY_KEY).toString().trimmed());
    if (rootPath.isEmpty())
        return false;

    service[DIRECTORY_KEY] = rootPath;
    service[SCHEME_KEY] = QStringLiteral("http");
    service[LOCAL_HOST_KEY] = QString(LOCALHOST);

    const auto serviceId = service.value(ID_KEY).toString();
    const auto existingService = existingServiceMap(accountId, serviceId);
    auto requestedPort = servicePort(service.value(LOCAL_PORT_KEY));
    if (requestedPort == 0)
        requestedPort = servicePort(existingService.value(LOCAL_PORT_KEY));

    const auto existingServerKey = embeddedServerKey(accountId, serviceId);
    const auto runningServer = serviceId.isEmpty() ? embeddedServers_.end() : embeddedServers_.find(existingServerKey);
    if (isServiceEnabled(service)) {
        if (runningServer != embeddedServers_.end() && runningServer->second
            && runningServer->second->rootPath == rootPath && runningServer->second->tcpServer
            && runningServer->second->tcpServer->isListening()) {
            service[LOCAL_PORT_KEY] = QString::number(runningServer->second->port);
            return true;
        }

        replacementServer = startEmbeddedServer(accountId, serviceId, rootPath, requestedPort);
        if (!replacementServer)
            return false;
        service[LOCAL_PORT_KEY] = QString::number(replacementServer->port);
        return true;
    }

    if (requestedPort == 0 && runningServer != embeddedServers_.end() && runningServer->second)
        requestedPort = runningServer->second->port;
    if (requestedPort == 0) {
        auto temporaryServer = startEmbeddedServer(accountId, serviceId, rootPath, 0);
        if (!temporaryServer)
            return false;
        requestedPort = temporaryServer->port;
    }
    service[LOCAL_PORT_KEY] = QString::number(requestedPort);
    return true;
}

std::unique_ptr<ExposedServicesAdapter::EmbeddedServer>
ExposedServicesAdapter::startEmbeddedServer(const QString& accountId,
                                            const QString& serviceId,
                                            const QString& directory,
                                            quint16 requestedPort)
{
    const auto rootPath = canonicalDirectoryPath(directory);
    if (rootPath.isEmpty())
        return nullptr;

    auto httpServer = std::make_unique<QHttpServer>();
    httpServer->setMissingHandler(this, [rootPath](const QHttpServerRequest& request, QHttpServerResponder& responder) {
        auto response = serveDirectoryFile(rootPath, request);
        responder.sendResponse(response);
    });

    auto* tcpServer = new QTcpServer();
    auto listening = tcpServer->listen(QHostAddress::LocalHost, requestedPort);
    if (!listening && requestedPort != 0) {
        tcpServer->close();
        listening = tcpServer->listen(QHostAddress::LocalHost, 0);
    }
    if (!listening) {
        qWarning() << "ExposedServicesAdapter: failed to listen for embedded service" << serviceId
                   << tcpServer->errorString();
        delete tcpServer;
        return nullptr;
    }

    if (!httpServer->bind(tcpServer)) {
        qWarning() << "ExposedServicesAdapter: failed to bind embedded HTTP server" << serviceId;
        tcpServer->close();
        delete tcpServer;
        return nullptr;
    }
    tcpServer->setParent(httpServer.get());

    auto embeddedServer = std::make_unique<EmbeddedServer>();
    embeddedServer->accountId = accountId;
    embeddedServer->serviceId = serviceId;
    embeddedServer->rootPath = rootPath;
    embeddedServer->port = tcpServer->serverPort();
    embeddedServer->tcpServer = tcpServer;
    embeddedServer->httpServer = std::move(httpServer);
    return embeddedServer;
}

void
ExposedServicesAdapter::syncAllEmbeddedServers()
{
    if (!lrcInstance_)
        return;
    const auto accountIds = lrcInstance_->accountModel().getAccountList();
    for (const auto& accountId : accountIds)
        syncEmbeddedServers(accountId);
}

void
ExposedServicesAdapter::syncEmbeddedServers(const QString& accountId)
{
    if (accountId.isEmpty())
        return;

    auto& configurationManager = NetworkServiceManager::instance();
    const auto records = configurationManager.getExposedServices(accountId);
    QSet<QString> desiredServerKeys;

    for (auto record : records) {
        const auto serviceId = record.value(ID_KEY);
        if (serviceId.isEmpty())
            continue;
        const auto service = mapToVariant(record);
        const auto serverKey = embeddedServerKey(accountId, serviceId);

        if (!isEmbeddedService(service) || !isServiceEnabled(service)) {
            stopEmbeddedServer(accountId, serviceId);
            continue;
        }

        const auto rootPath = canonicalDirectoryPath(service.value(DIRECTORY_KEY).toString());
        if (rootPath.isEmpty()) {
            stopEmbeddedServer(accountId, serviceId);
            continue;
        }

        desiredServerKeys.insert(serverKey);
        auto runningServer = embeddedServers_.find(serverKey);
        if (runningServer == embeddedServers_.end() || !runningServer->second
            || runningServer->second->rootPath != rootPath || !runningServer->second->tcpServer
            || !runningServer->second->tcpServer->isListening()) {
            stopEmbeddedServer(accountId, serviceId);
            auto replacementServer = startEmbeddedServer(accountId,
                                                         serviceId,
                                                         rootPath,
                                                         servicePort(service.value(LOCAL_PORT_KEY)));
            if (!replacementServer)
                continue;
            embeddedServers_[serverKey] = std::move(replacementServer);
            runningServer = embeddedServers_.find(serverKey);
        }

        const auto actualPort = runningServer->second->port;
        const auto actualPortString = QString::number(actualPort);
        if (record.value(LOCAL_HOST_KEY) != LOCALHOST || record.value(LOCAL_PORT_KEY) != actualPortString
            || record.value(DIRECTORY_KEY) != rootPath || record.value(SCHEME_KEY) != "http"
            || record.value(TYPE_KEY) != TYPE_EMBEDDED) {
            record[TYPE_KEY] = TYPE_EMBEDDED;
            record[DIRECTORY_KEY] = rootPath;
            record[LOCAL_HOST_KEY] = LOCALHOST;
            record[LOCAL_PORT_KEY] = actualPortString;
            record[SCHEME_KEY] = "http";
            configurationManager.updateExposedService(accountId, record);
        }
    }

    const auto accountPrefix = accountId + '\n';
    for (auto serverIterator = embeddedServers_.begin(); serverIterator != embeddedServers_.end();) {
        if (serverIterator->first.startsWith(accountPrefix) && !desiredServerKeys.contains(serverIterator->first)) {
            serverIterator = embeddedServers_.erase(serverIterator);
        } else {
            ++serverIterator;
        }
    }
}

void
ExposedServicesAdapter::stopEmbeddedServer(const QString& accountId, const QString& serviceId)
{
    embeddedServers_.erase(embeddedServerKey(accountId, serviceId));
}

void
ExposedServicesAdapter::stopEmbeddedServersForAccount(const QString& accountId)
{
    const auto accountPrefix = accountId + '\n';
    for (auto serverIterator = embeddedServers_.begin(); serverIterator != embeddedServers_.end();) {
        if (serverIterator->first.startsWith(accountPrefix))
            serverIterator = embeddedServers_.erase(serverIterator);
        else
            ++serverIterator;
    }
}

quint32
ExposedServicesAdapter::queryPeerServices(const QString& accountId, const QString& peerUri)
{
    const auto id = resolveAccountId(accountId);
    if (id.isEmpty() || peerUri.isEmpty())
        return 0;
    return NetworkServiceManager::instance().queryPeerServices(id, peerUri);
}

QString
ExposedServicesAdapter::openServiceTunnel(const QString& accountId,
                                          const QString& peerUri,
                                          const QString& peerDevice,
                                          const QString& serviceId,
                                          const QString& serviceName,
                                          quint16 localPort)
{
    const auto id = resolveAccountId(accountId);
    if (id.isEmpty())
        return {};
    return NetworkServiceManager::instance()
        .openServiceTunnel(id, peerUri, peerDevice, serviceId, serviceName, localPort);
}

bool
ExposedServicesAdapter::closeServiceTunnel(const QString& accountId, const QString& tunnelId)
{
    const auto id = resolveAccountId(accountId);
    if (id.isEmpty() || tunnelId.isEmpty())
        return false;
    return NetworkServiceManager::instance().closeServiceTunnel(id, tunnelId);
}

QVariantList
ExposedServicesAdapter::getActiveTunnels(const QString& accountId) const
{
    QVariantList out;
    const auto id = resolveAccountId(accountId);
    if (id.isEmpty())
        return out;
    const auto records = NetworkServiceManager::instance().getActiveTunnels(id);
    out.reserve(records.size());
    for (const auto& m : records)
        out.append(mapToVariant(m));
    return out;
}
