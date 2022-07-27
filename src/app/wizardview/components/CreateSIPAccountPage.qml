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

import net.jami.Models 1.1
import net.jami.Constants 1.1

import "../../commoncomponents"

Rectangle {
    id: root

    property int preferredHeight: createSIPAccountPageColumnLayout.implicitHeight

    signal showThisPage

    function clearAllTextFields() {
        sipUsernameEdit.clear()
        sipPasswordEdit.clear()
        sipServernameEdit.clear()
        sipProxyEdit.clear()
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

    color: JamiTheme.backgroundColor



    StackLayout {
        id: createAccountStack

        objectName: "createAccountStack"
        anchors.fill: parent

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
                font.pixelSize: 26
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            Label {
                text: JamiStrings.configureExistingSIP
                Layout.preferredWidth: Math.min(360, root.width - JamiTheme.preferredMarginSize * 2)
                Layout.topMargin: 15
                Layout.alignment: Qt.AlignCenter
                font.pixelSize: 15
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            EditableLineEdit {
                id: sipServernameEdit

                objectName: "sipServernameEdit"

                Layout.alignment: Qt.AlignCenter
                Layout.preferredWidth: Math.min(440, root.width - JamiTheme.preferredMarginSize * 2)

                focus: visible
                fontSize: 15
                selectByMouse: true
                placeholderText: JamiStrings.server
                font.pointSize: JamiTheme.textFontSize
                font.kerning: true

                KeyNavigation.tab: sipProxyEdit
                KeyNavigation.up: backButton
                KeyNavigation.down: KeyNavigation.tab

                onEditingFinished: sipProxyEdit.forceActiveFocus()
            }

            EditableLineEdit {
                id: sipProxyEdit

                objectName: "sipProxyEdit"

                Layout.alignment: Qt.AlignCenter
                Layout.preferredWidth: Math.min(440, root.width - JamiTheme.preferredMarginSize * 2)

                focus: visible
                fontSize: 15
                selectByMouse: true
                placeholderText: JamiStrings.proxy
                font.pointSize: JamiTheme.textFontSize
                font.kerning: true

                KeyNavigation.tab: sipUsernameEdit
                KeyNavigation.up: sipServernameEdit
                KeyNavigation.down: KeyNavigation.tab

                onEditingFinished: sipUsernameEdit.forceActiveFocus()
            }

            EditableLineEdit {
                id: sipUsernameEdit

                objectName: "sipUsernameEdit"

                Layout.alignment: Qt.AlignCenter
                Layout.preferredWidth: Math.min(440, root.width - JamiTheme.preferredMarginSize * 2)

                fontSize: 15
                selectByMouse: true
                placeholderText: JamiStrings.username
                font.pointSize: JamiTheme.textFontSize
                font.kerning: true

                KeyNavigation.tab: sipPasswordEdit
                KeyNavigation.up: sipProxyEdit
                KeyNavigation.down: KeyNavigation.tab

                onEditingFinished: sipPasswordEdit.forceActiveFocus()
            }

            EditableLineEdit {
                id: sipPasswordEdit

                objectName: "sipPasswordEdit"

                Layout.alignment: Qt.AlignCenter
                Layout.preferredWidth: Math.min(440, root.width - JamiTheme.preferredMarginSize * 2)

                selectByMouse: true
                echoMode: TextInput.Password
                fontSize: 15

                placeholderText: JamiStrings.password
                font.pointSize: JamiTheme.textFontSize
                font.kerning: true

                KeyNavigation.tab: createAccountButton
                KeyNavigation.up: sipUsernameEdit
                KeyNavigation.down: KeyNavigation.tab

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

                KeyNavigation.tab: backButton
                KeyNavigation.up: sipPasswordEdit
                KeyNavigation.down: KeyNavigation.tab

                onClicked: {
                    WizardViewStepModel.accountCreationInfo =
                            JamiQmlUtils.setUpAccountCreationInputPara(
                                {hostname : sipServernameEdit.text,
                                    username : sipUsernameEdit.text,
                                    password : sipPasswordEdit.text,
                                    proxy : sipProxyEdit.text})
                    WizardViewStepModel.nextStep()
                }
            }

            MaterialButton {

                id:personalizeAccount
                text: JamiStrings.personalizeAccount
                tertiary: true
                preferredWidth: Math.min(JamiTheme.wizardButtonWidth, root.width - JamiTheme.preferredMarginSize * 2)

                Layout.alignment: Qt.AlignCenter
                Layout.bottomMargin: JamiTheme.wizardViewPageBackButtonMargins

                onClicked: createAccountStack.currentIndex += 1
            }
        }



        Rectangle {
            id: personalizeSipAccount

            color: JamiTheme.transparentColor
            property int stackIndex: 2

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
                }

                PhotoboothView {
                    id: currentAccountAvatar
                    darkTheme: UtilsAdapter.luma(JamiTheme.primaryBackgroundColor)

                    Layout.alignment: Qt.AlignCenter
                    Layout.topMargin: 50

                    imageId: visible ? "temp" : ""
                    avatarSize: 150
                    buttonSize: JamiTheme.smartListAvatarSize

                }

                EditableLineEdit {

                    id: displayNameLineEdit

                    Layout.alignment: Qt.AlignCenter
                    Layout.preferredWidth: Math.min(300, root.width - JamiTheme.preferredMarginSize * 2)
                    Layout.topMargin: 30
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter

                    fontSize: 15

                    placeholderText: CurrentAccount.alias === "" ? JamiStrings.enterNickname: CurrentAccount.alias

                    onEditingFinished: AccountAdapter.setCurrAccDisplayName(text)

                }

                Text {

                    Layout.topMargin: 15
                    Layout.alignment: Qt.AlignCenter
                    Layout.preferredWidth: Math.min(320, root.width - JamiTheme.preferredMarginSize * 2)
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    wrapMode: Text.WordWrap

                    text: JamiStrings.customizeProfileDescription
                    font.pixelSize: 13
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
        KeyNavigation.up: createAccountButton
        KeyNavigation.down: KeyNavigation.tab

        onClicked: {
            if (createAccountStack.currentIndex !== 0) {
                createAccountStack.currentIndex--
            } else {
                WizardViewStepModel.previousStep()
            }
        }
    }
}
