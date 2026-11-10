/*
 * Copyright (C) 2026 Savoir-faire Linux Inc.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, see <https://www.gnu.org/licenses/>.
 */

#include "conversationlistproxymodel.h"

#include <gtest/gtest.h>

namespace {
using Mode = lrc::api::conversation::Mode;
using Role = ConversationList::Role;

struct Row
{
    QString uid;
    Mode mode;
    bool request = false;
    int timestamp = 100;
    bool banned = false;
    int unread = 0;
};

class ConversationRows : public QAbstractListModel
{
public:
    QList<Row> rows {
        {"dialog", Mode::ONE_TO_ONE, false, 600, false, 2},
        {"legacy", Mode::NON_SWARM, false, 500, false, 3},
        {"group", Mode::INVITES_ONLY, false, 400, false, 4},
        {"feed", Mode::FEED, false, 300, false, 5},
        {"dialog-invite", Mode::ONE_TO_ONE, true, 200, false, 8},
        {"group-invite", Mode::INVITES_ONLY, true, 100, false, 9},
        {"feed-invite", Mode::FEED, true, 50, false, 10},
    };

    int rowCount(const QModelIndex& parent = {}) const override
    {
        return parent.isValid() ? 0 : rows.size();
    }

    QVariant data(const QModelIndex& index, int role) const override
    {
        if (!index.isValid() || index.row() >= rows.size())
            return {};
        const auto& row = rows[index.row()];
        switch (role) {
        case Role::UID:
        case Role::Title:
            return row.uid;
        case Role::Uris:
            return QStringList {row.uid};
        case Role::Mode:
            return static_cast<int>(row.mode);
        case Role::IsRequest:
            return row.request;
        case Role::LastInteractionTimeStamp:
            return row.timestamp;
        case Role::IsBanned:
            return row.banned;
        case Role::UnreadMessagesCount:
            return row.unread;
        default:
            return {};
        }
    }

    void changed(int row)
    {
        Q_EMIT dataChanged(index(row), index(row));
    }
};

QStringList
ids(const ConversationListProxyModel& proxy)
{
    QStringList result;
    for (int row = 0; row < proxy.rowCount(); ++row)
        result.append(proxy.index(row, 0).data(Role::UID).toString());
    return result;
}
} // namespace

TEST(ConversationListProxyModel, AllExcludesInvitations)
{
    ConversationRows source;
    ConversationListProxyModel proxy(&source);
    EXPECT_EQ(ids(proxy), (QStringList {"dialog", "legacy", "group", "feed"}));
}

TEST(ConversationListProxyModel, AllCanToggleBetweenConversationsAndAllInvitations)
{
    ConversationRows source;
    ConversationListProxyModel proxy(&source);
    proxy.setInvitationsOnly(true);
    EXPECT_EQ(ids(proxy), (QStringList {"dialog-invite", "group-invite", "feed-invite"}));
    proxy.setInvitationsOnly(false);
    EXPECT_EQ(ids(proxy), (QStringList {"dialog", "legacy", "group", "feed"}));
}

TEST(ConversationListProxyModel, ContactsAndGroupsDefaultToAcceptedConversations)
{
    ConversationRows source;
    ConversationListProxyModel proxy(&source);
    proxy.setCategory(ConversationListProxyModel::OneToOne);
    EXPECT_EQ(ids(proxy), (QStringList {"dialog", "legacy"}));
    proxy.setCategory(ConversationListProxyModel::Groups);
    EXPECT_EQ(ids(proxy), (QStringList {"group"}));
}

TEST(ConversationListProxyModel, InvitationToggleSeparatesRows)
{
    ConversationRows source;
    ConversationListProxyModel proxy(&source);
    proxy.setCategory(ConversationListProxyModel::OneToOne);
    proxy.setInvitationsOnly(true);
    EXPECT_EQ(ids(proxy), (QStringList {"dialog-invite"}));
    proxy.setInvitationsOnly(false);
    proxy.setCategory(ConversationListProxyModel::Groups);
    EXPECT_EQ(ids(proxy), (QStringList {"group"}));
    proxy.setInvitationsOnly(true);
    EXPECT_EQ(ids(proxy), (QStringList {"group-invite"}));
    proxy.setInvitationsOnly(false);
    EXPECT_EQ(ids(proxy), (QStringList {"group"}));
    proxy.setCategory(ConversationListProxyModel::Feeds);
    EXPECT_EQ(ids(proxy), (QStringList {"feed"}));
    proxy.setInvitationsOnly(true);
    EXPECT_EQ(ids(proxy), (QStringList {"feed-invite"}));
    proxy.setCategory(ConversationListProxyModel::All);
    EXPECT_EQ(ids(proxy), (QStringList {"dialog-invite", "group-invite", "feed-invite"}));
}

TEST(ConversationListProxyModel, SearchIncludesInvitationsAcrossCategories)
{
    ConversationRows source;
    ConversationListProxyModel proxy(&source);
    proxy.setCategory(ConversationListProxyModel::Groups);
    proxy.setFilter("feed");
    EXPECT_EQ(ids(proxy), (QStringList {"feed", "feed-invite"}));
    proxy.setFilter("");
    EXPECT_EQ(ids(proxy), (QStringList {"group"}));
    proxy.setInvitationsOnly(true);
    proxy.setFilter("feed");
    EXPECT_EQ(ids(proxy), (QStringList {"feed", "feed-invite"}));
    proxy.setFilter("");
    EXPECT_EQ(ids(proxy), (QStringList {"group-invite"}));
}

TEST(ConversationListProxyModel, InvitationModeSortsByActivityAndRemovesAcceptedRows)
{
    ConversationRows source;
    source.rows.append({"other-group-invite", Mode::PUBLIC, true, 150});
    ConversationListProxyModel proxy(&source);
    proxy.setCategory(ConversationListProxyModel::Groups);
    proxy.setInvitationsOnly(true);
    EXPECT_EQ(ids(proxy), (QStringList {"other-group-invite", "group-invite"}));
    source.rows[2].timestamp = 1000;
    source.changed(2);
    EXPECT_EQ(ids(proxy).first(), "other-group-invite");
    source.rows[5].timestamp = 2000;
    source.changed(5);
    EXPECT_EQ(ids(proxy), (QStringList {"group-invite", "other-group-invite"}));
    source.rows[5].request = false;
    source.changed(5);
    EXPECT_EQ(ids(proxy), (QStringList {"other-group-invite"}));
    source.rows.last().request = false;
    source.changed(source.rows.size() - 1);
    EXPECT_EQ(proxy.rowCount(), 0);
}

TEST(ConversationListProxyModel, CategoryChangeKeepsSourceSelection)
{
    ConversationRows source;
    ConversationListProxyModel proxy(&source);
    proxy.selectSourceRow(0);
    proxy.setCategory(ConversationListProxyModel::OneToOne);
    proxy.setInvitationsOnly(true);
    EXPECT_EQ(proxy.get_currentFilteredRow(), -1);
    proxy.setInvitationsOnly(false);
    EXPECT_EQ(proxy.get_currentFilteredRow(), 0);
    proxy.setCategory(ConversationListProxyModel::Groups);
    EXPECT_EQ(proxy.get_currentFilteredRow(), -1);
    proxy.setCategory(ConversationListProxyModel::All);
    EXPECT_EQ(proxy.get_currentFilteredRow(), 0);
}

TEST(ConversationListProxyModel, SearchPreservesBannedExactMatchAndHighlightedMembers)
{
    ConversationRows source;
    source.rows[0].banned = true;
    ConversationListProxyModel proxy(&source);
    proxy.setFilter("dia");
    EXPECT_EQ(ids(proxy), (QStringList {"dialog-invite"}));
    proxy.setFilter("dialog");
    EXPECT_EQ(ids(proxy), (QStringList {"dialog", "dialog-invite"}));
    proxy.ignoreFiltering({"legacy"});
    proxy.setFilter("no-match");
    EXPECT_EQ(ids(proxy), (QStringList {"legacy"}));
}

TEST(ConversationListProxyModel, GroupModesDoNotDependOnMemberCount)
{
    ConversationRows source;
    source.rows.append({"admin-group", Mode::ADMIN_INVITES_ONLY});
    source.rows.append({"public-group", Mode::PUBLIC});
    source.rows.append({"legacy-invite", Mode::NON_SWARM, true});
    ConversationListProxyModel proxy(&source);
    proxy.setCategory(ConversationListProxyModel::Groups);
    EXPECT_EQ(proxy.rowCount(), 3);
    proxy.setCategory(ConversationListProxyModel::OneToOne);
    EXPECT_EQ(proxy.rowCount(), 2);
    proxy.setInvitationsOnly(true);
    EXPECT_EQ(proxy.rowCount(), 2);
}
