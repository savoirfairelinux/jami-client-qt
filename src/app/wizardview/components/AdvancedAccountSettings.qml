/*
 * Copyright (C) 2022 Savoir-faire Linux Inc.
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

    property bool openedPassword: false
    property bool openedNickname: false
    property string validatedPassword: ""
    property string alias: ""

    color: JamiTheme.secondaryBackgroundColor
    opacity: 0.93

    MouseArea {

        anchors.fill: parent

        onClicked: {

            openedPassword = false
            openedNickname = false
        }

    }

    BackButton {

        anchors.top: parent.top
        anchors.left: parent.right
    }

    Label {

        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: 50
        text: JamiStrings.advancedAccountSettings
        color: JamiTheme.textColor
        font.pixelSize: 22
    }

    ColumnLayout {

        anchors.centerIn: parent
        width : parent.width
        spacing: 30

        Rectangle {

            radius: JamiTheme.formsRadius
            border.color: JamiTheme.lightBlue_
            Layout.leftMargin: 45
            layer.enabled: true
            color: JamiTheme.secondaryBackgroundColor

            Behavior on Layout.preferredWidth {
                NumberAnimation { duration: 100 }
            }
            Behavior on Layout.preferredHeight {
                NumberAnimation { duration: 100 }
            }

            Layout.preferredWidth: {

                if (openedPassword)
                    return JamiTheme.passwordEditOpenedBoxWidth
                if (openedNickname)
                    return cornerIcon1.width
                return JamiTheme.passwordEditClosedBoxWidth
            }

            Layout.preferredHeight: {

                if (openedPassword)
                    return JamiTheme.passwordEditOpenedBoxHeight
                if (openedNickname)
                    return cornerIcon1.height
                return JamiTheme.passwordEditClosedBoxHeight
            }

            Rectangle {

                layer.enabled: true
                height: parent.height /2
                width: parent.width /2
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                border.color: JamiTheme.lightBlue_
                color: JamiTheme.secondaryBackgroundColor

                Rectangle {

                    height:  parent.height +1
                    width: parent.width +1
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.margins: 1
                    border.color: JamiTheme.secondaryBackgroundColor
                    color: JamiTheme.secondaryBackgroundColor

                }

            }

            ColumnLayout {

                id: passwordColumnLayout
                anchors.fill: parent

                Text {

                    visible: openedPassword

                    text: JamiStrings.encryptAccount
                    font.pixelSize: 15
                    Layout.leftMargin: 35
                    Layout.topMargin: 25
                    color: JamiTheme.textColor
                    width: 100

                }

                Text {

                    visible: openedPassword
                    Layout.topMargin: 12
                    Layout.leftMargin: 35

                    Layout.preferredWidth: 360
                    Layout.alignment: Qt.AlignLeft
                    color: JamiTheme.textColor
                    wrapMode: Text.WordWrap

                    text: JamiStrings.encryptDescription
                    font.pixelSize: 13
                }

                EditableLineEdit {

                    id: passwordEdit

                    visible: openedPassword
                    Layout.alignment: Qt.AlignCenter
                    Layout.preferredWidth: 325
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter

                    fontSize: 15

                    echoMode: TextInput.Password

                    placeholderText: JamiStrings.password
                    secondIco: JamiResources.eye_cross_svg
                    onSecondIcoClicked: { toggleEchoMode() }


                }

                EditableLineEdit {

                    id: passwordConfirmEdit
                    visible: openedPassword

                    Layout.alignment: Qt.AlignCenter
                    Layout.preferredWidth: 325
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter

                    fontSize: 15

                    echoMode: TextInput.Password

                    placeholderText: JamiStrings.confirmPassword
                    secondIco: JamiResources.eye_cross_svg
                    onSecondIcoClicked: { toggleEchoMode() }

                }

                MaterialButton {

                    visible: openedPassword

                    Layout.topMargin: 10
                    Layout.alignment: Qt.AlignCenter
                    preferredWidth: JamiTheme.wizardButtonWidth / 2
                    text: JamiStrings.setPassword
                    primary: true

                    hoveredColor: checkEnable() ? JamiTheme.buttonTintedBlueHovered : JamiTheme.buttonTintedGreyInactive
                    pressedColor: checkEnable() ? JamiTheme.buttonTintedBluePressed : JamiTheme.buttonTintedGreyInactive

                    color: checkEnable() ? JamiTheme.buttonTintedBlue :
                                           JamiTheme.buttonTintedGreyInactive

                    enabled: checkEnable()

                    function checkEnable() {
                        text = JamiStrings.setPassword
                        return (passwordEdit.text === passwordConfirmEdit.text
                                && passwordEdit.text.length !== 0)
                    }

                    onClicked: {
                        root.validatedPassword = passwordConfirmEdit.text
                        text = JamiStrings.setPasswordSuccess
                    }

                }

                Text {

                    visible: openedPassword

                    Layout.topMargin: 15
                    Layout.leftMargin: 35

                    Layout.preferredWidth: 360
                    Layout.alignment: Qt.AlignCenter
                    color: JamiTheme.textColor
                    wrapMode: Text.WordWrap

                    text: JamiStrings.encryptWarning
                    font.pixelSize: 13
                }

                RowLayout {

                    Layout.alignment: Qt.AlignLeft
                    Layout.fillWidth: true

                    Rectangle {

                        id: cornerIcon1
                        layer.enabled: true

                        radius: JamiTheme.formsRadius
                        height: JamiTheme.cornerIconSize
                        width: JamiTheme.cornerIconSize

                        color: openedPassword  ? JamiTheme.lightBlue_ : JamiTheme.transparentColor
                        Layout.alignment: Qt.AlignBottom | Qt.AlignLeft
                        Layout.leftMargin:  openedPassword ? 2 : openedNickname ? 0 : 20
                        Layout.bottomMargin: openedPassword ? 1 : 0

                        Rectangle {

                            visible: openedPassword

                            height: cornerIcon1.height/2
                            width: cornerIcon1.width/2
                            anchors.left: cornerIcon1.left
                            anchors.bottom: cornerIcon1.bottom
                            color: JamiTheme.lightBlue_

                        }

                        ResponsiveImage  {

                            width: 18
                            height: 18
                            source: JamiResources.lock_svg
                            color: JamiTheme.tintedBlue
                            anchors.centerIn: cornerIcon1
                        }
                    }

                    Text {

                        visible: !openedPassword && !openedNickname

                        text: JamiStrings.encryptAccount
                        color: JamiTheme.textColor
                        font.pixelSize: 15
                        width: 100

                    }
                }
            }

            TapHandler {
                target: passwordColumnLayout
                onTapped: {
                    openedNickname = false
                    openedPassword = true
                }
            }
        }

        Rectangle {

            radius: JamiTheme.formsRadius
            border.color: JamiTheme.lightBlue_
            Layout.rightMargin: 45
            Layout.alignment: Qt.AlignRight
            layer.enabled: true
            color: JamiTheme.secondaryBackgroundColor

            Behavior on Layout.preferredWidth {
                NumberAnimation { duration: 100 }
            }

            Behavior on Layout.preferredHeight {
                NumberAnimation { duration: 100 }
            }

            Layout.preferredWidth: {

                if (openedNickname)
                    return JamiTheme.customNicknameOpenedBoxWidth
                if (openedPassword)
                    return cornerIcon1.width
                return JamiTheme.customNicknameClosedBoxWidth
            }

            Layout.preferredHeight: {

                if (openedNickname)
                    return JamiTheme.customNicknameOpenedBoxHeight
                if (openedPassword)
                    return cornerIcon1.height
                return JamiTheme.customNicknameClosedBoxHeight

            }

            Rectangle {

                height: parent.height /2
                width: parent.width /2
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                border.color: JamiTheme.lightBlue_
                color: JamiTheme.secondaryBackgroundColor
                layer.enabled: true

                Rectangle {

                    height: parent.height +1
                    width: parent.width +1
                    opacity: 1
                    anchors.bottom: parent.bottom
                    anchors.right: parent.right
                    anchors.margins: 1
                    border.color: JamiTheme.secondaryBackgroundColor
                    color: JamiTheme.secondaryBackgroundColor

                }

            }

            ColumnLayout {

                id: customColumnLayout
                anchors.fill: parent

                Label {

                    visible: openedNickname
                    text: JamiStrings.customizeProfile
                    Layout.topMargin: 25
                    Layout.leftMargin: 35
                    font.pixelSize: 15
                    color: JamiTheme.textColor
                    width: 100
                }

                PhotoboothView {

                    id: currentAccountAvatar
                    darkTheme: UtilsAdapter.luma(JamiTheme.primaryBackgroundColor)
                    visible: openedNickname

                    Layout.alignment: Qt.AlignCenter
                    Layout.topMargin: 10

                    newItem: true
                    imageId: visible? "temp" : ""
                    avatarSize: 80
                    buttonSize: JamiTheme.smartListAvatarSize

                }

                EditableLineEdit {

                    id: displayNameLineEdit

                    visible: openedNickname

                    Layout.alignment: Qt.AlignCenter
                    Layout.preferredWidth: 280
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter

                    fontSize: 15

                    placeholderText: JamiStrings.enterNickname

                    onEditingFinished: root.alias = text

                }

                Text {

                    visible: openedNickname

                    Layout.topMargin: 20

                    Layout.preferredWidth: 360
                    Layout.alignment: Qt.AlignCenter
                    wrapMode: Text.WordWrap
                    color: JamiTheme.textColor

                    text: JamiStrings.customizeProfileDescription
                    font.pixelSize: 13
                }

                RowLayout{

                    Layout.alignment: openedNickname ? Qt.AlignRight : Qt.AlignLeft
                    Layout.fillWidth: true

                    Rectangle {

                        id: cornerIcon2
                        layer.enabled: true

                        radius: JamiTheme.formsRadius
                        height: JamiTheme.cornerIconSize
                        width: JamiTheme.cornerIconSize

                        color: openedNickname  ? JamiTheme.lightBlue_ : JamiTheme.transparentColor
                        Layout.alignment: Qt.AlignBottom | Qt.AlignRight
                        Layout.leftMargin: openedPassword ? 0 : 20
                        Layout.rightMargin:  openedNickname? 2 : 0
                        Layout.bottomMargin: openedNickname ? 2 : 0

                        Rectangle {

                            visible: openedNickname

                            height: cornerIcon2.height/2
                            width: cornerIcon2.width/2
                            anchors.right: cornerIcon2.right
                            anchors.bottom: cornerIcon2.bottom
                            color: JamiTheme.lightBlue_

                        }

                        ResponsiveImage  {

                            width: 18
                            height: 18
                            source: JamiResources.noun_paint_svg
                            color: JamiTheme.tintedBlue
                            anchors.centerIn: cornerIcon2
                        }
                    }

                    Text {

                        visible: !openedNickname && !openedPassword

                        color: JamiTheme.textColor
                        text: JamiStrings.customizeProfile
                        font.pixelSize: 15

                    }
                }
            }

            TapHandler {
                target: customColumnLayout
                onTapped: {
                    openedNickname = true
                    openedPassword = false
                }
            }
        }
    }

}
