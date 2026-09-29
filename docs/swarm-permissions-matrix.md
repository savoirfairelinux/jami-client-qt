# Swarm permission matrix

This documents the client-side permission policy for swarm conversations. It
describes what the client should offer; the daemon remains authoritative and
validates operations independently.

## Profiles

| Profile | Conversation modes |
| --- | --- |
| Basic | `INVITES_ONLY` |
| One-to-one | `ONE_TO_ONE` |
| None | `NON_SWARM` conversations do not use this policy |

This table lists modes in current client use, not every mode the daemon
recognizes.

## Intended policy

The matrices below show the intended policy. For both profiles and active roles,
messages may only be edited or deleted by the participant who authored them.

## Action definitions

| Action | Definition |
| --- | --- |
| Send file | Share a file in the conversation so its participants can receive it. |
| Send text | Send a new text message to the conversation. |
| Reply | Send a message as a reply to an existing conversation message. |
| React | Add a reaction to a conversation message. |
| Call | Initiate an audio or video call associated with the conversation. |
| Edit message | Change the content of an existing conversation message. |
| Delete message | Remove an existing message from the conversation. |
| Add member | Invite or re-add a participant. In one-to-one conversations, only the original peer may rejoin; a third participant cannot be added. |
| Change conversation profile | Update the shared profile of a group swarm, such as its title, description, or avatar in `profile.vcf`. This does not cover a participant’s personal Jami profile or the Qt client’s one-to-one peer contact profile. |
| Ban or unban member | Block a participant from the conversation, or lift that block. |

The matrix shows who may perform each action. Message authorship,
conversation-mode, and rejoining restrictions are included in the relevant
cells.

### Basic group conversations

| Action | Admin | Member |
| --- | --- | --- |
| Send file | Allow | Allow |
| Send text | Allow | Allow |
| Reply | Allow | Allow |
| React | Allow | Allow |
| Call | Allow | Allow |
| Edit message | Actor-authored only | Actor-authored only |
| Delete message | Actor-authored only | Actor-authored only |
| Add member | Allow | Allow when the conversation mode is known |
| Change conversation profile | Allow | Allow |
| Ban or unban member | Allow | Deny |

### One-to-one conversations

| Action | Admin | Member |
| --- | --- | --- |
| Send file | Allow | Allow |
| Send text | Allow | Allow |
| Reply | Allow | Allow |
| React | Allow | Allow |
| Call | Allow | Allow |
| Edit message | Actor-authored only | Actor-authored only |
| Delete message | Actor-authored only | Actor-authored only |
| Add member | Re-add original peer only | Re-add original peer only |
| Change conversation profile | Deny | Deny |
| Ban or unban member | Deny | Deny |

## Restricted member states

These rules apply in both profiles:

| Role | All actions |
| --- | --- |
| `INVITED` | Denied |
| `BANNED` | Denied |
| `LEFT` | Denied |

## Current daemon capability limits

The default client capability settings match the daemon support represented by
the current implementation. Only this matrix entry is narrower today:

| Profile and role | Action | Intended policy | Effective with current capabilities |
| --- | --- | --- | --- |
| Basic member | Change conversation profile | Allow | Deny |

This limit corresponds to `memberConversationProfileUpdate`. When support
changes, update the capability settings; the intended policy above remains
unchanged.

## Missing context

The client returns `Unknown` when it cannot determine a profile or role, or
when a required condition is missing (for example, whether the actor authored
the targeted message, the conversation mode for a member adding someone,
or whether a one-to-one target can rejoin).
Callers must treat `Unknown` as not allowed. For a Basic member adding someone,
the known mode is required; the currently used `INVITES_ONLY` mode allows it.

## UI wiring

`ConversationModel::isActionPermitted()` and `isActionPermittedForMessage()`
evaluate the policy for the local account. When the policy does not apply
(non-swarm conversations), they keep the previous behaviour. Denied actions
are hidden in the UI, and the adapters also refuse them and log a warning.

| Action | QML | Adapter guard |
| --- | --- | --- |
| Send text / Send file | `CurrentConversation.canSendText` / `canSendFile`: chat footer, attach and recorded-message buttons, file drop and paste | `MessagesAdapter::sendMessage*`, `sendFile*` |
| Reply | `canReply`: reply button, double click, context menu | `MessagesAdapter::sendMessage*` when `replyToId` is set |
| React | `canReact`: quick reactions, emoji picker, reaction removal | `MessagesAdapter::addEmojiReaction`, `removeReaction` |
| Call | `canCall` in the header; `ConversationsAdapter.canCall()` in the conversation list menu | `CallAdapter::startCall`, `startAudioOnlyCall` |
| Edit / Delete message | `CurrentConversation.canEditMessage()` / `canDeleteMessage()`: message menus, up-arrow edit | `MessagesAdapter::editMessage` (an empty body deletes) |
| Add member | `canAddMember`: invite buttons | `ContactAdapter::contactSelected`, `MessagesAdapter::addConversationMember` |
| Change conversation profile | `canChangeConversationProfile`: title, description, avatar in the details panel | `ConversationModel::isProfileUpdatePermitted()` in the title, description and avatar setters |
| Ban or unban member | `canBanUnbanMember`: participant menu | `MessagesAdapter::removeConversationMember`, and `addConversationMember` for a banned target |

One-to-one title and avatar edits only override the local contact profile, so
they are not gated by `ChangeConversationProfile`.

## Decision history

### 2026-09-27 — Establish the client-side policy matrix

The matrix records what the client should offer for each role and action; the
daemon remains authoritative for validating operations.

### 2026-09-29 — Enforce policy at both UI and adapter layers

The UI hides or disables denied actions, and adapters reject them as well. This
keeps alternate UI entry points from bypassing the presentation-level guards.

### 2026-09-29 — List only modes in current use

The matrix focuses on modes currently used by the client. Omitting less-used
daemon modes from the document does not remove their handling from the code.

### 2026-09-29 — Remove the client-side `Read` action

The earlier policy allowed banned members to read only pre-ban content, but no
production caller applied that rule. The daemon blocks future syncing with
banned peers; the client does not filter history already stored locally.

## Source

- Policy and capability evaluation: [`src/core/swarmpermissions.cpp`](../src/core/swarmpermissions.cpp)
- Public types and current capability defaults: [`src/core/api/swarmpermissions.h`](../src/core/api/swarmpermissions.h)
- Member roles: [`src/core/api/member.h`](../src/core/api/member.h)
- Unit tests: [`tests/unittests/swarmpermissions_unittest.cpp`](../tests/unittests/swarmpermissions_unittest.cpp)
