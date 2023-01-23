#pragma once

#include "messagelistmodel.h"

namespace lrc {
namespace api {

class DisplayedMessageListModel : public MessageListModel
{
public:
    DisplayedMessageListModel(QObject* parent,
                              QList<QPair<QString, interaction::Info>>& memoryInteractionslist);

    //    Q_INVOKABLE QVariant data(int idx, int role = Qt::DisplayRole) const;
    //    Q_INVOKABLE QVariant data(const QModelIndex& index, int, int role) const override;
    Q_INVOKABLE QVariant dataInMemory(int idx, int role = Qt::DisplayRole) const;
    QVariant dataForItem(item_t item, int indexRow, int role = Qt::DisplayRole) const override;
    int getIndexInMemoryOfMessage(const QString& messageId) const;
    void updateReplies(item_t& message) override;
    void test();
    friend class MemoryMessageListModel;

private:
    QList<QPair<QString, interaction::Info>>& memoryInteractionslist_;
};

} // namespace api
} // namespace lrc
