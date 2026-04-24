---
applyTo: "src/app/**/*,src/libclient/**/*,tests/qml/**/*,tests/unittests/**/*"
---

- For client-side changes, first confirm whether the wrong state already exists before it reaches the client. If ownership is unclear, inspect `.github/agents/shared/03-client-daemon-boundaries.md`, `src/app/lrcinstance.cpp`, `src/libclient/lrc.cpp`, and `src/libclient/callbackshandler.cpp`.
- Use `.github/agents/client/00-client-architecture.md`, `.github/agents/client/01-ui-qml-map.md`, and `.github/agents/client/02-client-runtime-flows.md` as the default first reads.
- QML and shell hubs are `src/app/MainApplicationWindow.qml`, `src/app/mainview/MainView.qml`, `src/app/ViewCoordinator.qml`, and `src/app/settingsview/SettingsView.qml`.
- State and adapter hubs are `src/app/currentconversation.cpp`, `src/app/currentcall.cpp`, `src/app/currentaccount.cpp`, `src/app/calladapter.cpp`, and `src/app/messagesadapter.cpp`.
- If a change affects daemon wrappers, callback payloads, or model synchronization, inspect both `src/libclient/dbus/` and `src/libclient/qtwrapper/` instead of changing only one integration path.
- Prefer the narrowest relevant validation. Client tests require `BUILD_TESTING=ON` and mainly live in `tests/qml/src` and `tests/unittests`.