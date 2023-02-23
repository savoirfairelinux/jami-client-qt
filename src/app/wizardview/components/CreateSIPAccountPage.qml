/*
 * Copyright (C) 2021-2023 Savoir-faire Linux Inc.
 * Author: Yang Wang <yang.wang@savoirfairelinux.com>
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
import QtQuick.Layouts
import QtQuick.Controls

import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import net.jami.Models 1.1

import "../../commoncomponents"

Rectangle {
    id: root

    property int preferredHeight: createSIPAccountPageColumnLayout.implicitHeight + 2 * JamiTheme.preferredMarginSize

    signal showThisPage

    function clearAllTextFields() {
        UtilsAdapter.setTempCreationImageFromString()
    }

    Connections {
        target: WizardViewStepModel

        function onMainStepChanged() {
            if (WizardViewStepModel.mainStep === WizardViewStepModel.MainSteps.AccountCreation &&
                    WizardViewStepModel.accountCreationOption ===
                    WizardViewStepModel.AccountCreationOption.CreateSipAccount) {
                clearAllTextFields()
                root.showThisPage()
                sipServernameEdit.focus = true
            }
        }
    }

    color: JamiTheme.secondaryBackgroundColor

    StackLayout {
        id: createAccountStack

        objectName: "createAccountStack"
        anchors.fill: parent

        Rectangle {

            Layout.fillHeight: true
            Layout.fillWidth: true
            color: JamiTheme.secondaryBackgroundColor

            ColumnLayout {
                id: createSIPAccountPageColumnLayout

                spacing: JamiTheme.wizardViewPageLayoutSpacing
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                width: Math.max(508, root.width - 100)

                Label {

                    text: JamiStrings.sipAccount
                    Layout.alignment: Qt.AlignCenter
                    Layout.preferredWidth: Math.min(450, root.width - JamiTheme.preferredMarginSize * 2)
                    Layout.topMargin: JamiTheme.preferredMarginSize
                    font.pixelSize: JamiTheme.wizardViewTitleFontPixelSize
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    color: JamiTheme.textColor
                }

                Label {
                    text: JamiStrings.configureExistingSIP
                    Layout.preferredWidth: Math.min(360, root.width - JamiTheme.preferredMarginSize * 2)
                    Layout.topMargin: JamiTheme.wizardViewDescriptionMarginSize
                    Layout.alignment: Qt.AlignCenter
                    font.pixelSize: JamiTheme.wizardViewDescriptionFontPixelSize
                    font.weight: Font.Medium
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    color: JamiTheme.textColor
                }

                ModalTextEdit {
                    id: sipServernameEdit

                    objectName: "sipServernameEdit"

                    Layout.alignment: Qt.AlignCenter
                    Layout.preferredWidth: Math.min(440, root.width - JamiTheme.preferredMarginSize * 2)
                    Layout.topMargin: JamiTheme.wizardViewBlocMarginSize

                    placeholderText: JamiStrings.server

                    KeyNavigation.tab: KeyNavigation.down
                    KeyNavigation.up: backButton
                    KeyNavigation.down: sipUsernameEdit

                    onAccepted: sipUsernameEdit.forceActiveFocus()
                }

                ModalTextEdit {
                    id: sipUsernameEdit

                    objectName: "sipUsernameEdit"

                    Layout.alignment: Qt.AlignCenter
                    Layout.preferredWidth: Math.min(440, root.width - JamiTheme.preferredMarginSize * 2)
                    Layout.topMargin: JamiTheme.wizardViewMarginSize

                    placeholderText: JamiStrings.username

                    KeyNavigation.tab: KeyNavigation.down
                    KeyNavigation.up: sipServernameEdit
                    KeyNavigation.down: sipPasswordEdit

                    onAccepted: sipPasswordEdit.forceActiveFocus()
                }

                PasswordTextEdit {
                    id: sipPasswordEdit

                    objectName: "sipPasswordEdit"

                    Layout.alignment: Qt.AlignCenter
                    Layout.preferredWidth: Math.min(440, root.width - JamiTheme.preferredMarginSize * 2)
                    Layout.topMargin: JamiTheme.wizardViewMarginSize

                    placeholderText: JamiStrings.password

                    KeyNavigation.tab: KeyNavigation.down
                    KeyNavigation.up: sipUsernameEdit
                    KeyNavigation.down: tlsRadioButton

                    onAccepted: tlsRadioButton.forceActiveFocus()
                }

                ButtonGroup { id: optionsB }

                RowLayout{

                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: Math.min(440, root.width - JamiTheme.preferredMarginSize * 2)
                    Layout.topMargin: JamiTheme.wizardViewBlocMarginSize

                    MaterialRadioButton {
                        id: tlsRadioButton
                        Layout.alignment: Qt.AlignHCenter
                        text: JamiStrings.tls
                        ButtonGroup.group: optionsB
                        checked: true

                        KeyNavigation.up: sipPasswordEdit
                        KeyNavigation.down: udpRadioButton
                        KeyNavigation.tab: KeyNavigation.down

                    }

                    MaterialRadioButton {
                        id: udpRadioButton
                        Layout.alignment: Qt.AlignHCenter
                        text: JamiStrings.udp
                        ButtonGroup.group: optionsB
                        color: JamiTheme.textColor

                        KeyNavigation.up: tlsRadioButton
                        KeyNavigation.down: createAccountButton
                        KeyNavigation.tab: KeyNavigation.down

                    }
                }

                MaterialButton {
                    id: createAccountButton

                    TextMetrics{
                        id: textSize
                        font.weight: Font.Bold
                        font.pixelSize: JamiTheme.wizardViewDescriptionFontPixelSize
                        text: createAccountButton.text
                    }

                    objectName: "createSIPAccountButton"

                    Layout.alignment: Qt.AlignCenter
                    Layout.topMargin: JamiTheme.wizardViewBlocMarginSize

                    preferredWidth: textSize.width + 2*JamiTheme.buttontextWizzardPadding
                    primary: true

                    text: JamiStrings.addSip

                    KeyNavigation.up: udpRadioButton
                    KeyNavigation.down: personalizeAccount
                    KeyNavigation.tab: KeyNavigation.down

                    onClicked: {
                        WizardViewStepModel.accountCreationInfo =
                                JamiQmlUtils.setUpAccountCreationInputPara(
                                    {hostname : sipServernameEdit.dynamicText,
                                        alias: displayNameLineEdit.dynamicText,
                                        username : sipUsernameEdit.dynamicText,
                                        password : sipPasswordEdit.dynamicText,
                                        tls: tlsRadioButton.checked,
                                        avatar: UtilsAdapter.tempCreationImage()})
                        WizardViewStepModel.nextStep()
                    }
                }

                MaterialButton {

                    id: personalizeAccount

                    TextMetrics{
                        id: personalizeAccountTextSize
                        font.weight: Font.Bold
                        font.pixelSize: JamiTheme.wizardViewDescriptionFontPixelSize
                        text: personalizeAccount.text
                    }


                    text: JamiStrings.personalizeAccount
                    tertiary: true
                    secHoveredColor: JamiTheme.secAndTertiHoveredBackgroundColor
                    preferredWidth: personalizeAccountTextSize.width + 2*JamiTheme.buttontextWizzardPadding + 1

                    Layout.alignment: Qt.AlignCenter
                    Layout.bottomMargin: JamiTheme.wizardViewPageBackButtonMargins*2
                    Layout.topMargin: JamiTheme.wizardViewBlocMarginSize

                    KeyNavigation.up: createAccountButton
                    KeyNavigation.down: backButton
                    KeyNavigation.tab: KeyNavigation.down

                    onClicked: createAccountStack.currentIndex += 1
                }
            }
        }

        Rectangle {

            Layout.fillHeight: true
            Layout.fillWidth: true
            color: JamiTheme.secondaryBackgroundColor

            ColumnLayout {
                spacing: JamiTheme.wizardViewPageLayoutSpacing

                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: JamiTheme.wizardViewLayoutTopMargin

                width: Math.max(508, root.width - 100)

                Label {

                    text: JamiStrings.personalizeAccount
                    Layout.alignment: Qt.AlignCenter
                    Layout.preferredWidth: Math.min(450, root.width - JamiTheme.preferredMarginSize * 2)
                    Layout.topMargin: JamiTheme.preferredMarginSize
                    font.pixelSize: 26
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    color: JamiTheme.textColor
                }

                PhotoboothView {
                    id: currentAccountAvatar
                    darkTheme: UtilsAdapter.luma(JamiTheme.primaryBackgroundColor)
                    width: avatarSize
                    height: avatarSize

                    Layout.alignment: Qt.AlignCenter
                    Layout.topMargin: 50

                    newItem: true
                    imageId: visible ? "temp" : ""
                    avatarSize: 150
                    buttonSize: JamiTheme.smartListAvatarSize
                }

                ModalTextEdit {
                    id: displayNameLineEdit

                    Layout.alignment: Qt.AlignCenter
                    Layout.preferredWidth: Math.min(300, root.width - JamiTheme.preferredMarginSize * 2)
                    Layout.topMargin: 30
                    placeholderText: JamiStrings.enterNickname
                }

                Text {

                    Layout.topMargin: JamiTheme.preferredMarginSize
                    Layout.alignment: Qt.AlignCenter
                    Layout.preferredWidth: Math.min(320, root.width - JamiTheme.preferredMarginSize * 2)
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    wrapMode: Text.WordWrap

                    text: JamiStrings.customizeProfileDescription
                    lineHeight: JamiTheme.wizardViewTextLineHeight
                    font.pixelSize: JamiTheme.headerFontSize
                    color: JamiTheme.textColor
                }
            }
        }
    }

    BackButton {
        id: backButton

        objectName: "createSIPAccountPageBackButton"

        anchors.left: parent.left
        anchors.top: parent.top
        anchors.margins: 20

        preferredSize: JamiTheme.wizardViewPageBackButtonSize

        KeyNavigation.up: personalizeAccount
        KeyNavigation.down: sipServernameEdit
        KeyNavigation.tab: KeyNavigation.down

        onClicked: {
            if (createAccountStack.currentIndex !== 0) {
                createAccountStack.currentIndex--
            } else {
                WizardViewStepModel.previousStep()
            }
        }
    }
}
