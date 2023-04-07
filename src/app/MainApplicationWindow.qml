/*
 * Copyright (C) 2020-2023 Savoir-faire Linux Inc.
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

    enum LoadedSource {
        WizardView = 0,
        MainView,
        AccountMigrationView,
        None
    }

    property ApplicationWindow appWindow: root
    property LayoutManager layoutManager: LayoutManager {
        appContainer: appContainer
    }
    property ViewManager viewManager: ViewManager {}
    property ViewCoordinator viewCoordinator: ViewCoordinator {
        viewManager: root.viewManager
    }

    property bool windowSettingsLoaded: false
    property bool allowVisibleWindow: true

    function checkLoadedSource() {
        var sourceString = mainApplicationLoader.source.toString()

        if (sourceString === JamiQmlUtils.wizardViewLoadPath)
            return MainApplicationWindow.LoadedSource.WizardView
        else if (sourceString === JamiQmlUtils.mainViewLoadPath)
            return MainApplicationWindow.LoadedSource.MainView

        return MainApplicationWindow.LoadedSource.None
    }

    function startClient() {
        if (UtilsAdapter.getAccountListSize() !== 0) {
            setMainLoaderSource(JamiQmlUtils.mainViewLoadPath)
        } else {
            setMainLoaderSource(JamiQmlUtils.wizardViewLoadPath)
        }
    }

    function setMainLoaderSource(source) {
        if (checkLoadedSource() === MainApplicationWindow.LoadedSource.MainView) {
            cleanupMainView()
        }
        mainApplicationLoader.setSource(source)
    }

    function cleanupMainView() {
        // Save the main view window size if loading anything else.
        layoutManager.saveWindowSettings()

        // Unload any created views used by the main view.
        viewCoordinator.deinit()
    }

    function close(force = false) {
        // If we're in the onboarding wizard or 'MinimizeOnClose'
        // is set, then we can quit
        if (force || !UtilsAdapter.getAppValue(Settings.MinimizeOnClose) ||
                !UtilsAdapter.getAccountListSize()) {
            if (checkLoadedSource() === MainApplicationWindow.LoadedSource.MainView) {
                cleanupMainView()
            }
            Qt.quit()
        } else {
            layoutManager.closeToTray()
        }
    }

    title: JamiStrings.appTitle

    visible: mainApplicationLoader.status === Loader.Ready
             && windowSettingsLoaded
             && allowVisibleWindow

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
            target: viewCoordinator

            function onRequestAppWindowWizardView() {
                setMainLoaderSource(JamiQmlUtils.wizardViewLoadPath)
            }
        }

        Connections {
            id: connectionMigrationEnded

            target: CurrentAccountToMigrate

            function onAccountNeedsMigration(accountId) {
                viewCoordinator.present("AccountMigrationView")
            }

            function onAllMigrationsFinished() {
                viewCoordinator.dismiss("AccountMigrationView")
                startClient()
            }
        }

        Connections {
            target: mainApplicationLoader.item

            function onLoaderSourceChangeRequested(sourceToLoad) {
                if (sourceToLoad === MainApplicationWindow.LoadedSource.WizardView)
                    setMainLoaderSource(JamiQmlUtils.wizardViewLoadPath)
                else if (sourceToLoad === MainApplicationWindow.LoadedSource.AccountMigrationView)
                    setMainLoaderSource(JamiQmlUtils.accountMigrationViewLoadPath)
                else
                    setMainLoaderSource(JamiQmlUtils.mainViewLoadPath)
            }
        }

        // Set `visible = false` when loading a new QML file.
        onSourceChanged: windowSettingsLoaded = false

        onLoaded: {
            if (checkLoadedSource() === MainApplicationWindow.LoadedSource.WizardView) {
                // Onboarding wizard window, these settings are fixed.
                // - window screen will default to the primary
                // - the window will showNormal once windowSettingsLoaded is
                //   set to true(then forcing visible to true)
                appWindow.width = JamiTheme.wizardViewMinWidth
                appWindow.height = JamiTheme.wizardViewMinHeight
                appWindow.minimumWidth = JamiTheme.wizardViewMinWidth
                appWindow.minimumHeight = JamiTheme.wizardViewMinHeight
            } else {
                // Main window, load any valid app settings, and allow the
                // layoutManager to handle as much as possible.
                layoutManager.restoreWindowSettings()

                // Present the welcome view once the viewCoordinator is setup.
                viewCoordinator.initialized.connect(function() {
                    viewCoordinator.preload("SidePanel")
                    viewCoordinator.preload("SettingsSidePanel")
                    viewCoordinator.present("WelcomePage")
                    viewCoordinator.preload("ConversationView")
                })
                // Set the viewCoordinator's root item.
                viewCoordinator.init(item)
                if (CurrentAccountToMigrate.accountToMigrateListSize > 0)
                    viewCoordinator.present("AccountMigrationView")
            }
            if (Qt.platform.os.toString() === "osx") {
                MainApplication.setEventFilter()
            }

            // This will trigger `visible = true`.
            windowSettingsLoaded = true

            // Quiet check for updates on start if set to.
            if (Qt.platform.os.toString() !== "osx") {
                if (UtilsAdapter.getAppValue(Settings.AutoUpdate)) {
                    UpdateManager.checkForUpdates(true)
                    UpdateManager.setAutoUpdateCheck(true)
                }
            }

            // Handle a start URI if set as start option.
            MainApplication.handleUriAction();
        }
    }

    Connections {
        target: LRCInstance

        function onRestoreAppRequested() {
            requestActivate()
            layoutManager.restoreApp()
        }

        function onNotificationClicked() {
            requestActivate()
            raise()
            layoutManager.restoreApp()
        }
    }

    Connections {
        target: MainApplication

        function onCloseRequested() {
            close(true)
        }

        function onSearchAndSelect(request) {
            ConversationsAdapter.setFilterAndSelect(request)
        }
    }

    Connections {
        target: {
            if (Qt.platform.os.toString()  !== "windows" && Qt.platform.os.toString()  !== "osx")
                return DBusErrorHandler
            return null
        }
        ignoreUnknownSignals: true

        function onShowDaemonReconnectPopup(visible) {
            if (visible) {
                viewCoordinator.presentDialog(
                            appWindow,
                            "commoncomponents/DaemonReconnectPopup.qml")
            }
        }
    }

    function presentUpdateInfoDialog(infoText) {
        viewCoordinator.presentDialog(
            appWindow,
            "commoncomponents/SimpleMessageDialog.qml",
            {
                title: JamiStrings.updateDialogTitle,
                infoText: infoText,
                buttonTitles: [JamiStrings.optionOk],
                buttonStyles: [SimpleMessageDialog.ButtonStyle.TintedBlue],
                buttonCallBacks: []
            })
    }

    function presentConfirmInstallDialog(infoText, beta) {

    }

    Connections {
        target: UpdateManager

        function onUpdateDownloadStarted() {
            viewCoordinator.presentDialog(
                appWindow,
                "settingsview/components/UpdateDownloadDialog.qml",
                {title: JamiStrings.updateDialogTitle})
        }

        function onUpdateCheckReplyReceived(ok, found) {
            if (!ok) {
                presentUpdateInfoDialog(JamiStrings.updateCheckError)
                return
            }
            if (!found) {
                presentUpdateInfoDialog(JamiStrings.updateNotFound)
            } else {
                viewCoordinator.presentDialog(
                    appWindow,
                    "commoncomponents/SimpleMessageDialog.qml",
                    {
                        title: JamiStrings.updateDialogTitle,
                        infoText: JamiStrings.updateFound,
                        buttonTitles: [JamiStrings.optionUpgrade, JamiStrings.optionLater],
                        buttonStyles: [
                            SimpleMessageDialog.ButtonStyle.TintedBlue,
                            SimpleMessageDialog.ButtonStyle.TintedBlue
                        ],
                        buttonCallBacks: [function() {UpdateManager.applyUpdates()}]
                    })
            }
        }

        function onUpdateErrorOccurred(error) {
            presentUpdateInfoDialog((function () {
                switch(error){
                case NetWorkManager.ACCESS_DENIED:
                    return JamiStrings.genericError
                case NetWorkManager.DISCONNECTED:
                    return JamiStrings.networkDisconnected
                case NetWorkManager.NETWORK_ERROR:
                    return JamiStrings.updateNetworkError
                case NetWorkManager.SSL_ERROR:
                    return JamiStrings.updateSSLError
                case NetWorkManager.CANCELED:
                    return JamiStrings.updateDownloadCanceled
                default: return {}
                }
            })())
        }
    }

    onClosing: root.close()

    Component.onCompleted: {
        startClient()
        if (Qt.platform.os.toString()  !== "windows" && Qt.platform.os.toString()  !== "osx")
            DBusErrorHandler.setActive(true)
    }
}
