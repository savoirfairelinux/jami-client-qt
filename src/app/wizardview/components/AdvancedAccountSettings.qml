/*
 * Copyright (C) 2022-2023 Savoir-faire Linux Inc.
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
    signal saveButtonClicked

    property bool openedPassword: false
    property bool openedNickname: false
    property string validatedPassword: ""
    property string alias: ""

    color: JamiTheme.secondaryBackgroundColor
    opacity: 0.93

    function clear() {
        openedPassword = false
        openedNickname = false
        //displayNameLineEdit.text = ""
        passwordEdit.dynamicText = ""
        passwordConfirmEdit.dynamicText = ""
        UtilsAdapter.setTempCreationImageFromString()
    }


    JamiFlickable {
        id: scrollView

        MouseArea {
            anchors.fill: parent

            onClicked: {
                openedPassword = false
                openedNickname = false
            }
        }

        property ScrollBar vScrollBar: ScrollBar.vertical

        anchors.fill: parent

        contentHeight: settings.implicitHeight + 2 * JamiTheme.preferredMarginSize

        ColumnLayout {
            id: settings
            width: Math.min(500, root.width - 2 * JamiTheme.preferredMarginSize)
            anchors.horizontalCenter: parent.horizontalCenter

            Label {
                Layout.alignment: Qt.AlignTop | Qt.AlignHCenter
                Layout.margins: 50
                text: JamiStrings.advancedAccountSettings
                color: JamiTheme.textColor
                font.pixelSize: JamiTheme.bigFontSize
            }

            ColumnLayout {
                spacing: 30
                Layout.preferredWidth: parent.width
                Layout.preferredHeight: implicitHeight
                Layout.alignment: Qt.AlignCenter

                Item {

                    Layout.alignment: Qt.AlignTop

                    Layout.preferredWidth: {
                        if (root.openedPassword)
                            return Math.min(settings.width, JamiTheme.passwordEditOpenedBoxWidth)
                        if (root.openedNickname)
                            return Math.min(settings.width, cornerIcon1.width)
                        return Math.min(settings.width, JamiTheme.passwordEditClosedBoxWidth)
                    }

                    Layout.preferredHeight: {
                        if (root.openedPassword)
                            return passwordColumnLayout.implicitHeight
                        return Math.max(cornerIcon1.height, labelEncrypt.height)
                    }


                    Behavior on Layout.preferredWidth {
                        NumberAnimation { duration: 100 }
                    }
                    Behavior on Layout.preferredHeight {
                        NumberAnimation { duration: 100 }
                    }

                    DropShadow {
                        z: -1
                        visible: openedPassword
                        width: parent.width
                        height: parent.height
                        horizontalOffset: 3.0
                        verticalOffset: 3.0
                        radius: 16
                        color: Qt.rgba(0, 0.34,0.6,0.16)
                        source: bg
                        transparentBorder: true
                    }

                    Rectangle {
                        id: bg
                        radius: JamiTheme.formsRadius
                        border.color: openedPassword? JamiTheme.transparentColor : JamiTheme.lightBlue_
                        layer.enabled: true
                        color: JamiTheme.secondaryBackgroundColor
                        anchors.fill: parent

                        Rectangle {

                            layer.enabled: true
                            height: parent.height /2
                            width: parent.width /2
                            anchors.bottom: parent.bottom
                            anchors.left: parent.left
                            border.color: openedPassword? JamiTheme.transparentColor : JamiTheme.lightBlue_
                            color: JamiTheme.secondaryBackgroundColor

                            Rectangle {

                                height:  parent.height +1
                                width: parent.width +1
                                anchors.bottom: parent.bottom
                                anchors.left: parent.left
                                anchors.margins: 1
                                border.color: openedPassword? JamiTheme.transparentColor : JamiTheme.secondaryBackgroundColor
                                color: JamiTheme.secondaryBackgroundColor

                            }
                        }

                        ColumnLayout {
                            id: passwordColumnLayout
                            anchors.fill: parent

                            Text {
                                visible: openedPassword
                                elide: Text.ElideRight

                                text: JamiStrings.encryptAccount
                                font.pixelSize: JamiTheme.creditsTextSize
                                font.weight: Font.Medium
                                Layout.fillWidth: true
                                Layout.leftMargin: 35
                                Layout.topMargin: 25
                                color: JamiTheme.textColor

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
                                font.pixelSize: JamiTheme.headerFontSize
                            }

                            PasswordTextEdit {

                                id: passwordEdit

                                visible: openedPassword
                                focus: openedPassword
                                firstEntry: true
                                placeholderText: JamiStrings.password
                                Layout.topMargin: 10
                                Layout.alignment: Qt.AlignCenter
                                Layout.preferredWidth: 325

                                KeyNavigation.tab: passwordConfirmEdit
                                KeyNavigation.down: passwordConfirmEdit
                            }

                            PasswordTextEdit {

                                id: passwordConfirmEdit
                                visible: openedPassword
                                placeholderText: JamiStrings.confirmPassword
                                Layout.alignment: Qt.AlignCenter
                                Layout.preferredWidth: 325

                                KeyNavigation.tab: passwordEdit
                                KeyNavigation.up: passwordEdit
                                KeyNavigation.down: setButton
                            }

                            MaterialButton {

                                id: setButton

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
                                                                    return (passwordEdit.dynamicText === passwordConfirmEdit.dynamicText
                                                                            && passwordEdit.dynamicText.length !== 0)
                                                                }

                                                                onClicked: {
                                                                    root.validatedPassword = passwordConfirmEdit.dynamicText
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
                                font.pixelSize: JamiTheme.headerFontSize
                            }

                            RowLayout {

                                Layout.alignment: Qt.AlignLeft
                                Layout.preferredWidth: parent.width

                                Rectangle {

                                    id: cornerIcon1
                                    layer.enabled: true

                                    radius: JamiTheme.formsRadius
                                    height: JamiTheme.cornerIconSize
                                    width: JamiTheme.cornerIconSize

                                    color: openedPassword  ? JamiTheme.lightBlue_ : JamiTheme.transparentColor
                                    Layout.alignment: Qt.AlignBottom | Qt.AlignLeft
                                    Layout.leftMargin:  openedPassword ? 2 : openedNickname ? 0 : 20
                                    Layout.bottomMargin: openedPassword ? 2 : 0

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
                                    id: labelEncrypt
                                    visible: !openedPassword && !openedNickname
                                    Layout.fillWidth: true

                                    text: JamiStrings.encryptAccount
                                    elide: Text.ElideRight
                                    color: JamiTheme.textColor
                                    font.pixelSize: JamiTheme.creditsTextSize

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
                }


                Item {
                    Layout.alignment: Qt.AlignRight | Qt.AlignTop

                    Layout.preferredWidth: {
                        if (openedNickname)
                            return Math.min(settings.width, JamiTheme.customNicknameOpenedBoxWidth)
                        if (openedPassword)
                            return Math.min(settings.width, cornerIcon1.width)
                        return Math.min(settings.width, JamiTheme.customNicknameClosedBoxWidth)
                    }

                    Layout.preferredHeight: {
                        if (openedNickname)
                            return customColumnLayout.implicitHeight
                        return Math.max(cornerIcon2.height, labelCustomize.height)
                    }

                    Behavior on Layout.preferredWidth {
                        NumberAnimation { duration: 100 }
                    }

                    Behavior on Layout.preferredHeight {
                        NumberAnimation { duration: 100 }
                    }

                    DropShadow {
                        z: -1
                        visible: openedNickname
                        width: parent.width
                        height: parent.height
                        horizontalOffset: 3.0
                        verticalOffset: 3.0
                        radius: 16
                        color: Qt.rgba(0, 0.34,0.6,0.16)
                        source: bg2
                        transparentBorder: true
                    }

                    Rectangle {
                        id: bg2

                        radius: JamiTheme.formsRadius
                        border.color: openedNickname ? JamiTheme.transparentColor : JamiTheme.lightBlue_
                        layer.enabled: true
                        color: JamiTheme.secondaryBackgroundColor
                        anchors.fill: parent

                        Rectangle {

                            height: parent.height /2
                            width: parent.width /2
                            anchors.bottom: parent.bottom
                            anchors.right: parent.right
                            border.color: openedNickname ? JamiTheme.transparentColor : JamiTheme.lightBlue_
                            color: JamiTheme.secondaryBackgroundColor
                            layer.enabled: true

                            Rectangle {

                                height: parent.height +1
                                width: parent.width +1
                                opacity: 1
                                anchors.bottom: parent.bottom
                                anchors.right: parent.right
                                anchors.margins: 1
                                border.color: openedNickname ? JamiTheme.transparentColor : JamiTheme.secondaryBackgroundColor
                                color: JamiTheme.secondaryBackgroundColor

                            }

                        }

                        ColumnLayout {

                            id: customColumnLayout
                            anchors.fill: parent

                            Text {

                                visible: openedNickname
                                text: JamiStrings.customizeProfile
                                elide: Text.ElideRight
                                font.weight: Font.Medium
                                Layout.topMargin: 25
                                Layout.leftMargin: 35
                                font.pixelSize: JamiTheme.creditsTextSize
                                color: JamiTheme.textColor
                                Layout.fillWidth: true
                            }

                            PhotoboothView {

                                id: currentAccountAvatar
                                width: avatarSize
                                height: avatarSize
                                darkTheme: UtilsAdapter.luma(JamiTheme.primaryBackgroundColor)
                                visible: openedNickname

                                Layout.alignment: Qt.AlignCenter
                                Layout.topMargin: 10

                                newItem: true
                                imageId: visible? "temp" : ""
                                avatarSize: 80
                                buttonSize: JamiTheme.smartListAvatarSize

                            }

                            ModalTextEdit {

                                id: displayNameLineEdit
                                visible: openedNickname
                                focus: openedNickname
                                Layout.alignment: Qt.AlignCenter
                                Layout.preferredWidth: 280

                                placeholderText: JamiStrings.enterNickname

                                onAccepted: root.alias = displayNameLineEdit.dynamicText

                            }

                            Text {

                                visible: openedNickname

                                Layout.topMargin: 20

                                Layout.preferredWidth: 360
                                Layout.alignment: Qt.AlignCenter
                                wrapMode: Text.WordWrap
                                color: JamiTheme.textColor

                                text: JamiStrings.customizeProfileDescription
                                font.pixelSize: JamiTheme.headerFontSize
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
                                    id: labelCustomize
                                    visible: !openedNickname && !openedPassword

                                    color: JamiTheme.textColor
                                    text: JamiStrings.customizeProfile
                                    font.pixelSize: JamiTheme.creditsTextSize
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight

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

                MaterialButton {
                    id: showAdvancedButton

                    tertiary: true
                    secHoveredColor: JamiTheme.secAndTertiHoveredBackgroundColor

                    Layout.alignment: Qt.AlignHCenter | Qt.AlignBottom
                    Layout.bottomMargin: JamiTheme.wizardViewPageBackButtonMargins

                    preferredWidth: Math.min(JamiTheme.wizardButtonWidth, root.width - JamiTheme.preferredMarginSize * 2)
                    text: JamiStrings.optionSave

                    onClicked: { root.saveButtonClicked()
                        root.alias = displayNameLineEdit.dynamicText}
                }
            }

        }
    }

}
