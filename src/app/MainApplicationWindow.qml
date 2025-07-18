/*
 * Copyright (C) 2020-2025 Savoir-faire Linux Inc.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */
import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Enums 1.1
import net.jami.Helpers 1.1
import net.jami.Constants 1.1
import "mainview"
import "mainview/components"
import "wizardview"
import "commoncomponents"
import QWindowKit

ApplicationWindow {
    id: appWindow

    readonly property bool useFrameless: UtilsAdapter.getAppValue(Settings.Key.UseFramelessWindow)
    property bool isRTL: UtilsAdapter.isRTL
    LayoutMirroring.enabled: isRTL
    LayoutMirroring.childrenInherit: isRTL
    property var raiseWhenCalled: AppSettingsManager.getValue(Settings.RaiseWhenCalled)

    onActiveFocusItemChanged: {
        focusOverlay.margin = -5;
        if (activeFocusItem) {
            const goodReasonToChangeFocus = activeFocusItem instanceof ItemDelegate || ((activeFocusItem.focusReason === Qt.TabFocusReason) || (activeFocusItem.focusReason === Qt.BacktabFocusReason));
            if (goodReasonToChangeFocus) {
                if (activeFocusItem.focusOnChild) {
                    focusOverlay.parent = activeFocusItem.parent;
                } else if (activeFocusItem.dontShowFocusState) {
                    focusOverlay.parent = null;
                } else {
                    if (activeFocusItem.showFocusMargin)
                        focusOverlay.margin = 0;
                    focusOverlay.parent = activeFocusItem;
                }
            } else {
                focusOverlay.parent = null;
            }
        } else {
            focusOverlay.parent = null;
        }
    }

    header: Loader {
        active: true
        sourceComponent: GenericErrorsRow {
            id: genericError
            text: CurrentAccount.enabled ? JamiStrings.noNetworkConnectivity : JamiStrings.disabledAccount
            height: visible ? JamiTheme.qwkTitleBarHeight : 0
        }
    }

    Rectangle {
        id: focusOverlay
        objectName: "focusOverlay"
        property real margin: -5
        z: -2
        anchors.fill: parent
        anchors.margins: margin
        visible: true
        color: "transparent"
        radius: parent ? parent.radius ? parent.radius : 0 : 0
        border.width: 2
        border.color: JamiTheme.tintedBlue
    }

    // Used to manage full screen mode and save/restore window geometry.
    LayoutManager {
        id: layoutManager
        appContainer: fullscreenContainer
    }
    // Used to manage dynamic view loading and unloading.
    property ViewManager viewManager: ViewManager {
    }
    // Used to manage the view stack and the current view.
    property ViewCoordinator viewCoordinator: ViewCoordinator {
    }

    // Used to prevent the window from being visible until the
    // window geometry has been restored and the view stack has
    // been loaded.
    property bool windowSettingsLoaded: false

    // This setting can be used to block a loading Jami instance
    // from showNormal() and showMaximized() when starting minimized.
    property bool allowVisibleWindow: true

    function cleanupMainView() {
        // Save the main view window size if loading anything else.
        layoutManager.saveWindowSettings();

        // Unload any created views used by the main view.
        viewCoordinator.deinit();
    }

    function close(force = false) {
        // If we're in the onboarding wizard or 'MinimizeOnClose'
        // is set, then we can quit
        var minimizeToTray = UtilsAdapter.getAppValue(Settings.MinimizeOnClose) && UtilsAdapter.isSystemTrayIconVisible();
        if (force || !minimizeToTray || !UtilsAdapter.getAccountListSize()) {
            Qt.quit();
        } else {
            layoutManager.closeToTray();
        }
    }

    title: JamiStrings.appTitle

    visible: mainViewLoader.status === Loader.Ready && windowSettingsLoaded && allowVisibleWindow

    Connections {
        id: connectionMigrationEnded

        target: CurrentAccountToMigrate

        function onAccountNeedsMigration(accountId) {
            viewCoordinator.present("AccountMigrationView");
        }

        function onAllMigrationsFinished() {
            viewCoordinator.dismiss("AccountMigrationView");
            viewCoordinator.present("WelcomePage");
        }
    }

    function initMainView(view) {
        console.info("Initializing main view");

        // Main window, load any valid app settings, and allow the
        // layoutManager to handle as much as possible.
        layoutManager.restoreWindowSettings();

        // QWK: setup
        if (useFrameless) {
            windowAgent.setTitleBar(titleBar);
            // Now register the system buttons (non-macOS).
            if (sysBtnsLoader.item) {
                const sysBtns = sysBtnsLoader.item;
                windowAgent.setSystemButton(WindowAgent.Minimize, sysBtns.minButton);
                windowAgent.setSystemButton(WindowAgent.Maximize, sysBtns.maxButton);
                windowAgent.setSystemButton(WindowAgent.Close, sysBtns.closeButton);
            }
        }

        // Set the viewCoordinator's root item.
        viewCoordinator.init(view);

        // Navigate to something.
        if (UtilsAdapter.getAccountListSize() > 0) {
            // Already have an account.
            if (CurrentAccountToMigrate.accountToMigrateListSize > 0)
                // Do we need to migrate any accounts?
                viewCoordinator.present("AccountMigrationView");
            else
                // Okay now just start the client normally.
                viewCoordinator.present("WelcomePage");
        } else {
            // No account, so start the wizard.
            viewCoordinator.present("WizardView");
        }

        // Set up the event filter for macOS.
        if (Qt.platform.os.toString() === "osx") {
            MainApplication.setEventFilter();
        }

        // Quiet check for updates on start if set to.
        if (Qt.platform.os.toString() === "windows") {
            if (UtilsAdapter.getAppValue(Settings.AutoUpdate)) {
                AppVersionManager.checkForUpdates(true);
                AppVersionManager.setAutoUpdateCheck(true);
            }
        }

        // Handle a start URI if set as start option.
        MainApplication.handleUriAction();

        // This will allow visible to become true if not starting minimized.
        windowSettingsLoaded = true;
    }

    Component.onCompleted: {
        // QWK: setup
        if (useFrameless) {
            windowAgent.setup(appWindow);
        }
        mainViewLoader.active = true;

        // Dbus error handler for Linux.
        if (Qt.platform.os.toString() !== "windows" && Qt.platform.os.toString() !== "osx")
            DBusErrorHandler.setActive(true);

        // Handle potential crash recovery.
        var crashedLastRun = crashReporter.getHasPendingReport();
        if (crashedLastRun) {
            // A crash was detected during the last session. We need to inform the user and offer to send a crash report.
            var dlg = viewCoordinator.presentDialog(appWindow, "commoncomponents/ConfirmDialog.qml", {
                    "title": JamiStrings.crashReportTitle,
                    "textLabel": JamiStrings.crashReportMessage + "\n\n" + JamiStrings.crashReportMessageExtra,
                    "confirmLabel": JamiStrings.send,
                    "rejectLabel": JamiStrings.dontSend,
                    "textHAlign": Text.AlignLeft,
                    "textMaxWidth": 400
                });
            dlg.accepted.connect(function () {
                    crashReporter.uploadLastReport();
                });
            dlg.rejected.connect(function () {
                    crashReporter.clearReports();
                });
        }
    }

    Loader {
        id: mainViewLoader
        active: false
        source: "qrc:/mainview/MainView.qml"
        anchors.fill: parent
        onLoaded: initMainView(item)
    }

    // Use this as a parent for fullscreen items.
    Item {
        id: fullscreenContainer
        anchors.fill: parent
    }

    // QWK: Window Title bar
    Item {
        id: titleBar
        height: JamiTheme.qwkTitleBarHeight
        anchors {
            top: parent.top
            right: parent.right
            left: parent.left
        }

        // On Windows and Linux, use custom system buttons.
        Loader {
            id: sysBtnsLoader
            active: Qt.platform.os.toString() !== "osx" && useFrameless
            height: titleBar.height
            anchors {
                top: parent.top
                right: parent.right
                // Note: leave these margins, they prevent image scaling artifacts
                topMargin: 1
                rightMargin: 1
            }
            source: "qrc:/commoncomponents/QWKSystemButtonGroup.qml"
        }
    }

    // QWK: Main interop component.
    WindowAgent {
        id: windowAgent
    }

    Connections {
        target: LRCInstance

        function onRestoreAppRequested() {
            requestActivate();
            layoutManager.restoreApp();
        }

        function onNotificationClicked() {
            requestActivate();
            raise();
            layoutManager.restoreApp();
        }

        function onCurrentAccountRemoved() {
            if (UtilsAdapter.getAccountListSize() === 0) {
                viewCoordinator.present("WizardView");
            }
        }
    }

    Connections {
        target: UtilsAdapter
        function onRaiseWhenCalledChanged() {
            raiseWhenCalled = AppSettingsManager.getValue(Settings.RaiseWhenCalled);
        }
    }

    Connections {
        target: CallAdapter

        function onCallStatusChanged(index, accountId, convUid) {
            //If we are starting a call with raiseWhenCalled activated
            if (raiseWhenCalled && index === Call.Status.INCOMING_RINGING) {
                appWindow.raise();
                appWindow.requestActivate();
                layoutManager.restoreApp();
            }
        }
    }

    Connections {
        target: MainApplication

        function onAboutToQuit() {
            cleanupMainView();
        }

        function onCloseRequested() {
            close(true);
        }

        function onSearchAndSelect(request) {
            ConversationsAdapter.setFilterAndSelect(request);
        }
    }

    Connections {
        target: {
            if (Qt.platform.os.toString() !== "windows" && Qt.platform.os.toString() !== "osx")
                return DBusErrorHandler;
            return null;
        }
        ignoreUnknownSignals: true

        function onShowDaemonReconnectPopup(visible) {
            if (visible) {
                viewCoordinator.presentDialog(appWindow, "commoncomponents/DaemonReconnectPopup.qml");
            }
        }
    }

    function presentUpdateInfoDialog(infoText) {
        return viewCoordinator.presentDialog(appWindow, "commoncomponents/SimpleMessageDialog.qml", {
                "title": JamiStrings.updateDialogTitle,
                "infoText": infoText,
                "buttonTitles": [JamiStrings.optionOk],
                "buttonStyles": [SimpleMessageDialog.ButtonStyle.TintedBlue],
                "buttonCallBacks": [],
                "buttonRoles": [DialogButtonBox.AcceptRole]
            });
    }

    function presentUpdateConfirmInstallDialog(switchToBeta = false) {
        return viewCoordinator.presentDialog(appWindow, "commoncomponents/SimpleMessageDialog.qml", {
                "title": JamiStrings.updateDialogTitle,
                "infoText": switchToBeta ? JamiStrings.confirmBeta : JamiStrings.updateFound,
                "buttonTitles": [JamiStrings.optionUpgrade, JamiStrings.optionLater],
                "buttonStyles": [SimpleMessageDialog.ButtonStyle.TintedBlue, SimpleMessageDialog.ButtonStyle.TintedBlue],
                "buttonCallBacks": [function () {
                        AppVersionManager.applyUpdates(switchToBeta);
                    }],
                "buttonRoles": [DialogButtonBox.AcceptRole, DialogButtonBox.RejectRole]
            });
    }

    function translateErrorToString(error) {
        switch (error) {
        case NetworkManager.DISCONNECTED:
            return JamiStrings.networkDisconnected;
        case NetworkManager.CONTENT_NOT_FOUND:
            return JamiStrings.contentNotFoundError;
        case NetworkManager.ACCESS_DENIED:
            return JamiStrings.accessError;
        case NetworkManager.SSL_ERROR:
            return JamiStrings.updateSSLError;
        case NetworkManager.CANCELED:
            return JamiStrings.updateDownloadCanceled;
        case NetworkManager.NETWORK_ERROR:
        default:
            return JamiStrings.updateNetworkError;
        }
    }

    Connections {
        target: AppVersionManager

        function onDownloadStarted() {
            viewCoordinator.presentDialog(appWindow, "settingsview/components/UpdateDownloadDialog.qml", {
                    "title": JamiStrings.updateDialogTitle
                });
        }

        function onUpdateCheckReplyReceived(ok, found) {
            if (!ok) {
                // Show an error dialog describing that an update check failed.
                presentUpdateInfoDialog(JamiStrings.updateCheckError);
                return;
            }
            if (!found) {
                // Show a dialog describing that no update was found.
                presentUpdateInfoDialog(JamiStrings.updateNotFound);
            } else {
                // Show a dialog describing that an update were found, and offering to install it.
                presentUpdateConfirmInstallDialog();
            }
        }

        function onNetworkErrorOccurred(error) {
            var errorStr = translateErrorToString(error);
            presentUpdateInfoDialog(errorStr);
        }
    }

    onClosing: appWindow.close()

    // Capture the inputs to the main window while the File Dialog is open
    // This is used to mitigate modality issues on Ubuntu 22.04 systems that use wayland.
    Loader {
        active: JamiQmlUtils.openFileDialogCount > 0
        sourceComponent: Popup {
            modal: true
            visible: true
            closePolicy: Popup.NoAutoClose
            width: appWindow.width
            height: appWindow.height
            background: Rectangle {
                color: "#80808080"  // Semi-transparent grey
            }
        }
    }
}
