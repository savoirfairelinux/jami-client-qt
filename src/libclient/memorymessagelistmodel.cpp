#include "memorymessagelistmodel.h"
namespace lrc {
using namespace api;

MemoryMessageListModel::MemoryMessageListModel(QObject* parent)
    : MessageListModel(parent)
//, displayedinteractionsModel_(displayedinteractionsModel)

{}

void
MemoryMessageListModel::insertMessage(int index, item_t& message)
{
    Q_EMIT beginInsertRows(QModelIndex(), index, index);
    interactions_.insert(index, message);
    if (message.second.body == "testReplyBody")
        qWarning() << "message added in interaction memory";
    Q_EMIT endInsertRows();
    updateReplies(message);
    if (displayedinteractionsModel_ != nullptr)
        displayedinteractionsModel_->get()->updateReplies(message);
}

MessageListModel::iterator
MemoryMessageListModel::insertMessage(iterator it, item_t& message)
{
    auto index = std::distance(begin(), it);
    Q_EMIT beginInsertRows(QModelIndex(), index, index);
    auto insertion = interactions_.insert(it, message);
    Q_EMIT endInsertRows();
    updateReplies(message);
    if (displayedinteractionsModel_ != nullptr) {
        qWarning() << displayedinteractionsModel_; //<< " " << displayedinteractionsModel_->get();
        qWarning() << displayedinteractionsModel_->get();
        //        // if (displayedinteractionsModel_->get())
        //        //  displayedinteractionsModel_->get()->test();
    }
    return insertion;
}

void
MemoryMessageListModel::setDisplayedList(
    std::unique_ptr<DisplayedMessageListModel>* displayedinteractionsModel)
{
    displayedinteractionsModel_ = displayedinteractionsModel;
}

// QVariant
// MemoryMessageListModel::dataForItem(item_t item, int, int role) const
//{
//     auto replyId = item.second.commit["reply-to"];
//     auto repliedMsg = getIndexOfMessage(replyId);
//     //    if (memoryinteractions_ != nullptr)
//     //        repliedMsg = getIndexOfMemoryMessage(replyId);

//    if (!replyId.isEmpty())
//        qWarning() << item.second.body << "efefefef" << repliedMsg << "--" <<
//        interactions_.size();
//    switch (role) {
//    case Role::Id:
//        return QVariant(item.first);
//    case Role::Author:
//        return QVariant(item.second.authorUri);
//    case Role::Body:
//        return QVariant(item.second.body);
//    case Role::Timestamp:
//        return QVariant::fromValue(item.second.timestamp);
//    case Role::Duration:
//        if (!item.second.commit.empty()) {
//            // For swarm, check the commit value
//            if (item.second.commit.find("duration") == item.second.commit.end())
//                return QVariant::fromValue(0);
//            else
//                return QVariant::fromValue(item.second.commit["duration"].toInt() / 1000);
//        }
//        return QVariant::fromValue(item.second.duration);
//    case Role::Type:
//        return QVariant(static_cast<int>(item.second.type));
//    case Role::Status:
//        return QVariant(static_cast<int>(item.second.status));
//    case Role::IsRead:
//        return QVariant(item.second.isRead);
//    case Role::LinkPreviewInfo:
//        return QVariant(item.second.linkPreviewInfo);
//    case Role::Linkified:
//        return QVariant(item.second.linkified);
//    case Role::ActionUri:
//        return QVariant(item.second.commit["uri"]);
//    case Role::ConfId:
//        return QVariant(item.second.commit["confId"]);
//    case Role::DeviceId:
//        return QVariant(item.second.commit["device"]);
//    case Role::ContactAction:
//        return QVariant(item.second.commit["action"]);
//    case Role::PreviousBodies: {
//        QVariantList variantList;
//        for (int i = 0; i < item.second.previousBodies.size(); i++) {
//            variantList.append(QVariant::fromValue(item.second.previousBodies[i]));
//        }
//        return variantList;
//    }
//    case Role::ReplyTo:
//        return QVariant(replyId);
//    case Role::ReplyToAuthor:
//        return repliedMsg == -1 ? QVariant("") : QVariant(data(repliedMsg, Role::Author));
//    case Role::ReplyToBody:
//        return repliedMsg == -1
//                   ? QVariant("")
//                   : QVariant(data(repliedMsg, Role::Body).toString().replace("\n", " "));
//    case Role::TotalSize:
//        return QVariant(item.second.commit["totalSize"].toInt());
//    case Role::TransferName:
//        return QVariant(item.second.commit["displayName"]);
//    case Role::Readers:
//        return QVariant(messageToReaders_[item.first]);
//    case Role::IsEmojiOnly:
//        return QVariant(isOnlyEmoji(item.second.body));
//    case Role::Reactions:
//        return QVariant(item.second.reactions);
//    default:
//        return {};
//    }
//}

} // namespace lrc
