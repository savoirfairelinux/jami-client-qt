#pragma once

#include "messagelistmodel.h"
#include "displayedmessagelistmodel.h"

namespace lrc {
namespace api {

class MemoryMessageListModel : public MessageListModel
{
public:
    MemoryMessageListModel(QObject* parent);

    // QVariant dataForItem(item_t item, int indexRow, int role = Qt::DisplayRole) const;
    void insertMessage(int index, item_t& message) override;
    iterator insertMessage(iterator it, item_t& message) override;
    void setDisplayedList(std::unique_ptr<DisplayedMessageListModel>* displayedinteractionsModel);

private:
    std::unique_ptr<DisplayedMessageListModel>* displayedinteractionsModel_ = nullptr;
};

} // namespace api
} // namespace lrc
