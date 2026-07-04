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

#include "sharedservicesadapter.h"

#include "lrcinstance.h"

#include "dbus/networkservicemanager.h"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QHostAddress>
#include <QHttpHeaders>
#include <QHttpServer>
#include <QHttpServerRequest>
#include <QHttpServerResponder>
#include <QHttpServerResponse>
#include <QIODevice>
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
#include <QUuid>

#include <algorithm>
#include <cstring>
#include <utility>
#include <vector>

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
                                             : QStringLiteral("/") + urlPath
                                                   + (urlPath.endsWith('/') ? QString() : QStringLiteral("/"));
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

constexpr int MAX_RANGES = 16;

struct ByteRange
{
    qint64 start {0};
    qint64 end {0};
    qint64 length() const
    {
        return end - start + 1;
    }
};

struct BodySegment
{
    QByteArray literal;
    qint64 fileStart {0};
    qint64 fileLength {0};
    qint64 size() const
    {
        return fileLength > 0 ? fileLength : static_cast<qint64>(literal.size());
    }
};

// Streams an ordered list of BodySegments from a single file without ever
// loading the whole file into memory. Reported size() is the exact number of
// bytes produced so QHttpServer can set a correct Content-Length and stream in
// fixed-size chunks.
class HttpFileBodyDevice final : public QIODevice
{
public:
    HttpFileBodyDevice(const QString& filePath, std::vector<BodySegment> segments, QObject* parent = nullptr)
        : QIODevice(parent)
        , file_(filePath)
        , segments_(std::move(segments))
    {
        for (const auto& segment : segments_)
            total_ += segment.size();
    }

    bool open(OpenMode mode) override
    {
        if (!(mode & QIODevice::ReadOnly))
            return false;
        if (!file_.open(QIODevice::ReadOnly))
            return false;
        cursor_ = 0;
        segmentIndex_ = 0;
        segmentBase_ = 0;
        return QIODevice::open(mode);
    }

    void close() override
    {
        file_.close();
        QIODevice::close();
    }

    bool isSequential() const override
    {
        return false;
    }
    qint64 size() const override
    {
        return total_;
    }
    bool atEnd() const override
    {
        return cursor_ >= total_ && QIODevice::bytesAvailable() == 0;
    }

    bool seek(qint64 pos) override
    {
        if (pos < 0 || pos > total_)
            return false;
        QIODevice::seek(pos);
        cursor_ = pos;
        segmentIndex_ = 0;
        segmentBase_ = 0;
        while (segmentIndex_ < segments_.size() && segmentBase_ + segments_[segmentIndex_].size() <= pos) {
            segmentBase_ += segments_[segmentIndex_].size();
            ++segmentIndex_;
        }
        return true;
    }

protected:
    qint64 readData(char* data, qint64 maxSize) override
    {
        if (maxSize <= 0)
            return 0;

        qint64 produced = 0;
        while (produced < maxSize && cursor_ < total_) {
            if (segmentIndex_ >= segments_.size())
                break;

            const auto& segment = segments_[segmentIndex_];
            const auto segmentSize = segment.size();
            const auto offsetInSegment = cursor_ - segmentBase_;
            const auto segmentRemaining = segmentSize - offsetInSegment;
            if (segmentRemaining <= 0) {
                segmentBase_ += segmentSize;
                ++segmentIndex_;
                continue;
            }

            const auto toRead = std::min(maxSize - produced, segmentRemaining);
            if (segment.fileLength > 0) {
                if (!file_.seek(segment.fileStart + offsetInSegment))
                    return -1;
                const auto read = file_.read(data + produced, toRead);
                if (read <= 0)
                    return -1; // unexpected EOF/error before logical end
                produced += read;
                cursor_ += read;
            } else {
                std::memcpy(data + produced, segment.literal.constData() + offsetInSegment, toRead);
                produced += toRead;
                cursor_ += toRead;
            }
        }
        return produced;
    }

    qint64 writeData(const char*, qint64) override
    {
        return -1;
    }

private:
    QFile file_;
    std::vector<BodySegment> segments_;
    qint64 total_ {0};
    qint64 cursor_ {0};
    std::size_t segmentIndex_ {0};
    qint64 segmentBase_ {0};
};

enum class RangeKind { Full, Single, Multiple, Unsatisfiable };

struct RangeResolution
{
    RangeKind kind {RangeKind::Full};
    QList<ByteRange> ranges;
};

// Parses an RFC 7233 byte-range request against a known content size.
// Malformed or unsupported headers resolve to Full (serve 200). A
// syntactically valid set with no satisfiable range resolves to Unsatisfiable
// (416). Satisfiable ranges are clamped, sorted and coalesced.
RangeResolution
resolveRanges(const QByteArray& rangeHeader, qint64 size)
{
    RangeResolution result;
    if (size <= 0 || rangeHeader.isEmpty())
        return result;

    const auto trimmed = rangeHeader.trimmed();
    constexpr char unitPrefix[] = "bytes=";
    if (!trimmed.startsWith(unitPrefix))
        return result; // unsupported unit: ignore Range, serve full content

    const auto spec = trimmed.mid(static_cast<int>(sizeof(unitPrefix)) - 1);
    const auto tokens = spec.split(',');
    if (tokens.size() > MAX_RANGES)
        return result;

    QList<ByteRange> ranges;
    for (const auto& rawToken : tokens) {
        const auto token = rawToken.trimmed();
        if (token.isEmpty())
            continue;

        const auto dash = token.indexOf('-');
        if (dash < 0)
            return result; // malformed: ignore Range

        const auto left = token.left(dash).trimmed();
        const auto right = token.mid(dash + 1).trimmed();

        if (left.isEmpty()) {
            // suffix form: -N (last N bytes)
            if (right.isEmpty())
                return result;
            bool ok = false;
            const auto suffix = right.toLongLong(&ok);
            if (!ok || suffix < 0)
                return result;
            if (suffix == 0)
                continue; // unsatisfiable, skip
            const auto start = suffix >= size ? 0 : size - suffix;
            ranges.append({start, size - 1});
            continue;
        }

        bool okStart = false;
        const auto start = left.toLongLong(&okStart);
        if (!okStart || start < 0)
            return result;

        qint64 end = size - 1;
        if (!right.isEmpty()) {
            bool okEnd = false;
            end = right.toLongLong(&okEnd);
            if (!okEnd || end < 0)
                return result;
            if (start > end)
                return result; // malformed: ignore Range
        }

        if (start >= size)
            continue; // unsatisfiable, skip
        ranges.append({start, std::min(end, size - 1)});
    }

    if (ranges.isEmpty()) {
        result.kind = RangeKind::Unsatisfiable;
        return result;
    }

    std::sort(ranges.begin(), ranges.end(), [](const ByteRange& a, const ByteRange& b) { return a.start < b.start; });
    QList<ByteRange> coalesced;
    for (const auto& range : ranges) {
        if (!coalesced.isEmpty() && range.start <= coalesced.last().end + 1)
            coalesced.last().end = std::max(coalesced.last().end, range.end);
        else
            coalesced.append(range);
    }

    result.ranges = coalesced;
    result.kind = coalesced.size() == 1 ? RangeKind::Single : RangeKind::Multiple;
    return result;
}

void
serveFile(const QString& canonicalFilePath,
          qint64 fileSize,
          const QByteArray& mimeType,
          bool headOnly,
          const QHttpServerRequest& request,
          QHttpServerResponder& responder)
{
    using StatusCode = QHttpServerResponder::StatusCode;
    using WellKnownHeader = QHttpHeaders::WellKnownHeader;

    const auto resolution = resolveRanges(request.headers().value(WellKnownHeader::Range).toByteArray(), fileSize);

    if (resolution.kind == RangeKind::Unsatisfiable) {
        QHttpHeaders headers;
        headers.append(WellKnownHeader::AcceptRanges, "bytes");
        headers.append(WellKnownHeader::ContentRange, "bytes */" + QByteArray::number(fileSize));
        headers.append(WellKnownHeader::ContentLength, "0");
        responder.write(QByteArray {}, headers, StatusCode::RequestRangeNotSatisfiable);
        return;
    }

    if (resolution.kind == RangeKind::Full) {
        QHttpHeaders headers;
        headers.append(WellKnownHeader::AcceptRanges, "bytes");
        headers.append(WellKnownHeader::ContentType, mimeType);
        if (headOnly) {
            headers.append(WellKnownHeader::ContentLength, QByteArray::number(fileSize));
            responder.write(QByteArray {}, headers, StatusCode::Ok);
            return;
        }
        std::vector<BodySegment> segments;
        segments.push_back({QByteArray {}, 0, fileSize});
        responder.write(new HttpFileBodyDevice(canonicalFilePath, std::move(segments)), headers, StatusCode::Ok);
        return;
    }

    if (resolution.kind == RangeKind::Single) {
        const auto& range = resolution.ranges.first();
        QHttpHeaders headers;
        headers.append(WellKnownHeader::AcceptRanges, "bytes");
        headers.append(WellKnownHeader::ContentType, mimeType);
        headers.append(WellKnownHeader::ContentRange,
                       "bytes " + QByteArray::number(range.start) + '-' + QByteArray::number(range.end) + '/'
                           + QByteArray::number(fileSize));
        if (headOnly) {
            headers.append(WellKnownHeader::ContentLength, QByteArray::number(range.length()));
            responder.write(QByteArray {}, headers, StatusCode::PartialContent);
            return;
        }
        std::vector<BodySegment> segments;
        segments.push_back({QByteArray {}, range.start, range.length()});
        responder.write(new HttpFileBodyDevice(canonicalFilePath, std::move(segments)),
                        headers,
                        StatusCode::PartialContent);
        return;
    }

    // Multiple ranges: multipart/byteranges with a high-entropy boundary.
    const auto boundary = QUuid::createUuid().toString(QUuid::Id128).toLatin1();
    std::vector<BodySegment> segments;
    qint64 total = 0;
    for (const auto& range : resolution.ranges) {
        QByteArray header;
        header.append("\r\n--");
        header.append(boundary);
        header.append("\r\nContent-Type: ");
        header.append(mimeType);
        header.append("\r\nContent-Range: bytes ");
        header.append(QByteArray::number(range.start));
        header.append('-');
        header.append(QByteArray::number(range.end));
        header.append('/');
        header.append(QByteArray::number(fileSize));
        header.append("\r\n\r\n");
        segments.push_back({header, 0, 0});
        segments.push_back({QByteArray {}, range.start, range.length()});
        total += header.size() + range.length();
    }
    QByteArray closing;
    closing.append("\r\n--");
    closing.append(boundary);
    closing.append("--\r\n");
    segments.push_back({closing, 0, 0});
    total += closing.size();

    QHttpHeaders headers;
    headers.append(WellKnownHeader::AcceptRanges, "bytes");
    headers.append(WellKnownHeader::ContentType, "multipart/byteranges; boundary=" + boundary);
    if (headOnly) {
        headers.append(WellKnownHeader::ContentLength, QByteArray::number(total));
        responder.write(QByteArray {}, headers, StatusCode::PartialContent);
        return;
    }
    responder.write(new HttpFileBodyDevice(canonicalFilePath, std::move(segments)), headers, StatusCode::PartialContent);
}

void
serveDirectoryRequest(const QString& rootPath, const QHttpServerRequest& request, QHttpServerResponder& responder)
{
    using StatusCode = QHttpServerResponse::StatusCode;

    const auto sendResponse = [&responder](QHttpServerResponse&& response) {
        responder.sendResponse(response);
    };

    const auto isHead = request.method() == QHttpServerRequest::Method::Head;
    if (request.method() != QHttpServerRequest::Method::Get && !isHead) {
        sendResponse(QHttpServerResponse(StatusCode::MethodNotAllowed));
        return;
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
        if (canonicalDir.isEmpty()) {
            sendResponse(QHttpServerResponse(StatusCode::NotFound));
            return;
        }
        canonicalDir = QDir::cleanPath(canonicalDir);
        if (canonicalDir != normalizedRootPath && !canonicalDir.startsWith(rootPrefix)) {
            sendResponse(QHttpServerResponse(StatusCode::Forbidden));
            return;
        }

        // Try index.html first.
        QFileInfo indexInfo(QDir(canonicalDir).filePath(QStringLiteral("index.html")));
        if (indexInfo.isFile() && indexInfo.isReadable()) {
            QFile file(indexInfo.canonicalFilePath());
            if (file.open(QIODevice::ReadOnly)) {
                auto data = isHead ? QByteArray {} : file.readAll();
                sendResponse(QHttpServerResponse("text/html", std::move(data)));
                return;
            }
        }

        // Generate directory listing.
        auto listing = isHead ? QByteArray {} : generateDirectoryListing(normalizedRootPath, canonicalDir, requestPath);
        sendResponse(QHttpServerResponse("text/html", std::move(listing)));
        return;
    }

    // Serve a regular file.
    if (requestPath.isEmpty()) {
        sendResponse(QHttpServerResponse(StatusCode::NotFound));
        return;
    }

    auto canonicalFilePath = targetInfo.canonicalFilePath();
    if (canonicalFilePath.isEmpty()) {
        sendResponse(QHttpServerResponse(StatusCode::NotFound));
        return;
    }

    canonicalFilePath = QDir::cleanPath(canonicalFilePath);
    if (canonicalFilePath != normalizedRootPath && !canonicalFilePath.startsWith(rootPrefix)) {
        sendResponse(QHttpServerResponse(StatusCode::Forbidden));
        return;
    }

    targetInfo.setFile(canonicalFilePath);
    if (!targetInfo.isFile() || !targetInfo.isReadable()) {
        sendResponse(QHttpServerResponse(StatusCode::NotFound));
        return;
    }

    QFile probe(canonicalFilePath);
    if (!probe.open(QIODevice::ReadOnly)) {
        sendResponse(QHttpServerResponse(StatusCode::NotFound));
        return;
    }
    const auto fileSize = probe.size();
    probe.close();

    QMimeDatabase mimeDatabase;
    const auto mimeType = mimeDatabase.mimeTypeForFile(canonicalFilePath).name().toUtf8();
    serveFile(canonicalFilePath, fileSize, mimeType, isHead, request, responder);
}

QVariantMap
existingServiceMap(const QString& accountId, const QString& serviceId)
{
    if (serviceId.isEmpty())
        return {};
    const VectorMapStringString records = NetworkServiceManager::instance().getSharedServices(accountId);
    for (const auto& record : records) {
        if (record.value(ID_KEY) == serviceId)
            return mapToVariant(record);
    }
    return {};
}

} // namespace

struct SharedServicesAdapter::EmbeddedServer
{
    QString accountId;
    QString serviceId;
    QString rootPath;
    quint16 port {0};
    std::unique_ptr<QHttpServer> httpServer;
    QTcpServer* tcpServer {nullptr};
};

SharedServicesAdapter*
SharedServicesAdapter::create(QQmlEngine*, QJSEngine*)
{
    return new SharedServicesAdapter(qApp->property("LRCInstance").value<LRCInstance*>());
}

SharedServicesAdapter::SharedServicesAdapter(LRCInstance* instance, QObject* parent)
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

SharedServicesAdapter::~SharedServicesAdapter() = default;

QString
SharedServicesAdapter::resolveAccountId(const QString& accountId) const
{
    if (!accountId.isEmpty())
        return accountId;
    if (lrcInstance_)
        return lrcInstance_->get_currentAccountId();
    return {};
}

QVariantList
SharedServicesAdapter::getSharedServices(const QString& accountId)
{
    QVariantList out;
    const auto id = resolveAccountId(accountId);
    if (id.isEmpty())
        return out;
    syncEmbeddedServers(id);
    const VectorMapStringString records = NetworkServiceManager::instance().getSharedServices(id);
    out.reserve(records.size());
    for (const auto& m : records)
        out.append(mapToVariant(m));
    return out;
}

QString
SharedServicesAdapter::addSharedService(const QString& accountId, const QVariantMap& service)
{
    const auto id = resolveAccountId(accountId);
    if (id.isEmpty())
        return {};

    auto serviceForStorage = service;
    std::unique_ptr<EmbeddedServer> replacementServer;
    if (!prepareServiceForStorage(id, serviceForStorage, replacementServer))
        return {};

    const QString serviceId = NetworkServiceManager::instance().addSharedService(id, variantToMap(serviceForStorage));
    if (serviceId.isEmpty())
        return {};

    if (replacementServer) {
        replacementServer->serviceId = serviceId;
        embeddedServers_[embeddedServerKey(id, serviceId)] = std::move(replacementServer);
    }
    syncEmbeddedServers(id);

    Q_EMIT refreshSharedServices();
    return serviceId;
}

bool
SharedServicesAdapter::updateSharedService(const QString& accountId, const QVariantMap& service)
{
    const auto id = resolveAccountId(accountId);
    if (id.isEmpty())
        return false;

    auto serviceForStorage = service;
    const auto serviceId = serviceForStorage.value(ID_KEY).toString();
    std::unique_ptr<EmbeddedServer> replacementServer;
    if (!prepareServiceForStorage(id, serviceForStorage, replacementServer))
        return false;

    const auto updated = NetworkServiceManager::instance().updateSharedService(id, variantToMap(serviceForStorage));
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
    Q_EMIT refreshSharedServices();
    return true;
}

bool
SharedServicesAdapter::removeSharedService(const QString& accountId, const QString& serviceId)
{
    const auto id = resolveAccountId(accountId);
    if (id.isEmpty() || serviceId.isEmpty())
        return false;
    const auto removed = NetworkServiceManager::instance().removeSharedService(id, serviceId);
    if (removed) {
        stopEmbeddedServer(id, serviceId);
        Q_EMIT refreshSharedServices();
    }
    return removed;
}

QString
SharedServicesAdapter::embeddedServerKey(const QString& accountId, const QString& serviceId) const
{
    return accountId + '\n' + serviceId;
}

bool
SharedServicesAdapter::prepareServiceForStorage(const QString& accountId,
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

std::unique_ptr<SharedServicesAdapter::EmbeddedServer>
SharedServicesAdapter::startEmbeddedServer(const QString& accountId,
                                           const QString& serviceId,
                                           const QString& directory,
                                           quint16 requestedPort)
{
    const auto rootPath = canonicalDirectoryPath(directory);
    if (rootPath.isEmpty())
        return nullptr;

    auto httpServer = std::make_unique<QHttpServer>();
    httpServer->setMissingHandler(this, [rootPath](const QHttpServerRequest& request, QHttpServerResponder& responder) {
        serveDirectoryRequest(rootPath, request, responder);
    });

    auto* tcpServer = new QTcpServer();
    auto listening = tcpServer->listen(QHostAddress::LocalHost, requestedPort);
    if (!listening && requestedPort != 0) {
        tcpServer->close();
        listening = tcpServer->listen(QHostAddress::LocalHost, 0);
    }
    if (!listening) {
        qWarning() << "SharedServicesAdapter: failed to listen for embedded service" << serviceId
                   << tcpServer->errorString();
        delete tcpServer;
        return nullptr;
    }

    if (!httpServer->bind(tcpServer)) {
        qWarning() << "SharedServicesAdapter: failed to bind embedded HTTP server" << serviceId;
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
SharedServicesAdapter::syncAllEmbeddedServers()
{
    if (!lrcInstance_)
        return;
    const auto accountIds = lrcInstance_->accountModel().getAccountList();
    for (const auto& accountId : accountIds)
        syncEmbeddedServers(accountId);
}

void
SharedServicesAdapter::syncEmbeddedServers(const QString& accountId)
{
    if (accountId.isEmpty())
        return;

    auto& configurationManager = NetworkServiceManager::instance();
    const VectorMapStringString records = configurationManager.getSharedServices(accountId);
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
            configurationManager.updateSharedService(accountId, record);
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
SharedServicesAdapter::stopEmbeddedServer(const QString& accountId, const QString& serviceId)
{
    embeddedServers_.erase(embeddedServerKey(accountId, serviceId));
}

void
SharedServicesAdapter::stopEmbeddedServersForAccount(const QString& accountId)
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
SharedServicesAdapter::queryPeerServices(const QString& accountId, const QString& peerUri)
{
    const auto id = resolveAccountId(accountId);
    if (id.isEmpty() || peerUri.isEmpty())
        return 0;
    return NetworkServiceManager::instance().queryPeerServices(id, peerUri);
}

QString
SharedServicesAdapter::openServiceTunnel(const QString& accountId,
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
SharedServicesAdapter::closeServiceTunnel(const QString& accountId, const QString& tunnelId)
{
    const auto id = resolveAccountId(accountId);
    if (id.isEmpty() || tunnelId.isEmpty())
        return false;
    return NetworkServiceManager::instance().closeServiceTunnel(id, tunnelId);
}

QVariantList
SharedServicesAdapter::getActiveTunnels(const QString& accountId) const
{
    QVariantList out;
    const auto id = resolveAccountId(accountId);
    if (id.isEmpty())
        return out;
    const VectorMapStringString records = NetworkServiceManager::instance().getActiveTunnels(id);
    out.reserve(records.size());
    for (const auto& m : records)
        out.append(mapToVariant(m));
    return out;
}
