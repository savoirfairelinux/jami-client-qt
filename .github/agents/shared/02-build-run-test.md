# Build, Run, Test

## Client Build

Confirmed from the root `CMakeLists.txt`:

- The top-level project builds the Qt client application and, by default, adds the embedded daemon submodule with `add_subdirectory(${DAEMON_DIR} EXCLUDE_FROM_ALL)` when `JAMICORE_AS_SUBDIR` is enabled.
- `src/libclient` is added as a subdirectory before the main app target is assembled.
- Qt 6.8 or higher is required.
- `ENABLE_LIBWRAP` is forced on for non-Linux, for tests, and when explicitly enabled.

Important client build options:

- `WITH_DAEMON_SUBMODULE`
- `JAMICORE_AS_SUBDIR`
- `WITH_WEBENGINE`
- `ENABLE_LIBWRAP`
- `ENABLE_CRASHREPORTS`
- `BUILD_TESTING`

Workspace tasks already defined here:

- `cmake-configure`
- `cmake-configure-tests`
- `cmake-build`
- `run-tests`

Verified local desktop workflow in this repository:

- `cmake-configure` configures `build/` with `-DCMAKE_BUILD_TYPE=Debug`.
- `cmake-build` reuses that directory and produces a Debug `build/jami` binary.
- A minimal runtime smoke test on Linux is `QT_QPA_PLATFORM=offscreen ./build/jami --debug`.
- `build/jami` from that flow contains debug info and is not stripped.

## Client Runtime Entry

- `src/app/main.cpp` is the desktop client entry point.
- `MainApplication::init()` loads `DaemonReconnectWindow.qml` on Unix when DBus connectivity is unavailable.
- In normal startup, `MainApplication::initQmlLayer()` loads `qrc:/MainApplicationWindow.qml`.

## Client Tests

Confirmed from `tests/CMakeLists.txt` and root `CMakeLists.txt`:

- Client tests are only added when `BUILD_TESTING` is enabled.
- There are two main client test executables:
  - `Qml_Tests`
  - `Unit_Tests`
- `Qml_Tests` runs QML component/screen tests from `tests/qml/src`.
- `Unit_Tests` covers selected app logic such as account handling, contacts, conversation switch, message parser, preview engine, API token manager, and API server.
- Tests are configured with `QT_QPA_PLATFORM=offscreen`.

## Daemon Build

Confirmed from `daemon/CMakeLists.txt` and `daemon/src/meson.build`:

- The daemon can be built with CMake in the top-level build and also has Meson build descriptions under `daemon/src/meson.build` and `daemon/test/meson.build`.
- Core daemon/library options include:
  - `JAMI_PLUGIN`
  - `JAMI_DBUS`
  - `JAMI_VIDEO`
  - `JAMI_VIDEO_ACCEL`
  - `BUILD_CONTRIB`
  - `BUILD_TESTING`
- The CMake build creates the core library target and, when DBus is enabled, the `jamid` executable under `daemon/bin/dbus/`.

## Daemon Runtime Entry

- `daemon/bin/dbus/main.cpp` is the DBus service executable entry point.
- It calls `libjami::init()`, registers DBus managers, calls `libjami::start()`, then enters the DBus event loop.

## Daemon Tests

Confirmed from `daemon/CMakeLists.txt` and `daemon/test/meson.build`:

- Daemon tests are enabled under `BUILD_TESTING`.
- There is broad unit coverage in `daemon/test/unitTest/` including account, call, conference, conversation, file transfer, media, ICE, namedirectory, presence, plugin, and simulation-oriented flows.
- `dst_library` is built for deterministic simulation testing.

## Practical Pain Points

- Build and runtime behavior differ depending on whether the client is using DBus wrappers or libwrap/native wrappers. This matters whenever `src/libclient/dbus/` and `src/libclient/qtwrapper/` must stay aligned.
- The repository contains both client and daemon build systems, so a change may need validation in more than one place even when only one top-level command is used in daily work.
- `BUILD_TESTING` influences both client and daemon behavior. Client tests compile with `BUILD_TESTING="ON"`, and daemon tests add `LIBJAMI_TEST` in the daemon CMake build.
- Packaging and CI surfaces in `extras/` explicitly toggle `BUILD_TESTING` off for release packaging, so test-only assumptions should not leak into production code.
- A locally advanced `daemon/` submodule can break the root build before the client compiles, even when the root checkout itself is correct. If the checked-out daemon commit differs from the gitlink pinned by the superproject, resync with `git submodule update --init --recursive daemon` before treating the failure as a CMake or dependency issue.

## To Confirm

- Exact local run workflows beyond the code-inspected entry points can vary by environment and packaging mode.
