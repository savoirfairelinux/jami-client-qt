# Name

Client State Sync Investigation

## Purpose

Debug stale or incorrect state propagation inside the client-facing side of Jami.

## When To Use

- account switch issues
- selected-conversation issues
- current call/conversation state mismatches
- message list not updating correctly

## When Not To Use

- Pure layout/styling issues.

## Required First Reads

- `src/app/lrcinstance.cpp`
- `src/app/currentconversation.cpp`
- `src/app/currentcall.cpp`
- `src/app/messagesadapter.cpp` or `src/app/calladapter.cpp`
- relevant `src/libclient/*model.cpp`
- `src/libclient/callbackshandler.cpp`

## Navigation Heuristics

- Look for `currentAccountIdChanged`, `selectedConvUidChanged`, and related rebinding points.
- Confirm whether source models are swapped or recomputed at the right time.

## Investigation Strategy

1. Identify the stale property or model.
2. Find the signal that should refresh it.
3. Verify the signal reaches the owner.
4. Verify the owner recomputes or rebinds correctly.

## Output Format

- stale state name
- expected trigger path
- broken hop
- proposed fix and validation

## Success Criteria

- The fix restores synchronization without introducing duplicate local state.

## Risks / Pitfalls

- fixing only one account/conversation transition

## Escalation Rules

- Escalate if the source callback or wrapper data is incorrect before reaching the client owner.
