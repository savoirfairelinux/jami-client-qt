/*!
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

import QtQuick 2.15
import QtQuick.Controls 2.14
import QtQuick.Layouts 1.14
import QtQuick.Controls.Styles 1.4
import net.jami.Models 1.0

import "../../commoncomponents"

Dialog {
    id: root

    function openLinkDeviceDialog() {
        infoLabel.text = qsTr("This pin and the account password should be entered in your device within 10 minutes.")
        passwordEdit.clear()
        root.open()
        if(ClientWrapper.accountAdaptor.hasPassword()) {
            stackedWidget.currentIndex = 0
        } else {
            setGeneratingPage()
        }
    }

    function setGeneratingPage() {
        if(passwordEdit.length === 0 && ClientWrapper.accountAdaptor.hasPassword()){
            setExportPage(NameDirectory.ExportOnRingStatus.WRONG_PASSWORD, "")
            return
        }

        stackedWidget.currentIndex = 1
        spinnerMovie.playing = true

        timerForExport.restart()
    }

    function slotExportOnRing() {
        ClientWrapper.accountModel.exportOnRing(ClientWrapper.utilsAdaptor.getCurrAccId(),passwordEdit.text)
    }

    Timer{
        id: timerForExport

        repeat: false
        interval: 200

        onTriggered: {
            timeOut.restart()
            slotExportOnRing()
        }
    }

    Timer{
        id: timeOut

        repeat: false
        interval: exportTimeout

        onTriggered: {
            setExportPage(NameDirectory.ExportOnRingStatus.NETWORK_ERROR, "")
        }
    }

    function setExportPage(status, pin){
        timeOut.stop()

        if(status === NameDirectory.ExportOnRingStatus.SUCCESS) {
            infoLabel.isSucessState = true
            yourPinLabel.visible = true
            exportedPIN.visible = true
            infoLabel.text = qsTr("This pin and the account password should be entered in your device within 10 minutes.")
            exportedPIN.text = pin
        } else {
            infoLabel.isSucessState = false
            yourPinLabel.visible = false
            exportedPIN.visible = false

            switch(status) {
            case NameDirectory.ExportOnRingStatus.WRONG_PASSWORD:
                infoLabel.text = qsTr("Incorrect password")

                break
            case NameDirectory.ExportOnRingStatus.NETWORK_ERROR:
                infoLabel.text = qsTr("Error connecting to the network.\nPlease try again later.")

                break
            case NameDirectory.ExportOnRingStatus.INVALID:
                infoLabel.text = qsTr("Something went wrong.\n")

                break
            }
        }
        stackedWidget.currentIndex = 2
    }

    property int exportTimeout : 20000

    Connections{
        target: ClientWrapper.nameDirectory

        function onExportOnRingEnded(status, pin) {
            setExportPage(status, pin)
        }
    }

    visible: false

    x: (parent.width - width) / 2
    y: (parent.height - height) / 2

    header : Rectangle {
        width: parent.width
        height: 64
        color: "transparent"
        Text {
            anchors.left: parent.left
            anchors.leftMargin: 24
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 24

            text: qsTr("Link another device")
            font.pointSize: JamiTheme.headerFontSize
        }
    }

    onClosed: {
        if(infoLabel.isSucessState) {
            accept()
        } else {
            reject()
        }
    }

    contentItem: Rectangle {
        implicitWidth: 350
        implicitHeight: 210

        StackLayout {
            id: stackedWidget
            anchors.fill: parent
            currentIndex: 2

            Rectangle {
                id: passwordConfirmPage

                Layout.fillWidth: true
                Layout.fillHeight: true

                Layout.leftMargin: 11
                Layout.rightMargin: 11
                Layout.topMargin: 11
                Layout.bottomMargin: 11

                ColumnLayout {
                    anchors.fill: parent

                    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

                    Label {
                        Layout.topMargin: 20
                        Layout.preferredWidth: 219
                        Layout.alignment: Qt.AlignHCenter
                        wrapMode: Text.Wrap
                        text: qsTr("Enter your account password")
                        font.pointSize: 8
                        font.kerning: true
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    InfoLineEdit {
                        id: passwordEdit

                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: 20

                        Layout.minimumWidth: 294
                        Layout.preferredWidth: 294
                        Layout.preferredHeight: 30

                        echoMode: TextInput.Password

                        placeholderText: qsTr("Password")
                    }

                    RowLayout {

                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: 20
                        Layout.fillWidth: true
                        Layout.preferredHeight: 30

                        HoverableRadiusButton {
                            id: btnPasswordOk

                            Layout.preferredWidth: 130

                            radius: height / 2

                            text: qsTr("Register")
                            font.pointSize: 10
                            font.kerning: true

                            onClicked: {
                                setGeneratingPage()
                            }
                        }

                        HoverableButtonTextItem {
                            id: btnCancel
                            Layout.leftMargin: 40

                            Layout.preferredWidth: 130
                            Layout.minimumWidth: 130
                            Layout.preferredHeight: 30

                            backgroundColor: "red"
                            onEnterColor: Qt.rgba(150 / 256, 0, 0, 0.7)
                            onDisabledBackgroundColor: Qt.rgba(
                                                           255 / 256,
                                                           0, 0, 0.8)
                            onPressColor: backgroundColor
                            textColor: "white"

                            radius: height /2

                            text: qsTr("Cancel")
                            font.pointSize: 10
                            font.kerning: true

                            onClicked: {
                                reject()
                            }
                        }
                    }
                }
            }

            Rectangle {
                id: exportingPage

                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.topMargin: 20

                ColumnLayout {
                    anchors.fill: parent
                    anchors.centerIn: parent

                    Label {
                        Layout.alignment: Qt.AlignLeft

                        Layout.preferredHeight: 30
                        Layout.leftMargin: JamiTheme.preferredMarginSize

                        wrapMode: Text.Wrap
                        text: qsTr("Exporting Account")
                        horizontalAlignment: Text.AlignLeft
                        verticalAlignment: Text.AlignVCenter
                    }

                    RowLayout {
                        Layout.preferredHeight: 20

                        Label {
                            id: exportingSpinner

                            Layout.alignment: Qt.AlignHCenter

                            Layout.preferredWidth: 96
                            Layout.preferredHeight: 96

                            background: Rectangle {
                                anchors.fill: parent
                                AnimatedImage {
                                    id: spinnerMovie

                                    anchors.fill: parent

                                    source: "qrc:/images/jami_eclipse_spinner.gif"

                                    playing: exportingSpinner.visible
                                    paused: false
                                    fillMode: Image.PreserveAspectFit
                                    mipmap: true
                                }
                            }
                        }
                    }
                }
            }

            Rectangle {
                id: exportedPage

                Layout.fillWidth: true
                Layout.fillHeight: true

                ColumnLayout {
                    anchors.fill: parent
                    anchors.centerIn: parent

                    RowLayout {
                        Layout.alignment: Qt.AlignLeft
                        Layout.fillWidth: true
                        Layout.leftMargin: JamiTheme.preferredMarginSize

                        Label {
                            id: yourPinLabel

                            Layout.alignment: Qt.AlignLeft
                            Layout.preferredHeight: 24

                            wrapMode: Text.Wrap
                            text: "Your PIN is:"
                            font.kerning: true
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        Label {
                            id: exportedPIN

                            Layout.alignment: Qt.AlignHCenter
                            Layout.preferredHeight: 24

                            wrapMode: Text.Wrap
                            text: "PIN"
                            font.pointSize: 12
                            font.kerning: true
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                    }

                    Label {
                        id: infoLabel

                        property bool isSucessState: false
                        property int borderWidth : isSucessState? 1 : 0
                        property int borderRadius : isSucessState? 15 : 0
                        property string backgroundColor : isSucessState? "whitesmoke" : "transparent"
                        property string borderColor : isSucessState? "lightgray" : "transparent"
                        color: isSucessState ? "#2b5084" : "black"
                        padding: isSucessState ? 8 : 0

                        Layout.alignment: Qt.AlignLeft
                        Layout.leftMargin: 12
                        Layout.preferredWidth: 280 - 32
                        Layout.preferredHeight: 50

                        wrapMode: Text.Wrap
                        text: qsTr("This pin and the account password should be entered in your device within 10 minutes.")
                        font.pointSize: 8
                        font.kerning: true

                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter

                        background: Rectangle{
                            id: infoLabelBackground

                            anchors.fill: parent
                            border.width: infoLabel.borderWidth
                            border.color: infoLabel.borderColor
                            radius: infoLabel.borderRadius
                            color: infoLabel.backgroundColor
                        }
                    }

                    RowLayout {
                        width: 280
                        Layout.alignment: Qt.AlignRight

                        Button {
                            id: btnCloseExportDialog

                            contentItem: Text {
                                text: qsTr("CLOSE")
                                color: JamiTheme.buttonTintedBlue
                            }

                            background: Rectangle {
                                color: "transparent"
                            }

                            onClicked: {
                                if(infoLabel.isSucessState) {
                                    accept()
                                } else {
                                    reject()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
