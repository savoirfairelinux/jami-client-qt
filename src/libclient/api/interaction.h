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

#include <QString>
#include <QObject>
#include <QFileInfo>

#include <ctime>
#include "typedefs.h"

namespace lrc {

namespace api {

namespace interaction {
Q_NAMESPACE
Q_CLASSINFO("RegisterEnumClassesUnscoped", "false")

enum class Type {
    INVALID,
    INITIAL,
    TEXT,
    CALL,
    CONTACT,
    DATA_TRANSFER,
    MERGE,
    EDITED,
    REACTION,
    VOTE,
    UPDATE_PROFILE,
    COUNT__
};
Q_ENUM_NS(Type)

static inline bool
isTypeDisplayable(const Type& type)
{
    return type != interaction::Type::VOTE && type != interaction::Type::UPDATE_PROFILE;
}

static inline const QString
to_string(const Type& type)
{
    switch (type) {
    case Type::TEXT:
        return "TEXT";
    case Type::INITIAL:
        return "INITIAL";
    case Type::CALL:
        return "CALL";
    case Type::CONTACT:
        return "CONTACT";
    case Type::DATA_TRANSFER:
        return "DATA_TRANSFER";
    case Type::MERGE:
        return "MERGE";
    case Type::VOTE:
        return "VOTE";
    case Type::UPDATE_PROFILE:
        return "UPDATE_PROFILE";
    case Type::EDITED:
        return "EDITED";
    case Type::REACTION:
        return "REACTION";
    case Type::INVALID:
    case Type::COUNT__:
    default:
        return "INVALID";
    }
}

static inline Type
to_type(const QString& type)
{
    if (type == "INITIAL" || type == "initial")
        return interaction::Type::INITIAL;
    else if (type == "TEXT" || type == TEXT_PLAIN)
        return interaction::Type::TEXT;
    else if (type == "REACTION")
        return interaction::Type::REACTION;
    else if (type == "CALL" || type == "application/call-history+json")
        return interaction::Type::CALL;
    else if (type == "CONTACT" || type == "member")
        return interaction::Type::CONTACT;
    else if (type == "DATA_TRANSFER" || type == "application/data-transfer+json")
        return interaction::Type::DATA_TRANSFER;
    else if (type == "merge")
        return interaction::Type::MERGE;
    else if (type == "application/update-profile")
        return interaction::Type::UPDATE_PROFILE;
    else if (type == "vote")
        return interaction::Type::VOTE;
    else if (type == "application/edited-message")
        return interaction::Type::EDITED;
    else
        return interaction::Type::INVALID;
}

enum class Status { INVALID, UNKNOWN, SENDING, FAILURE, SUCCESS, DISPLAYED, COUNT__ };
Q_ENUM_NS(Status)

enum class TransferStatus {
    INVALID,
    TRANSFER_CREATED,
    TRANSFER_ACCEPTED,
    TRANSFER_CANCELED,
    TRANSFER_ERROR,
    TRANSFER_UNJOINABLE_PEER,
    TRANSFER_ONGOING,
    TRANSFER_AWAITING_PEER,
    TRANSFER_AWAITING_HOST,
    TRANSFER_TIMEOUT_EXPIRED,
    TRANSFER_FINISHED,
    COUNT__
};
Q_ENUM_NS(TransferStatus)

static inline const QString
to_string(const Status& status)
{
    switch (status) {
    case Status::UNKNOWN:
        return "UNKNOWN";
    case Status::SENDING:
        return "SENDING";
    case Status::FAILURE:
        return "FAILURE";
    case Status::SUCCESS:
        return "SUCCESS";
    case Status::DISPLAYED:
        return "DISPLAYED";
    case Status::INVALID:
    case Status::COUNT__:
    default:
        return "INVALID";
    }
}

static inline Status
to_status(const QString& status)
{
    if (status == "UNKNOWN")
        return Status::UNKNOWN;
    else if (status == "SENDING")
        return Status::SENDING;
    else if (status == "FAILURE")
        return Status::FAILURE;
    else if (status == "SUCCESS")
        return Status::SUCCESS;
    else if (status == "DISPLAYED")
        return Status::DISPLAYED;
    else
        return Status::INVALID;
}

static inline const QString
to_string(const TransferStatus& status)
{
    switch (status) {
    case TransferStatus::TRANSFER_CREATED:
        return "TRANSFER_CREATED";
    case TransferStatus::TRANSFER_ACCEPTED:
        return "TRANSFER_ACCEPTED";
    case TransferStatus::TRANSFER_CANCELED:
        return "TRANSFER_CANCELED";
    case TransferStatus::TRANSFER_ERROR:
        return "TRANSFER_ERROR";
    case TransferStatus::TRANSFER_UNJOINABLE_PEER:
        return "TRANSFER_UNJOINABLE_PEER";
    case TransferStatus::TRANSFER_ONGOING:
        return "TRANSFER_ONGOING";
    case TransferStatus::TRANSFER_AWAITING_HOST:
        return "TRANSFER_AWAITING_HOST";
    case TransferStatus::TRANSFER_AWAITING_PEER:
        return "TRANSFER_AWAITING_PEER";
    case TransferStatus::TRANSFER_TIMEOUT_EXPIRED:
        return "TRANSFER_TIMEOUT_EXPIRED";
    case TransferStatus::TRANSFER_FINISHED:
        return "TRANSFER_FINISHED";
    case TransferStatus::INVALID:
    case TransferStatus::COUNT__:
    default:
        return "INVALID";
    }
}

static inline TransferStatus
to_transferStatus(const QString& status)
{
    if (status == "TRANSFER_CREATED")
        return TransferStatus::TRANSFER_CREATED;
    else if (status == "TRANSFER_ACCEPTED")
        return TransferStatus::TRANSFER_ACCEPTED;
    else if (status == "TRANSFER_CANCELED")
        return TransferStatus::TRANSFER_CANCELED;
    else if (status == "TRANSFER_ERROR")
        return TransferStatus::TRANSFER_ERROR;
    else if (status == "TRANSFER_UNJOINABLE_PEER")
        return TransferStatus::TRANSFER_UNJOINABLE_PEER;
    else if (status == "TRANSFER_ONGOING")
        return TransferStatus::TRANSFER_ONGOING;
    else if (status == "TRANSFER_AWAITING_HOST")
        return TransferStatus::TRANSFER_AWAITING_HOST;
    else if (status == "TRANSFER_AWAITING_PEER")
        return TransferStatus::TRANSFER_AWAITING_PEER;
    else if (status == "TRANSFER_TIMEOUT_EXPIRED")
        return TransferStatus::TRANSFER_TIMEOUT_EXPIRED;
    else if (status == "TRANSFER_FINISHED")
        return TransferStatus::TRANSFER_FINISHED;
    else
        return TransferStatus::INVALID;
}

enum class ContactAction { ADD, JOIN, LEAVE, BANNED, UNBANNED, INVALID };
Q_ENUM_NS(ContactAction)

static inline const QString
to_string(const ContactAction& action)
{
    switch (action) {
    case ContactAction::ADD:
        return "ADD";
    case ContactAction::JOIN:
        return "JOIN";
    case ContactAction::LEAVE:
        return "LEAVE";
    case ContactAction::BANNED:
        return "BANNED";
    case ContactAction::UNBANNED:
        return "UNBANNED";
    case ContactAction::INVALID:
        return {};
    }
    return {};
}

static inline ContactAction
to_action(const QString& action)
{
    if (action == "add")
        return ContactAction::ADD;
    else if (action == "join")
        return ContactAction::JOIN;
    else if (action == "remove")
        return ContactAction::LEAVE;
    else if (action == "ban")
        return ContactAction::BANNED;
    else if (action == "unban")
        return ContactAction::UNBANNED;
    return ContactAction::INVALID;
}

static inline QString
getContactInteractionString(const QString& authorUri, const ContactAction& action)
{
    switch (action) {
    case ContactAction::ADD:
        if (authorUri.isEmpty()) {
            return QObject::tr("Contact added");
        }
        return QObject::tr("%1 was invited to join the conversation.").arg(authorUri);
    case ContactAction::JOIN:
        if (authorUri.isEmpty()) {
            return QObject::tr("You joined the conversation.");
        }
        return QObject::tr("%1 has joined the conversation.").arg(authorUri);
    case ContactAction::LEAVE:
        if (authorUri.isEmpty()) {
            return QObject::tr("You left the conversation.");
        }
        return QObject::tr("%1 has left the conversation.").arg(authorUri);
    case ContactAction::BANNED:
        return QObject::tr("%1 was blocked from the conversation.").arg(authorUri);
    case ContactAction::UNBANNED:
        return QObject::tr("%1 was unblocked from the conversation.").arg(authorUri);
    case ContactAction::INVALID:
        return QObject::tr("Contact added");
    }
    return QObject::tr("Contact added");
}

static inline QString
getFormattedCallDuration(const std::time_t duration)
{
    if (duration == 0)
        return {};

    int seconds = duration % 60;
    int minutes = duration / 60;
    int hours = minutes / 60;
    int days = hours / 24;

    if (days > 0) {
        hours = hours % 24;
        minutes = minutes % 60;
        return QObject::tr("%L4d %L3h %L2m %L1s").arg(seconds).arg(minutes).arg(hours).arg(days);
    } else if (hours > 0) {
        minutes = minutes % 60;
        return QObject::tr("%L3h %L2m %L1s").arg(seconds).arg(minutes).arg(hours);
    } else if (minutes > 0) {
        return QObject::tr("%L2m %L1s").arg(seconds).arg(minutes);
    } else {
        return QObject::tr("%L1s").arg(seconds);
    }
}

/**
 * Get a formatted string for a call interaction's body
 * @param isSelf
 * @param info
 * @return the formatted and translated call message string
 */
static inline QString
getCallInteractionStringNonSwarm(bool isSelf, const std::time_t& duration, const QString& reason = "")
{
    if (reason == "busy") {
        return QObject::tr("Busy");
    } else if (reason == "declined") {
        return QObject::tr("Call declined");
    } else if (reason == "no_device") {
        return QObject::tr("Unreachable peer");
    }

    if (duration < 0) {
        if (isSelf) {
            return QObject::tr("Outgoing call");
        } else {
            return QObject::tr("Incoming call");
        }
    } else if (isSelf) {
        if (duration) {
            return QObject::tr("Outgoing call") + " - " + getFormattedCallDuration(duration);
        } else {
            return QObject::tr("Missed outgoing call");
        }
    } else {
        if (duration) {
            return QObject::tr("Incoming call") + " - " + getFormattedCallDuration(duration);
        } else {
            return QObject::tr("Missed incoming call");
        }
    }
}

struct Body
{
    Q_GADGET

    Q_PROPERTY(QString commitId MEMBER commitId)
    Q_PROPERTY(QString body MEMBER body)
    Q_PROPERTY(int timestamp MEMBER timestamp)
public:
    QString commitId;
    QString body;
    std::time_t timestamp;
};

struct Emoji
{
    Q_GADGET

    Q_PROPERTY(QString commitId MEMBER commitId)
    Q_PROPERTY(QString body MEMBER body)
public:
    QString commitId;
    QString body;
};

/**
 * @var authorUri
 * @var body
 * @var timestamp
 * @var duration
 * @var type
 * @var status
 * @var transferStatus
 * @var isRead
 * @var commit
 * @var linkPreviewInfo
 * @var parsedBody
 */
struct Info
{
    QString authorUri;
    QString body;
    QString parentId = "";
    QString confId;
    std::time_t timestamp = 0;
    std::time_t duration = 0;
    Type type = Type::INVALID;
    Status status = Status::INVALID;
    TransferStatus transferStatus = TransferStatus::INVALID;
    bool isRead = false;
    MapStringString commit;
    QVariantMap linkPreviewInfo = {};
    QString parsedBody = {};
    QVariantMap reactions;
    QString react_to;
    QVector<Body> previousBodies;

    Info() = default;

    Info(QString authorUri,
         QString body,
         std::time_t timestamp,
         std::time_t duration,
         Type type,
         Status status,
         bool isRead,
         TransferStatus transferStatus = TransferStatus::INVALID);

    static Info contact(const QString& authorUri, std::time_t timestamp);

    Info(const Info& other) = default;
    Info(Info&& other) = default;
    Info& operator=(const Info& other) = delete;
    Info& operator=(Info&& other) = default;

    bool sent() const;

    void init(const MapStringString& message,
              const QString& accountURI,
              const QString& accountId,
              const QString& conversationId);

    // NOTE: The `accountId` and `conversationId` arguments are only used for messages of
    // type DATA_TRANSFER. They can therefore be omitted if the caller knows that `message`
    // is of a different type. They must be provided otherwise, as failure to do so would
    // result in the `body` and `transferStatus` fields of the returned Info struct to
    // contain incorrect information whenever `message` is of type DATA_TRANSFER.
    Info(const MapStringString& message,
         const QString& accountURI,
         const QString& accountId = "",
         const QString& conversationId = "");

    Info(const SwarmMessage& msg, const QString& accountUri, const QString& accountId, const QString& conversationId);
};

static inline bool
isOutgoing(const Info& interaction)
{
    return interaction.authorUri.isEmpty();
}

static inline QString
getCallInteractionString(bool isSelf, const Info& info)
{
    if (!info.confId.isEmpty()) {
        if (info.duration <= 0) {
            return QObject::tr("Join call");
        }
    }
    return getCallInteractionStringNonSwarm(isSelf, info.duration, info.commit["reason"]);
}

static inline QString
getProfileUpdatedString()
{
    // Perhaps one day this will be more detailed.
    return QObject::tr("(Profile updated)");
}

} // namespace interaction
} // namespace api
} // namespace lrc
