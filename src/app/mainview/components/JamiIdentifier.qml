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

    property bool editable: false

    id: root

    radius: 20
    Layout.bottomMargin: 36
    Layout.leftMargin: 36
    width: 296
    height: 91
    color: "white"

    ColumnLayout {
        anchors.fill: parent

        RowLayout {
            id: firstLine

            Layout.preferredWidth: parent.width
            Layout.alignment: Qt.AlignTop

            Rectangle {
                id: mainRectangle

                width: 97
                height: 40
                color: "#005699"
                radius: 20

                Label {
                    id: jamiIdLogo
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    text: "JamiId"

                }

                Rectangle {

                    id: rectForRadius
                    anchors.bottom: parent.bottom
                    width: 20
                    height: 20
                    color: "#005699"

                }
            }

            RowLayout {
                Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                Layout.fillWidth: true

                PushButton {
                    id: btnEdit

                    imageColor: "#005699"
                    normalColor: "transparent"
                    Layout.topMargin: 10
                    hoverEnabled: false
                    visible: editable

                    source: JamiResources.round_edit_24dp_svg

                    onClicked: { }
                }

                PushButton {
                    id: btnCopy

                    imageColor: "#005699"
                    normalColor: "transparent"
                    Layout.topMargin: 10

                    hoverEnabled: false

                    source: JamiResources.content_copy_24dp_svg

                    onClicked: { }
                }

                PushButton {
                    id: btnShare


                    imageColor: "#005699"
                    normalColor: "transparent"
                    Layout.topMargin: 10
                    hoverEnabled: false

                    source: JamiResources.share_24dp_svg

                    onClicked: { }
                }

            }
        }

        Text {
            id: jamiRegisteredNameText

            Layout.alignment: Qt.AlignBottom | Qt.AlignCenter
            Layout.bottomMargin: JamiTheme.preferredMarginSize

            font.pointSize: JamiTheme.textFontSize + 1

            text: CurrentAccount.bestId
            color: "black"
        }
    }

}

