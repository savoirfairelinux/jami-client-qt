/*
 *  Copyright (C) 2020-2022 Savoir-faire Linux Inc.
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

#include "api/conversationmodel.h"
#include "api/interaction.h"
#include "qtwrapper/conversions_wrap.hpp"

#include <QAbstractListModel>

namespace lrc {

using namespace api;

using constIterator = MessageListModel::constIterator;
using iterator = MessageListModel::iterator;
using reverseIterator = MessageListModel::reverseIterator;

MessageListModel::MessageListModel(QObject* parent)
    : QAbstractListModel(parent)
    , timestampTimer_(new QTimer(this))
{
    connect(timestampTimer_, &QTimer::timeout, this, &MessageListModel::timestampUpdate);
    timestampTimer_->start(1000);
}

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
    editedBodies_.clear();
    reactedMessages_.clear();
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

    // move a message
    int newIndex = indexOfMessage(parentId) + 1;
    if (newIndex >= interactions_.size()) {
        newIndex = interactions_.size() - 1;
    }

    if (currentIndex == newIndex || newIndex == -1)
        return;

    // Pretty every messages is moved
    moveMessages(currentIndex, interactions_.size() - 1, newIndex);
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
    auto resetModel = (from <= 2 && last == interactions_.size() - 1);
    if (last < from)
        return;
    if (resetModel) {
        Q_EMIT beginResetModel();
    } else {
        Q_EMIT beginMoveRows(QModelIndex(), from, last, QModelIndex(), to);
    }
    for (int i = 0; i < (last - from); ++i)
        interactions_.move(last, to);
    if (resetModel) {
        Q_EMIT endResetModel();
    } else {
        Q_EMIT endMoveRows();
    }
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
    auto replyId = item.second.commit["reply-to"];
    auto repliedMsg = getIndexOfMessage(replyId);
    switch (role) {
    case Role::Id:
        return QVariant(item.first);
    case Role::Author:
        return QVariant(item.second.authorUri);
    case Role::Body:
        return QVariant(item.second.body);
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
    case Role::Linkified:
        return QVariant(item.second.linkified);
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
    case Role::ReplyToBody:
        return repliedMsg == -1
                   ? QVariant("")
                   : QVariant(data(repliedMsg, Role::Body).toString().replace("\n", " "));
    case Role::TotalSize:
        return QVariant(item.second.commit["totalSize"].toInt());
    case Role::TransferName:
        return QVariant(item.second.commit["displayName"]);
    case Role::Readers:
        return QVariant(messageToReaders_[item.first]);
    case Role::IsEmojiOnly:
        return QVariant(isOnlyEmoji(item.second.body));
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
MessageListModel::linkifyMessage(const QString& messageId, const QString& linkified)
{
    int index = getIndexOfMessage(messageId);
    if (index == -1) {
        return;
    }
    QModelIndex modelIndex = QAbstractListModel::index(index, 0);
    interactions_[index].second.body = linkified;
    interactions_[index].second.linkified = true;
    Q_EMIT dataChanged(modelIndex, modelIndex, {Role::Body, Role::Linkified});
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

void
MessageListModel::addEdition(const QString& msgId, const interaction::Info& info, bool end)
{
    auto editedId = info.commit["edit"];
    if (editedId.isEmpty())
        return;
    auto& edited = editedBodies_[editedId];
    auto editedMsgIt = std::find_if(edited.begin(), edited.end(), [&](const auto& v) {
        return msgId == v.commitId;
    });
    if (editedMsgIt != edited.end())
        return; // Already added
    auto value = interaction::Body {msgId, info.body, info.timestamp};
    if (end)
        edited.push_back(value);
    else
        edited.push_front(value);
    auto editedIt = find(editedId);
    if (editedIt != interactions_.end()) {
        // If already there, we can update the content
        editMessage(editedId, editedIt->second);
        if (!editedIt->second.react_to.isEmpty()) {
            auto reactToIt = find(editedIt->second.react_to);
            if (reactToIt != interactions_.end())
                reactToMessage(editedIt->second.react_to, reactToIt->second);
        }
    }
}

void
MessageListModel::addReaction(const QString& messageId, const QString& reactionId)
{
    auto itReacted = reactedMessages_.find(messageId);
    if (itReacted != reactedMessages_.end()) {
        itReacted->insert(reactionId);
    } else {
        QSet<QString> emojiList;
        emojiList.insert(reactionId);
        reactedMessages_.insert(messageId, emojiList);
    }
    auto interaction = find(reactionId);
    if (interaction != interactions_.end()) {
        // Edit reaction if needed
        editMessage(reactionId, interaction->second);
    }
}

QVariantMap
MessageListModel::convertReactMessagetoQVariant(const QSet<QString>& emojiIdList)
{
    QVariantMap convertedMap;
    QMap<QString, QStringList> mapStringEmoji;
    for (auto emojiId = emojiIdList.begin(); emojiId != emojiIdList.end(); emojiId++) {
        auto interaction = find(*emojiId);
        if (interaction != interactions_.end()) {
            auto author = interaction->second.authorUri;
            auto body = interaction->second.body;
            if (!body.isEmpty()) {
                auto itAuthor = mapStringEmoji.find(author);
                if (itAuthor != mapStringEmoji.end()) {
                    mapStringEmoji[author].append(body);
                } else {
                    QStringList emojiList;
                    emojiList.append(body);
                    mapStringEmoji.insert(author, emojiList);
                }
            }
        }
    }
    for (auto i = mapStringEmoji.begin(); i != mapStringEmoji.end(); i++) {
        convertedMap.insert(i.key(), i.value());
    }
    return convertedMap;
}

void
MessageListModel::editMessage(const QString& msgId, interaction::Info& info)
{
    auto it = editedBodies_.find(msgId);
    if (it != editedBodies_.end()) {
        if (info.previousBodies.isEmpty()) {
            info.previousBodies.push_back(interaction::Body {msgId, info.body, info.timestamp});
        }
        // Find if already added (because MessageReceived can be triggered
        // multiple times for same message)
        for (const auto& editedBody : *it) {
            auto itCommit = std::find_if(info.previousBodies.begin(),
                                         info.previousBodies.end(),
                                         [&](const auto& element) {
                                             return element.commitId == editedBody.commitId;
                                         });
            if (itCommit == info.previousBodies.end()) {
                info.previousBodies.push_back(editedBody);
            }
        }
        info.body = it->rbegin()->body;
        editedBodies_.erase(it);
        emitDataChanged(msgId, {MessageList::Role::Body, MessageList::Role::PreviousBodies});

        // Body changed, replies should update
        for (const auto& replyId : replyTo_[msgId]) {
            int index = getIndexOfMessage(replyId);
            if (index == -1)
                continue;
            QModelIndex modelIndex = QAbstractListModel::index(index, 0);
            Q_EMIT dataChanged(modelIndex, modelIndex, {Role::ReplyToBody});
        }
    }
}

void
MessageListModel::reactToMessage(const QString& msgId, interaction::Info& info)
{
    // If already there, we can update the content
    auto itReact = reactedMessages_.find(msgId);

    if (itReact != reactedMessages_.end()) {
        auto convertedMap = convertReactMessagetoQVariant(reactedMessages_[msgId]);
        info.reactions = convertedMap;
        emitDataChanged(find(msgId), {Role::Reactions});
    }
}

QString
MessageListModel::lastMessageUid() const
{
    for (auto it = interactions_.rbegin(); it != interactions_.rend(); ++it) {
        auto lastType = it->second.type;
        if (lastType != interaction::Type::MERGE and lastType != interaction::Type::EDITED
            and !it->second.body.isEmpty()) {
            return it->first;
        }
    }
    return {};
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

QString
MessageListModel::findEmojiReaction(const QString& emoji,
                                    const QString& authorURI,
                                    const QString& messageId)
{
    auto& messageReactions = reactedMessages_[messageId];
    for (auto it = messageReactions.begin(); it != messageReactions.end(); it++) {
        auto interaction = find(*it);
        if (interaction != interactions_.end() && interaction->second.body == emoji
            && interaction->second.authorUri == authorURI) {
            return *it;
        }
    }
    return {};
}
} // namespace lrc
