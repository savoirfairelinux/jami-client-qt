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

    ColumnLayout {
        id: createSIPAccountPageColumnLayout

        spacing: JamiTheme.wizardViewPageLayoutSpacing

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.top: parent.top
        anchors.topMargin: 38

        Label {

            text: JamiStrings.sipAccount
            Layout.alignment: Qt.AlignCenter | Qt.AlignTop
            font.pixelSize: 26

        }

        Label {
            text: JamiStrings.configureExistingSIP
            color: JamiTheme.textColor
            Layout.preferredWidth: 260
            Layout.topMargin: 15
            Layout.alignment: Qt.AlignCenter | Qt.AlignTop
            font.pointSize: JamiTheme.textFontSize + 3
            font.weight: Font.Medium
            wrapMode: Text.WordWrap
        }

        EditableLineEdit {
            id: sipServernameEdit

            objectName: "sipServernameEdit"

            Layout.alignment: Qt.AlignCenter

            focus: visible

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

            selectByMouse: true
            echoMode: hoveredIco ? TextInput.Normal : TextInput.Password

            placeholderText: JamiStrings.password
            font.pointSize: JamiTheme.textFontSize
            font.kerning: true

            KeyNavigation.tab: createAccountButton
            KeyNavigation.up: sipUsernameEdit
            KeyNavigation.down: KeyNavigation.tab

            secondIco: JamiResources.eye_cross_svg


            //onEditingFinished: createAccountButton.clicked()
        }

        MaterialButton {
            id: createAccountButton

            objectName: "createSIPAccountButton"

            Layout.alignment: Qt.AlignCenter
            Layout.bottomMargin: JamiTheme.wizardViewPageBackButtonMargins

            preferredWidth: JamiTheme.wizardButtonWidth

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

            Layout.alignment: Qt.AlignCenter
            Layout.bottomMargin: JamiTheme.wizardViewPageBackButtonMargins
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

        onClicked: WizardViewStepModel.previousStep()
    }
}
