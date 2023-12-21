/*
 * Copyright (C) 2022-2024 Savoir-faire Linux Inc.
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

Page {
    id: root

    anchors.fill: parent

    property color color: "transparent"

    // QWK: Title bar spacing for macOS and single pane mode.
    // Not using topMargin here on purpose, to make is simple to
    // keep the theme coloring without wrapping components that
    // derive from SidePanelBase.
    header: Rectangle {
        id: titleBarSpacer
        height: {
            if (Qt.platform.os.toString() === "osx"
                    || viewCoordinator.isInSinglePaneMode) {
                return titleBar.height;
            }
            return 0;
        }
        color: root.color
    }

    background: Rectangle {
        color: root.color
    }

    // Override these if needed.
    property var select: function () {}
    property var deselect: function () {}

    signal indexSelected(int index)
    signal deselected
}
