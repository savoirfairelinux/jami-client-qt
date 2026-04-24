# Name

Client Bugfix Triage

## Purpose

Localize a Jami client bug to the correct app-side owner before editing.

## When To Use

- Bugs in app logic, current-state aggregation, navigation, message/call UI behavior, or settings behavior.

## When Not To Use

- When the bug is already proven to originate in daemon runtime ownership.

## Required First Reads

- failing view or adapter
- `src/app/lrcinstance.cpp`
- relevant `src/app/current*.cpp`
- relevant `src/libclient/*model.cpp`

## Navigation Heuristics

- Trace from visible symptom to current-state singleton or adapter.
- Verify whether the underlying model state is already wrong.

## Investigation Strategy

1. Reproduce the visible symptom in code terms.
2. Check adapter/current-state logic.
3. Check the nearest libclient model.
4. Reclassify as shared/daemon if the source state is wrong upstream.

## Output Format

- likely owner
- confirmed trace
- smallest safe fix area
- validation plan

## Success Criteria

- The fix target is the true app-side owner, not a symptom-only layer.

## Risks / Pitfalls

- patching around stale upstream state

## Escalation Rules

- Escalate when `src/libclient/callbackshandler.cpp`, wrappers, or daemon interfaces appear in the failing path.
