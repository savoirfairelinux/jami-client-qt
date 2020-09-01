/*
 * Copyright (C) 2020 by Savoir-faire Linux
 * Author: Yang Wang <yang.wang@savoirfairelinux.com>
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

import QtQuick 2.14
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.14
import Qt.labs.platform 1.1

import "../"
import "../../constant"
import "../../commoncomponents"
import "../../settingsview/components"

Rectangle {
    id: root

    property alias text_usernameEditAlias: usernameEdit.text
    property int nameRegistrationUIState: WizardView.BLANK
    property bool isRendezVous: false
    property alias text_passwordEditAlias: passwordEdit.text

    signal createAccount
    signal leavePage

    function initializeOnShowUp(isRdv) {
        isRendezVous = isRdv
        createAccountStack.currentIndex = 0
        clearAllTextFields()
        passwordSwitch.checked = false
    }

    function clearAllTextFields() {
        usernameEdit.clear()
        passwordEdit.clear()
        passwordConfirmEdit.clear()
    }

    anchors.fill: parent

    color: JamiTheme.backgroundColor

    StackLayout {
        id: createAccountStack
        anchors.verticalCenter: root.verticalCenter
        anchors.horizontalCenter: root.horizontalCenter

        ColumnLayout {
            spacing: 12

            anchors.verticalCenter: parent.verticalCenter
            Layout.preferredWidth: root.width
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

            RowLayout {
                spacing: 12
                height: 48

                Layout.fillWidth: true
                anchors.left: usernameEdit.left

                Label {
                    text: isRendezVous ? qsTr("Choose a name for your meeting") : qsTr("Choose a username for your account")
                }

                Label {
                    text: qsTr("Recommended")
                    color: "white"
                    padding: 8
                    anchors.right: parent.right

                    background: Rectangle {
                        color: "#aed581"
                        radius: 24
                        anchors.fill: parent
                    }
                }
            }

            MaterialLineEdit {
                id: usernameEdit

                selectByMouse: true
                placeholderText: isRendezVous ? qsTr("Choose a name") : qsTr("Choose your username")
                font.pointSize: 10
                font.kerning: true

                borderColorMode: nameRegistrationUIState === WizardView.BLANK ? MaterialLineEdit.NORMAL
                                : nameRegistrationUIState >= WizardView.FREE ? MaterialLineEdit.NORMAL : MaterialLineEdit.ERROR

                fieldLayoutWidth: chooseUsernameButton.width
                Layout.topMargin: 32
            }

            Label {
                text: {
                    switch(nameRegistrationUIState){
                    case WizardView.BLANK:
                    case WizardView.SEARCHING:
                    case WizardView.FREE:
                        return ""
                    case WizardView.INVALID:
                        return isRendezVous ? qsTr("Invalid name") : qsTr("Invalid username")
                    case WizardView.TAKEN:
                        return isRendezVous ? qsTr("Name already taken") : qsTr("Username already taken")
                    }
                }

                anchors.left: usernameEdit.left
                anchors.right: usernameEdit.right
                Layout.alignment: Qt.AlignHCenter

                font.pointSize: JamiTheme.textFontSize
                color: "red"

                height: 32
            }

            MaterialButton {
                id: chooseUsernameButton
                text: isRendezVous ? qsTr("CHOOSE NAME") : qsTr("CHOOSE USERNAME")
                color: nameRegistrationUIState === WizardView.FREE?
                        JamiTheme.buttonTintedGrey
                        : JamiTheme.buttonTintedGreyInactive
                hoveredColor: JamiTheme.buttonTintedGreyHovered
                pressedColor: JamiTheme.buttonTintedGreyPressed

                onClicked: {
                    if (nameRegistrationUIState === WizardView.FREE)
                        createAccountStack.currentIndex = createAccountStack.currentIndex + 1
                }
            }

            MaterialButton {
                text: isRendezVous ? qsTr("SKIP CHOOSE NAME") : qsTr("SKIP CHOOSE USERNAME")
                color: JamiTheme.buttonTintedGrey
                hoveredColor: JamiTheme.buttonTintedGreyHovered
                pressedColor: JamiTheme.buttonTintedGreyPressed
                outlined: true

                onClicked: {
                    createAccountStack.currentIndex = createAccountStack.currentIndex + 1
                }
            }
        }

        ColumnLayout {
            spacing: 12

            anchors.verticalCenter: parent.verticalCenter
            Layout.preferredWidth: root.width
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

            RowLayout {
                spacing: 12
                height: 48

                anchors.right: createAccountButton.right
                anchors.left: createAccountButton.left

                Label {
                    text: isRendezVous ? qsTr("Encrypt archive with password") : qsTr("Encrypt account with password")

                    font.pointSize: JamiTheme.textFontSize + 3
                }

                Label {
                    text: qsTr("Optional")
                    color: "white"
                    anchors.right: parent.right
                    padding: 8

                    background: Rectangle {
                        color: "#28b1ed"
                        radius: 24
                        anchors.fill: parent
                    }
                }
            }

            RowLayout {
                spacing: 12
                height: 48

                anchors.right: createAccountButton.right
                anchors.left: createAccountButton.left

                Label {
                    text:  isRendezVous ? qsTr("Choose a password to encrypt the archive on this device") : qsTr("Choose a password to encrypt the account key on this device")

                    font.pointSize: JamiTheme.textFontSize
                }

                Switch {
                    id: passwordSwitch
                    Layout.alignment: Qt.AlignRight
                }
            }

            MaterialLineEdit {
                id: passwordEdit

                visible: passwordSwitch.checked

                fieldLayoutWidth: createAccountButton.width

                Layout.alignment: Qt.AlignHCenter

                selectByMouse: true
                echoMode: TextInput.Password
                placeholderText: qsTr("Password")
                font.pointSize: 10
                font.kerning: true
            }

            MaterialLineEdit {
                id: passwordConfirmEdit

                visible: passwordSwitch.checked

                fieldLayoutWidth: createAccountButton.width

                Layout.alignment: Qt.AlignHCenter

                selectByMouse: true
                echoMode: TextInput.Password
                placeholderText: qsTr("Confirm password")
                font.pointSize: 10
                font.kerning: true
            }

            Label {
                anchors.right: createAccountButton.right
                anchors.left: createAccountButton.left

                text: qsTr("Note that the password cannot be recovered")

                font.pointSize: JamiTheme.textFontSize
            }

            MaterialButton {
                id: createAccountButton
                text: isRendezVous ? qsTr("CREATE MEETING") : qsTr("CREATE ACCOUNT")
                color: !passwordSwitch.checked ||
                    (passwordEdit.text === passwordConfirmEdit.text && passwordEdit.text.length !== 0)?
                    JamiTheme.wizardBlueButtons : JamiTheme.buttonTintedGreyInactive
                hoveredColor: JamiTheme.buttonTintedBlueHovered
                pressedColor: JamiTheme.buttonTintedBluePressed

                onClicked: {
                    createAccount()
                    createAccountStack.currentIndex = createAccountStack.currentIndex + 1
                }
            }
        }
    }

    RowLayout {
        spacing: 12
        height: 48

        anchors.top: createAccountStack.bottom
        anchors.horizontalCenter: root.horizontalCenter
        Layout.alignment: Qt.AlignHCenter

        Rectangle {
            color: usernameEdit.visible? JamiTheme.wizardBlueButtons : "grey"
            radius: height / 2
            height: 12
            width: 12
        }

        Rectangle {
            color: createAccountButton.visible? JamiTheme.wizardBlueButtons : "grey"
            radius: height / 2
            height: 12
            width: 12
        }

        Rectangle {
            color: "grey"
            radius: height / 2
            height: 12
            width: 12
        }
    }

    HoverableButton {
        id: cancelButton
        z: 2

        anchors.right: parent.right
        anchors.top: parent.top

        rightPadding: 90
        topPadding: 90

        Layout.preferredWidth: 96
        Layout.preferredHeight: 96

        backgroundColor: "transparent"
        onEnterColor: "transparent"
        onPressColor: "transparent"
        onReleaseColor: "transparent"
        onExitColor: "transparent"

        buttonImageHeight: 48
        buttonImageWidth: 48
        source: "qrc:/images/icons/ic_close_white_24dp.png"
        radius: 48
        baseColor: "#7c7c7c"
        toolTipText: qsTr("Return to welcome page")

        Shortcut {
            sequence: StandardKey.Cancel
            enabled: parent.visible
            onActivated: leavePage()
        }

        onClicked: {
            leavePage()
        }
    }
}
