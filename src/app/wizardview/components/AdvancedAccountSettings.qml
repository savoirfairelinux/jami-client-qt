/*
 * Copyright (C) 2021-2022 Savoir-faire Linux Inc.
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
import QtQuick.Layouts
import QtQuick.Controls

import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import Qt5Compat.GraphicalEffects


import "../../commoncomponents"

Rectangle {

    id: root

    property bool opened : false

    color: "transparent"
    opacity: 0.93


    BackButton {

        anchors.top: parent.top
        anchors.left: parent.left

    }

    BackButton {

        anchors.top: parent.top
        anchors.right: parent.right
    }

    Label {

        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: 50
        text: JamiStrings.advancedAccountSettings
        font.pixelSize: 22
    }





    ColumnLayout {

        anchors.centerIn: parent
        width : parent.width
        spacing: 30

        Rectangle {

            radius: 30
            border.color: "black"
            Layout.preferredWidth: 330
            Layout.preferredHeight: 65
            Layout.leftMargin: 45


            RowLayout {

                anchors.centerIn: parent

                ResponsiveImage  {

                    width: 18
                    height: 18
                    source: JamiResources.round_edit_24dp_svg

                }

                Text {
                    text: JamiStrings.encryptAccount
                    font.pixelSize: 15

                }

            }

        }

        Rectangle {

            Layout.preferredWidth: 230
            Layout.preferredHeight: 65
            Layout.rightMargin: 45
            Layout.alignment: Qt.AlignRight
            border.color: "black"
            radius: 30

            RowLayout{

                anchors.centerIn: parent

                ResponsiveImage  {

                    width: 18
                    height: 18
                    source: JamiResources.round_edit_24dp_svg

                }

                Text {

                    text: JamiStrings.customizeProfile
                    font.pixelSize: 15

                }

            }
        }
    }


    TapHandler {
        target: rect
        onTapped: {
            opened = !opened
        }
    }
}


