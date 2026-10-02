#include "app/conversationlistproxymodel.h"

#include <QAbstractListModel>
#include <gtest/gtest.h>

using namespace lrc::api;

namespace {

class ConversationTestModel final : public QAbstractListModel
{
public:
    struct Item
    {
        conversation::Mode mode;
        bool isRequest;
    };

    int rowCount(const QModelIndex& parent = QModelIndex()) const override
    {
        return parent.isValid() ? 0 : items_.size();
    }

    QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const override
    {
        if (!index.isValid() || index.row() >= items_.size())
            return {};

        switch (role) {
        case ConversationList::Title:
            return QStringLiteral("Conversation");
        case ConversationList::IsRequest:
            return items_[index.row()].isRequest;
        case ConversationList::Mode:
            return static_cast<int>(items_[index.row()].mode);
        case ConversationList::Uris:
        case ConversationList::Monikers:
            return QStringList {QStringLiteral("peer")};
        default:
            return {};
        }
    }

    void append(conversation::Mode mode, bool isRequest)
    {
        const auto row = items_.size();
        beginInsertRows({}, row, row);
        items_.append({mode, isRequest});
        endInsertRows();
    }

private:
    QList<Item> items_;
};

} // namespace

TEST(ConversationListProxyModel, FiltersConversationsFeedsAndRequests)
{
    ConversationTestModel source;
    source.append(conversation::Mode::ONE_TO_ONE, false);
    source.append(conversation::Mode::FEED, false);
    source.append(conversation::Mode::FEED, true);

    ConversationListProxyModel proxy(&source);

    EXPECT_EQ(proxy.rowCount(), 1);

    proxy.setFilterFeeds(true);
    ASSERT_EQ(proxy.rowCount(), 1);
    EXPECT_EQ(proxy.data(proxy.index(0, 0), ConversationList::Mode).toInt(), static_cast<int>(conversation::Mode::FEED));
    EXPECT_FALSE(proxy.data(proxy.index(0, 0), ConversationList::IsRequest).toBool());

    proxy.setFilterRequests(true);
    ASSERT_EQ(proxy.rowCount(), 1);
    EXPECT_TRUE(proxy.data(proxy.index(0, 0), ConversationList::IsRequest).toBool());
}
