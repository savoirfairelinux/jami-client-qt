# Name

Conversation UI Change

## Purpose

Modify the conversation/message experience without losing track of Jami’s conversation state owners.

## When To Use

- chat view, message list, composer, conversation header, participant-side panels, and related UI changes.

## When Not To Use

- daemon conversation sync or message delivery issues with no client consumption problem.

## Required First Reads

- `src/app/mainview/ConversationView.qml`
- `src/app/mainview/components/ChatView.qml`
- `src/app/mainview/components/MessageListView.qml`
- `src/app/messagesadapter.cpp`
- `src/app/currentconversation.cpp`
- `src/libclient/conversationmodel.cpp`

## Navigation Heuristics

- Separate rendering changes from message-state changes.
- Check whether `MessagesAdapter` or `CurrentConversation` is the real owner of the behavior.

## Investigation Strategy

1. Identify the target conversation component.
2. Identify bound state and adapter actions.
3. Confirm whether the behavior is UI-only or model-driven.
4. Edit at the smallest useful layer.

## Output Format

- target conversation UI area
- bound state path
- change plan
- validation plan

## Success Criteria

- Conversation behavior remains aligned with selected conversation and message model state.

## Risks / Pitfalls

- breaking message-list updates on conversation switch

## Escalation Rules

- Escalate when the change needs new conversation model behavior or daemon message semantics.
