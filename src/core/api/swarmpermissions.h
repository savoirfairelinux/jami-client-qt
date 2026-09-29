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
 * Client-side permissions for swarm conversations.
 *
 * This decides what the UI offers; the daemon remains the authority and
 * validates every commit on its own.
 *
 * A decision combines two layers:
 *  - the intended policy: a (SwarmProfile, Role, Action) matrix describing
 *    what the product wants, even where the daemon does not support it yet;
 *  - the backend capabilities: what the daemon currently accepts. A matrix
 *    cell that goes beyond today's daemon names the capability it needs and
 *    falls back to a narrower rule while that capability is missing.
 *
 * When the daemon gains a feature, flip the matching field in
 * Capabilities::current(); the matrix does not change. To support a new kind
 * of swarm, add a SwarmProfile value, its table in swarmpermissions.cpp, and
 * its mapping in profileFor().
 */
namespace lrc {
namespace api {
namespace permissions {

enum class Action {
    SendFile,
    SendText,
    Reply,
    React,
    Call,
    EditMessage,
    DeleteMessage,
    AddMember,
    ChangeConversationProfile,
    BanUnbanMember,
    COUNT__
};

enum class SwarmProfile { Basic, OneToOne, COUNT__ };

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

struct Capabilities
{
    bool memberConversationProfileUpdate = false;

    // What the daemon supports today.
    static constexpr Capabilities current()
    {
        return {};
    }
};

Decision evaluate(std::optional<SwarmProfile> profile,
                  std::optional<member::Role> role,
                  Action action,
                  const Context& context = {},
                  const Capabilities& capabilities = Capabilities::current());

constexpr bool
isAllowed(Decision decision)
{
    return decision == Decision::Allowed;
}

// No profile for non-swarm conversations: the policy does not apply to them.
std::optional<SwarmProfile> profileFor(const conversation::Info& conversation);

std::optional<member::Role> roleOf(const conversation::Info& conversation, const QString& uri);

// Evaluates an action for selfUri in the conversation, filling the mode from
// the conversation. Returns nullopt when the policy does not apply (non-swarm),
// so callers keep their legacy behaviour.
std::optional<Decision> evaluateFor(const conversation::Info& conversation,
                                    const QString& selfUri,
                                    Action action,
                                    Context context = {},
                                    const Capabilities& capabilities = Capabilities::current());

// One-to-one only: the target is the original peer and has left.
bool targetCanRejoin(const conversation::Info& conversation, const QString& targetUri);

// Whether selfUri wrote the message; nullopt if the message is not loaded.
std::optional<bool> isMessageAuthoredBy(const conversation::Info& conversation,
                                        const QString& messageId,
                                        const QString& selfUri);

} // namespace permissions
} // namespace api
} // namespace lrc
