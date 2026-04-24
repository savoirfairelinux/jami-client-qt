# Repository Map

## Top-Level Practical Map

- `src/app/`: Qt application entry points, app services, adapters, state singletons, and QML resources.
- `src/libclient/`: Qt/libclient layer over libjami and DBus/libwrap interfaces. This is the main client/daemon seam.
- `src/version_info/`: generated/build metadata support.
- `tests/`: client-side QML and unit tests.
- `daemon/src/`: libjami and daemon runtime implementation.
- `daemon/bin/dbus/`: DBus service executable and DBus manager wrappers.
- `daemon/test/`: daemon unit, simulation, and support tests.
- `extras/`: CI, packaging, scripts, and build helpers.
- `resources/`, `share/`, `translations/`: packaged assets and localization.
- `3rdparty/`: vendored dependencies used by the client build.

## Actionable Drill-Down

### `src/app/`

- `main.cpp`: process startup, graphics mode, instance management, `MainApplication` creation.
- `mainapplication.cpp`: service initialization, `LRCInstance` setup, QML engine loading, tray/API server setup.
- `qmlregister.cpp`: QML-facing registration map for adapters, models, current-state objects, and image providers.
- `lrcinstance.cpp`: app-level wrapper around `lrc::api::Lrc`; central account/conversation/call access point.
- `mainview/`: primary application screens such as conversation, side panel, call UI, and welcome state.
- `settingsview/`: settings shell and pages.
- `wizardview/`: onboarding and account creation/import flow.
- `*adapter.cpp`: bridge between QML calls and model/service calls.
- `currentaccount.cpp`, `currentconversation.cpp`, `currentcall.cpp`: UI-facing state aggregates.

### `src/libclient/`

- `lrc.cpp`: main libclient entry point aggregating models and instance manager initialization.
- `callbackshandler.cpp`: callback fan-in from daemon-facing interfaces into Qt signals.
- `accountmodel.cpp`, `conversationmodel.cpp`, `callmodel.cpp`, `contactmodel.cpp`, `datatransfermodel.cpp`, `avmodel.cpp`, `pluginmodel.cpp`: main client-side models over daemon behavior.
- `dbus/`: DBus interface wrappers and connection validity handling.
- `qtwrapper/`: direct libjami/libwrap path for non-DBus/native embedding mode.
- `authority/`: thin authority-layer calls into daemon-facing configuration methods.

### `daemon/src/`

- `jami.cpp`: libjami lifecycle entry points.
- `manager.cpp`, `manager.h`: daemon control hub and runtime state manager.
- `client/`: concrete client-facing interface implementations.
- `jami/`: public libjami interface headers and constants.
- `jamidht/`: Jami account, conversation, sync, DHT, swarm, and related modules.
- `sip/`: SIP account/call/transport implementation.
- `media/`: audio/video/media pipeline.
- `plugin/`: plugin engine and service managers.
- `im/`: messaging helpers.

### `tests/`

- `qml/`: QML component and screen tests.
- `unittests/`: app/helper/unit tests for client-side logic.

### `daemon/test/`

- `unitTest/`: daemon unit coverage across call, account, conversation, media, presence, plugin, and simulation domains.
- `dst/`: deterministic simulation support.

## Recommended Reading Order For Agents

General:

1. root `CMakeLists.txt`
2. `src/app/main.cpp`
3. `src/app/mainapplication.cpp`
4. `src/app/qmlregister.cpp`
5. `src/app/lrcinstance.cpp`
6. `src/libclient/lrc.cpp`
7. `src/libclient/callbackshandler.cpp`
8. matching domain model in `src/libclient/`
9. matching daemon interface in `daemon/src/jami/`
10. matching daemon implementation in `daemon/src/client/` and runtime module

For UI change:

1. `src/app/MainApplicationWindow.qml`
2. `src/app/mainview/MainView.qml`
3. `src/app/ViewCoordinator.qml`
4. target QML component
5. relevant adapter/state singleton

For call/message/account bug:

1. relevant `src/app/*adapter.cpp`
2. `src/app/lrcinstance.cpp`
3. relevant `src/libclient/*model.cpp`
4. `src/libclient/callbackshandler.cpp`
5. relevant `daemon/src/jami/*.h`
6. relevant `daemon/src/client/*.cpp`
7. relevant daemon runtime module

For build/test issue:

1. root `CMakeLists.txt`
2. `src/libclient/CMakeLists.txt`
3. `tests/CMakeLists.txt`
4. `daemon/CMakeLists.txt`
5. `daemon/src/meson.build`
6. `daemon/test/meson.build`
7. `extras/scripts/install.sh` or relevant CI/packaging file
