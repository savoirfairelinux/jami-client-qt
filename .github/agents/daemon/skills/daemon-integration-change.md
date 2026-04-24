# Name

Daemon Integration Change

## Purpose

Safely change daemon interfaces that are consumed by the client.

## When To Use

- public libjami method changes
- callback or signal behavior changes
- client-facing interface implementation changes with wrapper impact

## When Not To Use

- daemon-internal refactors with no contract or callback impact

## Required First Reads

- relevant header in `daemon/src/jami/`
- relevant implementation in `daemon/src/client/`
- `src/libclient/dbus/` wrapper
- `src/libclient/qtwrapper/` wrapper
- `src/libclient/callbackshandler.cpp`

## Navigation Heuristics

- Treat DBus and libwrap as co-equal consumers.
- Check callback paths as carefully as direct method calls.

## Investigation Strategy

1. Identify the contract or callback being changed.
2. List all client wrappers and consumers.
3. Make the minimum coherent producer+consumer changes.
4. Define both daemon and client validation.

## Output Format

- changed contract/callback
- affected wrappers and consumers
- coordinated edit scope
- validation plan

## Success Criteria

- The integration change is coherent across producer, wrappers, and client consumers.

## Risks / Pitfalls

- updating only one wrapper mode
- forgetting callback fan-in consumers

## Escalation Rules

- Always escalate to cross-layer review.
