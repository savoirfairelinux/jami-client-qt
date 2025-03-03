/*
 * Copyright (C) 2022-2025 Savoir-faire Linux Inc.
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
import QtQuick.Controls

import net.jami.Adapters 1.1
import net.jami.Enums 1.1
import net.jami.Constants 1.1

import "mainview/components"

QtObject {
    id: root

    // A window-sized container for reparenting components.
    required property Item appContainer

    // True if the main window is fullscreen.
    readonly property bool isFullScreen: visibility === Window.FullScreen

    // Both the Hidden and Minimized states combined for convenience.
    readonly property bool isHidden: visibility === Window.Hidden ||
                                     visibility === Window.Minimized

    // Used to store if a OngoingCallPage component is fullscreened.
    property bool isCallFullscreen: false

    // QWK: Provide spacing for widgets that may be occluded by the system buttons.
    property QtObject qwkSystemButtonSpacing: QtObject {
        id: qwkSystemButtonSpacing
        readonly property bool isMacOS: Qt.platform.os.toString() === "osx"
        // macOS buttons are on the left.
        readonly property real left: {
            appWindow.useFrameless && isMacOS && viewCoordinator.isInSinglePaneMode ? 80 : 0
        }
        // Windows and Linux buttons are on the right.
        readonly property real right: {
            appWindow.useFrameless && !isMacOS && !root.isFullscreen ? sysBtnsLoader.width + 24 : 0
        }
    }

    // Restore a visible windowed mode.
    function restoreApp() {
        if (isHidden) {
            if (priv.windowedVisibility === Window.Hidden
                    || priv.windowedVisibility === Window.Minimized) {
                showNormal()
                return
            }
            visibility = priv.windowedVisibility
        }
        appWindow.allowVisibleWindow = true
    }

    // Start in a hidden state.
    function startMinimized(visibilitySetting) {
        // Save the loaded setting for when the app is restored.
        priv.windowedVisibility = visibilitySetting
        appWindow.allowVisibleWindow = false
        appWindow.hide();
    }

    // Close to a hidden state.
    function closeToTray(visibilitySetting = undefined) {
        // Save the current visibility.
        priv.windowedVisibility = visibility
        appWindow.hide();
    }

    // Save the window geometry and visibility settings.
    function saveWindowSettings() {
        // If closed-to-tray or minimized or fullscreen, save the cached windowedVisibility
        // value instead.
        const visibilityToSave = isHidden || isFullScreen ? priv.windowedVisibility : visibility;

        // Likewise, don't save fullscreen geometry.
        const geometry = isFullScreen ?
                           priv.windowedGeometry :
                           Qt.rect(appWindow.x, appWindow.y,
                                   appWindow.width, appWindow.height);

        // QWK: Account for the frameless window's offset.
        if (appWindow.useFrameless) {
            if (Qt.platform.os.toString() !== "osx") {
                // Add [7, 30, 0, 0] on Windows and GNU/Linux.
                geometry.x += 7;
                geometry.y += 30;
            }
        }

        console.debug("Saving window: " + JSON.stringify(geometry) + " " + visibilityToSave);

        AppSettingsManager.setValue(Settings.WindowState, visibilityToSave)
        AppSettingsManager.setValue(Settings.WindowGeometry, geometry)
    }

    // Restore the window geometry and visibility settings.
    function restoreWindowSettings() {
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
        var visibilitySetting = parseInt(visibilityStr)

        console.debug("Restoring window: " + JSON.stringify(geometry) + " " + visibilitySetting)

        // We should never restore a hidden or fullscreen state here. Default to normal
        // windowed state in such a case. This shouldn't happen.
        if (visibilitySetting === Window.Hidden || visibilitySetting === Window.FullScreen) {
            visibilitySetting = Window.Windowed
        }
        if (MainApplication.startMinimized) {
            startMinimized(visibilitySetting)
        } else {
            visibility = visibilitySetting
        }
    }

    // Simplified function to handle call fullscreen
    function setCallFullscreen(fullscreen, fullScreenItem = undefined) {
        if (fullscreen) {
            // Make sure our window is in fullscreen mode
            if (!isFullScreen) {
                priv.windowedVisibility = visibility;
                priv.windowedGeometry = Qt.rect(appWindow.x, appWindow.y, appWindow.width, appWindow.height);
            }

            // Cache the current call item's state
            priv.fullscreenItemStateObject = {
                item: fullScreenItem,
                parent: fullScreenItem.parent,
                anchorsFill: fullScreenItem.anchors.fill
            };

            // Reparent call item to app container
            fullScreenItem.parent = appContainer;
            fullScreenItem.anchors.fill = appContainer;
            showFullScreen();
        } else {
            // Using our cached item, restore the item to previous state
            fullScreenItem = priv.fullscreenItemStateObject.item;
            if (!fullScreenItem) {
                console.warn("No call item to restore from fullscreen");
                return;
            }
            fullScreenItem.anchors.fill = priv.fullscreenItemStateObject.anchorsFill;
            fullScreenItem.parent = priv.fullscreenItemStateObject.parent;

            // Reset the cached item
            priv.fullscreenItemStateObject = null;

            // Exit fullscreen if we're not manually fullscreened
            if (isFullScreen && priv.windowedVisibility !== Window.Hidden) {
                visibility = priv.windowedVisibility;
            }
        }
        isCallFullscreen = fullscreen;
    }

    property var data: QtObject {
        id: priv

        // Used to store the last windowed mode visibility
        property int windowedVisibility

        // Used to store the last windowed mode geometry
        property rect windowedGeometry

        // Cache of the fullscreen item's states (anchors.fill, parent)
        property var fullscreenItemStateObject: QtObject {
            property Item item
            property Item parent
            property var anchorsFill
        }

        // Listen for hangup to exit call fullscreen
        property var data: Connections {
            target: CallAdapter
            function onHasCallChanged() {
                if (!CallAdapter.hasCall && isCallFullscreen) {
                    setCallFullscreen(false);
                }
            }
        }
    }
}
