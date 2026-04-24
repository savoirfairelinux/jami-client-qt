# Client Runtime Flows

## Startup Flow

- `main.cpp` creates `MainApplication`.
- `MainApplication::init()` initializes services and `LRCInstance`.
- `initQmlLayer()` registers types and loads `MainApplicationWindow.qml`.
- `MainApplicationWindow.qml` restores window state, initializes `MainView`, and decides whether to show onboarding, migration, or the normal shell.

## Account-Related UI Logic

- Account list and switching are driven through `AccountAdapter`, `AccountListModel`, `CurrentAccount`, and `LRCInstance`.
- `LRCInstance` updates current-account state and emits account-related change signals used by adapters and current-state objects.
- Settings/account-management pages under `settingsview/components/` often combine app-local settings with daemon-backed account configuration.

## Conversation UI Flow

Confirmed path:

- conversation selection changes `LRCInstance::selectedConvUid`
- `CurrentConversation` recomputes derived state in `src/app/currentconversation.cpp`
- `MainView.qml` observes `CurrentConversation.id` and presents `ConversationView` or `WelcomePage`
- `MessagesAdapter` resets its proxy source model on `selectedConvUidChanged`
- conversation title, description, mode, call info, preferences, and members are read through `CurrentConversation`

## Call UI Flow

Confirmed path:

- user action in QML -> `CallAdapter` or related call object
- call actions reach `CallModel` through `LRCInstance`
- daemon events return through `CallbacksHandler` and `CallModel`
- `CurrentCall` and `CurrentConversation` expose active call state back to the UI
- notifications and tray responses on Linux are handled in `CallAdapter`

Important nuance:

- `CallAdapter` reconnects to the account context on account changes and listens to behavior-controller signals such as `showIncomingCallView` and `showCallView`.

## Settings / Preferences Flow

- `SettingsView.qml` switches content pages via an index-driven `StackView`.
- App-local settings go through `AppSettingsManager` and `UtilsAdapter`.
- Account/runtime settings go through account models, current-account logic, or specific adapters/models.
- Some settings changes should trigger follow-up behavior; for example, `SettingsView` dismissal reloads interactions through `CurrentConversation.reloadInteractions()`.

## Notifications / Device / Preview Flow

- `SystemTray` and `CallAdapter` coordinate notifications, especially call acceptance/decline on Linux.
- `PreviewEngine` is injected into the QML layer and used through message parsing/preview flows.
- Device and media state is exposed through `VideoDevices`, `AudioDeviceModel`, `AudioManagerListModel`, and related models.

## Local-Only Logic Worth Isolating

- view presentation and dismissal logic in `ViewCoordinator.qml`
- shell/minimize-to-tray logic in `MainApplicationWindow.qml`
- settings page stack and split-view behavior in `SettingsView.qml`
- message parsing/preview logic in `MessagesAdapter` and `MessageParser`

## To Confirm

- Some specialized flows such as plugin preference UI and advanced screen-sharing platform branches need deeper targeted reads when changed.
