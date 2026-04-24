# Name

Daemon Runtime Investigation

## Purpose

Analyze lifecycle, initialization, and subsystem ownership issues inside the Jami daemon.

## When To Use

- startup/init problems
- runtime ownership questions
- subsystem interaction bugs involving `Manager`

## When Not To Use

- narrow UI-only or wrapper-only issues

## Required First Reads

- `daemon/bin/dbus/main.cpp`
- `daemon/src/jami.cpp`
- `daemon/src/manager.h`
- `daemon/src/manager.cpp`

## Navigation Heuristics

- Start from lifecycle entry points before diving into subsystem internals.
- Identify the specific subsystem touched during init or runtime handoff.

## Investigation Strategy

1. Identify the failing phase.
2. Trace from `libjami::init/start` or the relevant runtime call.
3. Identify the subsystem owner under `Manager`.
4. Check whether public contract behavior is also affected.

## Output Format

- failing phase
- owning lifecycle path
- subsystem owner
- risks and validation plan

## Success Criteria

- The runtime/lifecycle issue is tied to a concrete owner.

## Risks / Pitfalls

- treating all runtime problems as generic `Manager` bugs without narrowing the subsystem

## Escalation Rules

- Escalate if the defect crosses into client wrappers or startup/build wiring.
