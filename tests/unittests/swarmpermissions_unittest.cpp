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
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

#include "api/conversation.h"
#include "api/swarmpermissions.h"

#include <gtest/gtest.h>

using namespace lrc::api::permissions;

TEST(SwarmPermissions, EveryDaemonNameMapsToItsPermission)
{
    for (const auto& [permission, name] : PERMISSION_NAME_TABLE) {
        const auto permissions = fromNames({QString::fromUtf8(name.data(), name.size())});
        EXPECT_EQ(permissions, PermissionSet {permission}) << name;
    }
}

TEST(SwarmPermissions, SeveralNamesGiveSeveralPermissions)
{
    const auto permissions = fromNames({"text", "call", "updateProfile"});

    EXPECT_EQ(permissions, (PermissionSet {Permission::Text, Permission::Call, Permission::UpdateProfile}));
}

// A newer daemon may grant permissions this client does not know about yet.
TEST(SwarmPermissions, UnknownNamesAreIgnored)
{
    const auto permissions = fromNames({"text", "somethingNew"});

    EXPECT_EQ(permissions, PermissionSet {Permission::Text});
}

TEST(SwarmPermissions, NoNamesGrantNothing)
{
    EXPECT_TRUE(fromNames({}).isEmpty());
}

TEST(SwarmPermissions, ASwarmGrantsNothingUntilTheDaemonAnswers)
{
    lrc::api::conversation::Info conversation("swarm-id", nullptr);
    conversation.mode = lrc::api::conversation::Mode::INVITES_ONLY;

    EXPECT_FALSE(conversation.isPermitted(Permission::Text));
    EXPECT_FALSE(conversation.isPermitted(Permission::UpdateProfile));
}

TEST(SwarmPermissions, ASwarmGrantsOnlyWhatTheDaemonSent)
{
    lrc::api::conversation::Info conversation("swarm-id", nullptr);
    conversation.mode = lrc::api::conversation::Mode::INVITES_ONLY;
    conversation.permissions = fromNames({"text", "hostConference"});

    EXPECT_TRUE(conversation.isPermitted(Permission::Text));
    EXPECT_TRUE(conversation.isPermitted(Permission::HostConference));
    EXPECT_FALSE(conversation.isPermitted(Permission::UpdateProfile));
    EXPECT_FALSE(conversation.isPermitted(Permission::BanUnbanMember));
}

// SIP and legacy conversations have no swarm permissions in the daemon.
TEST(SwarmPermissions, ANonSwarmConversationAllowsEverything)
{
    lrc::api::conversation::Info conversation("legacy-id", nullptr);
    conversation.mode = lrc::api::conversation::Mode::NON_SWARM;

    for (const auto& [permission, name] : PERMISSION_NAME_TABLE)
        EXPECT_TRUE(conversation.isPermitted(permission)) << name;
}

TEST(SwarmPermissions, OnlyAdminsSeeTheMembersOfAFeed)
{
    using lrc::api::member::Role;
    lrc::api::conversation::Info feed("feed-id", nullptr);
    feed.mode = lrc::api::conversation::Mode::FEED;
    feed.accountUri = "me";

    feed.participants = {{"me", Role::ADMIN}, {"follower", Role::MEMBER}};
    EXPECT_TRUE(feed.canViewMemberList());

    feed.participants = {{"owner", Role::ADMIN}, {"me", Role::MEMBER}};
    EXPECT_FALSE(feed.canViewMemberList());

    feed.participants = {{"owner", Role::ADMIN}};
    EXPECT_FALSE(feed.canViewMemberList());
}

TEST(SwarmPermissions, EveryoneSeesTheMembersOfAGroup)
{
    lrc::api::conversation::Info group("group-id", nullptr);
    group.mode = lrc::api::conversation::Mode::INVITES_ONLY;
    group.accountUri = "me";
    group.participants = {{"owner", lrc::api::member::Role::ADMIN}, {"me", lrc::api::member::Role::MEMBER}};

    EXPECT_TRUE(group.canViewMemberList());
}
