/*
 *  Copyright (C) 2020-2023 Savoir-faire Linux Inc.
 *
 *  Author: Kateryna Kostiuk <kateryna.kostiuk@savoirfairelinux.com>
 *  Author: Trevor Tabah <trevor.tabah@savoirfairelinux.com>
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
#include "api/interaction.h"

#include <QAbstractListModel>
#include <QFileInfo>

namespace lrc {

using namespace api;

using constIterator = MessageListModel::constIterator;
using iterator = MessageListModel::iterator;
using reverseIterator = MessageListModel::reverseIterator;

MessageListModel::MessageListModel(const account::Info* account, QObject* parent)
    : QAbstractListModel(parent)
    , account_(account)
{}

iterator
MessageListModel::find(const QString& msgId)
{
    iterator it;
    for (it = interactions_.begin(); it != interactions_.end(); ++it) {
        if (it->first == msgId) {
            return it;
        }
    }
    return interactions_.end();
}

iterator
MessageListModel::findActiveCall(const MapStringString& commit)
{
    iterator it;
    for (it = interactions_.begin(); it != interactions_.end(); ++it) {
        const auto& itCommit = it->second.commit;
        if (itCommit["confId"] == commit["confId"] && itCommit["uri"] == commit["uri"]
            && itCommit["device"] == commit["device"]) {
            return it;
        }
    }
    return interactions_.end();
}

iterator
MessageListModel::erase(const iterator& it)
{
    auto index = std::distance(interactions_.begin(), it);
    Q_EMIT beginRemoveRows(QModelIndex(), index, index);
    auto erased = interactions_.erase(it);
    Q_EMIT endRemoveRows();
    return erased;
}

constIterator
MessageListModel::find(const QString& msgId) const
{
    constIterator it;
    for (it = interactions_.cbegin(); it != interactions_.cend(); ++it) {
        if (it->first == msgId) {
            return it;
        }
    }
    return interactions_.cend();
}

int
MessageListModel::erase(const QString& msgId)
{
    iterator it;
    int index = 0;
    for (it = interactions_.begin(); it != interactions_.end(); ++it) {
        if (it->first == msgId) {
            removeMessage(index, it);
            return 1;
        }
        index++;
    }
    return 0;
}

int
MessageListModel::size() const
{
    std::lock_guard<std::recursive_mutex> lk(mutex_);
    return interactions_.size();
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
    Q_EMIT beginResetModel();
    for (auto& interaction : interactions_) {
        interaction.second.linkPreviewInfo.clear();
    }
    Q_EMIT endResetModel();
}

bool
MessageListModel::empty() const
{
    std::lock_guard<std::recursive_mutex> lk(mutex_);
    return interactions_.empty();
}

interaction::Info
MessageListModel::at(const QString& msgId) const
{
    for (auto it = interactions_.cbegin(); it != interactions_.cend(); ++it) {
        if (it->first == msgId) {
            return it->second;
        }
    }
    return {};
}

QPair<QString, interaction::Info>
MessageListModel::front() const
{
    return interactions_.front();
}

QPair<QString, interaction::Info>
MessageListModel::last() const
{
    return interactions_.last();
}

QPair<QString, interaction::Info>
MessageListModel::atIndex(int index) const
{
    return interactions_.at(index);
}

QPair<iterator, bool>
MessageListModel::insert(int index, QPair<QString, interaction::Info> message)
{
    iterator itr;
    for (itr = interactions_.begin(); itr != interactions_.end(); ++itr) {
        if (itr->first == message.first) {
            return qMakePair(itr, false);
        }
    }
    if (index >= size()) {
        auto iterator = insertMessage(interactions_.end(), message);
        return qMakePair(iterator, true);
    }
    insertMessage(index, message);
    return qMakePair(interactions_.end(), true);
}

int
MessageListModel::indexOfMessage(const QString& msgId, bool reverse) const
{
    auto getIndex = [reverse, &msgId](const auto& start, const auto& end) -> int {
        auto it = std::find_if(start, end, [&msgId](const auto& it) { return it.first == msgId; });
        if (it == end) {
            return -1;
        }
        return reverse ? std::distance(it, end) - 1 : std::distance(start, it);
    };
    return reverse ? getIndex(interactions_.rbegin(), interactions_.rend())
                   : getIndex(interactions_.begin(), interactions_.end());
}

void
MessageListModel::updateReplies(item_t& message)
{
    auto replyId = message.second.commit["reply-to"];
    auto commitId = message.second.commit["id"];
    if (!replyId.isEmpty()) {
        replyTo_[replyId].insert(commitId);
    }
    for (const auto& msgId : replyTo_[commitId]) {
        int index = getIndexOfMessage(msgId);
        if (index == -1)
            continue;
        QModelIndex modelIndex = QAbstractListModel::index(index, 0);
        Q_EMIT dataChanged(modelIndex, modelIndex, {Role::ReplyToAuthor, Role::ReplyToBody});
    }
}

void
MessageListModel::insertMessage(int index, item_t& message)
{
    Q_EMIT beginInsertRows(QModelIndex(), index, index);
    interactions_.insert(index, message);
    Q_EMIT endInsertRows();
    updateReplies(message);
}

iterator
MessageListModel::insertMessage(iterator it, item_t& message)
{
    auto index = std::distance(interactions_.begin(), it);
    Q_EMIT beginInsertRows(QModelIndex(), index, index);
    auto insertion = interactions_.insert(it, message);
    Q_EMIT endInsertRows();
    updateReplies(message);
    return insertion;
}

void
MessageListModel::removeMessage(int index, iterator it)
{
    beginRemoveRows(QModelIndex(), index, index);
    interactions_.erase(it);
    endRemoveRows();
}

int
MessageListModel::move(iterator it, const QString& newParentId)
{
    // This function assumes:
    // - the caller has already checked that the new parent exists
    // - the caller has locked the interactions mutex
    auto oldIndex = std::distance(interactions_.begin(), it);
    auto newParentIndex = indexOfMessage(newParentId);
    if (newParentIndex >= 0) {
        beginMoveRows(QModelIndex(), oldIndex, oldIndex, QModelIndex(), newParentIndex);
        interactions_.move(oldIndex, newParentIndex);
        endMoveRows();
    }
    return newParentIndex;
}

bool
MessageListModel::contains(const QString& msgId)
{
    std::lock_guard<std::recursive_mutex> lk(mutex_);
    return find(msgId) != interactions_.end();
}

int
MessageListModel::rowCount(const QModelIndex&) const
{
    return interactions_.size();
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

bool
MessageListModel::isOnlyEmoji(const QString& text) const
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

QVariant
MessageListModel::dataForItem(item_t item, int, int role) const
{
    QString replyId = item.second.commit["reply-to"];
    int repliedMsg = -1;
    if (!replyId.isEmpty() && (role == Role::ReplyToAuthor || role == Role::ReplyToBody)) {
        repliedMsg = getIndexOfMessage(replyId);
    }
    switch (role) {
    case Role::Id:
        return QVariant(item.first);
    case Role::Author:
        return QVariant(item.second.authorUri);
    case Role::Body: {
        if (account_) {
            if (item.second.type == lrc::api::interaction::Type::CALL) {
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
        return QVariant(replyId);
    case Role::ReplyToAuthor:
        return repliedMsg == -1 ? QVariant("") : QVariant(data(repliedMsg, Role::Author));
    case Role::ReplyToBody: {
        if (repliedMsg == -1)
            return QVariant("");
        auto parsed = data(repliedMsg, Role::ParsedBody).toString();
        if (!parsed.isEmpty())
            return QVariant(parsed);
        return QVariant(data(repliedMsg, Role::Body).toString());
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
        return QVariant(replyId.isEmpty() && item.second.previousBodies.isEmpty()
                        && isOnlyEmoji(item.second.body));
    case Role::Reactions:
        return QVariant(item.second.reactions);
    default:
        return {};
    }
}

QVariant
MessageListModel::data(int idx, int role) const
{
    QModelIndex index = QAbstractListModel::index(idx, 0);
    if (!index.isValid() || index.row() < 0 || index.row() >= rowCount()) {
        return {};
    }
    return dataForItem(interactions_.at(index.row()), index.row(), role);
}

QVariant
MessageListModel::data(const QModelIndex& index, int role) const
{
    if (!index.isValid() || index.row() < 0 || index.row() >= rowCount()) {
        return {};
    }
    return dataForItem(interactions_.at(index.row()), index.row(), role);
}

int
MessageListModel::getIndexOfMessage(const QString& messageId) const
{
    for (int i = 0; i < interactions_.size(); i++) {
        if (atIndex(i).first == messageId) {
            return i;
        }
    }
    return -1;
}

void
MessageListModel::addHyperlinkInfo(const QString& messageId, const QVariantMap& info)
{
    int index = getIndexOfMessage(messageId);
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
    int index = getIndexOfMessage(messageId);
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
    int index = getIndexOfMessage(messageId);
    if (index == -1)
        return;
    QModelIndex modelIndex = QAbstractListModel::index(index, 0);

    auto& reactions = interactions_[index].second.reactions;
    for (const auto& key : reactions.keys()) {
        QList<QVariant> emojis = reactions[key].toList();
        for (auto it = emojis.begin(); it != emojis.end(); ++it) {
            auto emoji = it->value<api::interaction::Emoji>();
            if (emoji.commitId == reactionId) {
                emojis.erase(it);
                reactions[key] = emojis;
                Q_EMIT dataChanged(modelIndex, modelIndex, {Role::Reactions});
                return;
            }
        }
    }
}

void
MessageListModel::setParsedMessage(const QString& messageId, const QString& parsed)
{
    int index = getIndexOfMessage(messageId);
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
    auto i = lastDisplayedMessageUid_.find(peer);
    if (i != lastDisplayedMessageUid_.end()) {
        auto old = i.value();
        messageToReaders_[old].removeAll(peer);
        auto msgIdx = getIndexOfMessage(old);
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
    auto msgIdx = getIndexOfMessage(messageId);
    // Remove from latest read
    if (msgIdx != -1) {
        QModelIndex modelIndex = QAbstractListModel::index(msgIdx, 0);
        Q_EMIT dataChanged(modelIndex, modelIndex, {Role::Readers});
    }
}

QString
MessageListModel::getRead(const QString& peer)
{
    auto i = lastDisplayedMessageUid_.find(peer);
    if (i != lastDisplayedMessageUid_.end())
        return i.value();
    return "";
}

QString
MessageListModel::lastSelfMessageId(const QString& id) const
{
    for (auto it = interactions_.rbegin(); it != interactions_.rend(); ++it) {
        auto lastType = it->second.type;
        if (lastType == interaction::Type::TEXT and !it->second.body.isEmpty()
            and (it->second.authorUri.isEmpty() || it->second.authorUri == id)) {
            return it->first;
        }
    }
    return {};
}

bool
MessageListModel::insert(const QString& id, const interaction::Info& interaction, int index)
{
    const std::lock_guard<std::recursive_mutex> lk(mutex_);
    // If the index parameter is -1, then insert at the parent of the message.
    if (index == -1) {
        index = getIndexOfMessage(interaction.parentId);
    }

    // The index should be valid and don't add duplicate messages.
    if (index < 0 || index > interactions_.size() || find(id) != interactions_.end()) {
        return false;
    }
    beginInsertRows(QModelIndex(), index, index);
    interactions_.emplace(interactions_.begin() + index, id, interaction);
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
}

bool
MessageListModel::update(const QString& id, const interaction::Info& interaction)
{
    // There are two cases: a) Parent ID changed, b) body changed (edit/delete).
    const std::lock_guard<std::recursive_mutex> lk(mutex_);
    auto it = find(id);
    if (it == interactions_.end()) {
        return false;
    }
    interaction::Info& current = it->second;
    if (current.parentId != interaction.parentId) {
        // Parent ID changed, in this case, move the interaction to the new parent.
        return move(it, interaction.parentId) >= 0;
    }
    // Just update body and previousBodies and notify the view.
    current.body = interaction.body;
    current.previousBodies = interaction.previousBodies;
    auto modelIndex = QAbstractListModel::index(getIndexOfMessage(id), 0);
    Q_EMIT dataChanged(modelIndex, modelIndex, {Role::Body, Role::PreviousBodies});
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
    auto modelIndex = QAbstractListModel::index(getIndexOfMessage(id), 0);
    Q_EMIT dataChanged(modelIndex, modelIndex, roles);
    return true;
}

QPair<bool, bool>
MessageListModel::addOrUpdate(const QString& id, const interaction::Info& interaction)
{
    if (find(id) == interactions_.end()) {
        return {true, append(id, interaction)};
    } else {
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

interaction::Info
MessageListModel::get(const QString& id) const
{
    std::lock_guard<std::recursive_mutex> lk(mutex_);
    auto it = find(id);
    if (it != interactions_.end()) {
        return it->second;
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
    return {it.value(), interactions_[getIndexOfMessage(it.value())].second.timestamp};
}

bool
MessageListModel::isOutgoing(const QString& id)
{
    std::lock_guard<std::recursive_mutex> lk(mutex_);
    auto it = find(id);
    if (it == interactions_.end()) {
        return false;
    }
    return interaction::isOutgoing(it->second);
}

std::recursive_mutex&
MessageListModel::getMutex()
{
    return mutex_;
}
} // namespace lrc
