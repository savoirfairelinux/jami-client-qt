# Swarm permission matrix

This documents the client-side permission policy for swarm conversations. It
describes what the client should offer; the daemon remains authoritative and
validates operations independently.

## Profiles

| Profile | Conversation modes |
| --- | --- |
| Basic | `ADMIN_INVITES_ONLY`, `INVITES_ONLY`, `PUBLIC` |
| One-to-one | `ONE_TO_ONE` |
| None | `NON_SWARM` conversations do not use this policy |

## Intended policy

The matrices below show the intended policy. For both profiles and active roles,
messages may only be edited or deleted by the participant who authored them.

## Action definitions

| Action | Definition |
| --- | --- |
| Send file | Share a file in the conversation so its participants can receive it. |
| Send text | Send a new text message to the conversation. |
| Read | View conversation content. This does not authorize sending messages or generating read receipts; for banned members, it is limited to content that existed before the ban. |
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
| Read | Allow | Allow |
| Reply | Allow | Allow |
| React | Allow | Allow |
| Call | Allow | Allow |
| Edit message | Actor-authored only | Actor-authored only |
| Delete message | Actor-authored only | Actor-authored only |
| Add member | Allow | Allow except in `ADMIN_INVITES_ONLY` mode |
| Change conversation profile | Allow | Allow |
| Ban or unban member | Allow | Deny |

### One-to-one conversations

| Action | Admin | Member |
| --- | --- | --- |
| Send file | Allow | Allow |
| Send text | Allow | Allow |
| Read | Allow | Allow |
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

| Role | Read | All other actions |
| --- | --- | --- |
| `INVITED` | Denied | Denied |
| `BANNED` | Allowed only for content that existed before the ban | Denied |
| `LEFT` | Denied | Denied |

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
the targeted message, the conversation mode for a member adding someone, or
whether content existed before a ban, or whether a one-to-one target can
rejoin).
Callers must treat `Unknown` as not allowed. For a Basic member adding someone,
the known mode is required: `ADMIN_INVITES_ONLY` denies the action, while
`INVITES_ONLY` and `PUBLIC` allow it.

## Source

- Policy and capability evaluation: [`src/core/swarmpermissions.cpp`](../src/core/swarmpermissions.cpp)
- Public types and current capability defaults: [`src/core/api/swarmpermissions.h`](../src/core/api/swarmpermissions.h)
- Member roles: [`src/core/api/member.h`](../src/core/api/member.h)
- Unit tests: [`tests/unittests/swarmpermissions_unittest.cpp`](../tests/unittests/swarmpermissions_unittest.cpp)
