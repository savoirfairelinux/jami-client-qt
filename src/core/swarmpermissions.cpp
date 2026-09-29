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

enum class Condition {
    None,
    // Denied when only admins may invite (conversation::Mode::ADMIN_INVITES_ONLY).
    NotAdminInvitesOnly,
    // In one-to-one conversations, only the original peer may rejoin.
    OneToOneRejoinOnly
};

struct Cell
{
    Rule rule = Rule::Deny;
    Condition condition = Condition::None;
};

constexpr auto ActionCount = static_cast<std::size_t>(Action::COUNT__);
constexpr auto RoleCount = static_cast<std::size_t>(member::Role::LEFT) + 1;
constexpr auto PolicyCount = static_cast<std::size_t>(Policy::COUNT__);

using RoleRow = std::array<Cell, ActionCount>;
using PolicyTable = std::array<RoleRow, RoleCount>;

constexpr Cell Deny {Rule::Deny};
constexpr Cell Allow {Rule::Allow};
constexpr Cell ActorAuthoredOnly {Rule::AllowIfActorIsAuthor};
constexpr Cell MemberInvite {Rule::Allow, Condition::NotAdminInvitesOnly};
constexpr Cell OneToOneRejoin {Rule::Allow, Condition::OneToOneRejoinOnly};

// clang-format off
constexpr RoleRow DenyAll {Deny, Deny, Deny, Deny, Deny, Deny, Deny, Deny, Deny, Deny, Deny, Deny};

// Columns follow Action: SendFile, SendText, ReplyText, ReplyFile, React, Call, EditMessage, DeleteMessage, AddMember, ChangeConversationProfile, BanUnbanMember, CreateCollaborativeDocument.
constexpr PolicyTable BasicTable {{
    {Allow, Allow, Allow, Allow, Allow, Allow, ActorAuthoredOnly, ActorAuthoredOnly, Allow, Allow, Allow, Allow}, // ADMIN
    {Allow, Allow, Allow, Allow, Allow, Allow, ActorAuthoredOnly, ActorAuthoredOnly, MemberInvite, Deny, Deny, Allow}, // MEMBER
    DenyAll, // INVITED
    DenyAll, // BANNED
    DenyAll, // LEFT
}};

constexpr PolicyTable OneToOneTable {{
    {Allow, Allow, Allow, Allow, Allow, Allow, ActorAuthoredOnly, ActorAuthoredOnly, OneToOneRejoin, Deny, Deny, Allow}, // ADMIN
    {Allow, Allow, Allow, Allow, Allow, Allow, ActorAuthoredOnly, ActorAuthoredOnly, OneToOneRejoin, Deny, Deny, Allow}, // MEMBER
    DenyAll, // INVITED
    DenyAll, // BANNED
    DenyAll, // LEFT
}};

constexpr std::array<const PolicyTable*, PolicyCount> Tables {&BasicTable, &OneToOneTable};
// clang-format on

} // namespace

Decision
evaluate(std::optional<Policy> policy, std::optional<member::Role> role, Action action, const Context& context)
{
    if (!policy || !role)
        return Decision::Unknown;

    const auto policyIndex = static_cast<std::size_t>(*policy);
    const auto roleIndex = static_cast<std::size_t>(*role);
    const auto actionIndex = static_cast<std::size_t>(action);
    if (policyIndex >= PolicyCount || roleIndex >= RoleCount || actionIndex >= ActionCount)
        return Decision::Unknown;

    const auto& cell = (*Tables[policyIndex])[roleIndex][actionIndex];
    const auto rule = cell.rule;
    if (rule == Rule::Deny)
        return Decision::Denied;

    if (cell.condition == Condition::NotAdminInvitesOnly) {
        if (!context.mode)
            return Decision::Unknown;
        if (*context.mode == conversation::Mode::ADMIN_INVITES_ONLY)
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

std::optional<Policy>
policyFor(const conversation::Info& conversation)
{
    switch (conversation.mode) {
    case conversation::Mode::ONE_TO_ONE:
        return Policy::OneToOne;
    case conversation::Mode::ADMIN_INVITES_ONLY:
    case conversation::Mode::INVITES_ONLY:
    case conversation::Mode::PUBLIC:
        return Policy::Basic;
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
evaluateFor(const conversation::Info& conversation, const QString& selfUri, Action action, Context context)
{
    const auto policy = policyFor(conversation);
    if (!policy)
        return std::nullopt;
    if (!context.mode)
        context.mode = conversation.mode;
    return evaluate(policy, roleOf(conversation, selfUri), action, context);
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
