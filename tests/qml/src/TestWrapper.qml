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

    // A binding to the windowShown property
    Binding {
        tw.appWindow: uut.Window.window
        when: QTestRootObject.windowShown
    }

    property int visibility: 0
    Binding {
        tw.visibility: uut.Window.window.visibility
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
    // Used to manage dynamic view loading and unloading.
    property ViewManager viewManager: ViewManager {}
    // Used to manage the view stack and the current view.
    property ViewCoordinator viewCoordinator: ViewCoordinator {}
    property QtObject appWindow: QtObject {
        property bool useFrameless: false
    }
}
