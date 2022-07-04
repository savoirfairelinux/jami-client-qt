/*
 * Copyright (C) 2020-2022 Savoir-faire Linux Inc.
 * Author: Fadi Shehadeh <fadi.shehadeh@savoirfairelinux.com>
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

import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1

import "../../commoncomponents"

Rectangle {

    property bool tips_ : true
    property bool hovered: false

    id: root
    width: 200
    height: 105

    border.color: JamiTheme.rectColor
    radius: 20

    ColumnLayout {

        RowLayout {

            Layout.topMargin: 20
            Layout.leftMargin: 20

            ResponsiveImage {
                id: icon

                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 26
                Layout.preferredHeight: 26

                containerHeight: Layout.preferredHeight
                containerWidth: Layout.preferredWidth

                source: tips_ ?  JamiResources.noun_paint_svg : JamiResources.glasses_tips_svg
                color: "#005699"
            }

            Label {

                text: tips_ ? "Customize" : " Tips"
                font.weight: Font.Medium
                Layout.alignment: Qt.AlignVCenter
                Layout.leftMargin: 10
                font.pixelSize: 13

            }

            //            PushButton {

            //            }



        }

        Text {

            Layout.preferredWidth: 170
            Layout.leftMargin: 20
            Layout.topMargin: 8
            font.pixelSize: 12
            wrapMode: Text.WordWrap
            text: tips_ ? "Add a picture and a nickname to complete your profile" : "Why should I save my account ?"
        }

    }

    MouseArea {

        id: mouseArea
        hoverEnabled: true

        onEntered: hovered = true
        onExited: hovered = false

        anchors.fill: root

    }

    states: [
        State {
            name: "clicked"; when: mouseArea.clicked
            PropertyChanges { target: root; height: 170 }
        },
        State {
            name: "hovered"; when: hovered
            PropertyChanges { target: root; border.color: "red" }
        }/*,
        State {
            name: "normal"; when: !hovered && !clicked
            PropertyChanges { target: background; color: normalColor }
        }*/

    ]

}



