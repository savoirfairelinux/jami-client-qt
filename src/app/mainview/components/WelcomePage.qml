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

    ColumnLayout{

        spacing: 20
        anchors.centerIn: parent

//        LottieAnimation {
//            //BUG https://bugreports.qt.io/browse/QTBUG-102550

//            Layout.alignment: Qt.AlignTop | Qt.AlignRight
//            source: JamiResources.notification_bell_outline_edited_json
//            autoPlay: true
//            width: 5
//            height:5
//            loops: Animation.Infinite

//        }

        Rectangle {

            Layout.alignment: Qt.AlignCenter
            color: JamiTheme.transparentColor

            width: 630
            height: 263

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
                        font.pixelSize: 13

                        wrapMode: Text.WordWrap
                        font.pointSize: JamiTheme.textFontSize + 1

                        text: JamiStrings.identifierDescription
                        color: JamiTheme.textColor
                    }

                    JamiIdentifier {

                        id: identifier
                        editable: true

                    }

                }

            }

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

        }

        Label {

            text: JamiStrings.recommendationMessage
            color: JamiTheme.welcomeText
            font.bold: true
            visible: false //Not visble for the moment
            Layout.alignment: Qt.AlignCenter
            Layout.topMargin: 10

        }

        RowLayout{
            spacing: 17
            Layout.alignment: Qt.AlignCenter
            Layout.topMargin: 10
            Layout.bottomMargin: 50

            TipBox {

                id: customization
            }

            TipBox {

                tips_ : false
            }

            TipBox {

                tips_ : false
            }


        }

        Label {

            text: JamiStrings.noRecommendations
            color: JamiTheme.welcomeText
            Layout.alignment: Qt.AlignCenter
            Layout.topMargin: 10
            visible: false //Not visible for the moment

        }
    }

    MaterialButton {

        id: aboutJami
        tertiary: true

        anchors.horizontalCenter: root.horizontalCenter
        anchors.bottom: root.bottom
        Layout.alignment: Qt.AlignCenter

        anchors.bottomMargin: 10
        preferredWidth: JamiTheme.aboutButtonPreferredWidth
        text: JamiStrings.aboutJami

        onClicked: aboutPopUpDialog.open()
    }



    //            Label {
    //                id: jamiShareWithFriendText

    //                Layout.alignment: Qt.AlignCenter
    //                Layout.preferredWidth: welcomePageColumnLayout.width
    //                Layout.preferredHeight: 50

    //                wrapMode: Text.WordWrap
    //                font.pointSize: JamiTheme.textFontSize

    //                horizontalAlignment: Text.AlignHCenter
    //                verticalAlignment: Text.AlignVCenter

    //                visible: LRCInstance.currentAccountType === Profile.Type.JAMI

    //                text: JamiStrings.shareInvite
    //                color: JamiTheme.faddedFontColor
    //            }

    //            Rectangle {
    //                id: jamiRegisteredNameRect

    //                Layout.alignment: Qt.AlignCenter
    //                Layout.preferredWidth: welcomePageColumnLayout.width
    //                Layout.preferredHeight: 65

    //                color: JamiTheme.secondaryBackgroundColor

    //                visible: LRCInstance.currentAccountType === Profile.Type.JAMI

    //                ColumnLayout {
    //                    id: jamiRegisteredNameRectColumnLayout

    //                    spacing: 0


    CustomBorder {
        commonBorder: false
        lBorderwidth: 1
        rBorderwidth: 0
        tBorderwidth: 0
        bBorderwidth: 0
        borderColor: JamiTheme.tabbarBorderColor
    }
}
