# Daemon Set

This set covers libjami, daemon runtime ownership, client-facing daemon interfaces, and daemon-specific testing/change guidance.

## Scope

- libjami lifecycle and `Manager` runtime ownership.
- account, call, conversation, media, plugin, and transport subsystems under `daemon/src/`.
- client-facing interface headers and implementations under `daemon/src/jami/` and `daemon/src/client/`.
- daemon test surfaces under `daemon/test/`.

## Non-Scope

- QML presentation and app-shell behavior. Use `client`.
- Routing/handoff policy. Use `orchestration`.
- generic boundary rules. Use `shared`.

## Relations

- Escalate to `shared` or `client` when a daemon change affects wrappers, callbacks, or client consumption assumptions.
- Read `shared/03-client-daemon-boundaries.md` before changing any public interface or callback behavior.

## Reading Order

1. `00-daemon-architecture.md`
2. `01-daemon-runtime-flows.md`
3. `02-daemon-hotspots.md`
4. `03-daemon-change-playbook.md`
5. `04-daemon-testing.md`
