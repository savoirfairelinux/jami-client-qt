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

import "../"
import "../../constant"
import "../../commoncomponents"
import "../../settingsview/components"

Rectangle {
    id: root

    property /*alias*/ var text_fullNameEditAlias: null// fullNameEdit.text
    property alias text_usernameEditAlias: usernameEdit.text

    property int nameRegistrationUIState: WizardView.BLANK

    property /*alias*/ var isToSetPassword_checkState_choosePasswordCheckBox: null// choosePasswordCheckBox.checked

    // photo booth alias
    property /*alias*/ var boothImgBase64: null// setAvatarWidget.imgBase64

    // collapse password widget property aliases
    property /*alias*/ var text_passwordEditAlias: null// collapsiblePasswordWidget.text_passwordEditAlias
    property /*alias*/ var text_confirmPasswordEditAlias: null// collapsiblePasswordWidget.text_confirmPasswordEditAlias
    property /*alias*/ var displayState_passwordStatusLabelAlias: null// collapsiblePasswordWidget.state_passwordStatusLabelAlias

    signal validateWizardProgressionCreateAccountPage
    signal leavePage

    function initializeOnShowUp() {
        //clearAllTextFields()
//
        //signUpCheckbox.checked = true
        //choosePasswordCheckBox.checked = false
        usernameEdit.enabled = true
        //fullNameEdit.enabled = true
    }

    function clearAllTextFields() {
        usernameEdit.clear()
        //fullNameEdit.clear()
//
        //collapsiblePasswordWidget.clearAllTextFields()
    }

    function setCollapsiblePasswordWidgetVisibility(visible) {
        /*choosePasswordCheckBox.checked = visible
        if (visible) {
            choosePasswordCheckBox.visible = true
        }*/
    }

    function startBooth(){
        //setAvatarWidget.startBooth()
    }

    function stopBooth(){
        //setAvatarWidget.stopBooth()
    }

    anchors.fill: parent

    color: JamiTheme.backgroundColor

    /*
    * JamiFileDialog for exporting account
    */
    JamiFileDialog {
        id: exportBtn_Dialog

        mode: JamiFileDialog.SaveFile

        title: qsTr("Export Account Here")
        folder: StandardPaths.writableLocation(StandardPaths.HomeLocation) + "/Desktop"

        nameFilters: [qsTr("Jami archive files") + " (*.gz)", qsTr(
                "All files") + " (*)"]

        onAccepted: {
            export_Btn_FileDialogAccepted(true, file)
        }

        onRejected: {
            export_Btn_FileDialogAccepted(false, folder)
        }

        onVisibleChanged: {
            if (!visible) {
                rejected()
            }
        }
    }

    Rectangle {
        radius: 24
        color: "transparent"

        width: parent.width / 2
        height: parent.height / 2
        anchors.verticalCenter: root.verticalCenter
        anchors.horizontalCenter: root.horizontalCenter

        StackLayout {
            id: createAccountStack

            anchors.fill: parent

            ColumnLayout {
                spacing: 12

                anchors.verticalCenter: parent.verticalCenter
                Layout.preferredWidth: parent.width
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

                RowLayout {
                    spacing: 12
                    height: 48

                    Layout.fillWidth: true
                    anchors.left: usernameEdit.left
                    anchors.right: usernameEdit.right

                    Label {
                        text: qsTr("Choose a username for your account")

                        font.pointSize: JamiTheme.headerFontSize
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

                InfoLineEdit {
                    id: usernameEdit

                    selectByMouse: true
                    placeholderText: qsTr("Choose your username")
                    font.pointSize: 10
                    font.kerning: true

                    borderColorMode: nameRegistrationUIState === WizardView.BLANK ? InfoLineEdit.NORMAL
                                   : nameRegistrationUIState >= WizardView.FREE ? InfoLineEdit.NORMAL : InfoLineEdit.ERROR

                    enabled: signUpCheckbox.visible && signUpCheckbox.checked
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
                            return qsTr("Invalid username")
                        case WizardView.TAKEN:
                            return qsTr("Username already taken")
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
                    text: qsTr("CHOOSE USERNAME")
                    color: nameRegistrationUIState === WizardView.FREE?
                            JamiTheme.buttonTintedGrey
                            : JamiTheme.buttonTintedGreyInactive

                    onClicked: {
                        if (nameRegistrationUIState === WizardView.FREE)
                            createAccountStack.currentIndex = createAccountStack.currentIndex + 1
                    }
                }


                MaterialButton {
                    text: qsTr("SKIP CHOOSING USERNAME")
                    color: JamiTheme.buttonTintedGrey
                    outlined: true

                    onClicked: {
                        createAccountStack.currentIndex = createAccountStack.currentIndex + 1
                    }
                }
            }

            ColumnLayout {
                spacing: 12

                anchors.verticalCenter: parent.verticalCenter
                Layout.preferredWidth: parent.width
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

                RowLayout {
                    spacing: 12
                    height: 48

                    anchors.right: parent.right
                    anchors.left: parent.left

                    Label {
                        text: qsTr("Encrypt account with password")

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

                    Layout.fillWidth: true

                    Label {
                        text: qsTr("Choose a password to encrypt the account key on this device")

                        font.pointSize: JamiTheme.textFontSize
                    }

                    ToggleSwitch {
                    }
                }

                Label {
                    text: qsTr("Note that the password cannot be recovered")

                    font.pointSize: JamiTheme.textFontSize
                }

                MaterialButton {
                    id: createAccountButton
                    text: qsTr("CREATE ACCOUNT")
                    color: JamiTheme.wizardBlueButtons

                    onClicked: {
                        console.log("///TODO///")
                    }
                }
            }

            ColumnLayout {

                spacing: 12

                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter

                RowLayout {
                    spacing: 12
                    height: 48

                    anchors.right: parent.right
                    anchors.left: parent.left

                    Label {
                        text: qsTr("Profile is only shared with contacts")

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

                PhotoboothView {
                    id: setAvatarWidget

                    Layout.alignment: Qt.AlignHCenter

                    Layout.maximumWidth: 261
                    Layout.preferredWidth: 261
                    Layout.minimumWidth: 261
                    Layout.maximumHeight: 261
                    Layout.preferredHeight: 261
                    Layout.minimumHeight: 261
                }

                InfoLineEdit {
                    id: displayNameEdit

                    anchors.left: parent.left
                    anchors.right: parent.right

                    selectByMouse: true
                    placeholderText: qsTr("Enter your name")
                    font.pointSize: 10
                    font.kerning: true

                    enabled: signUpCheckbox.visible && signUpCheckbox.checked

                    topPadding: 12
                    bottomPadding: 12
                    background: Rectangle {
                        color: "white"
                        radius: 24
                        anchors.fill: parent
                    }
                }

                Button {
                    text: qsTr("SAVE PROFILE")
                    Layout.alignment: Qt.AlignHCenter

                    background: Rectangle {
                        height: parent.height
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 200
                        color: "#28b1ed"
                        radius: height / 2
                    }

                    onClicked: {
                        createAccountStack.currentIndex = createAccountStack.currentIndex + 1
                    }
                }

                Button {
                    text: qsTr("SKIP AND DO THIS LATER")
                    Layout.alignment: Qt.AlignHCenter

                    background: Rectangle {
                        height: parent.height
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 200
                        color: "transparent"
                        radius: height / 2
                    }

                    onClicked: {
                        createAccountStack.currentIndex = createAccountStack.currentIndex + 1
                    }
                }
            }

            ColumnLayout {

                spacing: 12

                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter

                RowLayout {
                    spacing: 12
                    height: 48

                    anchors.right: parent.right
                    anchors.left: parent.left

                    Label {
                        text: qsTr("Backup your account!")

                        font.pointSize: JamiTheme.textFontSize + 3
                    }

                    Label {
                        text: qsTr("Recommended")
                        color: "white"
                        padding: 8

                        background: Rectangle {
                            color: "#aed581"
                            radius: 24
                            anchors.fill: parent
                        }
                    }
                }

                Label {
                    text: qsTr("This account only exists on this device. If you lost your device or uninstall the application, your account will be deleted. You can backup your account now or later.")
                    wrapMode:Text.Wrap

                    font.pointSize: JamiTheme.textFontSize
                }

                RowLayout {
                    spacing: 12
                    height: 48

                    Layout.fillWidth: true

                    Label {
                        text: qsTr("Never show me this again")

                        font.pointSize: JamiTheme.textFontSize
                    }

                    ToggleSwitch {
                    }
                }

                Button {
                    text: qsTr("BACKUP ACCOUNT")
                    Layout.alignment: Qt.AlignHCenter

                    background: Rectangle {
                        height: parent.height
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 200
                        color: "#e0e0e0"
                        radius: height / 2
                    }

                    onClicked: {
                        exportBtn_Dialog.open()
                        leavePage()
                    }
                }

                Button {
                    text: qsTr("SKIP")
                    Layout.alignment: Qt.AlignHCenter

                    background: Rectangle {
                        height: parent.height
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 200
                        color: "transparent"
                        radius: height / 2
                    }

                    onClicked: {
                        leavePage()
                    }
                }
            }
        }

    }

    HoverableButton {
        id: cancelButton
        z: 2

        anchors.right: parent.right
        anchors.top: parent.top

        rightPadding: 48
        topPadding: 48

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

        onClicked: {
            leavePage()
        }
    }

    /*ColumnLayout {
        Layout.alignment: Qt.AlignHCenter

        spacing: 5

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6

            Layout.alignment: Qt.AlignHCenter

        Label {
            id: profileSectionLabel


            Layout.alignment: Qt.AlignHCenter

            text: qsTr("Profile")
            font.pointSize: 13
            font.kerning: true

            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }


        RowLayout {
            spacing: 6
            Layout.alignment: Qt.AlignHCenter
            Layout.maximumHeight: 30

            Item {
                Layout.fillWidth: true
                Layout.maximumHeight: 10
            }

            InfoLineEdit {
                id: fullNameEdit

                fieldLayoutWidth: 261

                Layout.alignment: Qt.AlignCenter

                selectByMouse: true
                placeholderText: qsTr("Profile name")
                font.pointSize: 10
                font.kerning: true
            }

            Item {
                Layout.fillHeight: true
                Layout.fillWidth: true
            }
        }
        }
    }

    Item {
        Layout.fillHeight: true
        Layout.fillWidth: true
    }

    ColumnLayout {
        Layout.alignment: Qt.AlignHCenter

        spacing: 5
        Label {
            id: accountSectionLabel
            Layout.alignment: Qt.AlignHCenter

            Layout.maximumWidth: 261
            Layout.preferredWidth: 261
            Layout.minimumWidth: 261
            Layout.maximumHeight: 30
            Layout.preferredHeight: 30
            Layout.minimumHeight: 30

            text: qsTr("Account")
            font.pointSize: 13
            font.kerning: true

            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6

            CheckBox {
                id: signUpCheckbox
                checked: true

                indicator.width: 10
                indicator.height: 10

                Layout.leftMargin: 32

                Layout.minimumWidth: 261

                Layout.maximumHeight: 30
                Layout.preferredHeight: 30
                Layout.minimumHeight: 25

                Layout.alignment: Qt.AlignLeft

                text: qsTr("Register public username")
                font.pointSize: 10
                font.kerning: true

                indicator.implicitWidth: 20
                indicator.implicitHeight:20

                onClicked: {
                    if (!checked) {
                        usernameEdit.clear()
                    }

                    validateWizardProgressionCreateAccountPage()
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6

            CheckBox {
                id: choosePasswordCheckBox
                checked: false

                indicator.width: 10
                indicator.height: 10

                Layout.leftMargin: 32

                Layout.minimumWidth: 261

                Layout.preferredHeight: 30
                Layout.minimumHeight: 25

                indicator.implicitWidth: 20
                indicator.implicitHeight:20

                Layout.alignment: Qt.AlignLeft

                text: qsTr("Choose a password for enhanced security")
                font.pointSize: 8
                font.kerning: true

                onClicked: {
                    if (!checked) {
                        collapsiblePasswordWidget.clearAllTextFields()
                    }

                    validateWizardProgressionCreateAccountPage()
                }
            }

            CollapsiblePasswordWidget {
                id: collapsiblePasswordWidget

                Layout.alignment: Qt.AlignHCenter

                visibleCollapsble: choosePasswordCheckBox.checked
                                   && choosePasswordCheckBox.visible
            }
        }

        Item {
            Layout.maximumWidth: 261
            Layout.preferredWidth: 261
            Layout.minimumWidth: 261

            Layout.maximumHeight: 30
            Layout.preferredHeight: 30
            Layout.minimumHeight: 30

            Layout.alignment: Qt.AlignHCenter
        }
    }*/
}
