/*
 * Copyright (C) 2022-2024 Savoir-faire Linux Inc.
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
    property bool icon1Hovered: false
    property bool icon2Hovered: false

    onActiveFocusChanged: {
        if (activeFocus) {
            openedPassword = false;
            openedNickname = false;
            forcePasswordActiveFocus();
        }
    }

    function forcePasswordActiveFocus() {
        openedPassword = true;
        passwordEdit.forceActiveFocus();
    }

    function forceProfileActiveFocus() {
        openedPassword = false;
        openedNickname = true;
        displayNameLineEdit.forceActiveFocus();
    }

    color: JamiTheme.secondaryBackgroundColor
    opacity: 0.93

    function clear() {
        openedPassword = false;
        openedNickname = false;
        passwordEdit.dynamicText = "";
        passwordConfirmEdit.dynamicText = "";
        UtilsAdapter.setTempCreationImageFromString();
    }

    JamiFlickable {
        id: scrollView

        MouseArea {
            anchors.fill: parent

            onClicked: {
                openedPassword = false;
                openedNickname = false;
                adviceBox.checked = false;
            }
        }

        property ScrollBar vScrollBar: ScrollBar.vertical

        anchors.fill: parent
        anchors.topMargin: -100

        ColumnLayout {
            id: settings
            width: Math.min(500, root.width - 2 * JamiTheme.preferredMarginSize)
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter

            Label {
                Layout.alignment: Qt.AlignTop | Qt.AlignHCenter
                Layout.margins: JamiTheme.wizardViewBlocMarginSize
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
                            return Math.min(settings.width, JamiTheme.passwordEditOpenedBoxWidth);
                        if (root.openedNickname)
                            return Math.min(settings.width, cornerIcon1.width);
                        return Math.min(settings.width, JamiTheme.passwordEditClosedBoxWidth);
                    }

                    Layout.preferredHeight: {
                        if (root.openedPassword)
                            return passwordColumnLayout.implicitHeight;
                        return Math.max(cornerIcon1.height, labelEncrypt.height + 2 * JamiTheme.advancedAccountSettingsHeightMargin);
                    }

                    Behavior on Layout.preferredWidth {
                        NumberAnimation {
                            duration: 100
                        }
                    }
                    Behavior on Layout.preferredHeight  {
                        NumberAnimation {
                            duration: 100
                        }
                    }

                    Rectangle {
                        id: bg
                        radius: JamiTheme.formsRadius
                        border.color: openedPassword ? JamiTheme.transparentColor : JamiTheme.lightBlue_
                        layer.enabled: true
                        color: root.icon1Hovered ? JamiTheme.buttonTintedBlue : JamiTheme.secAndTertiHoveredBackgroundColor
                        anchors.fill: parent

                        Rectangle {

                            layer.enabled: true
                            height: parent.height / 2
                            width: parent.width / 2
                            anchors.bottom: parent.bottom
                            anchors.left: parent.left
                            border.color: openedPassword ? JamiTheme.transparentColor : JamiTheme.lightBlue_
                            color: root.icon1Hovered ? JamiTheme.buttonTintedBlue : JamiTheme.secAndTertiHoveredBackgroundColor

                            Rectangle {

                                height: parent.height
                                width: parent.width
                                anchors.bottom: parent.bottom
                                anchors.left: parent.left
                                anchors.margins: 1
                                color: root.icon1Hovered ? JamiTheme.buttonTintedBlue : JamiTheme.secAndTertiHoveredBackgroundColor
                            }
                        }

                        ColumnLayout {
                            id: passwordColumnLayout
                            anchors.fill: parent

                            Text {
                                visible: openedPassword

                                Layout.fillWidth: true
                                Layout.leftMargin: JamiTheme.cornerIconSize
                                Layout.rightMargin: JamiTheme.cornerIconSize
                                Layout.topMargin: 25

                                color: JamiTheme.textColor
                                wrapMode: Text.WordWrap
                                text: JamiStrings.encryptAccount
                                font.pixelSize: JamiTheme.creditsTextSize
                                font.weight: Font.Medium
                            }

                            Text {

                                visible: openedPassword

                                Layout.topMargin: 12
                                Layout.leftMargin: JamiTheme.cornerIconSize
                                Layout.rightMargin: JamiTheme.cornerIconSize
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignLeft

                                color: JamiTheme.textColor
                                wrapMode: Text.WordWrap
                                text: JamiStrings.encryptDescription
                                font.pixelSize: JamiTheme.headerFontSize
                                lineHeight: JamiTheme.wizardViewTextLineHeight
                            }

                            PasswordTextEdit {
                                id: passwordEdit

                                visible: openedPassword
                                focus: openedPassword
                                firstEntry: true
                                placeholderText: JamiStrings.password

                                Layout.topMargin: 10
                                Layout.leftMargin: JamiTheme.cornerIconSize
                                Layout.rightMargin: JamiTheme.cornerIconSize
                                Layout.alignment: Qt.AlignLeft
                                Layout.fillWidth: true

                                KeyNavigation.up: passwordConfirmEdit
                                KeyNavigation.down: KeyNavigation.up
                            }

                            PasswordTextEdit {
                                id: passwordConfirmEdit
                                visible: openedPassword
                                placeholderText: JamiStrings.confirmPassword

                                Layout.topMargin: 10
                                Layout.leftMargin: JamiTheme.cornerIconSize
                                Layout.rightMargin: JamiTheme.cornerIconSize
                                Layout.alignment: Qt.AlignLeft
                                Layout.fillWidth: true

                                KeyNavigation.up: passwordEdit
                                KeyNavigation.down: KeyNavigation.up

                                onActiveFocusChanged: {
                                    if (!activeFocus) {
                                        if (!setButton.enabled)
                                            forceProfileActiveFocus();
                                    }
                                }
                            }

                            Text {

                                visible: openedPassword

                                Layout.topMargin: 15
                                Layout.leftMargin: JamiTheme.cornerIconSize
                                Layout.rightMargin: JamiTheme.cornerIconSize
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignLeft

                                color: JamiTheme.textColor
                                wrapMode: Text.WordWrap
                                text: JamiStrings.encryptWarning
                                font.pixelSize: JamiTheme.headerFontSize
                                lineHeight: JamiTheme.wizardViewTextLineHeight
                            }

                            MaterialButton {
                                id: setButton

                                TextMetrics {
                                    id: setButtonTextSize
                                    font.weight: Font.Bold
                                    font.pixelSize: JamiTheme.wizardViewDescriptionFontPixelSize
                                    text: setButton.text
                                }

                                visible: openedPassword

                                Layout.topMargin: 10
                                Layout.alignment: Qt.AlignCenter
                                preferredWidth: setButtonTextSize.width + 2 * JamiTheme.buttontextWizzardPadding
                                text: JamiStrings.setPassword
                                primary: true

                                hoveredColor: checkEnable() ? JamiTheme.buttonTintedBlueHovered : JamiTheme.buttonTintedGreyInactive
                                pressedColor: checkEnable() ? JamiTheme.buttonTintedBluePressed : JamiTheme.buttonTintedGreyInactive

                                color: checkEnable() ? JamiTheme.buttonTintedBlue : JamiTheme.buttonTintedGreyInactive

                                enabled: checkEnable()

                                function checkEnable() {
                                    text = JamiStrings.setPassword;
                                    return (passwordEdit.dynamicText === passwordConfirmEdit.dynamicText && passwordEdit.dynamicText.length !== 0);
                                }

                                onClicked: {
                                    root.validatedPassword = passwordConfirmEdit.dynamicText;
                                    text = JamiStrings.setPasswordSuccess;
                                }

                                onActiveFocusChanged: {
                                    if (!activeFocus) {
                                        forceProfileActiveFocus();
                                    }
                                }

                                KeyNavigation.up: passwordConfirmEdit
                                KeyNavigation.down: passwordEdit
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

                                    color: openedPassword ? JamiTheme.buttonTintedBlue : JamiTheme.transparentColor
                                    Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
                                    Layout.leftMargin: openedPassword ? 2 : openedNickname ? 0 : 20
                                    Layout.bottomMargin: openedPassword ? 2 : 0

                                    Rectangle {

                                        visible: openedPassword

                                        height: cornerIcon1.height / 2
                                        width: cornerIcon1.width / 2
                                        anchors.left: cornerIcon1.left
                                        anchors.bottom: cornerIcon1.bottom
                                        color: JamiTheme.buttonTintedBlue
                                    }

                                    ResponsiveImage {

                                        width: 18
                                        height: 18
                                        source: JamiResources.lock_svg
                                        color: root.icon1Hovered ? JamiTheme.primaryTextColor : openedPassword ? JamiTheme.primaryTextColor : JamiTheme.buttonTintedBlue
                                        anchors.centerIn: cornerIcon1
                                    }
                                }

                                Text {
                                    id: labelEncrypt
                                    visible: !openedPassword && !openedNickname
                                    Layout.fillWidth: true
                                    Layout.rightMargin: 20

                                    text: JamiStrings.encryptAccount
                                    wrapMode: Text.WordWrap
                                    color: root.icon1Hovered ? JamiTheme.primaryTextColor : JamiTheme.textColor
                                    font.pixelSize: JamiTheme.creditsTextSize
                                }
                            }
                        }

                        TapHandler {
                            target: passwordColumnLayout
                            onTapped: {
                                openedNickname = false;
                                openedPassword = true;
                            }
                        }

                        HoverHandler {
                            target: passwordColumnLayout
                            enabled: !openedPassword
                            onHoveredChanged: {
                                root.icon1Hovered = hovered;
                            }
                        }
                    }
                }

                Item {
                    Layout.alignment: Qt.AlignRight | Qt.AlignTop

                    Behavior on Layout.preferredWidth {
                        NumberAnimation {
                            duration: 100
                        }
                    }

                    Behavior on Layout.preferredHeight  {
                        NumberAnimation {
                            duration: 100
                        }
                    }

                    Layout.preferredWidth: {
                        if (openedNickname)
                            return Math.min(settings.width, JamiTheme.customNicknameOpenedBoxWidth);
                        if (openedPassword)
                            return Math.min(settings.width, cornerIcon1.width);
                        return Math.min(settings.width, JamiTheme.customNicknameClosedBoxWidth);
                    }

                    Layout.preferredHeight: {
                        if (openedNickname)
                            return customColumnLayout.implicitHeight;
                        return Math.max(cornerIcon2.height, labelCustomize.height + 2 * JamiTheme.advancedAccountSettingsHeightMargin);
                    }

                    Rectangle {
                        id: bg2

                        radius: JamiTheme.formsRadius
                        border.color: openedNickname ? JamiTheme.transparentColor : JamiTheme.lightBlue_
                        layer.enabled: true
                        color: root.icon2Hovered ? JamiTheme.buttonTintedBlue : JamiTheme.secAndTertiHoveredBackgroundColor
                        anchors.fill: parent

                        Rectangle {

                            height: parent.height / 2
                            width: parent.width / 2
                            anchors.bottom: parent.bottom
                            anchors.right: parent.right
                            border.color: openedNickname ? JamiTheme.transparentColor : JamiTheme.lightBlue_
                            color: root.icon2Hovered ? JamiTheme.buttonTintedBlue : JamiTheme.secAndTertiHoveredBackgroundColor
                            layer.enabled: true

                            Rectangle {

                                height: parent.height
                                width: parent.width
                                opacity: 1
                                anchors.bottom: parent.bottom
                                anchors.right: parent.right
                                anchors.margins: 1
                                color: root.icon2Hovered ? JamiTheme.buttonTintedBlue : JamiTheme.secAndTertiHoveredBackgroundColor
                            }
                        }

                        ColumnLayout {
                            id: customColumnLayout
                            anchors.fill: parent

                            Text {

                                visible: openedNickname
                                text: JamiStrings.customizeProfile
                                wrapMode: Text.WordWrap
                                font.weight: Font.Medium
                                Layout.topMargin: 25
                                Layout.leftMargin: JamiTheme.cornerIconSize
                                Layout.fillWidth: true

                                font.pixelSize: JamiTheme.creditsTextSize
                                color: JamiTheme.textColor
                            }

                            RowLayout {
                                visible: openedNickname

                                PhotoboothView {
                                    id: currentAccountAvatar

                                    width: avatarSize
                                    height: avatarSize

                                    Layout.alignment: Qt.AlignLeft
                                    Layout.topMargin: 10
                                    Layout.preferredWidth: avatarSize
                                    Layout.leftMargin: JamiTheme.cornerIconSize

                                    newItem: true
                                    imageId: visible ? "temp" : ""
                                    avatarSize: 80
                                }

                                ModalTextEdit {
                                    id: displayNameLineEdit

                                    focus: openedNickname

                                    Layout.alignment: Qt.AlignLeft | Qt.AlignBottom
                                    Layout.fillWidth: true
                                    Layout.rightMargin: JamiTheme.cornerIconSize
                                    Layout.leftMargin: 10

                                    placeholderText: JamiStrings.enterNickname
                                    onAccepted: root.alias = displayNameLineEdit.dynamicText
                                }
                            }

                            Text {

                                visible: openedNickname

                                Layout.topMargin: 20
                                Layout.leftMargin: JamiTheme.cornerIconSize
                                Layout.rightMargin: JamiTheme.cornerIconSize
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignLeft

                                wrapMode: Text.WordWrap
                                color: JamiTheme.textColor
                                text: JamiStrings.customizeProfileDescription
                                font.pixelSize: JamiTheme.headerFontSize
                                lineHeight: JamiTheme.wizardViewTextLineHeight
                            }

                            RowLayout {

                                Layout.alignment: openedNickname ? Qt.AlignRight : Qt.AlignLeft
                                Layout.preferredWidth: parent.width

                                Rectangle {
                                    id: cornerIcon2
                                    layer.enabled: true

                                    radius: JamiTheme.formsRadius

                                    height: JamiTheme.cornerIconSize
                                    width: JamiTheme.cornerIconSize

                                    color: openedNickname ? JamiTheme.buttonTintedBlue : JamiTheme.transparentColor
                                    Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                                    Layout.leftMargin: openedPassword ? 0 : 20
                                    Layout.rightMargin: openedNickname ? 2 : 0
                                    Layout.bottomMargin: openedNickname ? 2 : 0

                                    Rectangle {
                                        visible: openedNickname

                                        height: cornerIcon2.height / 2
                                        width: cornerIcon2.width / 2
                                        anchors.right: cornerIcon2.right
                                        anchors.bottom: cornerIcon2.bottom
                                        color: JamiTheme.buttonTintedBlue
                                    }

                                    ResponsiveImage {
                                        width: 18
                                        height: 18
                                        source: JamiResources.noun_paint_svg
                                        color: root.icon2Hovered ? JamiTheme.primaryTextColor : openedNickname ? JamiTheme.primaryTextColor : JamiTheme.buttonTintedBlue
                                        anchors.centerIn: cornerIcon2
                                    }
                                }

                                Text {
                                    id: labelCustomize
                                    visible: !openedNickname && !openedPassword

                                    color: root.icon2Hovered ? JamiTheme.primaryTextColor : JamiTheme.textColor
                                    text: JamiStrings.customizeProfile
                                    font.pixelSize: JamiTheme.creditsTextSize
                                    Layout.fillWidth: true
                                    Layout.rightMargin: 20
                                    wrapMode: Text.WordWrap
                                }
                            }
                        }

                        TapHandler {
                            target: customColumnLayout
                            onTapped: {
                                openedNickname = true;
                                openedPassword = false;
                            }
                        }

                        HoverHandler {
                            target: customColumnLayout
                            enabled: !openedNickname
                            onHoveredChanged: {
                                root.icon2Hovered = hovered;
                            }
                        }
                    }
                }

                MaterialButton {
                    id: showAdvancedButton

                    TextMetrics {
                        id: showAdvancedButtonTextSize
                        font.weight: Font.Bold
                        font.pixelSize: JamiTheme.wizardViewDescriptionFontPixelSize
                        text: showAdvancedButton.text
                    }

                    primary: true
                    Layout.alignment: Qt.AlignHCenter | Qt.AlignBottom
                    Layout.bottomMargin: JamiTheme.wizardViewPageBackButtonMargins
                    Layout.topMargin: JamiTheme.wizardViewBlocMarginSize

                    preferredWidth: showAdvancedButtonTextSize.width + 2 * JamiTheme.buttontextWizzardPadding + 1
                    text: JamiStrings.optionSave

                    onClicked: {
                        root.saveButtonClicked();
                        root.alias = displayNameLineEdit.dynamicText;
                    }

                    //KeyNavigation.up: openedNickname ? displayNameLineEdit : passwordConfirmEdit
                }
            }
        }
    }
}
