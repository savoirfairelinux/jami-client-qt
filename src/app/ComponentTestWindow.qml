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
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick
import QtQuick.Controls

// A window into which we can load a QML file for testing.
ApplicationWindow {
    id: appWindow
    visible: true
    width: loader.width || 800
    height: loader.height || 600
    onWidthChanged: console.warn("Width changed to:", loader.width)
    onHeightChanged: console.warn("Height changed to:", loader.height)
    title: testComponentURI

    property ViewManager viewManager: ViewManager {}
    property ViewCoordinator viewCoordinator: ViewCoordinator {}

    Loader {
        id: loader
        source: Qt.resolvedUrl(testComponentURI)
        // Report size changes to the window
        onStatusChanged: {
            console.log("Status changed to:", loader.status)
            if (loader.status == Loader.Error || loader.status == Loader.Null) {
                console.error("Couldn't load component:", source)
                Qt.exit(1);
            } else if (loader.status == Loader.Ready) {
                console.info("Loaded component:", source)
            }
        }
    }
}
