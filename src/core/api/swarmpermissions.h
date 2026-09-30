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
#pragma once

#include "conversation.h"
#include "member.h"

#include <optional>

/**
 * Client-side permission policy for swarm conversations.
 *
 * This decides what the UI offers; the daemon remains the authority and
 * validates every commit on its own.
 *
 * To support a new kind of swarm, add a Policy value, its table in
 * swarmpermissions.cpp, and its mapping in policyFor().
 */
namespace lrc {
namespace api {
namespace permissions {

enum class Action {
    SendFile,
    SendText,
    ReplyText,
    ReplyFile,
    React,
    Call,
    EditMessage,
    DeleteMessage,
    AddMember,
    ChangeConversationProfile,
    BanUnbanMember,
    CreateCollaborativeDocument,
    ViewMemberList,
    COUNT__
};

enum class Policy { Basic, OneToOne, Feed, COUNT__ };

enum class Rule {
    Deny,
    Allow,
    // Message actions: only when the actor authored the message.
    AllowIfActorIsAuthor
};

// Unknown means the information needed to decide is missing; callers must
// treat it like Denied.
enum class Decision { Allowed, Denied, Unknown };

struct Context
{
    // For message actions: whether the actor wrote the targeted message.
    std::optional<bool> actorIsAuthor;
    // Needed for rules that depend on how invitations are restricted.
    std::optional<conversation::Mode> mode;
    // For one-to-one AddMember: whether the original peer can rejoin.
    std::optional<bool> targetCanRejoin;
};

Decision evaluate(std::optional<Policy> policy,
                  std::optional<member::Role> role,
                  Action action,
                  const Context& context = {});

constexpr bool
isAllowed(Decision decision)
{
    return decision == Decision::Allowed;
}

// Non-swarm conversations have no permission policy.
std::optional<Policy> policyFor(const conversation::Info& conversation);

std::optional<member::Role> roleOf(const conversation::Info& conversation, const QString& uri);

// Evaluates an action for selfUri in the conversation, filling the mode from
// the conversation. Returns nullopt when the policy does not apply (non-swarm),
// so callers keep their legacy behaviour.
std::optional<Decision> evaluateFor(const conversation::Info& conversation,
                                    const QString& selfUri,
                                    Action action,
                                    Context context = {});

// One-to-one only: the target is the original peer and has left.
bool targetCanRejoin(const conversation::Info& conversation, const QString& targetUri);

// Whether selfUri wrote the message; nullopt if the message is not loaded.
std::optional<bool> isMessageAuthoredBy(const conversation::Info& conversation,
                                        const QString& messageId,
                                        const QString& selfUri);

} // namespace permissions
} // namespace api
} // namespace lrc
