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
#include "api/interaction.h"
#include "api/messagelistmodel.h"

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
oneToOneOriginalPeerCanRejoin()
{
    return Context {std::nullopt, Mode::ONE_TO_ONE, true};
}

constexpr Context
oneToOneNewParticipant()
{
    return Context {std::nullopt, Mode::ONE_TO_ONE, false};
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
        for (const auto action :
             {Action::SendFile, Action::SendText, Action::ReplyText, Action::ReplyFile, Action::React, Action::Call}) {
            EXPECT_EQ(evaluate(Policy::Basic, role, action), Decision::Allowed) << roleName(role);
        }
    }
}

TEST(SwarmPermissions, InvitedAndLeftMembersCannotDoAnything)
{
    for (const auto policy : {Policy::Basic, Policy::OneToOne, Policy::Feed}) {
        for (const auto role : {Role::INVITED, Role::LEFT}) {
            for (int i = 0; i < static_cast<int>(Action::COUNT__); ++i) {
                const auto action = static_cast<Action>(i);
                const auto context = Context {true, Mode::INVITES_ONLY};
                EXPECT_EQ(evaluate(policy, role, action, context), Decision::Denied)
                    << roleName(role) << " action " << i;
            }
        }
    }
}

TEST(SwarmPermissions, BannedMembersCannotPerformAnyPolicyAction)
{
    for (const auto policy : {Policy::Basic, Policy::OneToOne, Policy::Feed}) {
        for (int i = 0; i < static_cast<int>(Action::COUNT__); ++i) {
            const auto action = static_cast<Action>(i);
            EXPECT_EQ(evaluate(policy, Role::BANNED, action), Decision::Denied) << "action " << i;
        }
    }
}

TEST(SwarmPermissions, AdminsAndMembersCanOnlyEditAndDeleteMessagesTheyAuthored)
{
    for (const auto policy : {Policy::Basic, Policy::OneToOne, Policy::Feed}) {
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

TEST(SwarmPermissions, FeedDeniesCollaborativeDocumentCreationForEveryRole)
{
    for (const auto role : {Role::ADMIN, Role::MEMBER})
        EXPECT_EQ(evaluate(Policy::Feed, role, Action::CreateCollaborativeDocument), Decision::Denied);
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
        for (const auto action :
             {Action::SendFile, Action::SendText, Action::ReplyText, Action::ReplyFile, Action::React, Action::Call}) {
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
    EXPECT_EQ(evaluate(Policy::Basic, std::nullopt, Action::SendText), Decision::Unknown);
}

TEST(SwarmPermissions, AConversationWithoutAPolicyIsNeverAllowed)
{
    EXPECT_EQ(evaluate(std::nullopt, Role::ADMIN, Action::SendText), Decision::Unknown);
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

TEST(SwarmPermissions, FeedAdminsCanManageAndPostButNotCall)
{
    for (const auto action : {Action::SendFile,
                              Action::SendText,
                              Action::ReplyText,
                              Action::ReplyFile,
                              Action::React,
                              Action::AddMember,
                              Action::ChangeConversationProfile,
                              Action::BanUnbanMember}) {
        EXPECT_EQ(evaluate(Policy::Feed, Role::ADMIN, action), Decision::Allowed)
            << "action " << static_cast<int>(action);
    }
    EXPECT_EQ(evaluate(Policy::Feed, Role::ADMIN, Action::Call), Decision::Denied);
}

TEST(SwarmPermissions, FeedMembersCanReplyAndReactButCannotPostOrManage)
{
    for (const auto action : {Action::ReplyText, Action::ReplyFile, Action::React}) {
        EXPECT_EQ(evaluate(Policy::Feed, Role::MEMBER, action), Decision::Allowed)
            << "action " << static_cast<int>(action);
    }
    for (const auto action : {Action::SendFile,
                              Action::SendText,
                              Action::Call,
                              Action::AddMember,
                              Action::ChangeConversationProfile,
                              Action::BanUnbanMember}) {
        EXPECT_EQ(evaluate(Policy::Feed, Role::MEMBER, action), Decision::Denied)
            << "action " << static_cast<int>(action);
    }
}

TEST(SwarmPermissions, OnlyFeedAdminsCanViewTheMemberList)
{
    EXPECT_EQ(evaluate(Policy::Feed, Role::ADMIN, Action::ViewMemberList), Decision::Allowed);
    EXPECT_EQ(evaluate(Policy::Feed, Role::MEMBER, Action::ViewMemberList), Decision::Denied);

    for (const auto policy : {Policy::Basic, Policy::OneToOne}) {
        for (const auto role : {Role::ADMIN, Role::MEMBER}) {
            EXPECT_EQ(evaluate(policy, role, Action::ViewMemberList), Decision::Allowed);
        }
    }
}

TEST(ConversationMode, ToModeMapsFeed)
{
    EXPECT_EQ(conversation::to_mode(5), Mode::FEED);
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

TEST(SwarmPermissions, FeedsUseTheFeedPolicy)
{
    conversation::Info conversation(QStringLiteral("conv"), nullptr);
    conversation.mode = Mode::FEED;
    EXPECT_EQ(policyFor(conversation), Policy::Feed);
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

// Evaluating an action for the local account in a conversation

namespace {

conversation::Info
conversationWith(Mode mode, QVector<member::Member> participants)
{
    conversation::Info conversation(QStringLiteral("conv"), nullptr);
    conversation.mode = mode;
    conversation.participants = std::move(participants);
    return conversation;
}

} // namespace

TEST(SwarmPermissions, ThePolicyDoesNotApplyToNonSwarmConversations)
{
    const auto conversation = conversationWith(Mode::NON_SWARM, {{QStringLiteral("self"), Role::ADMIN}});
    EXPECT_EQ(evaluateFor(conversation, QStringLiteral("self"), Action::SendText), std::nullopt);
}

TEST(SwarmPermissions, TheConversationModeIsUsedForTheSelfRole)
{
    const auto restricted = conversationWith(Mode::ADMIN_INVITES_ONLY, {{QStringLiteral("self"), Role::MEMBER}});
    EXPECT_EQ(evaluateFor(restricted, QStringLiteral("self"), Action::AddMember), Decision::Denied);

    const auto open = conversationWith(Mode::INVITES_ONLY, {{QStringLiteral("self"), Role::MEMBER}});
    EXPECT_EQ(evaluateFor(open, QStringLiteral("self"), Action::AddMember), Decision::Allowed);
}

TEST(SwarmPermissions, ABannedSelfCannotSend)
{
    const auto conversation = conversationWith(Mode::INVITES_ONLY, {{QStringLiteral("self"), Role::BANNED}});
    const auto sendDecision = evaluateFor(conversation, QStringLiteral("self"), Action::SendText);
    ASSERT_TRUE(sendDecision);
    EXPECT_EQ(*sendDecision, Decision::Denied);
    EXPECT_FALSE(isAllowed(*sendDecision));
}

TEST(SwarmPermissions, AnAbsentSelfIsNeverAllowed)
{
    const auto conversation = conversationWith(Mode::INVITES_ONLY, {{QStringLiteral("alice"), Role::ADMIN}});
    const auto decision = evaluateFor(conversation, QStringLiteral("self"), Action::SendText);
    ASSERT_TRUE(decision);
    EXPECT_EQ(*decision, Decision::Unknown);
    EXPECT_FALSE(isAllowed(*decision));
}

TEST(SwarmPermissions, OnlyTheOriginalOneToOnePeerWhoLeftCanRejoin)
{
    const auto conversation = conversationWith(Mode::ONE_TO_ONE,
                                               {{QStringLiteral("self"), Role::ADMIN},
                                                {QStringLiteral("peer"), Role::LEFT}});
    EXPECT_TRUE(targetCanRejoin(conversation, QStringLiteral("peer")));
    EXPECT_FALSE(targetCanRejoin(conversation, QStringLiteral("stranger")));
    EXPECT_FALSE(targetCanRejoin(conversation, QStringLiteral("self")));

    const auto group = conversationWith(Mode::INVITES_ONLY, {{QStringLiteral("peer"), Role::LEFT}});
    EXPECT_FALSE(targetCanRejoin(group, QStringLiteral("peer")));
}

TEST(SwarmPermissions, OneToOneAddMemberUsesTheTargetsRejoinEligibility)
{
    const auto conversation = conversationWith(Mode::ONE_TO_ONE,
                                               {{QStringLiteral("self"), Role::ADMIN},
                                                {QStringLiteral("peer"), Role::LEFT}});
    Context rejoin;
    rejoin.targetCanRejoin = targetCanRejoin(conversation, QStringLiteral("peer"));
    EXPECT_EQ(evaluateFor(conversation, QStringLiteral("self"), Action::AddMember, rejoin), Decision::Allowed);

    Context stranger;
    stranger.targetCanRejoin = targetCanRejoin(conversation, QStringLiteral("stranger"));
    EXPECT_EQ(evaluateFor(conversation, QStringLiteral("self"), Action::AddMember, stranger), Decision::Denied);
}

TEST(SwarmPermissions, MessageAuthorshipIsResolvedFromTheInteraction)
{
    auto conversation = conversationWith(Mode::INVITES_ONLY, {{QStringLiteral("self"), Role::MEMBER}});
    interaction::Info mine;
    mine.authorUri = QStringLiteral("self");
    mine.type = interaction::Type::TEXT;
    interaction::Info legacyMine;
    legacyMine.type = interaction::Type::TEXT;
    interaction::Info theirs;
    theirs.authorUri = QStringLiteral("alice");
    theirs.type = interaction::Type::TEXT;
    conversation.interactions->append(QStringLiteral("m1"), mine);
    conversation.interactions->append(QStringLiteral("m2"), legacyMine);
    conversation.interactions->append(QStringLiteral("m3"), theirs);

    EXPECT_EQ(isMessageAuthoredBy(conversation, QStringLiteral("m1"), QStringLiteral("self")), true);
    EXPECT_EQ(isMessageAuthoredBy(conversation, QStringLiteral("m2"), QStringLiteral("self")), true);
    EXPECT_EQ(isMessageAuthoredBy(conversation, QStringLiteral("m3"), QStringLiteral("self")), false);
    EXPECT_EQ(isMessageAuthoredBy(conversation, QStringLiteral("missing"), QStringLiteral("self")), std::nullopt);
    EXPECT_EQ(isMessageAuthoredBy(conversation, QString(), QStringLiteral("self")), std::nullopt);
}
