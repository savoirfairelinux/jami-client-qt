# Name

Conversation Message Flow

## Purpose

Investigate Jami conversation and message behavior on the daemon side.

## When To Use

- conversation lifecycle changes
- message send/load/edit/react behavior
- conversation member/preference/search behavior

## When Not To Use

- client-only rendering issues with correct conversation state

## Required First Reads

- `daemon/src/client/conversation_interface.cpp`
- `daemon/src/jami/conversation_interface.h`
- `daemon/src/jamidht/conversation_module.cpp`
- `daemon/src/jamidht/conversationrepository.cpp`
- `daemon/src/im/instant_messaging.cpp`

## Navigation Heuristics

- Separate public interface adaptation from conversation-module ownership.
- Check whether the flow is Jami conversation-specific or a SIP/account messaging path.

## Investigation Strategy

1. Identify the public operation or callback.
2. Trace into `ConversationModule` or messaging helper.
3. Check repository/persistence implications.
4. Confirm likely client consumers if public behavior changes.

## Output Format

- operation or event
- owner path
- persistence/sync implications
- validation plan

## Success Criteria

- The conversation/message owner is identified with the relevant persistence/sync impact.

## Risks / Pitfalls

- changing interface semantics without checking client `ConversationModel`/`MessagesAdapter`

## Escalation Rules

- Escalate for cross-layer review if conversation interface behavior or payload shape changes.
