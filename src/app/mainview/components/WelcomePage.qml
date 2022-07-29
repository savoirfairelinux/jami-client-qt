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
import Qt.labs.lottieqt

import "../../commoncomponents"

Rectangle {

    id: root
    color: JamiTheme.secondaryBackgroundColor

    MaterialButton {

        id: aboutJami
        tertiary: true

        anchors.bottom: root.bottom
        anchors.horizontalCenter: root.horizontalCenter
        anchors.bottomMargin: 10
        preferredWidth: JamiTheme.aboutButtonPreferredWidthth
        text: JamiStrings.aboutJami

        onClicked: aboutPopUpDialog.open()
    }

    ColumnLayout{

        anchors.centerIn: parent

        //        anchors.topMargin: 20
        //        anchors.centerIn: parent

        //                LottieAnimation {

        //                 Layout.alignment: Qt.AlignTop | Qt.AlignRight
        //                 source: JamiResources.notification_bell_outline_edited_json
        //                 autoPlay: true
        //                 width: 5
        //                 height:5
        //                 loops: Animation.Infinite

        //                }

        Item {

            Layout.alignment: Qt.AlignCenter


            width: 630
            height: 263

            ResponsiveImage {
                id: welcomeLogo

                visible: root.width > 630

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
                anchors.horizontalCenter: parent.horizontalCenter
                width: welcomeLogo.visible ? 630 : Math.min(350, root.width - 2* JamiTheme.preferredMarginSize)
                height: 243
                opacity:1

                Behavior on width {
                    NumberAnimation { duration: JamiTheme.shortFadeDuration }
                }

                ColumnLayout {

                    Label {
                        id: welcome

                        Layout.alignment: Qt.AlignLeft
                        Layout.preferredWidth: 180
                        Layout.preferredHeight: 36
                        Layout.bottomMargin: 5
                        font.pixelSize: JamiTheme.bigFontSize
                        Layout.leftMargin: 40
                        Layout.topMargin: 26

                        wrapMode: Text.WordWrap
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter

                        text: JamiStrings.welcomeToJami
                        color: JamiTheme.textColor
                    }

                    Label {
                        id: identifierDescription

                        Layout.alignment: Qt.AlignLeft
                        Layout.leftMargin: 40
                        Layout.preferredWidth: 300
                        Layout.preferredHeight: 36
                        Layout.bottomMargin: 5
                        font.pixelSize: JamiTheme.headerFontSize

                        wrapMode: Text.WordWrap

                        text: JamiStrings.hereIsIdentifier
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
            Layout.topMargin: 25
            color: JamiTheme.textColor
            font.pixelSize: JamiTheme.tipBoxTitleFontSize
        }

        RowLayout {
            spacing: 17
            Layout.alignment: Qt.AlignCenter
            Layout.topMargin: 10
            Layout.bottomMargin: 50

            TipBox {
                id: firstTipBox

                tips_ : false

            }

            TipBox {


            }

            TipBox {


            }

        }

        Label {


            text: JamiStrings.noRecommendations
            color: "#002B4A"
            visible: false
            Layout.alignment: Qt.AlignCenter
            Layout.topMargin: 10

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
