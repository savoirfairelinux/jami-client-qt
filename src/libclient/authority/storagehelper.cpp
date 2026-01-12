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
#include "storagehelper.h"

#include "api/profile.h"
#include "api/conversation.h"
#include "api/datatransfer.h"
#include "uri.h"
#include "vcard.h"

#include <account_const.h>
#include <datatransfer_interface.h>

#include <QImage>
#include <QByteArray>
#include <QBuffer>
#include <QJsonObject>
#include <QJsonDocument>

#include <fstream>
#include <filesystem>
#include <thread>
#include <cstring>

namespace lrc {

namespace authority {

namespace storage {

QString
getPath()
{
#ifdef Q_OS_WIN
    auto definedDataDir = qEnvironmentVariable("JAMI_DATA_HOME");
    if (!definedDataDir.isEmpty())
        return QDir(definedDataDir).absolutePath() + "/";
#endif
    QDir dataDir(QStandardPaths::writableLocation(QStandardPaths::AppLocalDataLocation));
    // Avoid to depends on the client name.
    dataDir.cdUp();
    return dataDir.absolutePath() + "/jami/";
}

static QString
profileVcardPath(const QString& accountId, const QString& uri, bool ov = false)
{
    auto accountLocalPath = getPath() + accountId + QDir::separator();
    if (uri.isEmpty())
        return accountLocalPath + "profile.vcf";

    auto fileName = QString(uri.toUtf8().toBase64());
    return accountLocalPath + "profiles" + QDir::separator() + fileName + (ov ? "_o.vcf" : ".vcf");
}

static QString
stringFromJSON(const QJsonObject& json)
{
    QJsonDocument doc(json);
    return QString::fromLocal8Bit(doc.toJson(QJsonDocument::Compact));
}

static QJsonObject
JSONFromString(const QString& str)
{
    QJsonObject json;
    QJsonDocument doc = QJsonDocument::fromJson(str.toUtf8());

    if (!doc.isNull()) {
        if (doc.isObject()) {
            json = doc.object();
        } else {
            qDebug() << "Document is not a JSON object: " << str;
        }
    } else {
        qDebug() << "Invalid JSON: " << str;
    }
    return json;
}

static QString
readJSONValue(const QJsonObject& json, const QString& key)
{
    if (!json.isEmpty() && json.contains(key) && json[key].isString()) {
        if (json[key].isString()) {
            return json[key].toString();
        }
    }
    return {};
}

static void
writeJSONValue(QJsonObject& json, const QString& key, const QString& value)
{
    json[key] = value;
}

QString
prepareUri(const QString& uri, api::profile::Type type)
{
    URI uriObject(uri);
    switch (type) {
    case api::profile::Type::SIP:
        return uriObject.format(URI::Section::USER_INFO | URI::Section::HOSTNAME);
        break;
    case api::profile::Type::JAMI:
        return uriObject.format(URI::Section::USER_INFO);
        break;
    case api::profile::Type::INVALID:
    case api::profile::Type::PENDING:
    case api::profile::Type::TEMPORARY:
    case api::profile::Type::COUNT__:
    default:
        return uri;
    }
}

namespace vcard {

QString
compressedAvatar(const QString& image)
{
    QImage qimage;
    // Avoid to use all formats. Some seems bugguy, like libpbf, asking
    // for a QGuiApplication for QFontDatabase
    auto ret = qimage.loadFromData(QByteArray::fromBase64(image.toUtf8()), "JPEG");
    if (!ret)
        ret = qimage.loadFromData(QByteArray::fromBase64(image.toUtf8()), "PNG");
    if (!ret) {
        qDebug() << "vCard image loading failed";
        return "";
    }
    QByteArray bArray;
    QBuffer buffer(&bArray);
    buffer.open(QIODevice::WriteOnly);

    auto size = qMin(qimage.width(), qimage.height());
    auto rect = QRect((qimage.width() - size) / 2, (qimage.height() - size) / 2, size, size);
    constexpr auto quality = 88;        // Same as android, between 80 and 90 jpeg compression changes a lot
    constexpr auto maxSize = 16000 * 8; // Because 16*3 (rgb) = 48k, which is a valid size for the
                                        // DHT and * 8 because typical jpeg compression
    // divides the size per 8
    while (size * size > maxSize)
        size /= 2;
    qimage.copy(rect).scaled({size, size}, Qt::KeepAspectRatio).save(&buffer, "JPEG", quality);
    auto b64Img = bArray.toBase64().trimmed();
    return QString::fromLocal8Bit(b64Img.constData(), b64Img.length());
}

QString
profileToVcard(const api::profile::Info& profileInfo, bool compressImage)
{
    using namespace api;
    bool compressedImage = std::strncmp(profileInfo.avatar.toStdString().c_str(), "/9j/", 4) == 0;
    if (compressedImage && !compressImage) {
        compressImage = false;
    }
    QString vCardStr = vCard::Delimiter::BEGIN_TOKEN;
    vCardStr += vCard::Delimiter::END_LINE_TOKEN;
    vCardStr += vCard::Property::VERSION;
    vCardStr += ":2.1";
    vCardStr += vCard::Delimiter::END_LINE_TOKEN;
    vCardStr += vCard::Property::FORMATTED_NAME;
    vCardStr += ":";
    vCardStr += profileInfo.alias;
    vCardStr += vCard::Delimiter::END_LINE_TOKEN;
    if (profileInfo.type == profile::Type::JAMI) {
        vCardStr += vCard::Property::TELEPHONE;
        vCardStr += vCard::Delimiter::SEPARATOR_TOKEN;
        vCardStr += "other:ring:";
        vCardStr += profileInfo.uri;
        vCardStr += vCard::Delimiter::END_LINE_TOKEN;
    } else {
        vCardStr += vCard::Property::TELEPHONE;
        vCardStr += ":";
        vCardStr += profileInfo.uri;
        vCardStr += vCard::Delimiter::END_LINE_TOKEN;
    }
    vCardStr += vCard::Property::PHOTO;
    vCardStr += vCard::Delimiter::SEPARATOR_TOKEN;
    vCardStr += vCard::Property::BASE64;
    vCardStr += vCard::Delimiter::SEPARATOR_TOKEN;
    if (compressImage) {
        vCardStr += vCard::Property::TYPE_JPEG;
        vCardStr += ":";
        vCardStr += compressedImage ? profileInfo.avatar : compressedAvatar(profileInfo.avatar);
    } else {
        vCardStr += compressedImage ? vCard::Property::TYPE_JPEG : vCard::Property::TYPE_PNG;
        vCardStr += ":";
        vCardStr += profileInfo.avatar;
    }
    vCardStr += vCard::Delimiter::END_LINE_TOKEN;
    vCardStr += vCard::Delimiter::END_TOKEN;
    return vCardStr;
}

void
setProfile(const QString& accountId, const api::profile::Info& profileInfo, bool isPeer, bool ov)
{
    withProfile(
        accountId,
        isPeer ? profileInfo.uri : "",
        QIODevice::WriteOnly,
        [&](const QByteArray&, QTextStream& stream) { stream << profileToVcard(profileInfo, ov); },
        isPeer ? ov : false);
}
} // namespace vcard

VectorString
getConversationsWithPeer(Database& db, const QString& participant_uri)
{
    return db.select("id", "conversations", "participant=:participant", {{":participant", participant_uri}}).payloads;
}

VectorString
getPeerParticipantsForConversation(Database& db, const QString& conversationId)
{
    return db.select("participant", "conversations", "id=:id", {{":id", conversationId}}).payloads;
}

void
createOrUpdateProfile(const QString& accountId, const api::profile::Info& profileInfo, bool ov)
{
    auto contact = storage::buildContactFromProfile(accountId, profileInfo.uri, profileInfo.type);
    if (!profileInfo.alias.isEmpty())
        contact.profileInfo.alias = profileInfo.alias;
    if (!profileInfo.avatar.isEmpty())
        contact.profileInfo.avatar = profileInfo.avatar;
    vcard::setProfile(accountId, contact.profileInfo, true /*isPeer*/, ov);
}

void
removeProfile(const QString& accountId, const QString& peerUri)
{
    auto path = profileVcardPath(accountId, peerUri);
    if (!QFile::remove(path)) {
        qWarning() << "Couldn't remove vcard for" << peerUri << "at" << path;
    }
    auto overridePath = profileVcardPath(accountId, peerUri, true);
    QFile::remove(overridePath);
}

QString
getAccountAvatar(const QString& accountId)
{
    QString avatar;
    withProfile(
        accountId,
        "",
        QIODevice::ReadOnly,
        [&](const QByteArray& readData, QTextStream&) {
            QHash<QByteArray, QByteArray> vCard = lrc::vCard::utils::toHashMap(readData);
            for (auto it = vCard.cbegin(); it != vCard.cend(); ++it)
                if (it.key().contains("PHOTO")) {
                    avatar = it.value();
                    return;
                }
        },
        false);
    return avatar;
}

static QPair<QString, QString>
getOverridenInfos(const QString& accountId, const QString& peerUri)
{
    QString overridenAlias, overridenAvatar;
    withProfile(
        accountId,
        peerUri,
        QIODevice::ReadOnly,
        [&](const QByteArray& readData, QTextStream&) {
            QHash<QByteArray, QByteArray> vCard = lrc::vCard::utils::toHashMap(readData);
            overridenAlias = vCard[vCard::Property::FORMATTED_NAME];
            for (auto it = vCard.cbegin(); it != vCard.cend(); ++it)
                if (it.key().contains("PHOTO")) {
                    overridenAvatar = it.value();
                    return;
                }
        },
        true);
    return {overridenAlias, overridenAvatar};
}

api::contact::Info
buildContactFromProfile(const QString& accountId, const QString& peerUri, const api::profile::Type& type)
{
    // Get base contact info
    lrc::api::profile::Info profileInfo;
    profileInfo.uri = peerUri;
    profileInfo.type = type;

    // Try to get overriden infos first
    auto [overridenAlias, overridenAvatar] = getOverridenInfos(accountId, peerUri);
    if (!overridenAlias.isEmpty())
        profileInfo.alias = overridenAlias;
    if (!overridenAvatar.isEmpty())
        profileInfo.avatar = overridenAvatar;

    // If either alias or avatar is empty, get from profile
    if (profileInfo.alias.isEmpty() || profileInfo.avatar.isEmpty()) {
        withProfile(
            accountId,
            peerUri,
            QIODevice::ReadOnly,
            [&](const QByteArray& readData, QTextStream&) {
                QHash<QByteArray, QByteArray> vCard = lrc::vCard::utils::toHashMap(readData);
                if (profileInfo.alias.isEmpty())
                    profileInfo.alias = vCard[vCard::Property::FORMATTED_NAME];
                if (profileInfo.avatar.isEmpty())
                    for (auto it = vCard.cbegin(); it != vCard.cend(); ++it)
                        if (it.key().contains("PHOTO")) {
                            profileInfo.avatar = it.value();
                            return;
                        }
            },
            false);
    }

    return {profileInfo, "", type == api::profile::Type::JAMI, false};
}

bool
withProfile(
    const QString& accountId, const QString& peerUri, QIODevice::OpenMode flags, ProfileLoadedCb&& callback, bool ov)
{
    QString path = profileVcardPath(accountId, !peerUri.isEmpty() ? peerUri : "", ov);

    // Ensure the directory exists if we are writing
    if (flags & QIODevice::WriteOnly && !QDir().mkpath((QFileInfo(path).absolutePath()))) {
        LC_WARN << "Cannot create directory for path:" << path;
        return false;
    }

    // Add QIODevice::Text to the flags
    flags |= QIODevice::Text;

    QFile file(path);
    if (!file.open(flags)) {
        LC_DBG << "Can't open file:" << path;
        return false;
    }

    QByteArray readData;
    QTextStream outStream(&file);
    if (flags & QIODevice::ReadOnly) {
        readData = file.readAll();
    }

    // Log what we are doing with the profile for now
    LC_DBG << (flags & QIODevice::ReadOnly ? "Reading" : "Writing") << "profile:" << path;

    // Execute the callback with readData and outStream
    callback(readData, outStream);

    file.close();
    return true;
}

QMap<QString, QString>
getProfileData(const QString& accountId, const QString& peerUri)
{
    QMap<QString, QString> profileData;

    // Try to get overriden infos first
    auto [overridenAlias, overridenAvatar] = getOverridenInfos(accountId, peerUri);
    if (!overridenAlias.isEmpty())
        profileData["alias"] = overridenAlias;
    if (!overridenAvatar.isEmpty())
        profileData["avatar"] = overridenAvatar;

    // If either alias or avatar is empty, get from profile
    if (profileData["alias"].isEmpty() || profileData["avatar"].isEmpty()) {
        withProfile(
            accountId,
            peerUri,
            QIODevice::ReadOnly,
            [&](const QByteArray& readData, QTextStream&) {
                QHash<QByteArray, QByteArray> vCard = lrc::vCard::utils::toHashMap(readData);
                if (profileData["alias"].isEmpty())
                    profileData["alias"] = vCard[vCard::Property::FORMATTED_NAME];
                if (profileData["avatar"].isEmpty())
                    for (auto it = vCard.cbegin(); it != vCard.cend(); ++it)
                        if (it.key().contains("PHOTO")) {
                            profileData["avatar"] = it.value();
                            return;
                        }
            },
            false);
    }

    return profileData;
}

QString
avatar(const QString& accountId, const QString& peerUri)
{
    if (peerUri.isEmpty())
        return getAccountAvatar(accountId);

    auto [_, overridenAvatar] = getOverridenInfos(accountId, peerUri);
    if (!overridenAvatar.isEmpty())
        return overridenAvatar;

    QString avatar;
    withProfile(
        accountId,
        peerUri,
        QIODevice::ReadOnly,
        [&](const QByteArray& readData, QTextStream&) {
            QHash<QByteArray, QByteArray> vCard = lrc::vCard::utils::toHashMap(readData);
            for (auto it = vCard.cbegin(); it != vCard.cend(); ++it)
                if (it.key().contains("PHOTO")) {
                    avatar = it.value();
                    return;
                }
        },
        false);

    return avatar;
}

VectorString
getAllConversations(Database& db)
{
    return db.select("id", "conversations", {}, {}).payloads;
}

VectorString
getConversationsBetween(Database& db, const QString& peer1_uri, const QString& peer2_uri)
{
    auto conversationsForPeer1 = getConversationsWithPeer(db, peer1_uri);
    std::sort(conversationsForPeer1.begin(), conversationsForPeer1.end());
    auto conversationsForPeer2 = getConversationsWithPeer(db, peer2_uri);
    std::sort(conversationsForPeer2.begin(), conversationsForPeer2.end());
    VectorString common;

    std::set_intersection(conversationsForPeer1.begin(),
                          conversationsForPeer1.end(),
                          conversationsForPeer2.begin(),
                          conversationsForPeer2.end(),
                          std::back_inserter(common));
    return common;
}

QString
beginConversationWithPeer(Database& db, const QString& peer_uri, const bool isOutgoing, time_t timestamp)
{
    // Add conversation between account and profile
    auto newConversationsId = db.select("IFNULL(MAX(id), 0) + 1", "conversations", "1=1", {}).payloads[0];
    db.insertInto("conversations",
                  {{":id", "id"}, {":participant", "participant"}},
                  {{":id", newConversationsId}, {":participant", peer_uri}});
    api::interaction::Info msg = api::interaction::Info::contact(isOutgoing ? "" : peer_uri, timestamp);
    // Add first interaction
    addMessageToConversation(db, newConversationsId, msg);
    return newConversationsId;
}

QString
getContactInteractionString(const QString& authorUri, const api::interaction::Status& status)
{
    if (authorUri.isEmpty()) {
        return QObject::tr("Contact added");
    } else {
        if (status == api::interaction::Status::UNKNOWN) {
            return QObject::tr("Invitation received");
        } else if (status == api::interaction::Status::SUCCESS) {
            return QObject::tr("Invitation accepted");
        }
    }
    return {};
}

void
getHistory(Database& db, api::conversation::Info& conversation, const QString& localUri)
{
    auto interactionsResult = db.select("id, author, body, timestamp, type, status, is_read, extra_data",
                                        "interactions",
                                        "conversation=:conversation",
                                        {{":conversation", conversation.uid}});
    auto nCols = 8;
    if (interactionsResult.nbrOfCols != nCols)
        return;

    auto payloads = interactionsResult.payloads;
    for (decltype(payloads.size()) i = 0; i < payloads.size(); i += nCols) {
        QString durationString;
        auto extra_data_str = payloads[i + 7];
        if (!extra_data_str.isEmpty()) {
            auto jsonData = JSONFromString(extra_data_str);
            durationString = readJSONValue(jsonData, "duration");
        }
        auto body = payloads[i + 2];
        auto type = api::interaction::to_type(payloads[i + 4]);
        std::time_t duration = durationString.isEmpty() ? 0 : std::stoi(durationString.toStdString());
        auto status = api::interaction::to_status(payloads[i + 5]);
        if (type == api::interaction::Type::CALL) {
            body = api::interaction::getCallInteractionStringNonSwarm(payloads[i + 1] == localUri, duration);
        } else if (type == api::interaction::Type::CONTACT) {
            body = storage::getContactInteractionString(payloads[i + 1], status);
        }
        auto msg = api::interaction::Info({payloads[i + 1],
                                           body,
                                           std::stoi(payloads[i + 3].toStdString()),
                                           duration,
                                           type,
                                           status,
                                           (payloads[i + 6] == "1" ? true : false)});
        conversation.interactions->append(payloads[i], std::move(msg));
        if (status != api::interaction::Status::DISPLAYED || !payloads[i + 1].isEmpty()) {
            continue;
        }
        conversation.interactions->setRead(conversation.participants.front().uri, payloads[i]);
    }
}

QString
addMessageToConversation(Database& db, const QString& conversationId, const api::interaction::Info& msg)
{
    return db.insertInto("interactions",
                         {{":author", "author"},
                          {":conversation", "conversation"},
                          {":timestamp", "timestamp"},
                          {":body", "body"},
                          {":type", "type"},
                          {":status", "status"},
                          {":is_read", "is_read"}},
                         {{":author", msg.authorUri},
                          {":conversation", conversationId},
                          {":timestamp", toQString(msg.timestamp)},
                          {":body", msg.body},
                          {":type", to_string(msg.type)},
                          {":status", to_string(msg.status)},
                          {":is_read", msg.isRead ? "1" : "0"}});
}

QString
addOrUpdateMessage(Database& db,
                   const QString& conversationId,
                   const api::interaction::Info& msg,
                   const QString& daemonId)
{
    // Check if profile is already present.
    auto msgAlreadyExists = db.select("id",
                                      "interactions",
                                      "author=:author AND daemon_id=:daemon_id",
                                      {{":author", msg.authorUri}, {":daemon_id", daemonId}})
                                .payloads;
    if (msgAlreadyExists.empty()) {
        auto extra_data_JSON = JSONFromString("");
        writeJSONValue(extra_data_JSON, "duration", QString::number(msg.duration));
        auto extra_data = stringFromJSON(extra_data_JSON);
        return db.insertInto("interactions",
                             {{":author", "author"},
                              {":conversation", "conversation"},
                              {":timestamp", "timestamp"},
                              {":body", "body"},
                              {":type", "type"},
                              {":status", "status"},
                              {":daemon_id", "daemon_id"},
                              {":extra_data", "extra_data"}},
                             {{":author", msg.authorUri.isEmpty() ? "" : msg.authorUri},
                              {":conversation", conversationId},
                              {":timestamp", toQString(msg.timestamp)},
                              {msg.body.isEmpty() ? "" : ":body", msg.body},
                              {":type", to_string(msg.type)},
                              {daemonId.isEmpty() ? "" : ":daemon_id", daemonId},
                              {":status", to_string(msg.status)},
                              {extra_data.isEmpty() ? "" : ":extra_data", extra_data}});
    } else {
        // already exists @ id(msgAlreadyExists[0])
        auto id = msgAlreadyExists[0];
        QString extra_data;
        if (msg.type == api::interaction::Type::CALL) {
            auto duration = std::max(msg.duration, static_cast<std::time_t>(0));
            auto extra_data_str = getInteractionExtraDataById(db, id);
            auto extra_data_JSON = JSONFromString(extra_data_str);
            writeJSONValue(extra_data_JSON, "duration", QString::number(duration));
            extra_data = stringFromJSON(extra_data_JSON);
        }
        db.update("interactions",
                  {"body=:body, extra_data=:extra_data"},
                  {{msg.body.isEmpty() ? "" : ":body", msg.body},
                   {extra_data.isEmpty() ? "" : ":extra_data", extra_data}},
                  "id=:id",
                  {{":id", id}});
        return id;
    }
}

QString
addDataTransferToConversation(Database& db, const QString& conversationId, const api::datatransfer::Info& infoFromDaemon)
{
    auto convId = conversationId.isEmpty() ? NULL : conversationId;
    return db.insertInto("interactions",
                         {{":author", "author"},
                          {":conversation", "conversation"},
                          {":timestamp", "timestamp"},
                          {":body", "body"},
                          {":type", "type"},
                          {":status", "status"},
                          {":is_read", "is_read"},
                          {":daemon_id", "daemon_id"}},
                         {{":author", infoFromDaemon.isOutgoing ? "" : infoFromDaemon.peerUri},
                          {":conversation", convId},
                          {":timestamp", toQString(std::time(nullptr))},
                          {":body", infoFromDaemon.path},
                          {":type", "DATA_TRANSFER"},
                          {":status", "TRANSFER_CREATED"},
                          {":is_read", "0"},
                          {":daemon_id", infoFromDaemon.uid}});
}

void
addDaemonMsgId(Database& db, const QString& interactionId, const QString& daemonId)
{
    db.update("interactions", "daemon_id=:daemon_id", {{":daemon_id", daemonId}}, "id=:id", {{":id", interactionId}});
}

QString
getDaemonIdByInteractionId(Database& db, const QString& id)
{
    auto ids = db.select("daemon_id", "interactions", "id=:id", {{":id", id}}).payloads;
    return ids.empty() ? "" : ids[0];
}

QString
getInteractionIdByDaemonId(Database& db, const QString& daemon_id)
{
    auto ids = db.select("id", "interactions", "daemon_id=:daemon_id", {{":daemon_id", daemon_id}}).payloads;
    return ids.empty() ? "" : ids[0];
}

void
updateDataTransferInteractionForDaemonId(Database& db, const QString& daemonId, api::interaction::Info& interaction)
{
    auto result = db.select("body, status", "interactions", "daemon_id=:daemon_id", {{":daemon_id", daemonId}}).payloads;
    if (result.size() < 2) {
        return;
    }
    auto body = result[0];
    auto status = api::interaction::to_transferStatus(result[1]);
    interaction.body = body;
    interaction.transferStatus = status;
}

QString
getInteractionExtraDataById(Database& db, const QString& id, const QString& key)
{
    auto extra_datas = db.select("extra_data", "interactions", "id=:id", {{":id", id}}).payloads;
    if (key.isEmpty()) {
        return extra_datas.empty() ? "" : extra_datas[0];
    }
    QString value;
    if (!extra_datas[0].isEmpty()) {
        value = readJSONValue(JSONFromString(extra_datas[0]), key);
    }
    return value;
}

void
updateInteractionBody(Database& db, const QString& id, const QString& newBody)
{
    db.update("interactions", "body=:body", {{":body", newBody}}, "id=:id", {{":id", id}});
}

void
updateInteractionStatus(Database& db, const QString& id, api::interaction::Status newStatus)
{
    db.update("interactions",
              {"status=:status"},
              {{":status", api::interaction::to_string(newStatus)}},
              "id=:id",
              {{":id", id}});
}

void
updateInteractionTransferStatus(Database& db, const QString& id, api::interaction::TransferStatus newStatus)
{
    db.update("interactions",
              {"status=:status"},
              {{":status", api::interaction::to_string(newStatus)}},
              "id=:id",
              {{":id", id}});
}

void
setInteractionRead(Database& db, const QString& id)
{
    db.update("interactions", {"is_read=:is_read"}, {{":is_read", "1"}}, "id=:id", {{":id", id}});
}

QString
conversationIdFromInteractionId(Database& db, const QString& interactionId)
{
    auto result = db.select("conversation", "interactions", "id=:id", {{":id", interactionId}});
    if (result.nbrOfCols == 1 && result.payloads.size()) {
        return result.payloads[0];
    }
    return {};
}

void
clearHistory(Database& db, const QString& conversationId)
{
    try {
        db.deleteFrom("interactions", "conversation=:conversation", {{":conversation", conversationId}});
    } catch (Database::QueryDeleteError& e) {
        qWarning() << "deleteFrom error: " << e.details();
    }
}

void
clearAllHistory(Database& db)
{
    try {
        db.deleteFrom("interactions", "1=1", {});
    } catch (Database::QueryDeleteError& e) {
        qWarning() << "deleteFrom error: " << e.details();
    }
}

void
deleteObsoleteHistory(Database& db, long int date)
{
    try {
        db.deleteFrom("interactions", "timestamp<=:date", {{":date", QString::number(date)}});
    } catch (Database::QueryDeleteError& e) {
        qWarning() << "deleteFrom error: " << e.details();
    }
}

void
removeContactConversations(Database& db, const QString& contactUri)
{
    // Get common conversations
    auto conversations = getConversationsWithPeer(db, contactUri);
    // Remove conversations + interactions
    try {
        for (const auto& conversationId : conversations) {
            // Remove conversation
            db.deleteFrom("conversations", "id=:id", {{":id", conversationId}});
            // clear History
            db.deleteFrom("interactions", "conversation=:id", {{":id", conversationId}});
        }
    } catch (Database::QueryDeleteError& e) {
        qWarning() << "deleteFrom error: " << e.details();
    }
}

int
countUnreadFromInteractions(Database& db, const QString& conversationId)
{
    return db.count("is_read",
                    "interactions",
                    "is_read=:is_read AND conversation=:id",
                    {{":is_read", "0"}, {":id", conversationId}});
}

uint64_t
getLastTimestamp(Database& db)
{
    auto timestamps = db.select("MAX(timestamp)", "interactions", "1=1", {}).payloads;
    auto result = std::time(nullptr);
    try {
        if (!timestamps.empty() && !timestamps[0].isEmpty()) {
            result = std::stoull(timestamps[0].toStdString());
        }
    } catch (const std::out_of_range& e) {
        qDebug() << "storage::getLastTimestamp, stoull throws an out_of_range exception: " << e.what();
    } catch (const std::invalid_argument& e) {
        qDebug() << "storage::getLastTimestamp, stoull throws an invalid_argument exception: " << e.what();
    }
    return result;
}

} // namespace storage

} // namespace authority

} // namespace lrc
