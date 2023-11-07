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

    signal accepted

    title: JamiStrings.setUsername

    button2.onClicked: close()

    popupContent: StackLayout {
        id: stackedWidget

        width: children[currentIndex].width

        function startRegistration() {
            stackedWidget.currentIndex = nameRegisterSpinnerPage.pageIndex;
            spinnerMovie.visible = true;
            timerForStartRegistration.restart();
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
                root.button1.text = JamiStrings.close;
                button1Role = DialogButtonBox.RejectRole;
                root.button1.onClicked = close()
                root.button2.visible = false;
            }
        }

        onVisibleChanged: {
            if (visible) {
                lblRegistrationError.text = JamiStrings.somethingWentWrong;
                passwordEdit.clear();
                if (CurrentAccount.hasArchivePassword) {
                    stackedWidget.currentIndex = nameRegisterEnterPasswordPage.pageIndex;
                    root.button1.text = JamiStrings.register;
                    button1Role = DialogButtonBox.AcceptRole;
                    root.button1.enabled = false
                    root.button1.clicked.connect(function() {
                        stackedWidget.startRegistration();
                    });

                    root.button2.text = JamiStrings.optionCancel;
                    root.button2Role = DialogButtonBox.RejectRole

                    passwordEdit.forceActiveFocus();
                } else {
                    startRegistration();
                }
            }
        }

        // Index = 0
        Item {
            id: nameRegisterEnterPasswordPage

            readonly property int pageIndex: 0

            width: childrenRect.width
            height: childrenRect.height

            ColumnLayout {

                spacing: 16

                Label {
                    Layout.alignment: Qt.AlignCenter

                    text: JamiStrings.enterAccountPassword
                    color: JamiTheme.textColor
                    font.pointSize: JamiTheme.textFontSize
                    font.kerning: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                MaterialLineEdit {
                    id: passwordEdit

                    Layout.alignment: Qt.AlignCenter
                    Layout.preferredWidth: JamiTheme.preferredFieldWidth
                    Layout.preferredHeight: 48

                    echoMode: TextInput.Password
                    placeholderText: JamiStrings.password

                    onTextChanged: root.button1.enabled = (text.length > 0)

                    onAccepted: root.button1.clicked()
                }
            }
        }

        // Index = 1
        Item {
            id: nameRegisterSpinnerPage

            readonly property int pageIndex: 1

            width: childrenRect.width
            height: childrenRect.height

            ColumnLayout {

                spacing: 16

                Label {
                    Layout.alignment: Qt.AlignCenter

                    text: JamiStrings.registeringName
                    color: JamiTheme.textColor
                    font.pointSize: JamiTheme.textFontSize + 3
                    font.kerning: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                AnimatedImage {
                    id: spinnerMovie

                    Layout.alignment: Qt.AlignCenter

                    Layout.preferredWidth: 30
                    Layout.preferredHeight: 30

                    source: JamiResources.jami_rolling_spinner_gif
                    playing: visible
                    fillMode: Image.PreserveAspectFit
                    mipmap: true
                }
            }
        }

        // Index = 2
        Item {
            id: nameRegisterErrorPage

            readonly property int pageIndex: 2

            width: childrenRect.width
            height: childrenRect.height

            ColumnLayout {

                Label {
                    id: lblRegistrationError

                    Layout.alignment: Qt.AlignCenter
                    text: JamiStrings.somethingWentWrong
                    font.pointSize: JamiTheme.textFontSize + 3
                    font.kerning: true
                    color: JamiTheme.redColor
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }
    }
}
