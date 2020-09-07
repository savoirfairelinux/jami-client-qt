/*
 * Copyright (C) 2020 by Savoir-faire Linux
 * Author: Yang Wang <yang.wang@savoirfairelinux.com>
 * Author: Albert Babí <yang.wang@savoirfairelinux.com>
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

import QtQuick 2.15
import QtQuick.Controls 2.14
import QtQuick.Layouts 1.14
import QtQuick.Controls.Styles 1.4
import QtQuick.Window 2.15
import net.jami.Models 1.0

import "../../commoncomponents"

Window {
    id: root

    property string registerdName : ""

    signal accepted

    function openNameRegistrationDialog(registerNameIn) {
        registerdName = registerNameIn
        lblRegistrationError.text = qsTr("Something went wrong")
        passwordEdit.clear()
        if (ClientWrapper.accountAdaptor.hasPassword()) {
            stackedWidget.currentIndex = 0
        } else {
            startRegistration()
        }
        show()
    }

    function startRegistration() {
        startSpinner()
        timerForStartRegistration.restart()
    }

    function slotStartNameRegistration() {
        var password = passwordEdit.text
        ClientWrapper.accountModel.registerName(ClientWrapper.utilsAdaptor.getCurrAccId(), password, registerdName)
    }

    function startSpinner() {
        stackedWidget.currentIndex = 1
        spinnerLabel.visible = true
        spinnerMovie.playing = true
    }

    Timer {
        id: timerForStartRegistration

        interval: 100
        repeat: false

        onTriggered: {
            slotStartNameRegistration()
        }
    }

    Connections {
        target: ClientWrapper.nameDirectory

        function onNameRegistrationEnded(status, name) {
            switch(status) {
            case NameDirectory.RegisterNameStatus.SUCCESS:
                accepted()
                close()
                return
            case NameDirectory.RegisterNameStatus.WRONG_PASSWORD:
                lblRegistrationError.text = qsTr("Incorrect password")
                break
            case NameDirectory.RegisterNameStatus.NETWORK_ERROR:
                lblRegistrationError.text = qsTr("Network error")
                break
            default:
                break
            }
            stackedWidget.currentIndex = 2
        }
    }

    visible: false
    title: qsTr("Register Name")
    modality: Qt.WindowModal
    flags: Qt.WindowStaysOnTopHint

    width: JamiTheme.preferredDialogWidth
    height: JamiTheme.preferredDialogWidth
    minimumWidth: JamiTheme.preferredDialogWidth
    minimumHeight: JamiTheme.preferredDialogHeight

    Rectangle {
        implicitWidth: root.width
        implicitHeight: root.height
        color: "transparent"

        StackLayout {
            id: stackedWidget
            anchors.fill: parent

            // Index = 0
            ColumnLayout {
                anchors.centerIn: parent
                spacing: 16

                Label {
                    Layout.alignment: Qt.AlignCenter
                    text: qsTr("Enter your account password")
                    font.pointSize: JamiTheme.textFontSize
                    font.kerning: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                MaterialLineEdit {
                    id: passwordEdit

                    Layout.alignment: Qt.AlignCenter
                    Layout.minimumWidth: JamiTheme.preferredFieldWidth
                    Layout.preferredWidth: JamiTheme.preferredFieldWidth
                    Layout.maximumWidth: JamiTheme.preferredFieldWidth
                    Layout.minimumHeight: 48
                    Layout.preferredHeight: 48
                    Layout.maximumHeight: 48

                    echoMode: TextInput.Password

                    placeholderText: qsTr("Password")

                    onTextChanged: btnRegister.enabled = (text.length > 0)
                }

                RowLayout {
                    spacing: 16
                    Layout.alignment: Qt.AlignHCenter
                    Layout.fillWidth: true

                    MaterialButton {
                        id: btnRegister

                        Layout.alignment: Qt.AlignHCenter
                        Layout.minimumWidth: JamiTheme.preferredFieldWidth / 2 - 8
                        Layout.preferredWidth: JamiTheme.preferredFieldWidth / 2 - 8
                        Layout.maximumWidth: JamiTheme.preferredFieldWidth / 2 - 8
                        Layout.minimumHeight: JamiTheme.preferredFieldHeight
                        Layout.preferredHeight: JamiTheme.preferredFieldHeight
                        Layout.maximumHeight: JamiTheme.preferredFieldHeight

                        color: enabled? JamiTheme.buttonTintedBlack : JamiTheme.buttonTintedGrey
                        hoveredColor: JamiTheme.buttonTintedBlackHovered
                        pressedColor: JamiTheme.buttonTintedBlackPressed
                        outlined: true
                        enabled: false

                        text: qsTr("Register")

                        onClicked: {
                            startRegistration()
                        }
                    }

                    MaterialButton {
                        id: btnCancel

                        Layout.alignment: Qt.AlignHCenter
                        Layout.minimumWidth: JamiTheme.preferredFieldWidth / 2 - 8
                        Layout.preferredWidth: JamiTheme.preferredFieldWidth / 2 - 8
                        Layout.maximumWidth: JamiTheme.preferredFieldWidth / 2 - 8
                        Layout.minimumHeight: JamiTheme.preferredFieldHeight
                        Layout.preferredHeight: JamiTheme.preferredFieldHeight
                        Layout.maximumHeight: JamiTheme.preferredFieldHeight

                        color: JamiTheme.buttonTintedBlack
                        hoveredColor: JamiTheme.buttonTintedBlackHovered
                        pressedColor: JamiTheme.buttonTintedBlackPressed
                        outlined: true

                        text: qsTr("Cancel")

                        onClicked: {
                            close()
                        }
                    }
                }
            }

            // Index = 1
            ColumnLayout {
                anchors.centerIn: parent
                spacing: 16

                Label {
                    Layout.alignment: Qt.AlignCenter
                    text: qsTr("Registering Name")
                    font.pointSize: JamiTheme.textFontSize
                    font.kerning: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                Label {
                    id: spinnerLabel

                    Layout.alignment: Qt.AlignHCenter

                    Layout.maximumWidth: 96
                    Layout.preferredWidth: 96
                    Layout.minimumWidth: 96

                    Layout.maximumHeight: 96
                    Layout.preferredHeight: 96
                    Layout.minimumHeight: 96

                    background: Rectangle {
                        AnimatedImage {
                            id: spinnerMovie
                            anchors.fill: parent
                            source: "qrc:/images/jami_eclipse_spinner.gif"
                            playing: spinnerLabel.visible
                            paused: false
                            fillMode: Image.PreserveAspectFit
                            mipmap: true
                        }
                    }
                }
            }

            // Index = 2
            ColumnLayout {
                anchors.centerIn: parent
                spacing: 16

                Label {
                    id: lblRegistrationError

                    Layout.alignment: Qt.AlignCenter
                    text: qsTr("Something went wrong")
                    font.pointSize: JamiTheme.textFontSize
                    font.kerning: true
                    color: "red"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                MaterialButton {
                    id: btnClose

                    Layout.alignment: Qt.AlignHCenter
                    Layout.minimumWidth: JamiTheme.preferredFieldWidth / 2 - 8
                    Layout.preferredWidth: JamiTheme.preferredFieldWidth / 2 - 8
                    Layout.maximumWidth: JamiTheme.preferredFieldWidth / 2 - 8
                    Layout.minimumHeight: JamiTheme.preferredFieldHeight
                    Layout.preferredHeight: JamiTheme.preferredFieldHeight
                    Layout.maximumHeight: JamiTheme.preferredFieldHeight

                    color: JamiTheme.buttonTintedBlack
                    hoveredColor: JamiTheme.buttonTintedBlackHovered
                    pressedColor: JamiTheme.buttonTintedBlackPressed
                    outlined: true

                    text: qsTr("Close")

                    onClicked: {
                        close()
                    }
                }
            }
        }
    }
}
