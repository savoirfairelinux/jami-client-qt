/*
 *  Copyright (C) 2020-2023 Savoir-faire Linux Inc.
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301 USA.
 */

#include "api/messagelistmodel.h"

#include "api/accountmodel.h"
#include "api/contactmodel.h"
#include "api/conversationmodel.h"

#include <QFileInfo>

static bool
isOnlyEmoji(const QString& text)
{
    if (text.isEmpty())
        return false;
    auto codepointList = text.toUcs4();
    for (QList<uint>::iterator it = codepointList.begin(); it != codepointList.end(); it++) {
        auto cur = false;
        if (*it == 20 or *it == 0x200D) {
            cur = true;
        } else if (0x1f000 <= *it && 0x1ffff >= *it) {
            cur = true;
        } else if (0x2600 <= *it && 0x27BF >= *it) {
            cur = true;
        } else if (0xFE00 <= *it && 0xFE0f >= *it) {
            cur = true;
        } else if (0xE0000 <= *it && 0xE007F >= *it) {
            cur = true;
        }
        if (!cur)
            return false;
    }
    return true;
}

namespace lrc {

using namespace api;

MessageListModel::MessageListModel(const account::Info* account, QObject* parent)
    : QAbstractListModel(parent)
    , account_(account)
{}

int
MessageListModel::rowCount(const QModelIndex&) const
{
    std::lock_guard<std::recursive_mutex> lk(mutex_);
    return interactions_.size();
}

QVariant
MessageListModel::data(const QModelIndex& index, int role) const
{
    std::lock_guard<std::recursive_mutex> lk(mutex_);
    if (!index.isValid() || index.row() < 0 || index.row() >= rowCount()) {
        return {};
    }
    return dataForItem(interactions_.at(index.row()), index.row(), role);
}

QHash<int, QByteArray>
MessageListModel::roleNames() const
{
    using namespace MessageList;
    QHash<int, QByteArray> roles;
#define X(role) roles[role] = #role;
    MSG_ROLES
#undef X
    return roles;
}

QVariant
MessageListModel::data(const QString& id, int role) const
{
    return data(indexOfMessage(id), role);
}

bool
MessageListModel::empty() const
{
    std::lock_guard<std::recursive_mutex> lk(mutex_);
    return interactions_.empty();
}

int
MessageListModel::indexOfMessage(const QString& messageId) const
{
    std::lock_guard<std::recursive_mutex> lk(mutex_);
    auto it = std::find_if(interactions_.rbegin(),
                           interactions_.rend(),
                           [&messageId](const auto& it) { return it.first == messageId; });
    if (it == interactions_.rend()) {
        return -1;
    }
    return std::distance(it, interactions_.rend()) - 1;
}

void
MessageListModel::clear()
{
    std::lock_guard<std::recursive_mutex> lk(mutex_);
    beginResetModel();
    interactions_.clear();
    replyTo_.clear();
    endResetModel();
}

void
MessageListModel::reloadHistory()
{
    std::lock_guard<std::recursive_mutex> lk(mutex_);
    beginResetModel();
    for (auto& interaction : interactions_) {
        interaction.second.linkPreviewInfo.clear();
    }
    endResetModel();
}

bool
MessageListModel::insert(const QString& id, const interaction::Info& interaction, int index)
{
    const std::lock_guard<std::recursive_mutex> lk(mutex_);
    // If the index parameter is -1, then insert at the parent of the message.
    if (index == -1) {
        index = indexOfMessage(interaction.parentId);
    }
    // The index should be valid and don't add duplicate messages.
    if (index < 0 || index > interactions_.size() || find(id) != interactions_.end()) {
        return false;
    }
    beginInsertRows(QModelIndex(), index, index);
    interactions_.emplace(interactions_.cbegin() + index, id, interaction);
    endInsertRows();
    return true;
}

bool
MessageListModel::append(const QString& id, const interaction::Info& interaction)
{
    const std::lock_guard<std::recursive_mutex> lk(mutex_);
    // Don't add duplicate messages.
    if (find(id) != interactions_.end()) {
        return false;
    }
    beginInsertRows(QModelIndex(), interactions_.size(), interactions_.size());
    interactions_.emplace_back(id, interaction);
    endInsertRows();
    return true;
}

bool
MessageListModel::update(const QString& id, const interaction::Info& interaction)
{
    // There are two cases: a) Parent ID changed, b) body changed (edit/delete).
    const std::lock_guard<std::recursive_mutex> lk(mutex_);
    auto it = find(id);
    if (find(id) == interactions_.end()) {
        return false;
    }
    interaction::Info& current = it->second;
    if (current.parentId != interaction.parentId) {
        // Parent ID changed, in this case, move the interaction to the new parent.
        it->second.parentId = interaction.parentId;
        auto newIndex = move(it, interaction.parentId);
        if (newIndex >= 0) {
            // The iterator is invalid now. But we can update all the roles.
            auto modelIndex = QAbstractListModel::index(newIndex);
            Q_EMIT dataChanged(modelIndex, modelIndex, roleNames().keys());
            return true;
        }
    }
    // Just update bodies notify the view.
    current.body = interaction.body;
    current.previousBodies = interaction.previousBodies;
    current.parsedBody = interaction.parsedBody;
    auto modelIndex = QAbstractListModel::index(indexOfMessage(id), 0);
    Q_EMIT dataChanged(modelIndex, modelIndex, {Role::Body, Role::PreviousBodies, Role::ParsedBody});
    return true;
}

bool
MessageListModel::updateStatus(const QString& id,
                               interaction::Status newStatus,
                               const QString& newBody)
{
    const std::lock_guard<std::recursive_mutex> lk(mutex_);
    auto it = find(id);
    if (it == interactions_.end()) {
        return false;
    }
    VectorInt roles;
    it->second.status = newStatus;
    roles.push_back(Role::Status);
    if (!newBody.isEmpty()) {
        it->second.body = newBody;
        roles.push_back(Role::Body);
    }
    auto modelIndex = QAbstractListModel::index(indexOfMessage(id), 0);
    Q_EMIT dataChanged(modelIndex, modelIndex, roles);
    return true;
}

QPair<bool, bool>
MessageListModel::addOrUpdate(const QString& id, const interaction::Info& interaction)
{
    if (find(id) == interactions_.end()) {
        // The ID doesn't exist, appending cannot fail here.
        return {true, append(id, interaction)};
    } else {
        // Update can only fail if the new parent ID is invalid.
        return {false, update(id, interaction)};
    }
}

void
MessageListModel::forEach(const InteractionCb& callback)
{
    const std::lock_guard<std::recursive_mutex> lk(mutex_);
    for (auto& interaction : interactions_) {
        callback(interaction.first, interaction.second);
    }
}

bool
MessageListModel::with(const QString& idHint, const InteractionCb& callback)
{
    const std::lock_guard<std::recursive_mutex> lk(mutex_);
    if (interactions_.empty()) {
        return false;
    }
    // If the ID is empty, then return the last interaction.
    auto it = idHint.isEmpty() ? std::prev(interactions_.end()) : find(idHint);
    if (it == interactions_.end()) {
        return false;
    }
    callback(it->first, it->second);
    return true;
}

bool
MessageListModel::withLast(const InteractionCb& callback)
{
    return with(QString(), callback);
}

std::recursive_mutex&
MessageListModel::getMutex()
{
    return mutex_;
}

void
MessageListModel::addHyperlinkInfo(const QString& messageId, const QVariantMap& info)
{
    std::lock_guard<std::recursive_mutex> lk(mutex_);
    int index = indexOfMessage(messageId);
    if (index == -1) {
        return;
    }
    QModelIndex modelIndex = QAbstractListModel::index(index, 0);

    interactions_[index].second.linkPreviewInfo = info;
    Q_EMIT dataChanged(modelIndex, modelIndex, {Role::LinkPreviewInfo});
}

void
MessageListModel::addReaction(const QString& messageId, const MapStringString& reaction)
{
    std::lock_guard<std::recursive_mutex> lk(mutex_);
    int index = indexOfMessage(messageId);
    if (index == -1)
        return;
    QModelIndex modelIndex = QAbstractListModel::index(index, 0);

    auto emoji = api::interaction::Emoji {reaction["id"], reaction["body"]};
    auto& pList = interactions_[index].second.reactions[reaction["author"]];
    QList<QVariant> newList = pList.toList();
    newList.emplace_back(QVariant::fromValue(emoji));
    pList = QVariantList::fromVector(newList);
    Q_EMIT dataChanged(modelIndex, modelIndex, {Role::Reactions});
}

void
MessageListModel::rmReaction(const QString& messageId, const QString& reactionId)
{
    std::lock_guard<std::recursive_mutex> lk(mutex_);
    int index = indexOfMessage(messageId);
    if (index == -1)
        return;
    QModelIndex modelIndex = QAbstractListModel::index(index, 0);

    auto& reactions = interactions_[index].second.reactions;
    for (auto reactionIt = reactions.begin(); reactionIt != reactions.end(); ++reactionIt) {
        // Use a temporary QList to store updated emojis
        QList<QVariant> updatedEmojis;
        bool found = false;
        for (const auto& item : reactionIt.value().toList()) {
            auto emoji = item.value<api::interaction::Emoji>();
            if (emoji.commitId != reactionId || found)
                updatedEmojis.append(item);
            else {
                found = true;
                break;
            }
        }
        if (found) {
            // Update the reactions with the modified list
            reactionIt.value() = QVariant::fromValue(updatedEmojis);
            Q_EMIT dataChanged(modelIndex, modelIndex, {Role::Reactions});
            return;
        }
    }
}

void
MessageListModel::setParsedMessage(const QString& messageId, const QString& parsed)
{
    std::lock_guard<std::recursive_mutex> lk(mutex_);
    int index = indexOfMessage(messageId);
    if (index == -1) {
        return;
    }
    QModelIndex modelIndex = QAbstractListModel::index(index, 0);
    interactions_[index].second.parsedBody = parsed;
    Q_EMIT dataChanged(modelIndex, modelIndex, {Role::ParsedBody});
}

void
MessageListModel::setRead(const QString& peer, const QString& messageId)
{
    std::lock_guard<std::recursive_mutex> lk(mutex_);
    auto i = lastDisplayedMessageUid_.find(peer);
    if (i != lastDisplayedMessageUid_.end()) {
        auto old = i.value();
        messageToReaders_[old].removeAll(peer);
        auto msgIdx = indexOfMessage(old);
        // Remove from latest read
        if (msgIdx != -1) {
            QModelIndex modelIndex = QAbstractListModel::index(msgIdx, 0);
            Q_EMIT dataChanged(modelIndex, modelIndex, {Role::Readers});
        }
    }
    // update map
    lastDisplayedMessageUid_[peer] = messageId;
    messageToReaders_[messageId].append(peer);
    // update interaction
    auto msgIdx = indexOfMessage(messageId);
    // Remove from latest read
    if (msgIdx != -1) {
        QModelIndex modelIndex = QAbstractListModel::index(msgIdx, 0);
        Q_EMIT dataChanged(modelIndex, modelIndex, {Role::Readers});
    }
}

QString
MessageListModel::getRead(const QString& peer)
{
    std::lock_guard<std::recursive_mutex> lk(mutex_);
    auto i = lastDisplayedMessageUid_.find(peer);
    if (i != lastDisplayedMessageUid_.end())
        return i.value();
    return "";
}

QString
MessageListModel::lastSelfMessageId(const QString& id) const
{
    std::lock_guard<std::recursive_mutex> lk(mutex_);
    for (auto it = interactions_.rbegin(); it != interactions_.rend(); ++it) {
        auto lastType = it->second.type;
        if (lastType == interaction::Type::TEXT and !it->second.body.isEmpty()
            and (it->second.authorUri.isEmpty() || it->second.authorUri == id)) {
            return it->first;
        }
    }
    return {};
}

QPair<QString, time_t>
MessageListModel::getDisplayedInfoForPeer(const QString& peerId)
{
    std::lock_guard<std::recursive_mutex> lk(mutex_);
    auto it = lastDisplayedMessageUid_.find(peerId);
    if (it == lastDisplayedMessageUid_.end())
        return {};
    const auto interaction = find(it.value());
    if (interaction == interactions_.end())
        return {};
    return {it.value(), interaction->second.timestamp};
}

MessageListModel::iterator
MessageListModel::find(const QString& msgId)
{
    // Note: assumes that the caller has locked the mutex.
    return std::find_if(interactions_.begin(), interactions_.end(), [&msgId](const auto& it) {
        return it.first == msgId;
    });
}

int
MessageListModel::move(iterator it, const QString& newParentId)
{
    // Note: assumes the new parent exists and that the caller has locked the mutex.
    auto oldIndex = indexOfMessage(it->first);
    auto newIndex = indexOfMessage(newParentId) + 1;
    if (newIndex >= 0 && oldIndex != newIndex) {
        qDebug() << "Moving message" << it->first << "from" << oldIndex << "to" << newIndex;
        beginMoveRows(QModelIndex(), oldIndex, oldIndex, QModelIndex(), newIndex);
        interactions_.move(oldIndex, newIndex);
        endMoveRows();
        return newIndex;
    }
    return -1;
}

QVariant
MessageListModel::data(int idx, int role) const
{
    QModelIndex index = QAbstractListModel::index(idx, 0);
    return data(index, role);
}

QVariant
MessageListModel::dataForItem(const item_t& item, int, int role) const
{
    // Used only for reply roles.
    const auto getReplyIndex = [this, &item, &role]() -> int {
        QString replyId = item.second.commit["reply-to"];
        int repliedMsgIndex = -1;
        if (!replyId.isEmpty() && (role == Role::ReplyToAuthor || role == Role::ReplyToBody)) {
            repliedMsgIndex = indexOfMessage(replyId);
        }
        return repliedMsgIndex;
    };

    switch (role) {
    case Role::Id:
        return QVariant(item.first);
    case Role::Author:
        return QVariant(item.second.authorUri);
    case Role::Body: {
        if (account_) {
            if (item.second.type == lrc::api::interaction::Type::UPDATE_PROFILE) {
                return QVariant(interaction::getProfileUpdatedString());
            } else if (item.second.type == lrc::api::interaction::Type::CALL) {
                return QVariant(
                    interaction::getCallInteractionString(item.second.authorUri
                                                              == account_->profileInfo.uri,
                                                          item.second));
            } else if (item.second.type == lrc::api::interaction::Type::CONTACT) {
                auto bestName = item.second.authorUri == account_->profileInfo.uri
                                    ? account_->accountModel->bestNameForAccount(account_->id)
                                    : account_->contactModel->bestNameForContact(
                                        item.second.authorUri);
                return QVariant(
                    interaction::getContactInteractionString(bestName,
                                                             interaction::to_action(
                                                                 item.second.commit["action"])));
            }
        }
        return QVariant(item.second.body);
    }
    case Role::Timestamp:
        return QVariant::fromValue(item.second.timestamp);
    case Role::Duration:
        if (!item.second.commit.empty()) {
            // For swarm, check the commit value
            if (item.second.commit.find("duration") == item.second.commit.end())
                return QVariant::fromValue(0);
            else
                return QVariant::fromValue(item.second.commit["duration"].toInt() / 1000);
        }
        return QVariant::fromValue(item.second.duration);
    case Role::Type:
        return QVariant(static_cast<int>(item.second.type));
    case Role::Status:
        return QVariant(static_cast<int>(item.second.status));
    case Role::IsRead:
        return QVariant(item.second.isRead);
    case Role::LinkPreviewInfo:
        return QVariant(item.second.linkPreviewInfo);
    case Role::ParsedBody:
        return QVariant(item.second.parsedBody);
    case Role::ActionUri:
        return QVariant(item.second.commit["uri"]);
    case Role::ConfId:
        return QVariant(item.second.commit["confId"]);
    case Role::DeviceId:
        return QVariant(item.second.commit["device"]);
    case Role::ContactAction:
        return QVariant(item.second.commit["action"]);
    case Role::PreviousBodies: {
        QVariantList variantList;
        for (int i = 0; i < item.second.previousBodies.size(); i++) {
            variantList.append(QVariant::fromValue(item.second.previousBodies[i]));
        }
        return variantList;
    }
    case Role::ReplyTo:
        return QVariant(item.second.commit["reply-to"]);
    case Role::ReplyToAuthor: {
        const auto replyIndex = getReplyIndex();
        return replyIndex == -1 ? QVariant("") : data(replyIndex, Role::Author);
    }
    case Role::ReplyToBody: {
        const auto replyIndex = getReplyIndex();
        if (replyIndex == -1)
            return QVariant("");
        auto parsed = data(replyIndex, Role::ParsedBody).toString();
        if (!parsed.isEmpty())
            return QVariant(parsed);
        return QVariant(data(replyIndex, Role::Body).toString());
    }
    case Role::TotalSize:
        return QVariant(item.second.commit["totalSize"].toInt());
    case Role::TransferName:
        return QVariant(item.second.commit["displayName"]);
    case Role::FileExtension:
        return QVariant(QFileInfo(item.second.body).suffix());
    case Role::Readers:
        return QVariant(messageToReaders_[item.first]);
    case Role::IsEmojiOnly:
        return QVariant(item.second.commit["reply-to"].isEmpty()
                        && item.second.previousBodies.isEmpty() && isOnlyEmoji(item.second.body));
    case Role::Reactions:
        return QVariant(item.second.reactions);
    case Role::Index:
        // For DEBUG only
        return QVariant(indexOfMessage(item.first));
    default:
        return {};
    }
}

void
MessageListModel::updateReplies(const item_t& message)
{
    auto replyId = message.second.commit["reply-to"];
    auto commitId = message.second.commit["id"];
    if (!replyId.isEmpty()) {
        replyTo_[replyId].insert(commitId);
    }

    // Use a const reference to avoid detaching
    const auto& replies = replyTo_[commitId];
    for (const auto& msgId : replies) {
        int index = indexOfMessage(msgId);
        if (index == -1)
            continue;
        QModelIndex modelIndex = QAbstractListModel::index(index, 0);
        Q_EMIT dataChanged(modelIndex, modelIndex, {Role::ReplyToAuthor, Role::ReplyToBody});
    }
}
} // namespace lrc
