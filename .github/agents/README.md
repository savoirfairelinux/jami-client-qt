# Jami Agent Knowledge Base

This knowledge base is a code-grounded starting point for AI agents working in the `jami-client-qt` repository. It was built from direct inspection of the client application under `src/app`, the client service/model layer under `src/libclient`, the embedded daemon under `daemon/src`, the build entry points in the root `CMakeLists.txt` and `daemon/CMakeLists.txt`, and the test surfaces under `tests/` and `daemon/test/`.

The repository is not only a Qt client. The top-level build includes the daemon as a subdirectory by default through `WITH_DAEMON_SUBMODULE` and `JAMICORE_AS_SUBDIR`, the client service layer depends on libjami interfaces from the daemon, and runtime behavior can cross `QML -> src/app adapters -> src/libclient models/wrappers -> libjami API -> daemon/src implementation`. That is why this knowledge base is split into four sets:

- `shared`: system-wide facts, repository map, build/test rules, boundary analysis, runtime flows, impact analysis, validation, glossary, and hotspots.
- `client`: QML/UI, application-side C++, adapters, local models, settings, and client-specific testing/change playbooks.
- `daemon`: libjami, daemon runtime, accounts, calls, conversations, media, plugins, DBus service, and daemon-specific testing/change playbooks.
- `orchestration`: task classification, routing, handoff rules, cross-set review rules, and specialist definitions.

## How To Start

Start from task ownership, not from the UI symptom alone.

- For QML layout, view navigation, visual regressions, settings page behavior, or app-only helpers, start in `client`.
- For account engine behavior, call state machines, message delivery, media pipeline issues, network/protocol behavior, or libjami contract changes, start in `daemon`.
- For failures that may cross `src/app`, `src/libclient`, and `daemon/src`, start in `shared`, especially the boundary and impact-analysis documents.
- If ownership is unclear, start in `orchestration/task-classification.md` and classify as `UNCERTAIN_REQUIRES_BOUNDARY_CHECK` until the boundary is inspected.

## Fast Reading Order

1. `shared/00-system-overview.md`
2. `shared/01-repository-map.md`
3. `orchestration/task-classification.md`
4. `shared/03-client-daemon-boundaries.md`
5. `client/00-client-architecture.md` or `daemon/00-daemon-architecture.md`

## Where To Look First By Task Type

- Bug fix in visible UI or view logic: `src/app/MainApplicationWindow.qml`, `src/app/mainview/`, `src/app/settingsview/`, adapter singleton in `src/app/`.
- Client state sync bug: `src/app/lrcinstance.cpp`, `src/app/currentconversation.cpp`, `src/app/currentcall.cpp`, `src/app/currentaccount.cpp`, `src/app/messagesadapter.cpp`, `src/app/calladapter.cpp`.
- Client/daemon contract issue: `src/libclient/lrc.cpp`, `src/libclient/callbackshandler.cpp`, `src/libclient/dbus/`, `src/libclient/qtwrapper/`, `daemon/src/jami/*.h`, `daemon/src/client/*.cpp`.
- Daemon call behavior: `daemon/src/manager.cpp`, `daemon/src/client/callmanager.cpp`, `daemon/src/call.cpp`, `daemon/src/sip/sipcall.cpp`, `daemon/src/conference.cpp`.
- Daemon conversation/message behavior: `daemon/src/client/conversation_interface.cpp`, `daemon/src/jamidht/conversation_module.cpp`, `daemon/src/jamidht/conversationrepository.cpp`, `daemon/src/im/instant_messaging.cpp`.
- Media/device issues: `src/app/avadapter.cpp`, `src/libclient/avmodel.cpp`, `daemon/src/client/videomanager.cpp`, `daemon/src/media/audio/`, `daemon/src/media/video/`.
- Build or CI failures: root `CMakeLists.txt`, `src/libclient/CMakeLists.txt`, `tests/CMakeLists.txt`, `daemon/CMakeLists.txt`, `daemon/src/meson.build`, `daemon/test/meson.build`, `extras/ci/`, `extras/scripts/install.sh`.

## Analysis Coverage

Analyzed in depth:

- Client startup and QML bootstrapping: `src/app/main.cpp`, `src/app/mainapplication.cpp`, `src/app/qmlregister.cpp`, `src/app/MainApplicationWindow.qml`, `src/app/mainview/MainView.qml`, `src/app/ViewCoordinator.qml`.
- Client service/model layer: `src/app/lrcinstance.cpp`, `src/app/currentconversation.cpp`, `src/app/calladapter.cpp`, `src/app/messagesadapter.cpp`, `src/libclient/lrc.cpp`, `src/libclient/callbackshandler.cpp`, `src/libclient/conversationmodel.cpp`, `src/libclient/callmodel.cpp`, `src/libclient/CMakeLists.txt`.
- Daemon lifecycle and contracts: `daemon/bin/dbus/main.cpp`, `daemon/src/jami.cpp`, `daemon/src/manager.h`, `daemon/src/manager.cpp`, `daemon/src/client/configurationmanager.cpp`, `daemon/src/client/callmanager.cpp`, `daemon/src/client/conversation_interface.cpp`, `daemon/src/jami/configurationmanager_interface.h`, `daemon/src/meson.build`, `daemon/test/meson.build`.
- Test/build surfaces: root `CMakeLists.txt`, `tests/CMakeLists.txt`, `daemon/CMakeLists.txt`, `tests/qml/`, `tests/unittests/`, `daemon/test/unitTest/`.

Less certain and marked `To confirm` inside the docs:

- Some daemon internal ownership transitions inside conference/media/plugin lifecycles where only partial local reads were necessary for this first version.
- Platform-specific branches not exercised here, especially mobile and some macOS/Windows-specific code paths.
- A few plugin and simulation test details that need deeper task-specific inspection before modification.

## Main Hotspots

- Client hubs: `src/app/mainapplication.cpp`, `src/app/qmlregister.cpp`, `src/app/lrcinstance.cpp`, `src/app/currentconversation.cpp`, `src/app/currentcall.cpp`, `src/app/calladapter.cpp`, `src/app/messagesadapter.cpp`, `src/libclient/lrc.cpp`, `src/libclient/callbackshandler.cpp`, `src/libclient/conversationmodel.cpp`, `src/libclient/callmodel.cpp`.
- Daemon hubs: `daemon/src/jami.cpp`, `daemon/src/manager.cpp`, `daemon/src/manager.h`, `daemon/src/client/callmanager.cpp`, `daemon/src/client/configurationmanager.cpp`, `daemon/src/client/conversation_interface.cpp`, `daemon/src/jamidht/conversation_module.cpp`, `daemon/src/jamidht/conversationrepository.cpp`, `daemon/src/sip/sipcall.cpp`, `daemon/src/conference.cpp`, `daemon/src/media/audio/ringbufferpool.cpp`.
- Boundary hubs: `src/libclient/dbus/`, `src/libclient/qtwrapper/`, `src/libclient/callbackshandler.cpp`, `daemon/src/jami/*.h`, `daemon/src/client/*.cpp`.

Read the set README files next:

- `orchestration/README.md`
- `shared/README.md`
- `client/README.md`
- `daemon/README.md`

## Maintaining This Map

- Treat this knowledge base as a maintained repository map, not a one-time snapshot.
- After a code change or a verified build/test/runtime discovery, update the smallest affected document under `.github/agents/`, `.github/instructions/`, or root `AGENTS.md` when the new fact is durable.
- Prefer narrow updates that capture the new owner, workflow, hotspot, boundary rule, or validation fact.
- If the new information is only partially verified, record it as `To confirm` instead of promoting it to a settled rule.
