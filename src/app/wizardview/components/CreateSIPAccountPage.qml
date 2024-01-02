/*
 * Copyright (C) 2021-2024 Savoir-faire Linux Inc.
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

    color: JamiTheme.secondaryBackgroundColor

    function clearAllTextFields() {
        UtilsAdapter.setTempCreationImageFromString();
    }
    signal showThisPage

    Connections {
        target: WizardViewStepModel

        function onMainStepChanged() {
            if (WizardViewStepModel.mainStep === WizardViewStepModel.MainSteps.AccountCreation && WizardViewStepModel.accountCreationOption === WizardViewStepModel.AccountCreationOption.CreateSipAccount) {
                clearAllTextFields();
                root.showThisPage();
                sipServernameEdit.focus = true;
            }
        }
    }
    StackLayout {
        id: createAccountStack
        anchors.fill: parent
        objectName: "createAccountStack"

        Rectangle {
            Layout.fillHeight: true
            Layout.fillWidth: true
            color: JamiTheme.secondaryBackgroundColor

            ColumnLayout {
                id: createSIPAccountPageColumnLayout
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                spacing: JamiTheme.wizardViewPageLayoutSpacing
                width: Math.max(508, root.width - 100)

                Label {
                    Layout.alignment: Qt.AlignCenter
                    Layout.preferredWidth: Math.min(450, root.width - JamiTheme.preferredMarginSize * 2)
                    Layout.topMargin: JamiTheme.preferredMarginSize
                    color: JamiTheme.textColor
                    font.pixelSize: JamiTheme.wizardViewTitleFontPixelSize
                    horizontalAlignment: Text.AlignHCenter
                    text: JamiStrings.sipAccount
                    verticalAlignment: Text.AlignVCenter
                }
                Label {
                    Layout.alignment: Qt.AlignCenter
                    Layout.preferredWidth: Math.min(360, root.width - JamiTheme.preferredMarginSize * 2)
                    Layout.topMargin: JamiTheme.wizardViewDescriptionMarginSize
                    color: JamiTheme.textColor
                    font.pixelSize: JamiTheme.wizardViewDescriptionFontPixelSize
                    font.weight: Font.Medium
                    horizontalAlignment: Text.AlignHCenter
                    text: JamiStrings.configureExistingSIP
                    verticalAlignment: Text.AlignVCenter
                    wrapMode: Text.WordWrap
                }
                ModalTextEdit {
                    id: sipServernameEdit
                    KeyNavigation.down: sipUsernameEdit
                    KeyNavigation.tab: KeyNavigation.down
                    KeyNavigation.up: backButton
                    Layout.alignment: Qt.AlignCenter
                    Layout.preferredWidth: Math.min(440, root.width - JamiTheme.preferredMarginSize * 2)
                    Layout.topMargin: JamiTheme.wizardViewBlocMarginSize
                    objectName: "sipServernameEdit"
                    placeholderText: JamiStrings.server

                    onAccepted: sipUsernameEdit.forceActiveFocus()
                }
                ModalTextEdit {
                    id: sipUsernameEdit
                    KeyNavigation.down: sipPasswordEdit
                    KeyNavigation.tab: KeyNavigation.down
                    KeyNavigation.up: sipServernameEdit
                    Layout.alignment: Qt.AlignCenter
                    Layout.preferredWidth: Math.min(440, root.width - JamiTheme.preferredMarginSize * 2)
                    Layout.topMargin: JamiTheme.wizardViewMarginSize
                    objectName: "sipUsernameEdit"
                    placeholderText: JamiStrings.username

                    onAccepted: sipPasswordEdit.forceActiveFocus()
                }
                PasswordTextEdit {
                    id: sipPasswordEdit
                    KeyNavigation.down: tlsRadioButton
                    KeyNavigation.tab: KeyNavigation.down
                    KeyNavigation.up: sipUsernameEdit
                    Layout.alignment: Qt.AlignCenter
                    Layout.preferredWidth: Math.min(440, root.width - JamiTheme.preferredMarginSize * 2)
                    Layout.topMargin: JamiTheme.wizardViewMarginSize
                    objectName: "sipPasswordEdit"
                    placeholderText: JamiStrings.password

                    onAccepted: tlsRadioButton.forceActiveFocus()
                }
                Flow {
                    Layout.alignment: Qt.AlignCenter
                    Layout.preferredHeight: childrenRect.height
                    Layout.preferredWidth: tlsRadioButton.width + udpRadioButton.width + 10
                    Layout.topMargin: JamiTheme.wizardViewMarginSize
                    spacing: 10

                    ButtonGroup {
                        id: optionsB
                    }
                    MaterialRadioButton {
                        id: tlsRadioButton
                        ButtonGroup.group: optionsB

                        KeyNavigation.down: udpRadioButton
                        KeyNavigation.tab: KeyNavigation.down
                        KeyNavigation.up: sipPasswordEdit

                        checked: true

                        height: 40
                        text: JamiStrings.tls
                        width: 120
                    }
                    MaterialRadioButton {
                        id: udpRadioButton
                        ButtonGroup.group: optionsB

                        KeyNavigation.down: createAccountButton
                        KeyNavigation.tab: KeyNavigation.down
                        KeyNavigation.up: tlsRadioButton

                        height: 40
                        text: JamiStrings.udp
                        width: 120
                    }
                }
                MaterialButton {
                    id: createAccountButton
                    KeyNavigation.down: personalizeAccount
                    KeyNavigation.tab: KeyNavigation.down
                    KeyNavigation.up: udpRadioButton
                    Layout.alignment: Qt.AlignCenter
                    Layout.topMargin: JamiTheme.wizardViewBlocMarginSize
                    objectName: "createSIPAccountButton"
                    preferredWidth: textSize.width + 2 * JamiTheme.buttontextWizzardPadding
                    primary: true
                    text: JamiStrings.addSip

                    onClicked: {
                        WizardViewStepModel.accountCreationInfo = JamiQmlUtils.setUpAccountCreationInputPara({
                                "hostname": sipServernameEdit.dynamicText,
                                "alias": displayNameLineEdit.dynamicText,
                                "username": sipUsernameEdit.dynamicText,
                                "password": sipPasswordEdit.dynamicText,
                                "tls": tlsRadioButton.checked,
                                "avatar": UtilsAdapter.tempCreationImage()
                            });
                        WizardViewStepModel.nextStep();
                    }

                    TextMetrics {
                        id: textSize
                        font.pixelSize: JamiTheme.wizardViewDescriptionFontPixelSize
                        font.weight: Font.Bold
                        text: createAccountButton.text
                    }
                }
                MaterialButton {
                    id: personalizeAccount
                    KeyNavigation.down: backButton
                    KeyNavigation.tab: KeyNavigation.down
                    KeyNavigation.up: createAccountButton
                    Layout.alignment: Qt.AlignCenter
                    Layout.bottomMargin: JamiTheme.wizardViewPageBackButtonMargins * 2
                    Layout.topMargin: JamiTheme.wizardViewBlocMarginSize
                    preferredWidth: personalizeAccountTextSize.width + 2 * JamiTheme.buttontextWizzardPadding + 1
                    secHoveredColor: JamiTheme.secAndTertiHoveredBackgroundColor
                    tertiary: true
                    text: JamiStrings.personalizeAccount

                    onClicked: createAccountStack.currentIndex += 1

                    TextMetrics {
                        id: personalizeAccountTextSize
                        font.pixelSize: JamiTheme.wizardViewDescriptionFontPixelSize
                        font.weight: Font.Bold
                        text: personalizeAccount.text
                    }
                }
            }
        }
        Rectangle {
            Layout.fillHeight: true
            Layout.fillWidth: true
            color: JamiTheme.secondaryBackgroundColor

            ColumnLayout {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter

                width: Math.max(508, root.width - 100)

                Label {
                    Layout.alignment: Qt.AlignCenter
                    Layout.preferredWidth: Math.min(450, root.width - JamiTheme.preferredMarginSize * 2)
                    Layout.topMargin: JamiTheme.preferredMarginSize
                    color: JamiTheme.textColor
                    font.pixelSize: 26
                    horizontalAlignment: Text.AlignHCenter
                    text: JamiStrings.personalizeAccount
                    verticalAlignment: Text.AlignVCenter
                }
                PhotoboothView {
                    id: currentAccountAvatar
                    Layout.alignment: Qt.AlignCenter
                    Layout.topMargin: 50

                    avatarSize: 150
                    width: avatarSize
                    height: avatarSize

                    newItem: true
                    imageId: visible ? "temp" : ""

                    KeyNavigation.up: backButton
                    KeyNavigation.down: displayNameLineEdit
                    KeyNavigation.tab: KeyNavigation.down
                }
                ModalTextEdit {
                    id: displayNameLineEdit
                    Layout.alignment: Qt.AlignCenter
                    Layout.preferredWidth: Math.min(300, root.width - JamiTheme.preferredMarginSize * 2)
                    Layout.topMargin: 30
                    placeholderText: JamiStrings.enterNickname

                    KeyNavigation.up: currentAccountAvatar
                    KeyNavigation.down: backButton
                    KeyNavigation.tab: KeyNavigation.down
                }
                Text {
                    Layout.alignment: Qt.AlignCenter
                    Layout.preferredWidth: Math.min(320, root.width - JamiTheme.preferredMarginSize * 2)
                    Layout.topMargin: JamiTheme.preferredMarginSize
                    color: JamiTheme.textColor
                    font.pixelSize: JamiTheme.headerFontSize
                    horizontalAlignment: Text.AlignHCenter
                    lineHeight: JamiTheme.wizardViewTextLineHeight
                    text: JamiStrings.customizeProfileDescription
                    verticalAlignment: Text.AlignVCenter
                    wrapMode: Text.WordWrap
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

        KeyNavigation.up: createAccountStack.currentIndex !== 0 ? displayNameLineEdit : personalizeAccount
        KeyNavigation.down: createAccountStack.currentIndex !== 0 ? currentAccountAvatar : sipServernameEdit
        KeyNavigation.tab: KeyNavigation.down

        onClicked: {
            if (createAccountStack.currentIndex !== 0) {
                createAccountStack.currentIndex--;
            } else {
                WizardViewStepModel.previousStep();
            }
        }
    }
}
