/*
 * Copyright (C) 2020-2024 Savoir-faire Linux Inc.
 * Author: Aline Gondim Santos <aline.gondimsantos@savoirfairelinux.com>
 * Author: Andreas Traczyk <andreas.traczyk@savoirfairelinux.com>
 * Author: Albert Babí <albert.babi@savoirfairelinux.com>
 * Author: Mingrui Zhang <mingrui.zhang@savoirfairelinux.com>
 * Author: Yang Wang   <yang.wang@savoirfairelinux.com>
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

ApplicationWindow {
    id: root

    property bool isRTL: UtilsAdapter.isRTL

    LayoutMirroring.enabled: isRTL
    LayoutMirroring.childrenInherit: isRTL

    enum LoadedSource {
        MainView,
        AccountMigrationView,
        None
    }

    onActiveFocusItemChanged: {
        focusOverlay.margin = -5;
        if (activeFocusItem && ((activeFocusItem.focusReason === Qt.TabFocusReason) || (activeFocusItem.focusReason === Qt.BacktabFocusReason))) {
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
    }

    header: Loader {
        active: true
        sourceComponent: GenericErrorsRow {
            id: genericError
            text: CurrentAccount.enabled ? JamiStrings.noNetworkConnectivity : JamiStrings.disabledAccount
            height: visible? JamiTheme.chatViewHeaderPreferredHeight : 0
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

    property ApplicationWindow appWindow: root
    property LayoutManager layoutManager: LayoutManager {
        appContainer: appContainer
    }
    property ViewManager viewManager: ViewManager {
    }
    property ViewCoordinator viewCoordinator: ViewCoordinator {
        viewManager: root.viewManager
    }

    property bool windowSettingsLoaded: false
    property bool allowVisibleWindow: true

    function checkLoadedSource() {
        var sourceString = mainApplicationLoader.source.toString();
        if (sourceString === JamiQmlUtils.mainViewLoadPath)
            return MainApplicationWindow.LoadedSource.MainView;
        return MainApplicationWindow.LoadedSource.None;
    }

    function startClient() {
        setMainLoaderSource(JamiQmlUtils.mainViewLoadPath);
    }

    function setMainLoaderSource(source) {
        if (checkLoadedSource() === MainApplicationWindow.LoadedSource.MainView) {
            cleanupMainView();
        }
        mainApplicationLoader.setSource(source);
    }

    function cleanupMainView() {
        // Save the main view window size if loading anything else.
        layoutManager.saveWindowSettings();

        // Unload any created views used by the main view.
        viewCoordinator.deinit();
    }

    function close(force = false) {
        // If we're in the onboarding wizard or 'MinimizeOnClose'
        // is set, then we can quit
        if (force || !UtilsAdapter.getAppValue(Settings.MinimizeOnClose) || !UtilsAdapter.getAccountListSize()) {
            Qt.quit();
        } else {
            layoutManager.closeToTray();
        }
    }

    title: JamiStrings.appTitle

    visible: mainApplicationLoader.status === Loader.Ready && windowSettingsLoaded && allowVisibleWindow

    // To facilitate reparenting of the callview during
    // fullscreen mode, we need QQuickItem based object.
    Item {
        id: appContainer

        anchors.fill: parent
    }

    Loader {
        id: mainApplicationLoader

        anchors.fill: parent
        z: -1

        asynchronous: true
        visible: status == Loader.Ready

        Connections {
            id: connectionMigrationEnded

            target: CurrentAccountToMigrate

            function onAccountNeedsMigration(accountId) {
                viewCoordinator.present("AccountMigrationView");
            }

            function onAllMigrationsFinished() {
                viewCoordinator.dismiss("AccountMigrationView");
                startClient();
            }
        }

        // Set `visible = false` when loading a new QML file.
        onSourceChanged: windowSettingsLoaded = false

        onLoaded: {
            if (UtilsAdapter.getAccountListSize() === 0) {
                layoutManager.restoreWindowSettings();
                if (!viewCoordinator.rootView)
                    // Set the viewCoordinator's root item.
                    viewCoordinator.init(item);
                viewCoordinator.present("WizardView");
            } else {
                // Main window, load any valid app settings, and allow the
                // layoutManager to handle as much as possible.
                layoutManager.restoreWindowSettings();

                // Present the welcome view once the viewCoordinator is setup.
                viewCoordinator.initialized.connect(function () {
                        viewCoordinator.preload("SidePanel");
                        viewCoordinator.preload("SettingsSidePanel");
                        viewCoordinator.present("WelcomePage");
                        viewCoordinator.preload("ConversationView");
                    });
                if (!viewCoordinator.rootView)
                    // Set the viewCoordinator's root item.
                    viewCoordinator.init(item);
                if (CurrentAccountToMigrate.accountToMigrateListSize > 0)
                    viewCoordinator.present("AccountMigrationView");
            }
            if (Qt.platform.os.toString() === "osx") {
                MainApplication.setEventFilter();
            }

            // This will trigger `visible = true`.
            windowSettingsLoaded = true;

            // Quiet check for updates on start if set to.
            if (Qt.platform.os.toString() === "windows") {
                if (UtilsAdapter.getAppValue(Settings.AutoUpdate)) {
                    AppVersionManager.checkForUpdates(true);
                    AppVersionManager.setAutoUpdateCheck(true);
                }
            }

            // Handle a start URI if set as start option.
            MainApplication.handleUriAction();
        }
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
    }

    Connections {
        target: MainApplication

        function onAboutToQuit() {
            cleanupMainView()
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

    function presentUpdateConfirmInstallDialog(switchToBeta=false) {
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
                // Show an error dialog describing that we could not successfully check for an update.
                presentUpdateInfoDialog(JamiStrings.updateCheckError);
                return;
            }
            if (!found) {
                // Show a dialog describing that no update was found.
                presentUpdateInfoDialog(JamiStrings.updateNotFound);
            } else {
                // Show a dialog describing that an update were found, and offering to install it.
                presentUpdateConfirmInstallDialog()
            }
        }

        function onNetworkErrorOccurred(error) {
            var errorStr = translateErrorToString(error);
            presentUpdateInfoDialog(errorStr);
        }
    }

    onClosing: root.close()

    Component.onCompleted: {
        startClient();
        if (Qt.platform.os.toString() !== "windows" && Qt.platform.os.toString() !== "osx")
            DBusErrorHandler.setActive(true);
    }
}
