# Client Set

This set covers the Qt/QML application layer and the app-facing side of libclient consumption.

## Scope

- QML views and navigation.
- `src/app` adapters, state singletons, app services, and helpers.
- Client-side use of `src/libclient` models.
- Client-focused validation and review practices.

## Non-Scope

- Daemon runtime ownership, network/protocol behavior, or libjami internals. Use `daemon`.
- Boundary/routing rules. Use `shared` and `orchestration`.

## Relations

- Use `shared/03-client-daemon-boundaries.md` before assuming a UI symptom is client-owned.
- Escalate to `daemon` when the source state or contract is wrong before it reaches the client.

## Reading Order

1. `00-client-architecture.md`
2. `01-ui-qml-map.md`
3. `02-client-runtime-flows.md`
4. `03-client-hotspots.md`
5. `04-client-change-playbook.md`
6. `05-client-testing.md`
