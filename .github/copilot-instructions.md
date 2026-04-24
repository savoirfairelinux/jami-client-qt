# Jami Repository Instructions

- Treat this repository as a multi-layer system, not a single Qt app: `src/app` is the desktop QML/application shell, `src/libclient` is the client/service and boundary layer, and `daemon/src` is the libjami/daemon runtime.
- Start from ownership, not from the visible symptom. A UI symptom can still be caused by `src/libclient` or `daemon/src`.
- First read `.github/agents/README.md`. Read `.github/agents/orchestration/task-classification.md` and assign a classification (`CLIENT_ONLY`, `DAEMON_ONLY`, `CROSS_CUTTING`, or `UNCERTAIN_REQUIRES_BOUNDARY_CHECK`) before modifying any file. If ownership is unclear, read `.github/agents/shared/03-client-daemon-boundaries.md` before editing.
- For client work, use `.github/agents/client/00-client-architecture.md`, `01-ui-qml-map.md`, and `02-client-runtime-flows.md` as the default first reads.
- For daemon work, use `.github/agents/daemon/00-daemon-architecture.md`, `01-daemon-runtime-flows.md`, and `03-daemon-change-playbook.md` as the default first reads.
- Boundary-critical files are `src/app/lrcinstance.cpp`, `src/libclient/lrc.cpp`, `src/libclient/callbackshandler.cpp`, `src/libclient/dbus/`, `src/libclient/qtwrapper/`, `daemon/src/jami/*.h`, and `daemon/src/client/*.cpp`.
- Client startup hubs are `src/app/main.cpp`, `src/app/mainapplication.cpp`, `src/app/qmlregister.cpp`, `src/app/MainApplicationWindow.qml`, and `src/app/mainview/MainView.qml`.
- Daemon runtime hubs are `daemon/bin/dbus/main.cpp`, `daemon/src/jami.cpp`, `daemon/src/manager.cpp`, `daemon/src/client/configurationmanager.cpp`, `daemon/src/client/callmanager.cpp`, and `daemon/src/client/conversation_interface.cpp`.
- When changing daemon-facing contracts or callbacks, inspect both `src/libclient/dbus/` and `src/libclient/qtwrapper/`. Do not update only one path unless the affected flow is proven to use only that mode. Any new signal wired in `src/libclient/callbackshandler.cpp` requires a matching declaration in both transport paths.
- The top-level build usually includes the embedded daemon via `WITH_DAEMON_SUBMODULE` and `JAMICORE_AS_SUBDIR`. `src/libclient` is added before the app target is assembled.
- Qt 6.8 or newer is required by the root build. `BUILD_TESTING` affects both client and daemon test surfaces.
- Client tests live in `tests/qml/` and `tests/unittests/`. Daemon tests live in `daemon/test/`.
- In local VS Code workflows, prefer the existing tasks `cmake-configure`, `cmake-configure-tests`, `cmake-build`, and `run-tests`. If those are unavailable, inspect `CMakeLists.txt`, `tests/CMakeLists.txt`, `daemon/CMakeLists.txt`, and `daemon/test/meson.build` before inventing a build or test command.
- Trust `.github/agents/` as the repository map and only widen search when those docs are incomplete or contradicted by the code you are touching.
- Keep `.github/agents/`, `.github/instructions/`, and nearby `AGENTS.md` files in sync with meaningful code changes and verified repository discoveries. Prefer small, code-grounded doc updates that capture durable new facts instead of leaving that learning implicit.