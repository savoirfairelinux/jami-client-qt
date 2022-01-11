/*
 * Copyright (C) 2020-2022 Savoir-faire Linux Inc.
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

    property bool windowSettingsLoaded: false

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
            var geometry = Qt.rect(appWindow.x, appWindow.y,
                                   appWindow.width, appWindow.height)
            AppSettingsManager.setValue(Settings.WindowGeometry, geometry)
            AppSettingsManager.setValue(Settings.WindowState, appWindow.visibility)
            Qt.quit()
        } else {
            hide()
        }
    }

    title: JamiStrings.appTitle

    visible: mainApplicationLoader.status === Loader.Ready && windowSettingsLoaded

    // To facilitate reparenting of the callview during
    // fullscreen mode, we need QQuickItem based object.
    Item {
        id: appContainer

        anchors.fill: parent
    }

    DaemonReconnectPopup {
        id: daemonReconnectPopup
    }

    Loader {
        id: mainApplicationLoader

        anchors.fill: parent
        z: -1

        asynchronous: true
        visible: status == Loader.Ready
        source: ""

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
            if (UtilsAdapter.getAppValue(Settings.StartMinimized)) {
                showMinimized()
            } else {
                if (checkLoadedSource() === MainApplicationWindow.LoadedSource.WizardView) {
                    appWindow.width = JamiTheme.wizardViewMinWidth
                    appWindow.height = JamiTheme.wizardViewMinHeight
                    appWindow.minimumWidth = JamiTheme.wizardViewMinWidth
                    appWindow.minimumHeight = JamiTheme.wizardViewMinHeight
                } else {
                    // Main window, load settings if possible.
                    var geometry = AppSettingsManager.getValue(Settings.WindowGeometry)

                    // Position.
                    if (!isNaN(geometry.x) && !isNaN(geometry.y)) {
                        appWindow.x = geometry.x
                        appWindow.y = geometry.y
                    }

                    // Dimensions.
                    appWindow.width = geometry.width ?
                                geometry.width :
                                JamiTheme.mainViewPreferredWidth
                    appWindow.height = geometry.height ?
                                geometry.height :
                                JamiTheme.mainViewPreferredHeight
                    appWindow.minimumWidth = JamiTheme.mainViewMinWidth
                    appWindow.minimumHeight = JamiTheme.mainViewMinHeight

                    // State.
                    const visibilityStr = AppSettingsManager.getValue(Settings.WindowState)
                    appWindow.visibility = parseInt(visibilityStr)
                }
            }

            // This will trigger `visible = true`.
            windowSettingsLoaded = true

            // Quiet check for updates on start if set to.
            if (UtilsAdapter.getAppValue(Settings.AutoUpdate)) {
                UpdateManager.checkForUpdates(true)
                UpdateManager.setAutoUpdateCheck(true)
            }
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
    }

    Connections {
        target: {
            if (Qt.platform.os !== "windows" && Qt.platform.os !== "macos")
                return DBusErrorHandler
            return null
        }
        ignoreUnknownSignals: true

        function onShowDaemonReconnectPopup(visible) {
            if (visible)
                daemonReconnectPopup.open()
            else
                daemonReconnectPopup.close()
        }

        function onDaemonReconnectFailed() {
            daemonReconnectPopup.connectionFailed = true
        }
    }

    onClosing: root.close()

    onScreenChanged: JamiQmlUtils.mainApplicationScreen = root.screen

    Component.onCompleted: {
        if (CurrentAccountToMigrate.accountToMigrateListSize <= 0)
            startClient()
        else
            startAccountMigration()

        JamiQmlUtils.mainApplicationScreen = root.screen

        if (Qt.platform.os !== "windows" && Qt.platform.os !== "macos")
            DBusErrorHandler.setActive(true)
    }
}
