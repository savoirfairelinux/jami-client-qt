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
import QtQuick.Layouts
import QtQuick.Window
import QtTest

import net.jami.Adapters 1.1

import "../../../src/app/"

// The purpose of this component is to fake the ApplicationWindow and prevent
// each UUT from having to manage its own top level app management objects
// (currently ViewManager, ViewCoordinator, and ApplicationWindow).
Item {
    id: tw

    width: childrenRect.width
    height: childrenRect.height
    property var uut: children.length > 0 ? children[0] : null

    // This is a helper function to wait for a signal to be emitted and check a condition.
    function waitForSignalAndCheck(signalObject, signalName, action, checkExpression) {
        // Create the SignalSpy component dynamically with the provided signal object and name.
        const spy = Qt.createQmlObject('import QtTest 1.0; SignalSpy {}', this);
        spy.target = signalObject;
        spy.signalName = signalName;
        // Perform the action that should emit the signal.
        if (action)
            action();
        // Wait a maximum of 1 second for the signal to be emitted.
        spy.wait(1000);
        // Check the signal count and the provided expression.
        return spy.count > 0 && checkExpression();
    }

    // Default app window for headless/offscreen when uut.Window.window is null.
    property QtObject _defaultAppWindow: QtObject {
        property bool useFrameless: false
    }
    // A binding to the windowShown property. Never set appWindow to null (e.g. offscreen).
    Binding {
        tw.appWindow: (QTestRootObject.windowShown && uut && uut.Window.window) ? uut.Window.window : _defaultAppWindow
        when: QTestRootObject.windowShown
    }

    property int visibility: 0
    Binding {
        tw.visibility: (uut && uut.Window.window) ? uut.Window.window.visibility : Window.Windowed
        when: QTestRootObject.windowShown
    }

    // WARNING: The following currently must be maintained in tandem with MainApplicationWindow.qml
    // Used to manage full screen mode and save/restore window geometry.
    property bool isRTL: UtilsAdapter.isRTL
    LayoutMirroring.enabled: isRTL
    LayoutMirroring.childrenInherit: isRTL
    property LayoutManager layoutManager: LayoutManager {
        appContainer: null
    }
    Item {
        id: testStackContainer
        anchors.fill: parent
    }
    // Used to manage dynamic view loading and unloading.
    property ViewManager viewManager: ViewManager {}
    // Used to manage the view stack and the current view.
    property ViewCoordinator viewCoordinator: ViewCoordinator {
        isTestContext: true
        viewManager: tw.viewManager
        appContext: tw.appContext
    }
    property QtObject appWindow: _defaultAppWindow
    readonly property var _appContextWindow: tw.appWindow
    property QtObject appContext: QtObject {
        property var appWindow: tw._appContextWindow
        property ViewManager viewManager: tw.viewManager
        property ViewCoordinator viewCoordinator: tw.viewCoordinator
        property LayoutManager layoutManager: tw.layoutManager
        readonly property bool useFrameless: !!(tw.appWindow && tw.appWindow.useFrameless)
        readonly property bool isInSinglePaneMode: tw.viewCoordinator.isInSinglePaneMode
        readonly property string currentViewName: tw.viewCoordinator.currentViewName
    }

    Component.onCompleted: {
        if (uut && uut.hasOwnProperty("appContext"))
            uut.appContext = appContext;
        viewCoordinator.init(testStackContainer);
    }
}
