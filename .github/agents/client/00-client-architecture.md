# Client Architecture

## Confirmed Entry Points

- `src/app/main.cpp` is the desktop client entry point.
- `MainApplication` in `src/app/mainapplication.cpp` owns startup orchestration.
- `MainApplication::initQmlLayer()` loads `qrc:/MainApplicationWindow.qml`.
- `Utils::registerTypes()` in `src/app/qmlregister.cpp` is the registry that makes adapters, singleton models, and current-state objects visible to QML.

## Client Layers

### 1. App Bootstrap And Services

Primary files:

- `src/app/main.cpp`
- `src/app/mainapplication.cpp`
- `src/app/mainapplication.h`

Responsibilities:

- process startup and instance handling
- graphics/WebEngine/runtime setup
- daemon reconnect behavior on Unix
- initialization of app services such as settings, tray, connectivity monitor, preview engine, crash reporter, API server, and API tokens

### 2. QML Shell And View Coordination

Primary files:

- `src/app/MainApplicationWindow.qml`
- `src/app/mainview/MainView.qml`
- `src/app/ViewCoordinator.qml`
- `src/app/ViewManager.qml`
- `src/app/LayoutManager.qml`

Responsibilities:

- root window and top-level loading behavior
- stack-based presentation and dismissal of views
- switching between welcome/conversation/settings/wizard/account-migration flows
- split-pane behavior in settings and other shell contexts

### 3. Adapter Layer Exposed To QML

Primary files:

- `src/app/accountadapter.cpp`
- `src/app/calladapter.cpp`
- `src/app/messagesadapter.cpp`
- `src/app/conversationsadapter.cpp`
- `src/app/contactadapter.cpp`
- `src/app/utilsadapter.cpp`
- `src/app/avadapter.cpp`
- `src/app/pluginadapter.cpp`

Pattern:

- QML calls adapter singletons.
- Adapters read and mutate state through `LRCInstance`, current-state singletons, and libclient models.
- Adapters contain app-facing coordination, not core daemon ownership.

### 4. Current-State Singletons

Primary files:

- `src/app/currentaccount.cpp`
- `src/app/currentconversation.cpp`
- `src/app/currentcall.cpp`

Responsibilities:

- expose selected/current account, conversation, and call state into QML as stable properties
- rebind or recompute derived state when account or conversation context changes

### 5. App-Level Model And Helper Objects

Examples:

- `src/app/accountlistmodel.cpp`
- `src/app/conversationstatusmodel.cpp`
- `src/app/trackedmembersmodel.cpp`
- `src/app/calloverlaymodel.cpp`
- `src/app/pluginlistmodel.cpp`
- `src/app/pluginstorelistmodel.cpp`
- `src/app/deviceitemlistmodel.cpp`
- `src/app/audiodevicemodel.cpp`
- `src/app/mediacodeclistmodel.cpp`

These are QObject/QAbstractListModel types exposed to QML for view binding.

### 6. Client Bridge Into Libclient

Primary files:

- `src/app/lrcinstance.cpp`
- `src/libclient/lrc.cpp`
- `src/libclient/accountmodel.cpp`
- `src/libclient/conversationmodel.cpp`
- `src/libclient/callmodel.cpp`
- `src/libclient/avmodel.cpp`
- `src/libclient/pluginmodel.cpp`

`LRCInstance` is the explicit client-side handoff point from app logic to daemon-backed models.

## Ownership Of State

App-local ownership:

- `AppSettingsManager` for local application settings.
- view state managed in QML and view coordinators.
- local shell helpers like tray state, crash reporting, preview generation, and some UI-only logic.

Daemon-backed ownership consumed by client:

- account details and registration state through `AccountModel`
- conversation and interaction state through `ConversationModel`
- call and conference state through `CallModel`
- device/media state through `AVModel` and related device models
- plugin state through `PluginModel`

Derived client ownership:

- `CurrentConversation` and `CurrentCall` derive and aggregate state for the currently selected context.

## Initialization Flow

Confirmed order:

1. `main.cpp` creates `MainApplication`.
2. `MainApplication::init()` creates app services and `QQmlApplicationEngine`.
3. `initLrc(...)` creates `LRCInstance`.
4. On Unix, daemon connectivity may be checked before the main window is loaded.
5. `initQmlLayer()` calls `Utils::registerTypes()`.
6. QML engine loads `MainApplicationWindow.qml`.
7. `MainApplicationWindow.qml` initializes `MainView` and the view coordinator.

## Client Architectural Risks

- `LRCInstance` is a broad dependency for many adapters and state holders.
- `qmlregister.cpp` is a single large registration hub; small mistakes there can make features invisible to QML.
- `CurrentConversation` and `CurrentCall` rely on selected account/conversation context and can show stale state if rebinding logic is incomplete.
- `MessagesAdapter` swaps source models when conversation selection changes, so message-list regressions often involve both QML and model-binding assumptions.

## To Confirm

- Some platform-specific shell services such as screen sharing, platform PTT listeners, and macOS-specific window behavior need deeper task-focused reads when modified.
