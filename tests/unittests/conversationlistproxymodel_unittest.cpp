/*
 * Copyright (C) 2026 Savoir-faire Linux Inc.
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

#include "conversationlistproxymodel.h"

#include <gtest/gtest.h>

#include <QAbstractListModel>

namespace {

struct Conversation
{
    QString title;
    bool isCoreDialog;
    qulonglong lastInteraction;
    conversation::Mode mode {conversation::Mode::ONE_TO_ONE};
};

// The roles the proxy reads, for conversations made up by the tests.
class FakeConversations final : public QAbstractListModel
{
public:
    explicit FakeConversations(QList<Conversation> conversations)
        : conversations_(std::move(conversations))
    {}

    int rowCount(const QModelIndex& parent = {}) const override
    {
        return parent.isValid() ? 0 : conversations_.size();
    }

    QVariant data(const QModelIndex& index, int role) const override
    {
        using namespace ConversationList;
        const auto& conversation = conversations_.at(index.row());
        switch (role) {
        case Role::UID:
            return QStringLiteral("uid-%1").arg(index.row());
        case Role::Title:
            return conversation.title;
        case Role::IsCoreDialog:
            return conversation.isCoreDialog;
        case Role::LastInteractionTimeStamp:
            return conversation.lastInteraction;
        case Role::Mode:
            return static_cast<int>(conversation.mode);
        case Role::Uris:
            return QStringList {conversation.title};
        case Role::IsRequest:
        case Role::IsBanned:
            return false;
        default:
            return {};
        }
    }

private:
    QList<Conversation> conversations_;
};

QStringList
titles(const QAbstractItemModel& model)
{
    QStringList result;
    for (int row = 0; row < model.rowCount(); ++row)
        result << model.index(row, 0).data(ConversationList::Role::Title).toString();
    return result;
}

} // namespace

TEST(ConversationListProxyModel, ListsContactsAndGroupsMostRecentFirst)
{
    FakeConversations source({{"Alice", true, 10}, {"Team", false, 30}, {"Bob", true, 20}});
    ConversationListProxyModel proxy(&source);

    EXPECT_EQ(titles(proxy), QStringList({"Team", "Bob", "Alice"}));
}

TEST(ConversationListProxyModel, CanListOnlyContactsOrOnlyGroups)
{
    FakeConversations source({{"Alice", true, 10}, {"Team", false, 30}, {"Bob", true, 20}});
    ConversationListProxyModel proxy(&source);

    proxy.setShowGroups(false);
    EXPECT_EQ(titles(proxy), QStringList({"Bob", "Alice"}));

    proxy.setShowContacts(false);
    proxy.setShowGroups(true);
    EXPECT_EQ(titles(proxy), QStringList({"Team"}));
}

TEST(ConversationListProxyModel, SortsByTitleFromAToZAndBack)
{
    FakeConversations source(
        {{"bob", true, 40}, {"Item 10", false, 30}, {"Alice", true, 10}, {"Item 9", false, 20}, {"Zoe", true, 50}});
    ConversationListProxyModel proxy(&source);

    proxy.setSortByTitle(true);
    // Case does not matter, and numbers are compared as numbers.
    EXPECT_EQ(titles(proxy), QStringList({"Alice", "bob", "Item 9", "Item 10", "Zoe"}));

    proxy.setSortByTitle(false);
    EXPECT_EQ(titles(proxy), QStringList({"Zoe", "bob", "Item 10", "Item 9", "Alice"}));
}

TEST(ConversationListProxyModel, NeverListsFeeds)
{
    FakeConversations source({{"Alice", true, 10}, {"News", false, 20, conversation::Mode::FEED}});
    ConversationListProxyModel proxy(&source);

    EXPECT_EQ(titles(proxy), QStringList({"Alice"}));
    proxy.setShowContacts(false);
    EXPECT_TRUE(titles(proxy).isEmpty());
}
