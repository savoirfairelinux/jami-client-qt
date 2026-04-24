# Name

Call UI Investigation

## Purpose

Debug or change Jami’s call-facing UI while respecting the client/daemon call seam.

## When To Use

- ongoing call pages, overlays, participant layout, call action bar, or call notification behavior.

## When Not To Use

- pure daemon-side call negotiation/runtime issues with correct client consumption.

## Required First Reads

- `src/app/mainview/components/OngoingCallPage.qml`
- `src/app/mainview/components/CallOverlay.qml`
- `src/app/calladapter.cpp`
- `src/app/currentcall.cpp`
- `src/app/currentconversation.cpp`
- `src/libclient/callmodel.cpp`

## Navigation Heuristics

- Identify whether the issue is in displayed state, user action routing, or notification side effects.

## Investigation Strategy

1. Identify the exact call UI symptom.
2. Trace to `CallAdapter`, `CurrentCall`, or `CurrentConversation`.
3. Confirm whether `CallModel` already has the wrong state.
4. Keep the fix on the client side only if upstream state is correct.

## Output Format

- call UI symptom
- state/action path
- owner and fix scope
- validation plan

## Success Criteria

- The call UI reflects real call state and action routing stays correct.

## Risks / Pitfalls

- ignoring multi-account current-call behavior

## Escalation Rules

- Escalate if `CallModel` or daemon call interfaces are the real owner of the defect.
