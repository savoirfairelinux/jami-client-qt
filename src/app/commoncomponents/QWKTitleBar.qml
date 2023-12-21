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

import net.jami.Constants 1.1

import QWindowKit

Rectangle {
    id: control

    height: 32
    color: "transparent"
    Component.onCompleted: appWindowAgent.setTitleBar(this)

    Row {
        anchors {
            top: parent.top
            right: parent.right
        }
        height: parent.height

        QWKButton {
            id: minButton
            height: parent.height
            source: JamiResources.window_bar_minimize_svg
            onClicked: appWindow.showMinimized()
            Component.onCompleted: appWindowAgent.setSystemButton(WindowAgent.Minimize, minButton)
        }

        QWKButton {
            id: maxButton
            height: parent.height
            source: appWindow.visibility === Window.Maximized ?
                        JamiResources.window_bar_restore_svg :
                        JamiResources.window_bar_maximize_svg
            onClicked: appWindow.visibility === Window.Maximized ?
                           appWindow.showNormal() :
                           appWindow.showMaximized()
            Component.onCompleted: appWindowAgent.setSystemButton(WindowAgent.Maximize, maxButton)
        }

        QWKButton {
            id: closeButton
            height: parent.height
            source: JamiResources.window_bar_close_svg
            baseColor: "#e81123"
            onClicked: appWindow.close()
            Component.onCompleted: appWindowAgent.setSystemButton(WindowAgent.Close, closeButton)
        }
    }
}
