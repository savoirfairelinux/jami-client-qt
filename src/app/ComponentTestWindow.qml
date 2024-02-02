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

import net.jami.Adapters 1.1

// A window into which we can load a QML file for testing.
ApplicationWindow {
    id: appWindow
    visible: true
    width: testWidth || loader.implicitWidth || 800
    height: testHeight || loader.implicitHeight || 600
    title: testComponentURI

    // WARNING: The following currently must be maintained in tandem with MainApplicationWindow.qml
    // Used to manage full screen mode and save/restore window geometry.
    property bool isRTL: UtilsAdapter.isRTL
    LayoutMirroring.enabled: isRTL
    LayoutMirroring.childrenInherit: isRTL
    // This needs to be set from the start.
    readonly property bool useFrameless: false
    LayoutManager {
        id: layoutManager
        appContainer: null
    }
    // Used to manage dynamic view loading and unloading.
    property ViewManager viewManager: ViewManager {}
    // Used to manage the view stack and the current view.
    property ViewCoordinator viewCoordinator: ViewCoordinator {}

    Loader {
        id: loader
        source: Qt.resolvedUrl(testComponentURI)
        onStatusChanged: {
            console.log("Status changed to:", loader.status)
            if (loader.status == Loader.Error || loader.status == Loader.Null) {
                console.error("Couldn't load component:", source)
                Qt.exit(1);
            } else if (loader.status == Loader.Ready) {
                console.info("Loaded component:", source);
                // If any of the dimensions are not set, set them to the appWindow's dimensions
                item.width = item.width || Qt.binding(() => appWindow.width);
                item.height = item.height || Qt.binding(() => appWindow.height);
            }
        }
    }

    // Closing this window should always exit the application.
    onClosing: Qt.quit()
}
