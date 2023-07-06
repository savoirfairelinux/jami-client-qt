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

#include "messagelistmodel.h"

#include "authority/storagehelper.h"
#include "api/accountmodel.h"
#include "api/contactmodel.h"
#include "api/conversationmodel.h"
#include "api/interaction.h"
#include "qtwrapper/conversions_wrap.hpp"

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

QPair<iterator, bool>
MessageListModel::emplace(const QString& msgId, interaction::Info message, bool beginning)
{
    iterator it;
    for (it = interactions_.begin(); it != interactions_.end(); ++it) {
        if (it->first == msgId) {
            return qMakePair(it, false);
        }
    }
    auto iter = beginning ? interactions_.begin() : interactions_.end();
    auto iterator = insertMessage(iter, qMakePair(msgId, message));
    return qMakePair(iterator, true);
}

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
    auto index = std::distance(begin(), it);
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

QPair<iterator, bool>
MessageListModel::insert(std::pair<QString, interaction::Info> message, bool beginning)
{
    return emplace(message.first, message.second, beginning);
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

interaction::Info&
MessageListModel::operator[](const QString& messageId)
{
    for (auto it = interactions_.cbegin(); it != interactions_.cend(); ++it) {
        if (it->first == messageId) {
            return const_cast<interaction::Info&>(it->second);
        }
    }
    // element not find, add it to the end
    interaction::Info newMessage = {};
    insertMessage(interactions_.end(), qMakePair(messageId, newMessage));
    if (interactions_.last().first == messageId) {
        return const_cast<interaction::Info&>(interactions_.last().second);
    }
    throw std::out_of_range("Cannot find message");
}

iterator
MessageListModel::end()
{
    return interactions_.end();
}

constIterator
MessageListModel::end() const
{
    return interactions_.end();
}

reverseIterator
MessageListModel::rend()
{
    return interactions_.rend();
}

constIterator
MessageListModel::cend() const
{
    return interactions_.cend();
}

iterator
MessageListModel::begin()
{
    return interactions_.begin();
}

constIterator
MessageListModel::begin() const
{
    return interactions_.begin();
}

reverseIterator
MessageListModel::rbegin()
{
    return interactions_.rbegin();
}

int
MessageListModel::size() const
{
    return interactions_.size();
}

void
MessageListModel::clear()
{
    Q_EMIT beginResetModel();
    interactions_.clear();
    replyTo_.clear();
    Q_EMIT endResetModel();
}

void
MessageListModel::reloadHistory()
{
    Q_EMIT beginResetModel();
    for (auto& interaction : interactions_) {
        interaction.second.linkPreviewInfo.clear();
    }
    Q_EMIT endResetModel();
}

bool
MessageListModel::empty() const
{
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
MessageListModel::moveMessages(QList<QString> msgIds, const QString& parentId)
{
    for (auto msgId : msgIds) {
        moveMessage(msgId, parentId);
    }
}

void
MessageListModel::moveMessage(const QString& msgId, const QString& parentId)
{
    int currentIndex = indexOfMessage(msgId);
    if (currentIndex == -1) {
        qWarning() << "Incorrect index detected in MessageListModel::moveMessage";
        return;
    }

    // if we have a next element check if it is a child interaction
    QString childMessageIdToMove;
    if (currentIndex < (interactions_.size() - 1)) {
        const auto& next = interactions_.at(currentIndex + 1);
        if (next.second.parentId == msgId) {
            childMessageIdToMove = next.first;
        }
    }

    auto endIdx = currentIndex;
    auto pId = msgId;

    // move a message
    int newIndex = indexOfMessage(parentId) + 1;
    if (newIndex >= interactions_.size()) {
        newIndex = interactions_.size() - 1;
        // If we can move all the messages after the current one, we can do it directly
        childMessageIdToMove.clear();
        endIdx = std::max(endIdx, newIndex - 1);
    }

    if (currentIndex == newIndex || newIndex == -1)
        return;

    // Pretty every messages is moved
    moveMessages(currentIndex, endIdx, newIndex);
    // move a child message
    if (!childMessageIdToMove.isEmpty())
        moveMessage(childMessageIdToMove, msgId);
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
    auto index = std::distance(begin(), it);
    Q_EMIT beginInsertRows(QModelIndex(), index, index);
    auto insertion = interactions_.insert(it, message);
    Q_EMIT endInsertRows();
    updateReplies(message);
    return insertion;
}

void
MessageListModel::removeMessage(int index, iterator it)
{
    Q_EMIT beginRemoveRows(QModelIndex(), index, index);
    interactions_.erase(it);
    Q_EMIT endRemoveRows();
}

void
MessageListModel::moveMessages(int from, int last, int to)
{
    if (last < from)
        return;
    QModelIndex sourceIndex = QAbstractListModel::index(from, 0);
    QModelIndex destinationIndex = QAbstractListModel::index(to, 0);
    Q_EMIT beginMoveRows(sourceIndex, from, last, destinationIndex, to);
    for (int i = 0; i < (last - from); ++i)
        interactions_.move(last, to);
    Q_EMIT endMoveRows();
}

bool
MessageListModel::contains(const QString& msgId)
{
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

void
MessageListModel::emitDataChanged(iterator it, VectorInt roles)
{
    auto index = std::distance(begin(), it);
    QModelIndex modelIndex = QAbstractListModel::index(index, 0);
    Q_EMIT dataChanged(modelIndex, modelIndex, roles);
}

void
MessageListModel::emitDataChanged(const QString& msgId, VectorInt roles)
{
    int index = getIndexOfMessage(msgId);
    if (index == -1) {
        return;
    }
    QModelIndex modelIndex = QAbstractListModel::index(index, 0);
    Q_EMIT dataChanged(modelIndex, modelIndex, roles);
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
} // namespace lrc
