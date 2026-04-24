# Validation Matrix

For non-trivial behavior changes, prefer a test-first loop when a close test surface exists: write or tighten the nearest failing test, implement the smallest fix, then rerun that same narrow test before widening validation.

Validation is not complete until the corresponding relevant tests all pass and the affected project build surface succeeds without errors. A green narrow test is necessary but not sufficient if the touched code no longer builds cleanly.

## UI-Only

- Prefer matching `tests/qml/src/` coverage when the target component or view already has a test.
- For UI behavior changes with an existing matching QML test, prefer updating that test first so it expresses the intended behavior before the QML edit.
- Validate navigation state and bound singleton/model properties.
- Re-check `ViewCoordinator` or `SettingsView` behavior if stack/selection changes are involved.

## Client Logic

- Run or extend `tests/unittests/` when the behavior lives in adapters, helpers, parsing, preview, API server, or similar logic.
- If a narrow unit test exists or can be added cheaply, make it fail first and use it as the primary edit loop.
- Re-check account/conversation/call rebinding when touching `LRCInstance`, current-state singletons, or adapters.

## Daemon Logic

- Prefer the narrowest relevant daemon unit or simulation test under `daemon/test/unitTest/`.
- For daemon behavior changes, prefer a targeted failing daemon test before implementation when the owner is clear and the test surface is already nearby.
- Re-check the specific interface method path from `daemon/src/client/*.cpp` into runtime ownership.

## Cross-Boundary Behavior

- Validate both the producer and the consumer.
- If only one side has a practical nearby test to start from, use that side first, then add the narrowest consumer or producer validation needed after the implementation lands.
- Ensure DBus and libwrap paths stay aligned if the touched surface is in `src/libclient/dbus/`, `src/libclient/qtwrapper/`, or public libjami contracts.
- Re-run a client-level test or workflow touching the consumer path when the daemon contract changed.

## Build / Tooling

- Validate the narrowest affected build surface first.
- If top-level CMake changed, also inspect whether daemon CMake/Meson or test wiring is affected.
- Do not treat validation as complete if the relevant tests pass but the touched target or affected project build still fails.

## Tests-Only

- Confirm the targeted tests still exercise the real owning path instead of only mocks or view fixtures.

## Refactor

- Refactor-only claims are weak in this repository if wrappers, callbacks, or build flags move.
- Treat refactors touching hotspots or boundaries as needing regression review.
