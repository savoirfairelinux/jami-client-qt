# Orchestration Set

This set exists to stop future agents from guessing task ownership too early. In `jami-client-qt`, a visible symptom in QML can still be caused by `src/libclient` synchronization or by daemon behavior exposed through libjami/DBus, so routing matters.

## Scope

- Initial task routing.
- Boundary-first classification when ownership is unclear.
- Handoff format between specialists.
- Review expectations across `client`, `daemon`, `shared`, and build/test surfaces.

## Non-Scope

- Detailed implementation guidance for QML/client code. Use `client`.
- Detailed implementation guidance for daemon runtime changes. Use `daemon`.
- Repository facts, runtime flows, or boundary mechanics beyond what routing needs. Use `shared`.

## Relations

- Use `shared` when the route depends on the actual client/daemon seam.
- Route to `client` for UI/app-only issues after the boundary check says the contract is stable.
- Route to `daemon` for libjami/runtime behavior after the boundary check says the client is consuming a stable contract.

## Reading Order

1. `task-classification.md`
2. `routing-rules.md`
3. `handoff-protocol.md`
4. `review-matrix.md`
5. `agents/task-router.md`

## Escalation Rule

If a task touches any of the following, treat it as cross-boundary until proven otherwise:

- `src/libclient/dbus/`
- `src/libclient/qtwrapper/`
- `src/libclient/callbackshandler.cpp`
- `daemon/src/jami/*.h`
- `daemon/src/client/*.cpp`
- build flags like `ENABLE_LIBWRAP`, `JAMI_DBUS`, `WITH_DAEMON_SUBMODULE`, `BUILD_TESTING`
