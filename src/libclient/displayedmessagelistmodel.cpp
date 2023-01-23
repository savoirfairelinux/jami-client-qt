#include "displayedmessagelistmodel.h"
namespace lrc {
using namespace api;

DisplayedMessageListModel::DisplayedMessageListModel(
    QObject* parent, QList<QPair<QString, interaction::Info>>& memoryInteractionslist)
    : MessageListModel(parent)
    , memoryInteractionslist_(memoryInteractionslist)
{}

// QVariant
// DisplayedMessageListModel::data(const QModelIndex& index, int, int role) const
//{
//     qWarning() << "dataaaaaaaaaaaaaaaaaaaaaaaddd";
//     if (!index.isValid() || index.row() < 0 || index.row() >= rowCount()) {
//         return {};
//     }
//     return dataForItem(interactions_.at(index.row()), index.row(), role);
// }

// QVariant
// DisplayedMessageListModel::data(int idx, int role) const
//{
//     qWarning() << "dataaaaaaaaaaaaaaaaaaaaaaa";
//     QModelIndex index = QAbstractListModel::index(idx, 0);
//     if (!index.isValid() || index.row() < 0 || index.row() >= rowCount()) {
//         return {};
//     }
//     return dataForItem(interactions_.at(index.row()), index.row(), role);
// }

QVariant
DisplayedMessageListModel::dataInMemory(int idx, int role) const
{
    QModelIndex index = QAbstractListModel::index(idx, 0);
    if (!index.isValid() || index.row() < 0 || index.row() >= memoryInteractionslist_.size()) {
        return {};
    }
    return dataForItem(memoryInteractionslist_.at(index.row()), index.row(), role);
}

void
DisplayedMessageListModel::updateReplies(item_t& message)
{
    // qWarning() << "message updated: " << message.second.body;
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
DisplayedMessageListModel::test()
{
    qWarning() << "test";
}

QVariant
DisplayedMessageListModel::dataForItem(item_t item, int, int role) const
{
    auto replyId = item.second.commit["reply-to"];
    auto repliedMsg = getIndexInMemoryOfMessage(replyId);

    //    if (!replyId.isEmpty())
    //        qWarning() << item.second.body << "efefefef" << repliedMsg << "--" << interactions_.size();
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
        return repliedMsg == -1 ? QVariant("") : QVariant(dataInMemory(repliedMsg, Role::Author));
    case Role::ReplyToBody:
        return repliedMsg == -1
                   ? QVariant("")
                   : QVariant(dataInMemory(repliedMsg, Role::Body).toString().replace("\n", " "));
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

int
DisplayedMessageListModel::getIndexInMemoryOfMessage(const QString& messageId) const
{
    for (int i = 0; i < memoryInteractionslist_.size(); i++) {
        if (memoryInteractionslist_.at(i).first == messageId) {
            return i;
        }
    }
    return -1;
}
} // namespace lrc
