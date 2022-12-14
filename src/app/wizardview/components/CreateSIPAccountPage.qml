/*
 * Copyright (C) 2021-2022 Savoir-faire Linux Inc.
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
        sipUsernameEdit.clear()
        sipPasswordEdit.clear()
        sipServernameEdit.clear()
        sipProxyEdit.clear()
        displayNameLineEdit.clear()
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
                anchors.top: parent.top
                anchors.topMargin: JamiTheme.wizardViewLayoutTopMargin

                width: Math.max(508, root.width - 100)

                Label {

                    text: JamiStrings.sipAccount
                    Layout.alignment: Qt.AlignCenter
                    Layout.preferredWidth: Math.min(450, root.width - JamiTheme.preferredMarginSize * 2)
                    Layout.topMargin: 15
                    font.pixelSize: JamiTheme.wizardViewTitleFontPixelSize
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    color: JamiTheme.textColor
                }

                Label {
                    text: JamiStrings.configureExistingSIP
                    Layout.preferredWidth: Math.min(360, root.width - JamiTheme.preferredMarginSize * 2)
                    Layout.topMargin: 15
                    Layout.alignment: Qt.AlignCenter
                    font.pixelSize: JamiTheme.wizardViewDescriptionFontPixelSize
                                        font.weight: Font.Medium
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    color: JamiTheme.textColor
                }

                EditableLineEdit {
                    id: sipServernameEdit

                    objectName: "sipServernameEdit"

                    Layout.alignment: Qt.AlignCenter
                    Layout.preferredWidth: Math.min(440, root.width - JamiTheme.preferredMarginSize * 2)

                    focus: visible
                    selectByMouse: true
                    placeholderText: JamiStrings.server
                    font.pointSize: JamiTheme.textFontSize
                    font.kerning: true

                    KeyNavigation.tab: sipProxyEdit
                    KeyNavigation.up: backButton
                    KeyNavigation.down: sipProxyEdit

                    onEditingFinished: sipProxyEdit.forceActiveFocus()
                }

                EditableLineEdit {
                    id: sipProxyEdit

                    objectName: "sipProxyEdit"

                    Layout.alignment: Qt.AlignCenter
                    Layout.preferredWidth: Math.min(440, root.width - JamiTheme.preferredMarginSize * 2)

                    focus: visible
                    selectByMouse: true
                    placeholderText: JamiStrings.proxy
                    font.pointSize: JamiTheme.textFontSize
                    font.kerning: true

                    KeyNavigation.tab: sipUsernameEdit
                    KeyNavigation.up: sipServernameEdit
                    KeyNavigation.down: sipUsernameEdit

                    onEditingFinished: sipUsernameEdit.forceActiveFocus()
                }

                EditableLineEdit {
                    id: sipUsernameEdit

                    objectName: "sipUsernameEdit"

                    Layout.alignment: Qt.AlignCenter
                    Layout.preferredWidth: Math.min(440, root.width - JamiTheme.preferredMarginSize * 2)

                    selectByMouse: true
                    placeholderText: JamiStrings.username
                    font.pointSize: JamiTheme.textFontSize
                    font.kerning: true

                    KeyNavigation.tab: sipPasswordEdit
                    KeyNavigation.up: sipProxyEdit
                    KeyNavigation.down: sipPasswordEdit

                    onEditingFinished: sipPasswordEdit.forceActiveFocus()
                }

                EditableLineEdit {
                    id: sipPasswordEdit

                    objectName: "sipPasswordEdit"

                    Layout.alignment: Qt.AlignCenter
                    Layout.preferredWidth: Math.min(440, root.width - JamiTheme.preferredMarginSize * 2)

                    selectByMouse: true
                    echoMode: TextInput.Password

                    placeholderText: JamiStrings.password
                    font.pointSize: JamiTheme.textFontSize
                    font.kerning: true

                    KeyNavigation.tab: createAccountButton
                    KeyNavigation.up: sipUsernameEdit
                    KeyNavigation.down: createAccountButton

                    secondIco: JamiResources.eye_cross_svg


                    onEditingFinished: createAccountButton.forceActiveFocus()

                    onSecondIcoClicked: { toggleEchoMode() }
                }

                MaterialButton {
                    id: createAccountButton

                    objectName: "createSIPAccountButton"

                    Layout.alignment: Qt.AlignCenter
                    Layout.bottomMargin: JamiTheme.wizardViewPageBackButtonMargins

                    preferredWidth: Math.min(JamiTheme.wizardButtonWidth, root.width - JamiTheme.preferredMarginSize * 2)

                    text: JamiStrings.addSip

                    KeyNavigation.tab: personalizeAccount
                    KeyNavigation.up: sipPasswordEdit
                    KeyNavigation.down: personalizeAccount

                    onClicked: {
                        WizardViewStepModel.accountCreationInfo =
                                JamiQmlUtils.setUpAccountCreationInputPara(
                                    {hostname : sipServernameEdit.text,
                                        alias: displayNameLineEdit.text,
                                        username : sipUsernameEdit.text,
                                        password : sipPasswordEdit.text,
                                        proxy : sipProxyEdit.text,
                                        avatar: UtilsAdapter.tempCreationImage()})
                        WizardViewStepModel.nextStep()
                    }
                }

                MaterialButton {

                    id: personalizeAccount
                    text: JamiStrings.personalizeAccount
                    tertiary: true
                    secHoveredColor: JamiTheme.secAndTertiHoveredBackgroundColor
                    preferredWidth: Math.min(JamiTheme.wizardButtonWidth, root.width - JamiTheme.preferredMarginSize * 2)

                    Layout.alignment: Qt.AlignCenter
                    Layout.bottomMargin: JamiTheme.wizardViewPageBackButtonMargins*2

                    KeyNavigation.tab: backButton
                    KeyNavigation.up: createAccountButton
                    KeyNavigation.down: backButton

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
                    Layout.topMargin: 15
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

                EditableLineEdit {

                    id: displayNameLineEdit

                    Layout.alignment: Qt.AlignCenter
                    Layout.preferredWidth: Math.min(300, root.width - JamiTheme.preferredMarginSize * 2)
                    Layout.topMargin: 30
                    verticalAlignment: Text.AlignVCenter

                    font.pointSize: JamiTheme.textFontSize

                    placeholderText: JamiStrings.enterNickname

                    color: JamiTheme.textColor
                }

                Text {

                    Layout.topMargin: 15
                    Layout.alignment: Qt.AlignCenter
                    Layout.preferredWidth: Math.min(320, root.width - JamiTheme.preferredMarginSize * 2)
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    wrapMode: Text.WordWrap

                    text: JamiStrings.customizeProfileDescription
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

        KeyNavigation.tab: sipServernameEdit
        KeyNavigation.up: personalizeAccount
        KeyNavigation.down: sipServernameEdit

        onClicked: {
            if (createAccountStack.currentIndex !== 0) {
                createAccountStack.currentIndex--
            } else {
                WizardViewStepModel.previousStep()
            }
        }
    }
}
