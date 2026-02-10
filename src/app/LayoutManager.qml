/*
 * Copyright (C) 2022-2026 Savoir-faire Linux Inc.
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

    // Used to store if a CallStackView component is fullscreened.
    property bool isCallFullscreen: false

    // Used to store if a WebEngineView component is fullscreened.
    property bool isWebFullscreen: false

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
            appWindow.useFrameless && !isMacOS && !root.isFullscreen ? sysBtnsLoader.width : 0
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

        // Determine screen metrics from the primary screen.
        const screen = Qt.application.primaryScreen || (Qt.application.screens.length > 0 ? Qt.application.screens[0] : null)

        // Compute default dimensions relative to the screen, bounded by theme mins and sensible caps.
        const ratio = 1.618;
        const screenSizeMultiplier = 0.6;
        const defaultWidth = (function() {
            if (!screen)
                return JamiTheme.mainViewPreferredWidth;
            const maxWidth = Math.round(screen.width * screenSizeMultiplier);
            const maxHeight = Math.round(screen.height * screenSizeMultiplier);
            // If the max width would result in a height that's too tall, constrain by height instead
            if (maxWidth / ratio > maxHeight) {
                return Math.round(maxHeight * ratio);
            }
            return maxWidth;
        })();
        const defaultHeight = (function() {
            if (!screen)
                return JamiTheme.mainViewPreferredHeight;
            const maxWidth = Math.round(screen.width * screenSizeMultiplier);
            const maxHeight = Math.round(screen.height * screenSizeMultiplier);
            // If the max height would result in a width that's too wide, constrain by width instead
            if (maxHeight * ratio > maxWidth) {
                return Math.round(maxWidth / ratio);
            }
            return maxHeight;
        })();

        // Dimensions.
        const widthToUse = geometry.width && geometry.width > 0 ? geometry.width : defaultWidth
        const heightToUse = geometry.height && geometry.height > 0 ? geometry.height : defaultHeight
        appWindow.width = widthToUse
        appWindow.height = heightToUse
        appWindow.minimumWidth = JamiTheme.mainViewMinWidth
        appWindow.minimumHeight = JamiTheme.mainViewMinHeight

        // Position.
        if (!isNaN(geometry.x) && !isNaN(geometry.y)) {
            appWindow.x = geometry.x
            appWindow.y = geometry.y
        } else if (screen) {
            // No saved position: center on the primary screen.
            appWindow.x = Math.round(screen.width / 2 - appWindow.width / 2)
            appWindow.y = Math.round(screen.height / 2 - appWindow.height / 2)
        }

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

    // Adds an item to the fullscreen item stack. Automatically puts
    // the main window in fullscreen mode if needed. Callbacks should be used
    // to perform component-specific tasks upon successful transitions.
    function pushFullScreenItem(item, removedCb=undefined) {
        if (!item || priv.fullScreenItems.length >= 3) {
            return
        }

        // Make sure our window is in fullscreen mode.
        priv.requestWindowModeChange(true)

        // Add the item to our list and reparent it to appContainer.
        priv.fullScreenItems.push({
                                 "item": item,
                                 "prevParent": item.parent,
                                 "prevAnchorsFill": item.anchors.fill,
                                 "removedCb": removedCb
                             })

        item.parent = appContainer
        item.anchors.fill = appContainer

        // Reevaluate isCallFullscreen.
        priv.fullScreenItemsChanged()
    }

    // Remove an item if specified, or by default, the top item. Automatically
    // resets the main window to windowed mode if no items remain in the stack.
    function popFullScreenItem(obj = undefined) {
        // Remove the item and reparent it to its original parent.
        if (obj === undefined) {
            obj = priv.fullScreenItems.pop();
        } else {
            const index = priv.fullScreenItems.indexOf(obj);
            if (index > -1) {
                priv.fullScreenItems.splice(index, 1);
            }
        }
        if (obj && typeof obj === 'object') {
            if (obj.item !== appWindow) {
                // Clear anchors first, then set parent, then reset anchors.
                obj.item.anchors.fill = undefined;
                obj.item.parent = obj.prevParent;
                obj.item.anchors.fill = obj.prevAnchorsFill;

                // Call removed callback if it's a function.
                if (typeof obj.removedCb === 'function') {
                    obj.removedCb();
                }
            }

            // Reevaluate isCallFullscreen.
            priv.fullScreenItemsChanged();
        }

        // Only leave fullscreen mode if our window isn't in fullscreen mode already.
        if (priv.fullScreenItems.length === 0 && priv.windowedVisibility !== Window.Hidden) {
            // Simply recall the last visibility state.
            visibility = priv.windowedVisibility;
        }
    }

    // Used to filter removal for a specific item.
    function removeFullScreenItem(item) {
        priv.fullScreenItems.forEach(o => {
            if (o.item === item) {
                popFullScreenItem(o)
                return
            }
        });
    }

    // Toggle the application window in fullscreen mode.
    function toggleWindowFullScreen() {
        priv.requestWindowModeChange(!isFullScreen)

        // If we succeeded, place a dummy item onto the stack as
        // a state indicator to prevent returning to windowed mode
        // when popping an item on top. The corresponding pop will
        // be made within requestWindowModeChange.
        if (isFullScreen) {
            priv.fullScreenItems.push({ "item": appWindow })
        }
    }

    property var data: QtObject {
        id: priv

        // Used to store the last windowed mode visibility.
        property int windowedVisibility

        // Used to store the last windowed mode geometry.
        property rect windowedGeometry

        // An stack of items that are fullscreened.
        property variant fullScreenItems: []

        // When fullScreenItems is changed, we can recompute isCallFullscreen.
        onFullScreenItemsChanged: {
            isCallFullscreen = fullScreenItems
                .filter(o => o.item.objectName === "callViewLoader")
                .length
            isWebFullscreen = WITH_WEBENGINE ? fullScreenItems
                .filter(o => o.item && (
                    o.item.objectName === JamiQmlUtils.webEngineNames.mediaPreview ||
                    o.item.objectName === JamiQmlUtils.webEngineNames.videoPreview ||
                    o.item.objectName === JamiQmlUtils.webEngineNames.map ||
                    o.item.objectName === JamiQmlUtils.webEngineNames.general ||
                    o.item.objectName === JamiQmlUtils.webEngineNames.emojiPicker
                ))
                .length : 0
        }

        // Listen for an "end" call combined with a fullscreen call state and
        // remove the OngoingCallPage component.
        property var data: Connections {
            target: CallAdapter
            function onHasCallChanged() {
                if (!CallAdapter.hasCall && isCallFullscreen) {
                    priv.fullScreenItems.forEach(o => {
                        if (o.item.objectName === "callViewLoader") {
                            popFullScreenItem(o)
                            return
                        }
                    });
                }
            }
        }

        // Used internally to switch modes.
        function requestWindowModeChange(fullScreen) {
            if (fullScreen) {
                if (!isFullScreen) {
                    // Save the previous visibility state and geometry.
                    windowedVisibility = visibility
                    windowedGeometry = Qt.rect(appWindow.x, appWindow.y,
                                               appWindow.width, appWindow.height)
                    showFullScreen()
                }
            } else {
                // Clear the stack.
                while (fullScreenItems.length) {
                    popFullScreenItem()
                }
            }
        }
    }
}
