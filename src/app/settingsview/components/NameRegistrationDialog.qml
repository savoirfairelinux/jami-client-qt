/*
 * Copyright (C) 2020-2023 Savoir-faire Linux Inc.
 * Author: Yang Wang <yang.wang@savoirfairelinux.com>
 * Author: Albert Babí <albert.babi@savoirfairelinux.com>
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
import QtQuick.Controls
import QtQuick.Layouts
import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import "../../commoncomponents"

BaseModalDialog {
    id: root
    property string registeredName: ""

    height: Math.min(appWindow.height - 2 * JamiTheme.preferredMarginSize, JamiTheme.preferredDialogHeight)
    title: JamiStrings.setUsername
    width: Math.min(appWindow.width - 2 * JamiTheme.preferredMarginSize, JamiTheme.preferredDialogWidth)

    signal accepted

    popupContent: StackLayout {
        id: stackedWidget
        function startRegistration() {
            stackedWidget.currentIndex = nameRegisterSpinnerPage.pageIndex;
            spinnerMovie.visible = true;
            timerForStartRegistration.restart();
        }

        onVisibleChanged: {
            if (visible) {
                lblRegistrationError.text = JamiStrings.somethingWentWrong;
                passwordEdit.clear();
                if (CurrentAccount.hasArchivePassword) {
                    stackedWidget.currentIndex = nameRegisterEnterPasswordPage.pageIndex;
                    passwordEdit.forceActiveFocus();
                } else {
                    startRegistration();
                }
            }
        }

        Timer {
            id: timerForStartRegistration
            interval: 100
            repeat: false

            onTriggered: {
                AccountAdapter.model.registerName(LRCInstance.currentAccountId, passwordEdit.text, registeredName);
            }
        }
        Connections {
            target: NameDirectory

            function onNameRegistrationEnded(status, name) {
                switch (status) {
                case NameDirectory.RegisterNameStatus.SUCCESS:
                    accepted();
                    close();
                    return;
                case NameDirectory.RegisterNameStatus.WRONG_PASSWORD:
                    lblRegistrationError.text = JamiStrings.incorrectPassword;
                    break;
                case NameDirectory.RegisterNameStatus.NETWORK_ERROR:
                    lblRegistrationError.text = JamiStrings.networkError;
                    break;
                default:
                    break;
                }
                stackedWidget.currentIndex = nameRegisterErrorPage.pageIndex;
            }
        }

        // Index = 0
        Item {
            id: nameRegisterEnterPasswordPage
            readonly property int pageIndex: 0

            ColumnLayout {
                anchors.fill: parent
                spacing: 16

                Label {
                    Layout.alignment: Qt.AlignCenter
                    color: JamiTheme.textColor
                    font.kerning: true
                    font.pointSize: JamiTheme.textFontSize
                    horizontalAlignment: Text.AlignHCenter
                    text: JamiStrings.enterAccountPassword
                    verticalAlignment: Text.AlignVCenter
                }
                MaterialLineEdit {
                    id: passwordEdit
                    Layout.alignment: Qt.AlignCenter
                    Layout.preferredHeight: 48
                    Layout.preferredWidth: JamiTheme.preferredFieldWidth
                    echoMode: TextInput.Password
                    placeholderText: JamiStrings.password

                    onAccepted: btnRegister.clicked()
                    onTextChanged: btnRegister.enabled = (text.length > 0)
                }
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.fillWidth: true
                    spacing: 16

                    MaterialButton {
                        id: btnRegister
                        Layout.alignment: Qt.AlignHCenter
                        buttontextHeightMargin: JamiTheme.buttontextHeightMargin
                        color: enabled ? JamiTheme.buttonTintedBlack : JamiTheme.buttonTintedGrey
                        enabled: false
                        hoveredColor: JamiTheme.buttonTintedBlackHovered
                        preferredWidth: JamiTheme.preferredFieldWidth / 2 - 8
                        pressedColor: JamiTheme.buttonTintedBlackPressed
                        secondary: true
                        text: JamiStrings.register

                        onClicked: stackedWidget.startRegistration()
                    }
                    MaterialButton {
                        id: btnCancel
                        Layout.alignment: Qt.AlignHCenter
                        buttontextHeightMargin: JamiTheme.buttontextHeightMargin
                        color: JamiTheme.buttonTintedBlack
                        hoveredColor: JamiTheme.buttonTintedBlackHovered
                        preferredWidth: JamiTheme.preferredFieldWidth / 2 - 8
                        pressedColor: JamiTheme.buttonTintedBlackPressed
                        secondary: true
                        text: JamiStrings.optionCancel

                        onClicked: close()
                    }
                }
            }
        }

        // Index = 1
        Item {
            id: nameRegisterSpinnerPage
            readonly property int pageIndex: 1

            ColumnLayout {
                anchors.fill: parent
                spacing: 16

                Label {
                    Layout.alignment: Qt.AlignCenter
                    color: JamiTheme.textColor
                    font.kerning: true
                    font.pointSize: JamiTheme.textFontSize + 3
                    horizontalAlignment: Text.AlignHCenter
                    text: JamiStrings.registeringName
                    verticalAlignment: Text.AlignVCenter
                }
                AnimatedImage {
                    id: spinnerMovie
                    Layout.alignment: Qt.AlignCenter
                    Layout.preferredHeight: 30
                    Layout.preferredWidth: 30
                    fillMode: Image.PreserveAspectFit
                    mipmap: true
                    playing: visible
                    source: JamiResources.jami_rolling_spinner_gif
                }
            }
        }

        // Index = 2
        Item {
            id: nameRegisterErrorPage
            readonly property int pageIndex: 2

            ColumnLayout {
                anchors.fill: parent
                spacing: 16

                Label {
                    id: lblRegistrationError
                    Layout.alignment: Qt.AlignCenter
                    color: JamiTheme.redColor
                    font.kerning: true
                    font.pointSize: JamiTheme.textFontSize + 3
                    horizontalAlignment: Text.AlignHCenter
                    text: JamiStrings.somethingWentWrong
                    verticalAlignment: Text.AlignVCenter
                }
                MaterialButton {
                    id: btnClose
                    Layout.alignment: Qt.AlignHCenter | Qt.AlignBottom
                    Layout.bottomMargin: JamiTheme.preferredMarginSize
                    buttontextHeightMargin: JamiTheme.buttontextHeightMargin
                    color: JamiTheme.buttonTintedBlack
                    hoveredColor: JamiTheme.buttonTintedBlackHovered
                    preferredWidth: JamiTheme.preferredFieldWidth / 2 - 8
                    pressedColor: JamiTheme.buttonTintedBlackPressed
                    secondary: true
                    text: JamiStrings.close

                    onClicked: close()
                }
            }
        }
    }
}
