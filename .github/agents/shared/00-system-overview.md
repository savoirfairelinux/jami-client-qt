# System Overview

## Confirmed From Code

- The top-level client build includes the daemon as a subdirectory by default when `WITH_DAEMON_SUBMODULE` and `JAMICORE_AS_SUBDIR` are enabled in the root `CMakeLists.txt`.
- Client startup begins in `src/app/main.cpp`, which constructs `MainApplication`, handles single-instance behavior, initializes graphics/WebEngine settings, and then calls `MainApplication::init()`.
- `MainApplication::init()` in `src/app/mainapplication.cpp` creates app services, initializes `LRCInstance`, and later loads `qrc:/MainApplicationWindow.qml` through `QQmlApplicationEngine`.
- `Utils::registerTypes()` in `src/app/qmlregister.cpp` registers the QML-facing adapters, singleton models, and current-state objects used by the UI.
- `LRCInstance` in `src/app/lrcinstance.cpp` wraps `lrc::api::Lrc`, exposes current-account/current-conversation state, and acts as the app-side bridge into the libclient layer.
- `lrc::api::Lrc` in `src/libclient/lrc.cpp` initializes `InstanceManager` before constructing account/call/conversation/plugin/AV models. This is the main client service/model aggregator.
- The daemon runtime is exposed through libjami entry points in `daemon/src/jami.cpp`, then delegated into `jami::Manager::instance().init(...)` and `finish()` in `daemon/src/manager.cpp`.
- The DBus daemon executable is started from `daemon/bin/dbus/main.cpp`, which calls `libjami::init()`, registers DBus managers, then calls `libjami::start()`.

## Responsibility Split

Client responsibilities:

- QML window/view hierarchy and navigation.
- App-level services such as settings, tray integration, crash reporting, preview generation, local API server, and device/UI helpers.
- QObject adapter layer that translates QML actions into model calls.
- Current-state singletons for account, conversation, and call state in the UI.

Daemon responsibilities:

- Core account lifecycle, SIP/Jami account implementations, call state machine, conference behavior, message/conversation handling, media pipeline, plugin engine, and transport/network logic.
- Client-facing C ABI/libjami contracts under `daemon/src/jami/`.
- Concrete interface implementations under `daemon/src/client/`.
- DBus service executable under `daemon/bin/dbus/`.

Shared reality inside this repository:

- The client consumes daemon behavior through `src/libclient`, not directly from QML.
- `src/libclient` is the seam where daemon-facing methods, callbacks, DBus wrappers, and libwrap wrappers are adapted into Qt models and signals.
- Many end-to-end bugs pass through `src/app`, `src/libclient`, and `daemon/src` even if only one layer shows the symptom.

## End-To-End Flows That Are Truly Cross-Layer

- Startup and daemon availability.
- Account creation, loading, switching, and registration state updates.
- Conversation/message load, send, search, typing status, and file transfer state.
- Call initiation, acceptance, hold/resume, conferencing, participant state, and media changes.
- Audio/video device enumeration and capture/render state.
- Plugin availability and plugin-managed handlers exposed to the client.

## Likely But Not Fully Exhaustive

- Platform-specific branches for mobile and some desktop variants are present in both client and daemon, but this first version focuses on the main Linux/desktop paths.

## To Confirm

- Some platform-specific initialization branches and plugin runtime details need task-specific deeper inspection before changing those areas.
