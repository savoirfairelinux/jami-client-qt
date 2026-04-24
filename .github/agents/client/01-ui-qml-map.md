# UI / QML Map

## Root Window And Shell

Primary shell files:

- `src/app/MainApplicationWindow.qml`
- `src/app/mainview/MainView.qml`
- `src/app/ViewCoordinator.qml`
- `src/app/LayoutManager.qml`

Key behaviors:

- `MainApplicationWindow.qml` owns the root `Window`, global focus overlay, view coordination setup, tray/minimize/close behavior, and first-route logic.
- `MainApplicationWindow.qml::initMainView()` decides between `WizardView`, `WelcomePage`, and `AccountMigrationView`, and preloads `ConversationView`.
- `MainView.qml` observes `CurrentConversation.id`; non-empty selection presents `ConversationView`, otherwise `WelcomePage`.

## Main Screens

### Welcome / Main Shell

- `src/app/mainview/components/WelcomePage.qml`
- `src/app/mainview/components/SidePanel.qml`
- `src/app/mainview/components/ConversationListView.qml`
- `src/app/mainview/components/Searchbar.qml`

### Conversation / Messaging

- `src/app/mainview/ConversationView.qml`
- `src/app/mainview/components/ChatView.qml`
- `src/app/mainview/components/MessageListView.qml`
- `src/app/mainview/components/ChatViewFooter.qml`
- `src/app/mainview/components/MessageBar.qml`
- `src/app/mainview/components/MessageBarTextArea.qml`

### Calls

- `src/app/mainview/components/OngoingCallPage.qml`
- `src/app/mainview/components/CallOverlay.qml`
- `src/app/mainview/components/CallActionBar.qml`
- `src/app/mainview/components/ParticipantsLayer.qml`
- `src/app/mainview/components/ParticipantOverlay.qml`

### Settings

- `src/app/settingsview/SettingsView.qml`
- `src/app/settingsview/SettingsSidePanel.qml`
- `src/app/settingsview/components/*.qml`

### Onboarding / Account Creation

- `src/app/wizardview/WizardView.qml`
- `src/app/wizardview/components/*.qml`

### Migration / Auxiliary Views

- `src/app/AccountMigrationView.qml`
- `src/app/DaemonReconnectWindow.qml`

## Navigation Patterns

- `ViewCoordinator.qml` maps view names to concrete QML resources and provides `present`, `dismiss`, `getView`, and `preload` behavior.
- Main app navigation uses `viewCoordinator.present(...)` rather than ad hoc Loader switching.
- Settings uses a two-pane `ListSelectionView` in `SettingsView.qml`, with `SettingsSidePanel` on the left and a `StackView`-based content pane on the right.

## Reuse Structure

- `mainview/components/` contains most reusable UI components for conversation, side panel, call overlays, lists, and popups.
- `settingsview/components/` contains page-level settings components and shared settings widgets.
- `commoncomponents/` contains common shell widgets used across views.

## Bindings, Signals, State

Common QML dependencies:

- `net.jami.Adapters 1.1`
- `net.jami.Models 1.1`
- `net.jami.Constants 1.1`
- `net.jami.Enums 1.1`

Typical state sources:

- `CurrentConversation`
- `CurrentCall`
- `CurrentAccount`
- `AppSettingsManager`
- adapter singletons such as `MessagesAdapter`, `CallAdapter`, `ConversationsAdapter`, `UtilsAdapter`
- list models such as `ConversationListProxyModel`, `AccountListModel`, `CallParticipantsModel`

## Where To Modify What

- Root shell/window behavior: `MainApplicationWindow.qml`
- View routing or stack behavior: `ViewCoordinator.qml`, `MainView.qml`
- Conversation list and sidebar behavior: `mainview/components/SidePanel.qml`, `ConversationListView.qml`, related adapters/models
- Message list and composer behavior: `ChatView.qml`, `MessageListView.qml`, `ChatViewFooter.qml`, `MessagesAdapter`
- Ongoing call layout or participant overlay: `OngoingCallPage.qml`, `CallOverlay.qml`, `CallActionBar.qml`, `CurrentCall`, `CallAdapter`
- Settings page composition: `SettingsView.qml`, `SettingsSidePanel.qml`, target page under `settingsview/components/`
- Onboarding/account import: `wizardview/`

## To Confirm

- Some component-local behavior under specialized pages such as plugins, location sharing, or screen sharing still needs task-specific reading before non-trivial changes.
