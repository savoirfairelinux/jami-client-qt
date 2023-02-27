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
            mainApplicationLoader.setSource(JamiQmlUtils.mainViewLoadPath)
        } else {
            mainApplicationLoader.setSource(JamiQmlUtils.wizardViewLoadPath)
        }
    }

    function startAccountMigration() {
        mainApplicationLoader.setSource(JamiQmlUtils.accountMigrationViewLoadPath)
    }

    function close(force = false) {
        // If we're in the onboarding wizard or 'MinimizeOnClose'
        // is set, then we can quit
        if (force || !UtilsAdapter.getAppValue(Settings.MinimizeOnClose) ||
                !UtilsAdapter.getAccountListSize()) {
            // Save the window geometry and state before quitting.
            layoutManager.saveWindowSettings()
            viewCoordinator.deinit()
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
                mainApplicationLoader.setSource(JamiQmlUtils.wizardViewLoadPath)
            }
        }

        Connections {
            target: mainApplicationLoader.item

            function onLoaderSourceChangeRequested(sourceToLoad) {
                if (sourceToLoad === MainApplicationWindow.LoadedSource.WizardView)
                    mainApplicationLoader.setSource(JamiQmlUtils.wizardViewLoadPath)
                else
                    mainApplicationLoader.setSource(JamiQmlUtils.mainViewLoadPath)
            }
        }

        // Set `visible = false` when loading a new QML file.
        onSourceChanged: windowSettingsLoaded = false

        onLoaded: {
            if (checkLoadedSource() === MainApplicationWindow.LoadedSource.WizardView) {
                // Onboarding wizard window, these settings are fixed.
                // - window screen should default to the primary
                // - position should default to being centered based on the
                //   following dimensions
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
                    //viewCoordinator.preload("ConversationView")
                })
                // Set the viewCoordinator's root item.
                viewCoordinator.init(item)
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

    onClosing: root.close()

    Component.onCompleted: {
        if (CurrentAccountToMigrate.accountToMigrateListSize <= 0)
            startClient()
        else
            startAccountMigration()

        if (Qt.platform.os.toString()  !== "windows" && Qt.platform.os.toString()  !== "osx")
            DBusErrorHandler.setActive(true)
    }
}
