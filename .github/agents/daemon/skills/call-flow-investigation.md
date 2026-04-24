# Name

Call Flow Investigation

## Purpose

Investigate daemon-side call, conference, and related media-control behavior.

## When To Use

- outgoing/incoming call bugs
- hold/resume issues
- conference problems
- call action semantics exposed to clients

## When Not To Use

- purely client-side call UI issues with correct upstream call state

## Required First Reads

- `daemon/src/client/callmanager.cpp`
- `daemon/src/jami/callmanager_interface.h`
- `daemon/src/manager.cpp`
- `daemon/src/call.cpp`
- `daemon/src/sip/sipcall.cpp`
- `daemon/src/conference.cpp`

## Navigation Heuristics

- Start from the public call method or event.
- Determine whether the owner is `Manager`, `Call`, `SIPCall`, or `Conference`.

## Investigation Strategy

1. Identify the exact call operation or state transition.
2. Trace into the runtime owner.
3. Check neighboring conference/media behavior.
4. Review client-facing implications.

## Output Format

- call path
- runtime owner
- state-machine risk
- validation plan

## Success Criteria

- The fix addresses the actual call/conference owner.

## Risks / Pitfalls

- changing call behavior without checking conference side effects

## Escalation Rules

- Escalate when client wrappers, `CallModel`, or current-call assumptions must change too.
