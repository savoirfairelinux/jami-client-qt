#include <QAbstractListModel>
#include <QDebug>
#include "messagelistmodel.h"

MessageListModel::MessageListModel(LRCInstance* instance, QObject* parent)
    : AbstractListModelBase(parent)
{
    lrcInstance_ = instance;
    model_ = lrcInstance_->getCurrentConversationModel();

    if (!model_)
        return;

    connect(
        model_,
        &ConversationModel::beginInsertInteractionRows,
        this,
        [this](const QString& conversationId, int size, int rowsAdded) {
            //         if (instance->selectedConvUid_ != convId) return;
            beginInsertRows(QModelIndex(), size, size + rowsAdded - 1);
        },
        Qt::DirectConnection);
    connect(model_,
            &ConversationModel::endInsertInteractionRows,
            this,
            &MessageListModel::endInsertRows,
            Qt::DirectConnection);
}

int
MessageListModel::rowCount(const QModelIndex& parent) const
{
    return 0; /* data_.size();*/
}

QHash<int, QByteArray>
MessageListModel::roleNames() const
{
    QHash<int, QByteArray> roles;
    roles[Role::Content] = "Content";
    return roles;
}

void
MessageListModel::removeLine()
{
    beginRemoveRows(QModelIndex(), 0, 0);
    // data_.removeFirst();
    endRemoveRows();
}

void
MessageListModel::insertMessage(const QString& line)
{
    beginInsertRows(QModelIndex(), rowCount(), rowCount());
    // data_.append(line);
    endInsertRows();
    if (rowCount() >= 10000) {
        removeLine();
    }
}
void
MessageListModel::clearModel()
{
    // data_.clear();
}

QVariant
MessageListModel::data(const QModelIndex& index, int role) const
{
    if (!index.isValid() || index.row() < 0 || index.row() >= rowCount())
        return QVariant();
    // return data_.at(index.row());
    return QVariant();
}
