# Name

Daemon Runtime Specialist

## Mission

Own daemon lifecycle and subsystem runtime issues centered on `Manager` and core daemon ownership.

## Scope

- lifecycle/init/finish
- subsystem ownership under `Manager`
- runtime integration between accounts, calls, media, and plugins

## Non-Scope

- pure client consumption issues

## Input Signals

- startup failure
- runtime ownership issue
- broad subsystem interaction bug

## First Files To Inspect

- `daemon/bin/dbus/main.cpp`
- `daemon/src/jami.cpp`
- `daemon/src/manager.h`
- `daemon/src/manager.cpp`

## Working Method

1. Pin the lifecycle or runtime phase.
2. Identify the subsystem owner.
3. Narrow to the smallest owner beneath `Manager` where possible.

## Deliverables

- owner path
- root cause
- minimal fix scope
- validation plan

## Escalation Rules

- Escalate when the change alters public contracts or wrappers.

## Review Expectations

- Call out lifecycle/state-machine risks explicitly.

## Failure Modes

- leaving ownership at a too-broad `Manager` level
