/*
 * Copyright (C) 2020-2022 Savoir-faire Linux Inc.
 * Author: Mingrui Zhang <mingrui.zhang@savoirfairelinux.com>
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
    id: root
    color: JamiTheme.secondaryBackgroundColor

    ColumnLayout{

        spacing: 20
        anchors.fill:parent

        Rectangle {

            Layout.alignment: Qt.AlignCenter
            width: 630
            height: 263

            ResponsiveImage {
                id: welcomeLogo

                width: 212
                height: 244
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.rightMargin: 20
                opacity: 1

                source: JamiResources.welcome_illustration_2_svg

            }


            Rectangle {

                radius: 30
                color: JamiTheme.rectColor
                anchors.topMargin: 25
                anchors.fill: parent
                height: 243
                opacity:1


                ColumnLayout {

                    Label {
                        id: welcome

                        Layout.alignment: Qt.AlignLeft
                        Layout.preferredWidth: 180
                        Layout.preferredHeight: 36
                        Layout.bottomMargin: 5
                        font.pixelSize: 22
                        Layout.leftMargin: 40
                        Layout.topMargin: 26

                        wrapMode: Text.WordWrap
                        font.pointSize: JamiTheme.textFontSize + 1

                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter

                        text: "Welcome to Jami"
                        color: JamiTheme.textColor
                    }

                    Label {
                        id: identifierDescription

                        Layout.alignment: Qt.AlignLeft
                        Layout.leftMargin: 40
                        Layout.preferredWidth: 300
                        Layout.preferredHeight: 36
                        Layout.bottomMargin: 5
                        font.pixelSize: 13

                        wrapMode: Text.WordWrap
                        font.pointSize: JamiTheme.textFontSize + 1

                        text: "Here is your Jami identifier, don’t hesitate to share it in order to be contacted more easily! "
                        color: JamiTheme.textColor
                    }

                    JamiIdentifier {

                        id: identifier
                        editable: true

                    }

                }

            }

        }

    Label {

        text: JamiStrings.recommendationMessage
        font.bold: true
        Layout.alignment: Qt.AlignCenter
    }

    RowLayout{
        spacing: 17
        Layout.alignment: Qt.AlignCenter

        TipBox {

            id: lol

        }

        TipBox {

            tips_ : false


        }

        Rectangle {radius:20
            height: 100
            width:200


        }
    }



    MaterialButton {
        id: aboutJami
        tertiary: true

        Layout.alignment: Qt.AlignCenter
        Layout.bottomMargin: 10

        preferredWidth: JamiTheme.aboutButtonPreferredWidthth
        text: JamiStrings.aboutJami

        onClicked: aboutPopUpDialog.open()
    }



}


CustomBorder {
    commonBorder: false
    lBorderwidth: 1
    rBorderwidth: 0
    tBorderwidth: 0
    bBorderwidth: 0
    borderColor: JamiTheme.tabbarBorderColor
}
}
