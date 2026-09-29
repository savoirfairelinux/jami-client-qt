/****************************************************************************
 *   Copyright (C) 2026 Savoir-faire Linux Inc.                             *
 *                                                                          *
 *   This library is free software; you can redistribute it and/or          *
 *   modify it under the terms of the GNU Lesser General Public             *
 *   License as published by the Free Software Foundation; either           *
 *   version 2.1 of the License, or (at your option) any later version.     *
 *                                                                          *
 *   This library is distributed in the hope that it will be useful,        *
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of         *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU      *
 *   Lesser General Public License for more details.                        *
 *                                                                          *
 *   You should have received a copy of the GNU General Public License      *
 *   along with this program.  If not, see <http://www.gnu.org/licenses/>.  *
 ***************************************************************************/
#include "api/swarmpermissions.h"

#include "api/interaction.h"
#include "api/messagelistmodel.h"

#include <array>

namespace lrc {
namespace api {
namespace permissions {

namespace {

enum class Capability { None, MemberConversationProfileUpdate };

enum class Condition {
    None,
    // Denied when only admins may invite (conversation::Mode::ADMIN_INVITES_ONLY).
    NotAdminInvitesOnly,
    // Banned members can read only content that existed before the ban.
    PreBanContentOnly,
    // In one-to-one conversations, only the original peer may rejoin.
    OneToOneRejoinOnly
};

struct Cell
{
    Rule rule = Rule::Deny;
    Capability capability = Capability::None;
    Rule withoutCapability = Rule::Deny;
    Condition condition = Condition::None;
};

constexpr auto ActionCount = static_cast<std::size_t>(Action::COUNT__);
constexpr auto RoleCount = static_cast<std::size_t>(member::Role::LEFT) + 1;
constexpr auto ProfileCount = static_cast<std::size_t>(SwarmProfile::COUNT__);

using RoleRow = std::array<Cell, ActionCount>;
using ProfileTable = std::array<RoleRow, RoleCount>;

constexpr Cell D {Rule::Deny};
constexpr Cell A {Rule::Allow};
constexpr Cell ActorAuthoredOnly {Rule::AllowIfActorIsAuthor};
constexpr Cell MemberInvite {Rule::Allow, Capability::None, Rule::Deny, Condition::NotAdminInvitesOnly};
constexpr Cell MemberConversationProfile {Rule::Allow, Capability::MemberConversationProfileUpdate, Rule::Deny};
constexpr Cell BannedRead {Rule::Allow, Capability::None, Rule::Deny, Condition::PreBanContentOnly};
constexpr Cell OneToOneRejoin {Rule::Allow, Capability::None, Rule::Deny, Condition::OneToOneRejoinOnly};

constexpr RoleRow DenyAll {D, D, D, D, D, D, D, D, D, D, D};
constexpr RoleRow BannedReadOnly {D, D, BannedRead, D, D, D, D, D, D, D, D};

// Columns follow Action: SendFile, SendText, Read, Reply, React, Call,
// EditMessage, DeleteMessage, AddMember, ChangeConversationProfile, BanUnbanMember.
// Rows follow member::Role: ADMIN, MEMBER, INVITED, BANNED, LEFT.
constexpr ProfileTable BasicTable {{
    {A, A, A, A, A, A, ActorAuthoredOnly, ActorAuthoredOnly, A, A, A},
    {A, A, A, A, A, A, ActorAuthoredOnly, ActorAuthoredOnly, MemberInvite, MemberConversationProfile, D},
    DenyAll,
    BannedReadOnly,
    DenyAll,
}};

constexpr ProfileTable OneToOneTable {{
    {A, A, A, A, A, A, ActorAuthoredOnly, ActorAuthoredOnly, OneToOneRejoin, D, D},
    {A, A, A, A, A, A, ActorAuthoredOnly, ActorAuthoredOnly, OneToOneRejoin, D, D},
    DenyAll,
    BannedReadOnly,
    DenyAll,
}};

constexpr std::array<const ProfileTable*, ProfileCount> Tables {&BasicTable, &OneToOneTable};

constexpr bool
supports(const Capabilities& capabilities, Capability capability)
{
    switch (capability) {
    case Capability::None:
        return true;
    case Capability::MemberConversationProfileUpdate:
        return capabilities.memberConversationProfileUpdate;
    }
    return false;
}

} // namespace

Decision
evaluate(std::optional<SwarmProfile> profile,
         std::optional<member::Role> role,
         Action action,
         const Context& context,
         const Capabilities& capabilities)
{
    if (!profile || !role)
        return Decision::Unknown;

    const auto profileIndex = static_cast<std::size_t>(*profile);
    const auto roleIndex = static_cast<std::size_t>(*role);
    const auto actionIndex = static_cast<std::size_t>(action);
    if (profileIndex >= ProfileCount || roleIndex >= RoleCount || actionIndex >= ActionCount)
        return Decision::Unknown;

    const auto& cell = (*Tables[profileIndex])[roleIndex][actionIndex];
    const auto rule = supports(capabilities, cell.capability) ? cell.rule : cell.withoutCapability;
    if (rule == Rule::Deny)
        return Decision::Denied;

    if (cell.condition == Condition::NotAdminInvitesOnly) {
        if (!context.mode)
            return Decision::Unknown;
        if (*context.mode == conversation::Mode::ADMIN_INVITES_ONLY)
            return Decision::Denied;
    }
    if (cell.condition == Condition::PreBanContentOnly) {
        if (!context.contentExistedBeforeBan)
            return Decision::Unknown;
        if (!*context.contentExistedBeforeBan)
            return Decision::Denied;
    }
    if (cell.condition == Condition::OneToOneRejoinOnly) {
        if (!context.targetCanRejoin)
            return Decision::Unknown;
        if (!*context.targetCanRejoin)
            return Decision::Denied;
    }

    if (rule == Rule::AllowIfActorIsAuthor) {
        if (!context.actorIsAuthor)
            return Decision::Unknown;
        return *context.actorIsAuthor ? Decision::Allowed : Decision::Denied;
    }

    return Decision::Allowed;
}

std::optional<SwarmProfile>
profileFor(const conversation::Info& conversation)
{
    switch (conversation.mode) {
    case conversation::Mode::ONE_TO_ONE:
        return SwarmProfile::OneToOne;
    case conversation::Mode::ADMIN_INVITES_ONLY:
    case conversation::Mode::INVITES_ONLY:
    case conversation::Mode::PUBLIC:
        return SwarmProfile::Basic;
    case conversation::Mode::NON_SWARM:
        return std::nullopt;
    }
    return std::nullopt;
}

std::optional<member::Role>
roleOf(const conversation::Info& conversation, const QString& uri)
{
    for (const auto& participant : conversation.participants) {
        if (participant.uri == uri)
            return participant.role;
    }
    return std::nullopt;
}

std::optional<Decision>
evaluateFor(const conversation::Info& conversation,
            const QString& selfUri,
            Action action,
            Context context,
            const Capabilities& capabilities)
{
    const auto profile = profileFor(conversation);
    if (!profile)
        return std::nullopt;
    if (!context.mode)
        context.mode = conversation.mode;
    return evaluate(profile, roleOf(conversation, selfUri), action, context, capabilities);
}

bool
targetCanRejoin(const conversation::Info& conversation, const QString& targetUri)
{
    if (conversation.mode != conversation::Mode::ONE_TO_ONE)
        return false;
    return roleOf(conversation, targetUri) == member::Role::LEFT;
}

std::optional<bool>
isMessageAuthoredBy(const conversation::Info& conversation, const QString& messageId, const QString& selfUri)
{
    // An empty id would make the lookup fall back to the last message.
    if (messageId.isEmpty() || !conversation.interactions)
        return std::nullopt;
    std::optional<bool> authored;
    conversation.interactions->with(messageId, [&](const QString&, interaction::Info& interaction) {
        authored = interaction.authorUri.isEmpty() || interaction.authorUri == selfUri;
    });
    return authored;
}

} // namespace permissions
} // namespace api
} // namespace lrc
