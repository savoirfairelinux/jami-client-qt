# Review Matrix

## Same-Set Review Only

Use same-set review when:

- The change is clearly local to QML/app presentation with no wrapper/model changes.
- The change is clearly local to daemon internals with no contract or callback changes.
- The change only updates tests or docs within one set.

## Cross-Set Review

Require cross-set review when:

- `src/libclient/` and `daemon/src/` both change.
- Any libjami interface header in `daemon/src/jami/` changes.
- Callback registration, signal names, or payload conversion changes.
- A client adapter/state singleton change depends on daemon sequencing assumptions.

## Build / Tooling Review

Require build/tooling review when:

- root `CMakeLists.txt`, `src/libclient/CMakeLists.txt`, `tests/CMakeLists.txt`, `daemon/CMakeLists.txt`, or `daemon/src/meson.build` changes.
- Build flags such as `ENABLE_LIBWRAP`, `JAMI_DBUS`, `WITH_DAEMON_SUBMODULE`, `JAMICORE_AS_SUBDIR`, `BUILD_TESTING`, `JAMI_VIDEO`, or `JAMI_PLUGIN` change.
- Packaging or CI surfaces under `extras/ci/`, `extras/scripts/`, or `extras/packaging/` change.

## Boundary Review

Require boundary review when:

- `src/libclient/dbus/`, `src/libclient/qtwrapper/`, `src/libclient/callbackshandler.cpp`, or `src/libclient/lrc.cpp` changes.
- Daemon client-facing implementations in `daemon/src/client/` change.
- The task changes how state moves from daemon to client or from client to daemon.

## Test / Regression Review

Require test/regression review when:

- Runtime state machines, account switching, message lists, calls, transfers, device management, or plugin flows change.
- Existing test coverage exists but was not updated.
- The work touches hotspots listed in `shared/08-hotspots.md`.
