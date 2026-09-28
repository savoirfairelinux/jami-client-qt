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

#include "api/swarmpermissions.h"

#include <gtest/gtest.h>

using namespace lrc::api;
using namespace lrc::api::permissions;
using Role = member::Role;
using Mode = conversation::Mode;

namespace {

constexpr Context
actorAuthoredMessage()
{
    return Context {true, std::nullopt};
}

constexpr Context
anotherMemberAuthoredMessage()
{
    return Context {false, std::nullopt};
}

constexpr Context
contentExistedBeforeBan()
{
    return Context {std::nullopt, std::nullopt, true};
}

constexpr Context
contentDidNotExistBeforeBan()
{
    return Context {std::nullopt, std::nullopt, false};
}

constexpr Context
oneToOneOriginalPeerCanRejoin()
{
    return Context {std::nullopt, Mode::ONE_TO_ONE, std::nullopt, true};
}

constexpr Context
oneToOneNewParticipant()
{
    return Context {std::nullopt, Mode::ONE_TO_ONE, std::nullopt, false};
}

constexpr Context
inMode(Mode mode)
{
    return Context {std::nullopt, mode};
}

const char*
roleName(Role role)
{
    switch (role) {
    case Role::ADMIN:
        return "admin";
    case Role::MEMBER:
        return "member";
    case Role::INVITED:
        return "invited";
    case Role::BANNED:
        return "banned";
    case Role::LEFT:
        return "left";
    }
    return "?";
}

} // namespace

// Basic swarm

TEST(SwarmPermissions, AdminsAndMembersCanUseTheConversation)
{
    for (const auto role : {Role::ADMIN, Role::MEMBER}) {
        for (const auto action : {Action::SendFile,
                                  Action::SendText,
                                  Action::Read,
                                  Action::ReplyText,
                                  Action::ReplyFile,
                                  Action::React,
                                  Action::Call}) {
            EXPECT_EQ(evaluate(Policy::Basic, role, action), Decision::Allowed) << roleName(role);
        }
    }
}

TEST(SwarmPermissions, InvitedAndLeftMembersCannotDoAnything)
{
    for (const auto policy : {Policy::Basic, Policy::OneToOne}) {
        for (const auto role : {Role::INVITED, Role::LEFT}) {
            for (int i = 0; i < static_cast<int>(Action::COUNT__); ++i) {
                const auto action = static_cast<Action>(i);
                const auto context = Context {true, Mode::INVITES_ONLY, true};
                EXPECT_EQ(evaluate(policy, role, action, context), Decision::Denied)
                    << roleName(role) << " action " << i;
            }
        }
    }
}

TEST(SwarmPermissions, BannedMembersCanReadOnlyContentThatExistedBeforeTheBan)
{
    for (const auto policy : {Policy::Basic, Policy::OneToOne}) {
        EXPECT_EQ(evaluate(policy, Role::BANNED, Action::Read, contentExistedBeforeBan()), Decision::Allowed);
        EXPECT_EQ(evaluate(policy, Role::BANNED, Action::Read, contentDidNotExistBeforeBan()), Decision::Denied);
        EXPECT_EQ(evaluate(policy, Role::BANNED, Action::Read), Decision::Unknown);

        for (int i = 0; i < static_cast<int>(Action::COUNT__); ++i) {
            const auto action = static_cast<Action>(i);
            if (action == Action::Read)
                continue;
            EXPECT_EQ(evaluate(policy, Role::BANNED, action, contentExistedBeforeBan()), Decision::Denied)
                << "action " << i;
        }
    }
}

TEST(SwarmPermissions, AdminsAndMembersCanOnlyEditAndDeleteMessagesTheyAuthored)
{
    for (const auto policy : {Policy::Basic, Policy::OneToOne}) {
        for (const auto role : {Role::ADMIN, Role::MEMBER}) {
            for (const auto action : {Action::EditMessage, Action::DeleteMessage}) {
                EXPECT_EQ(evaluate(policy, role, action, actorAuthoredMessage()), Decision::Allowed) << roleName(role);
                EXPECT_EQ(evaluate(policy, role, action, anotherMemberAuthoredMessage()), Decision::Denied)
                    << roleName(role);
            }
        }
    }
}

TEST(SwarmPermissions, BasicConversationProfileCanOnlyBeChangedByAdmins)
{
    EXPECT_EQ(evaluate(Policy::Basic, Role::ADMIN, Action::ChangeConversationProfile), Decision::Allowed);
    EXPECT_EQ(evaluate(Policy::Basic, Role::MEMBER, Action::ChangeConversationProfile), Decision::Denied);
}

TEST(SwarmPermissions, OnlyAdminsCanBanOrUnbanMembers)
{
    EXPECT_EQ(evaluate(Policy::Basic, Role::ADMIN, Action::BanUnbanMember, {}), Decision::Allowed);
    EXPECT_EQ(evaluate(Policy::Basic, Role::MEMBER, Action::BanUnbanMember, {}), Decision::Denied);
}

TEST(SwarmPermissions, CollaborativeDocumentCreationIsAllowedInBasicAndOneToOne)
{
    for (const auto role : {Role::ADMIN, Role::MEMBER}) {
        EXPECT_EQ(evaluate(Policy::Basic, role, Action::CreateCollaborativeDocument), Decision::Allowed);
        EXPECT_EQ(evaluate(Policy::OneToOne, role, Action::CreateCollaborativeDocument), Decision::Allowed);
    }
}

TEST(SwarmPermissions, AdminsCanAddMembersInEveryMode)
{
    for (const auto mode : {Mode::ADMIN_INVITES_ONLY, Mode::INVITES_ONLY, Mode::PUBLIC}) {
        EXPECT_EQ(evaluate(Policy::Basic, Role::ADMIN, Action::AddMember, inMode(mode)), Decision::Allowed);
    }
}

TEST(SwarmPermissions, MembersCanAddMembersUnlessInvitesAreRestrictedToAdmins)
{
    EXPECT_EQ(evaluate(Policy::Basic, Role::MEMBER, Action::AddMember, inMode(Mode::INVITES_ONLY)), Decision::Allowed);
    EXPECT_EQ(evaluate(Policy::Basic, Role::MEMBER, Action::AddMember, inMode(Mode::PUBLIC)), Decision::Allowed);
    EXPECT_EQ(evaluate(Policy::Basic, Role::MEMBER, Action::AddMember, inMode(Mode::ADMIN_INVITES_ONLY)),
              Decision::Denied);
}

TEST(SwarmPermissions, OneToOneMembersCanReAddTheOriginalPeerButNotAddThirdParties)
{
    for (const auto role : {Role::ADMIN, Role::MEMBER}) {
        EXPECT_EQ(evaluate(Policy::OneToOne, role, Action::AddMember, oneToOneOriginalPeerCanRejoin()),
                  Decision::Allowed);
        EXPECT_EQ(evaluate(Policy::OneToOne, role, Action::AddMember, oneToOneNewParticipant()), Decision::Denied);
        EXPECT_EQ(evaluate(Policy::OneToOne, role, Action::AddMember), Decision::Unknown);
    }
}

// One-to-one swarm

TEST(SwarmPermissions, BothPeersOfAOneToOneCanUseTheConversation)
{
    for (const auto role : {Role::ADMIN, Role::MEMBER}) {
        for (const auto action : {Action::SendFile,
                                  Action::SendText,
                                  Action::Read,
                                  Action::ReplyText,
                                  Action::ReplyFile,
                                  Action::React,
                                  Action::Call}) {
            EXPECT_EQ(evaluate(Policy::OneToOne, role, action), Decision::Allowed) << roleName(role);
        }
        for (const auto action : {Action::EditMessage, Action::DeleteMessage}) {
            EXPECT_EQ(evaluate(Policy::OneToOne, role, action, actorAuthoredMessage()), Decision::Allowed);
            EXPECT_EQ(evaluate(Policy::OneToOne, role, action, anotherMemberAuthoredMessage()), Decision::Denied);
        }
    }
}

TEST(SwarmPermissions, OneToOneParticipantsCannotChangeTheConversationProfile)
{
    for (const auto role : {Role::ADMIN, Role::MEMBER}) {
        EXPECT_EQ(evaluate(Policy::OneToOne, role, Action::ChangeConversationProfile, {}), Decision::Denied)
            << roleName(role);
    }
}

TEST(SwarmPermissions, NobodyCanBanOrUnbanMembersOfAOneToOne)
{
    for (const auto role : {Role::ADMIN, Role::MEMBER}) {
        EXPECT_EQ(evaluate(Policy::OneToOne, role, Action::BanUnbanMember, inMode(Mode::ONE_TO_ONE)), Decision::Denied);
    }
}

// Missing information fails closed

TEST(SwarmPermissions, AnUnknownRoleIsNeverAllowed)
{
    EXPECT_EQ(evaluate(Policy::Basic, std::nullopt, Action::Read), Decision::Unknown);
}

TEST(SwarmPermissions, AConversationWithoutAPolicyIsNeverAllowed)
{
    EXPECT_EQ(evaluate(std::nullopt, Role::ADMIN, Action::Read), Decision::Unknown);
}

TEST(SwarmPermissions, EditingWithoutKnowingTheAuthorIsNeverAllowed)
{
    EXPECT_EQ(evaluate(Policy::Basic, Role::MEMBER, Action::EditMessage), Decision::Unknown);
}

TEST(SwarmPermissions, AddingAMemberWithoutKnowingTheModeIsNeverAllowed)
{
    EXPECT_EQ(evaluate(Policy::Basic, Role::MEMBER, Action::AddMember), Decision::Unknown);
}

TEST(SwarmPermissions, OnlyAllowedMeansYes)
{
    EXPECT_TRUE(isAllowed(Decision::Allowed));
    EXPECT_FALSE(isAllowed(Decision::Denied));
    EXPECT_FALSE(isAllowed(Decision::Unknown));
}

// Mapping a conversation onto a policy

TEST(SwarmPermissions, GroupSwarmsUseTheBasicPolicy)
{
    for (const auto mode : {Mode::ADMIN_INVITES_ONLY, Mode::INVITES_ONLY, Mode::PUBLIC}) {
        conversation::Info conversation(QStringLiteral("conv"), nullptr);
        conversation.mode = mode;
        EXPECT_EQ(policyFor(conversation), Policy::Basic);
    }
}

TEST(SwarmPermissions, OneToOneSwarmsUseTheOneToOnePolicy)
{
    conversation::Info conversation(QStringLiteral("conv"), nullptr);
    conversation.mode = Mode::ONE_TO_ONE;
    EXPECT_EQ(policyFor(conversation), Policy::OneToOne);
}

TEST(SwarmPermissions, NonSwarmConversationsHaveNoPolicy)
{
    conversation::Info conversation(QStringLiteral("conv"), nullptr);
    conversation.mode = Mode::NON_SWARM;
    EXPECT_EQ(policyFor(conversation), std::nullopt);
}

// Looking up a participant's role

TEST(SwarmPermissions, AParticipantsRoleIsFound)
{
    conversation::Info conversation(QStringLiteral("conv"), nullptr);
    conversation.participants = {{QStringLiteral("alice"), Role::ADMIN}, {QStringLiteral("bob"), Role::BANNED}};
    EXPECT_EQ(roleOf(conversation, QStringLiteral("alice")), Role::ADMIN);
    EXPECT_EQ(roleOf(conversation, QStringLiteral("bob")), Role::BANNED);
}

// The legacy lookup reports a missing participant as a member; this one must not.
TEST(SwarmPermissions, AMissingParticipantHasNoRole)
{
    conversation::Info conversation(QStringLiteral("conv"), nullptr);
    conversation.participants = {{QStringLiteral("alice"), Role::ADMIN}};
    EXPECT_EQ(roleOf(conversation, QStringLiteral("mallory")), std::nullopt);
}
