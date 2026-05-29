/****************************************************************************
 *   Copyright (C) 2024-2026 Savoir-faire Linux Inc.                        *
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

#include "api/interaction.h"
#include "dbus/configurationmanager.h"

namespace lrc {

namespace api {

namespace interaction {

Info::Info(QString authorUri,
           QString body,
           std::time_t timestamp,
           std::time_t duration,
           Type type,
           Status status,
           bool isRead,
           TransferStatus transferStatus)
{
    this->authorUri = authorUri;
    this->body = body;
    this->timestamp = timestamp;
    this->duration = duration;
    this->type = type;
    this->status = status;
    this->isRead = isRead;
    this->transferStatus = transferStatus;
}

Info
Info::contact(const QString& authorUri, std::time_t timestamp)
{
    return Info(authorUri,
                "",
                timestamp,
                0,
                Type::CONTACT,
                authorUri.isEmpty() ? Status::UNKNOWN : Status::SUCCESS,
                authorUri.isEmpty());
}

bool
Info::sent() const
{
    return status == Status::SUCCESS || status == Status::DISPLAYED;
}

void
Info::init(const MapStringString& message,
           const QString& accountURI,
           const QString& accountId,
           const QString& conversationId)
{
    type = to_type(message["type"]);
    if (message.contains("react-to") && type == Type::TEXT) {
        type = to_type("REACTION");
        react_to = message["react-to"];
    }
    authorUri = message["author"];

    if (type == Type::TEXT) {
        body = message["body"];
    }
    timestamp = message["timestamp"].toInt();
    status = Status::SUCCESS;
    parentId = message["linearizedParent"];
    isRead = false;
    if (type == Type::CONTACT) {
        authorUri = accountURI == message["uri"] ? "" : message["uri"];
    } else if (type == Type::INITIAL) {
        if (message["mode"] == "0") {
            body = QObject::tr("Private conversation created");
        } else {
            body = QObject::tr("Group conversation created");
        }
    } else if (type == Type::CALL) {
        duration = message["duration"].toInt() / 1000;
        if (message.contains("confId"))
            confId = message["confId"];
    } else if (type == Type::DATA_TRANSFER) {
        QString path;
        qlonglong bytesProgress, totalSize;
        ConfigurationManager::instance()
            .fileTransferInfo(accountId, conversationId, message["fileId"], path, totalSize, bytesProgress);
        QFileInfo fi(path);
        body = fi.isSymLink() ? fi.symLinkTarget() : path;
        transferStatus = bytesProgress == 0           ? TransferStatus::TRANSFER_AWAITING_HOST
                         : bytesProgress == totalSize ? TransferStatus::TRANSFER_FINISHED
                                                      : TransferStatus::TRANSFER_ONGOING;
    }
    commit = message;
}

Info::Info(const MapStringString& message,
           const QString& accountURI,
           const QString& accountId,
           const QString& conversationId)
{
    init(message, accountURI, accountId, conversationId);
}

Info::Info(const SwarmMessage& msg, const QString& accountUri, const QString& accountId, const QString& conversationId)
{
    MapStringString msgBody;
    for (auto it = msg.body.cbegin(); it != msg.body.cend(); ++it) {
        const auto& key = it.key();
        const auto& value = it.value();
        msgBody.insert(key, value);
    }
    init(msgBody, accountUri, accountId, conversationId);
    parentId = msg.linearizedParent;
    type = to_type(msg.type);
    for (const auto& edition : msg.editions)
        previousBodies.append(
            Body {edition.value("id"), edition.value("body"), QString(edition.value("timestamp")).toInt()});
    QMap<QString, QVariantList> mapStringEmoji;
    for (const auto& reaction : msg.reactions) {
        auto author = reaction.value("author");
        auto body = reaction.value("body");
        auto emoji = Emoji {reaction.value("id"), body};
        QVariant variant = QVariant::fromValue(emoji);
        mapStringEmoji[author].append(variant);
    }
    for (auto i = mapStringEmoji.begin(); i != mapStringEmoji.end(); i++)
        reactions.insert(i.key(), i.value());
    // Compute the status of the message.
    // Basically, we got the status per member.
    // We consider the message as sent if at least one member has received it or displayed if
    // someone displayed it.
    auto maxStatus = 0;
    status = Status::SENDING;
    for (const auto& member : msg.status.keys()) {
        if (member == accountUri)
            continue;
        auto stValue = msg.status.value(member);
        if (stValue > maxStatus) {
            maxStatus = stValue;
            status = maxStatus <= 1 ? Status::SENDING : (stValue == 2 ? Status::SUCCESS : Status::DISPLAYED);
        }
        if (maxStatus == 3)
            break;
    }
}

} // namespace interaction
} // namespace api
} // namespace lrc