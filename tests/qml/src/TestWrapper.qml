/*
 * Copyright (C) 2024 Savoir-faire Linux Inc.
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

import "../../../src/app/"

// The purpose of this component is to fake the ApplicationWindow and prevent
// each UUT from having to manage its own top level app management objects
// (currently ViewManager, ViewCoordinator, and ApplicationWindow).
Item {
    // This will be our UUT.
    required default property var uut

    // These are our fake app management objects. The caveat is that they
    // must be maintained in sync with the actual objects in the app for now.
    // The benefit, is that this should be the single place where we need to
    // sync them.
    property ViewManager viewManager: ViewManager {}
    property ViewCoordinator viewCoordinator: ViewCoordinator {}
    property ApplicationWindow appWindow: ApplicationWindow {
        property bool useFrameless: false
    }
}
