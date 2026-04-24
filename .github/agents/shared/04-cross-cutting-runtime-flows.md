# Cross-Cutting Runtime Flows

## Startup / Init

Confirmed flow:

- `src/app/main.cpp` sets process-level Qt/runtime options and creates `MainApplication`.
- `MainApplication::init()` in `src/app/mainapplication.cpp` creates app services, initializes `LRCInstance`, and on Unix may load `DaemonReconnectWindow.qml` if DBus is unavailable.
- `MainApplication::initQmlLayer()` registers QML-facing objects, creates `ApiServer`, exposes managers to QML, and loads `MainApplicationWindow.qml`.
- `LRCInstance` constructs `lrc::api::Lrc`.
- `lrc::api::Lrc` in `src/libclient/lrc.cpp` calls `InstanceManager::instance(...)` first, ensuring daemon-side instance setup through DBus or libwrap.
- On the daemon side, `daemon/bin/dbus/main.cpp` calls `libjami::init()` and `libjami::start()`, which delegate into `daemon/src/jami.cpp` and `daemon/src/manager.cpp`.

## Account Lifecycle

Confirmed path:

- UI/account actions come from `AccountAdapter` or settings pages.
- They reach `LRCInstance` and `AccountModel` in `src/libclient/accountmodel.cpp`.
- Account-related daemon calls go through configuration interfaces/wrappers.
- `daemon/src/client/configurationmanager.cpp` delegates into `jami::Manager` and account implementations (`SIPAccount`, `JamiAccount`).
- Account/registration changes are emitted back through configuration signals, then handled by `CallbacksHandler`, `AccountModel`, and `CurrentAccount`/QML consumers.

## Conversation / Message Flow

Confirmed path for send:

- QML -> `MessagesAdapter::sendMessage()` in `src/app/messagesadapter.cpp`
- `ConversationModel::sendMessage(...)` in `src/libclient/conversationmodel.cpp`
- daemon contract in `daemon/src/client/conversation_interface.cpp`
- `JamiAccount::convModule(true)` and `ConversationModule::sendMessage(...)`

Confirmed receive/update path:

- daemon conversation/message events -> wrapper/DBus manager -> `src/libclient/callbackshandler.cpp`
- `ConversationModel` updates interactions and conversation state
- `MessagesAdapter` swaps proxy source model on selected conversation changes and listens for new interactions/message load events
- QML views bound to the message list model update

Notes:

- File transfer state is also folded into conversation/interactions through `ConversationModelPimpl` and `DataTransferModel` mapping between file IDs and interaction IDs.

## Call Flow

Confirmed path for outgoing/accept/hangup class of actions:

- QML -> `CallAdapter` or `CurrentCall`/other call consumers
- `CallModel` in `src/libclient/callmodel.cpp` talks through `CallManager::instance()` wrappers
- daemon implementation in `daemon/src/client/callmanager.cpp`
- runtime ownership in `jami::Manager`, `Call`, `SIPCall`, and `Conference`

Confirmed return path:

- daemon call events -> wrapper/DBus manager -> `CallbacksHandler`
- `CallModel` updates call state and participants
- `CallAdapter`, `CurrentCall`, and `CurrentConversation` reflect call state into the UI

Important nuance:

- `CallModel::setCurrentCall()` can hold other calls across accounts, so call focus in the client influences multi-account runtime behavior.

## Media / Device Flow

Confirmed path:

- UI -> `AvAdapter`, settings pages, or `VideoDevices`
- `src/libclient/avmodel.cpp` and related device models
- wrapper/DBus video/configuration managers
- daemon implementations in `daemon/src/client/videomanager.cpp` and configuration manager
- runtime media ownership in `daemon/src/media/audio/` and `daemon/src/media/video/`

## Settings / Preferences Propagation

- App-local settings are managed in `AppSettingsManager` and consumed through `UtilsAdapter` and settings QML.
- Account or runtime settings propagate into daemon-side configuration through account/configuration models and interfaces.
- Settings pages in `src/app/settingsview/SettingsView.qml` swap many pages that touch both app-local and daemon-backed settings, so this area often needs mixed ownership analysis.

## Plugin Flow

- Client-side plugin views and adapters live in `src/app/plugin*`, `PluginAdapter`, `PluginListModel`, and settings/mainview components.
- libclient exposes `PluginModel`.
- daemon-side plugin behavior lives in `daemon/src/plugin/` and `daemon/src/client/plugin_manager_interface.cpp`.

## To Confirm

- Some lower-level plugin service callbacks and platform-specific media branches need deeper task-specific reads.
