/*
 * Copyright (C) 2024-2026 Savoir-faire Linux Inc.
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
import QtQuick.Window
import QtTest

import net.jami.Adapters 1.1
import net.jami.Enums 1.1
import net.jami.Constants 1.1

import "../../../src/app/"

// Self-contained test harness for LayoutManager.
// Provides scope-chain symbols that LayoutManager resolves from the
// enclosing Window in production (visibility, showNormal, showFullScreen,
// appWindow, viewCoordinator, sysBtnsLoader).
Item {
    id: root
    width: 800
    height: 600

    // --- Scope-chain stubs for LayoutManager ---

    // Simulates Window.visibility.
    property int visibility: Window.Hidden

    // Simulates Window.showNormal() / showFullScreen().
    function showNormal() { root.visibility = Window.Windowed }
    function showFullScreen() { root.visibility = Window.FullScreen }

    // Mock appWindow (the Window id in MainApplicationWindow).
    QtObject {
        id: appWindow
        property bool useFrameless: false
        property real x: 100
        property real y: 200
        property real width: 800
        property real height: 600
        property real minimumWidth: 0
        property real minimumHeight: 0
        function hide() { root.visibility = Window.Hidden }
    }

    // Mock sysBtnsLoader referenced by qwkSystemButtonSpacing.
    QtObject { id: sysBtnsLoader; property real width: 120 }

    // Mock viewCoordinator referenced by qwkSystemButtonSpacing.
    QtObject { id: viewCoordinator; property bool isInSinglePaneMode: false }

    // Container for fullscreen-reparented items.
    Item {
        id: fullscreenContainer
        anchors.fill: parent
    }

    // --- Unit Under Test ---
    LayoutManager {
        id: uut
        appContainer: fullscreenContainer
    }

    // --- Test helper items for fullscreen stack operations ---
    Item { id: callItem; objectName: "callViewLoader"; width: 50; height: 50 }
    Item { id: otherItem; objectName: "otherTestItem"; width: 50; height: 50 }

    // ================================================================
    // Test: computed properties
    // ================================================================
    TestCase {
        name: "LayoutManager — computed properties"
        when: windowShown

        function test_isFullScreenReflectsVisibility() {
            root.visibility = Window.Windowed
            compare(uut.isFullScreen, false)
            root.visibility = Window.FullScreen
            compare(uut.isFullScreen, true)
        }

        function test_isHidden() {
            root.visibility = Window.Hidden
            verify(uut.isHidden, "Hidden → isHidden")
            root.visibility = Window.Minimized
            verify(uut.isHidden, "Minimized → isHidden")
            root.visibility = Window.Windowed
            verify(!uut.isHidden, "Windowed → !isHidden")
            root.visibility = Window.FullScreen
            verify(!uut.isHidden, "FullScreen → !isHidden")
        }
    }

    // ================================================================
    // Test: fullscreen item stack
    // ================================================================
    TestCase {
        name: "LayoutManager — fullscreen stack"
        when: windowShown

        function init() {
            root.visibility = Window.Windowed
            callItem.parent = root
            callItem.anchors.fill = undefined
            otherItem.parent = root
            otherItem.anchors.fill = undefined
        }

        function cleanup() {
            // Best-effort drain of the fullscreen stack.
            for (var i = 0; i < 5; i++)
                uut.popFullScreenItem()
            root.visibility = Window.Windowed
        }

        function test_pushEntersFullscreen() {
            uut.pushFullScreenItem(otherItem)
            compare(root.visibility, Window.FullScreen,
                    "Window should be fullscreen after push")
            compare(otherItem.parent, fullscreenContainer,
                    "Item should be reparented to appContainer")
        }

        function test_pushCallItemSetsFlag() {
            uut.pushFullScreenItem(callItem)
            verify(uut.isCallFullscreen,
                   "isCallFullscreen should be set for callViewLoader")
        }

        function test_popRestoresWindowed() {
            uut.pushFullScreenItem(otherItem)
            uut.popFullScreenItem()
            compare(root.visibility, Window.Windowed,
                    "Popping the last item should restore windowed mode")
            verify(!uut.isCallFullscreen)
        }

        function test_popRestoresParent() {
            var orig = otherItem.parent
            uut.pushFullScreenItem(otherItem)
            uut.popFullScreenItem()
            compare(otherItem.parent, orig,
                    "Popped item should return to its original parent")
        }

        function test_removeSpecificItem() {
            uut.pushFullScreenItem(callItem)
            uut.pushFullScreenItem(otherItem)
            verify(uut.isCallFullscreen)
            uut.removeFullScreenItem(callItem)
            verify(!uut.isCallFullscreen,
                    "Removing the call item should clear isCallFullscreen")
            // otherItem still on stack → fullscreen persists.
            compare(root.visibility, Window.FullScreen)
        }

        function test_pushNullIsNoop() {
            uut.pushFullScreenItem(null)
            compare(root.visibility, Window.Windowed,
                    "Pushing null should be a no-op")
        }

        function test_removedCallbackFires() {
            var fired = false
            uut.pushFullScreenItem(otherItem, function() { fired = true })
            uut.popFullScreenItem()
            verify(fired, "Removed callback should fire on pop")
        }

        function test_toggleFullScreen() {
            uut.toggleWindowFullScreen()
            compare(root.visibility, Window.FullScreen,
                    "First toggle should enter fullscreen")
            uut.toggleWindowFullScreen()
            compare(root.visibility, Window.Windowed,
                    "Second toggle should restore windowed")
        }
    }

    // ================================================================
    // Test: start-minimized / restore / close-to-tray
    // ================================================================
    TestCase {
        name: "LayoutManager — visibility transitions"
        when: windowShown

        function init() {
            for (var i = 0; i < 5; i++)
                uut.popFullScreenItem()
            root.visibility = Window.Windowed
        }

        function test_startMinimizedKeepsHidden() {
            // startMinimized should explicitly set visibility to Hidden,
            // even if the window was visible before.
            root.visibility = Window.Windowed
            uut.startMinimized(Window.Windowed)
            compare(root.visibility, Window.Hidden,
                    "Window should be hidden after startMinimized")
        }

        function test_restoreFromStartMinimized() {
            root.visibility = Window.Hidden
            uut.startMinimized(Window.Windowed)
            uut.restoreApp()
            compare(root.visibility, Window.Windowed,
                    "restoreApp should restore saved windowed visibility")
        }

        function test_restoreFromStartMinimizedMaximized() {
            root.visibility = Window.Hidden
            uut.startMinimized(Window.Maximized)
            uut.restoreApp()
            compare(root.visibility, Window.Maximized,
                    "restoreApp should restore Maximized if that was saved")
        }

        function test_restoreFromStartMinimizedFallback() {
            // If the saved visibility was Hidden, restoreApp should
            // fall back to showNormal().
            root.visibility = Window.Hidden
            uut.startMinimized(Window.Hidden)
            uut.restoreApp()
            compare(root.visibility, Window.Windowed,
                    "restoreApp should showNormal when cached state was Hidden")
        }

        function test_closeToTrayHides() {
            root.visibility = Window.Maximized
            uut.closeToTray()
            compare(root.visibility, Window.Hidden,
                    "closeToTray should hide the window")
        }

        function test_restoreFromCloseToTray() {
            root.visibility = Window.Maximized
            uut.closeToTray()
            uut.restoreApp()
            compare(root.visibility, Window.Maximized,
                    "restoreApp should restore pre-close-to-tray visibility")
        }

        function test_restoreNoopWhenVisible() {
            root.visibility = Window.Windowed
            uut.restoreApp()
            compare(root.visibility, Window.Windowed,
                    "restoreApp on a visible window should be a no-op")
        }
    }

    // ================================================================
    // Test: save and restore window settings
    // ================================================================
    TestCase {
        name: "LayoutManager — save/restore settings"
        when: windowShown

        function init() {
            for (var i = 0; i < 5; i++)
                uut.popFullScreenItem()
            root.visibility = Window.Windowed
            appWindow.x = 100; appWindow.y = 200
            appWindow.width = 800; appWindow.height = 600
        }

        function test_roundTripWindowedState() {
            uut.saveWindowSettings()
            root.visibility = Window.Hidden
            uut.restoreWindowSettings()
            compare(root.visibility, Window.Windowed,
                    "Restored visibility should match saved Windowed state")
        }

        function test_roundTripMaximized() {
            root.visibility = Window.Maximized
            uut.saveWindowSettings()
            root.visibility = Window.Hidden
            uut.restoreWindowSettings()
            compare(root.visibility, Window.Maximized,
                    "Restored visibility should match saved Maximized state")
        }

        function test_savedHiddenClampedToWindowed() {
            // If somehow Hidden was persisted, it should be clamped to Windowed.
            AppSettingsManager.setValue(Settings.WindowState, Window.Hidden)
            uut.restoreWindowSettings()
            compare(root.visibility, Window.Windowed,
                    "Hidden should be clamped to Windowed on restore")
        }

        function test_savedFullScreenClampedToWindowed() {
            AppSettingsManager.setValue(Settings.WindowState, Window.FullScreen)
            uut.restoreWindowSettings()
            compare(root.visibility, Window.Windowed,
                    "FullScreen should be clamped to Windowed on restore")
        }

        function test_savedMinimizedClampedToWindowed() {
            AppSettingsManager.setValue(Settings.WindowState, Window.Minimized)
            uut.restoreWindowSettings()
            compare(root.visibility, Window.Windowed,
                    "Minimized should be clamped to Windowed on restore")
        }

        function test_savedInvalidClampedToWindowed() {
            // NaN / empty / garbage from first run or corruption.
            AppSettingsManager.setValue(Settings.WindowState, "")
            uut.restoreWindowSettings()
            compare(root.visibility, Window.Windowed,
                    "Invalid (NaN) should be clamped to Windowed on restore")
        }

        function test_saveWhileHiddenUsesCachedVisibility() {
            // Go windowed, close to tray, then save.
            root.visibility = Window.Windowed
            uut.closeToTray()
            compare(root.visibility, Window.Hidden)
            uut.saveWindowSettings()
            // Restore should get Windowed back.
            uut.restoreWindowSettings()
            compare(root.visibility, Window.Windowed,
                    "Save while hidden should persist the cached windowed visibility")
        }
    }
}
