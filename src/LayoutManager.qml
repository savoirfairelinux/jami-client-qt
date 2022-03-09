/*
 * Copyright (C) 2022 Savoir-faire Linux Inc.
 * Author: Andreas Traczyk <andreas.traczyk@savoirfairelinux.com>
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
        var geometry = Qt.rect(appWindow.x, appWindow.y,
                               appWindow.width, appWindow.height)
        AppSettingsManager.setValue(Settings.WindowGeometry, geometry)

        // If closed-to-tray or minimized, save the cached windowedVisibility
        // value instead.
        if (isHidden) {
            AppSettingsManager.setValue(Settings.WindowState, priv.windowedVisibility)
        } else {
            AppSettingsManager.setValue(Settings.WindowState, visibility)
        }
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
    function pushFullScreenItem(item, originalParent, pushedCb, removedCb) {
        if (item === null || item === undefined
                || priv.fullScreenItems.length >= 3) {
            return
        }

        // Make sure our window is in fullscreen mode.
        priv.requestWindowModeChange(true)

        // Add the item to our list and reparent it to appContainer.
        priv.fullScreenItems.push({
                                 "item": item,
                                 "originalParent": originalParent,
                                 "removedCb": removedCb
                             })
        item.parent = appContainer
        if (pushedCb) {
            pushedCb()
        }

        // Reevaluate isCallFullscreen.
        priv.fullScreenItemsChanged()
    }

    // Remove an item if specified, or by default, the top item. Automatically
    // resets the main window to windowed mode if no items remain in the stack.
    function popFullScreenItem(obj=null) {
        // Remove the item and reparent it to its original parent.
        if (obj === null) {
            obj = priv.fullScreenItems.pop()
        } else {
            const index = priv.fullScreenItems.indexOf(obj);
            if (index > -1) {
                priv.fullScreenItems.splice(index, 1);
            }
        }
        if (obj !== undefined) {
            if (obj.item !== appWindow) {
                obj.item.parent = obj.originalParent
                if (obj.removedCb) {
                    obj.removedCb()
                }
            }

            // Reevaluate isCallFullscreen.
            priv.fullScreenItemsChanged()
        }

        // Only leave fullscreen mode if our window isn't in fullscreen
        // mode already.
        if (priv.fullScreenItems.length === 0) {
            // Simply recall the last visibility state.
            visibility = priv.windowedVisibility
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

        // An stack of items that are fullscreened.
        property variant fullScreenItems: []

        // When fullScreenItems is changed, we can recompute isCallFullscreen.
        onFullScreenItemsChanged: {
            isCallFullscreen = fullScreenItems
                .filter(o => o.item instanceof OngoingCallPage)
                .length
        }

        // Listen for a hangup combined with a fullscreen call state and
        // remove the OngoingCallPage component.
        property var data: Connections {
            target: CallAdapter
            function onHasCallChanged() {
                if (!CallAdapter.hasCall && isCallFullscreen) {
                    priv.fullScreenItems.forEach(o => {
                        if (o.item instanceof OngoingCallPage) {
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
                    // Save the previous visibility state.
                    windowedVisibility = visibility
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
