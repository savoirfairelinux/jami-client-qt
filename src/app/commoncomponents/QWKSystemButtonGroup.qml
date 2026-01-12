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

import net.jami.Constants 1.1

import QWindowKit

Row {
    id: root

    property alias minButton: minButton
    property alias maxButton: maxButton
    property alias closeButton: closeButton

    component SystemButton : QWKButton {
        height: parent.height
    }

    visible: appWindow.visibility !== Window.FullScreen

    SystemButton {
        id: minButton
        Accessible.name: JamiStrings.minimize
        Accessible.role: Accessible.Button
        source: JamiResources.window_bar_minimize_svg
        onClicked: appWindow.showMinimized()
    }

    SystemButton {
        id: maxButton
        Accessible.name: JamiStrings.maximize
        Accessible.role: Accessible.Button
        source: appWindow.visibility === Window.Maximized ?
                    JamiResources.window_bar_restore_svg :
                    JamiResources.window_bar_maximize_svg
        onClicked: appWindow.visibility === Window.Maximized ?
                       appWindow.showNormal() :
                       appWindow.showMaximized()
    }

    SystemButton {
        id: closeButton
        Accessible.name: JamiStrings.closeApplication
        Accessible.role: Accessible.Button
        source: JamiResources.window_bar_close_svg
        baseColor: "#e81123"
        onClicked: appWindow.close()
    }
}
