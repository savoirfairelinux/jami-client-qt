# App Layer Agent Guidance

- Scope here is the desktop QML and application shell under `src/app`.
- Read `.github/agents/client/00-client-architecture.md`, `.github/agents/client/01-ui-qml-map.md`, and `.github/agents/client/02-client-runtime-flows.md` before editing.
- Start from the visible owner: target QML file, adapter, singleton, or current-state object.
- Treat `LRCInstance` in `src/app/lrcinstance.cpp` as the main bridge from app code into `src/libclient`.
- Hotspots include `mainapplication.cpp`, `qmlregister.cpp`, `MainApplicationWindow.qml`, `mainview/MainView.qml`, `ViewCoordinator.qml`, `currentconversation.cpp`, `currentcall.cpp`, `calladapter.cpp`, and `messagesadapter.cpp`.
- Before declaring a bug client-owned, confirm the wrong state is not already wrong in `src/libclient` or daemon-facing callbacks.
- Escalate to cross-layer review when a change touches `src/libclient`, callback propagation, wrapper behavior, or daemon-facing contracts.
- Do not treat app-layer work as validated until the relevant client tests pass and the affected client build surface succeeds.
- After meaningful app-side changes or verified new app-layer facts, update the smallest affected agent or instruction doc so the guidance improves with the code.
