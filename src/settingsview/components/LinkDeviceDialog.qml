/*
 * Copyright (C) 2020 by Savoir-faire Linux
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

import QtQuick 2.15
import QtQuick.Controls 2.14
import QtQuick.Layouts 1.14
import QtQuick.Controls.Styles 1.4
import QtQuick.Window 2.15
import net.jami.Models 1.0

import "../../commoncomponents"

Window {
    id: root

    property int exportTimeout : 20000

    signal accepted

    function openLinkDeviceDialog(){
        infoLabel.text = qsTr("This pin and the account password should be entered in your device within 10 minutes.")
        passwordEdit.clear()
        root.show()
        if(ClientWrapper.accountAdaptor.hasPassword()){
            stackedWidget.currentIndex = 0
        } else {
            setGeneratingPage()
        }
    }

    function setGeneratingPage(){
        if(passwordEdit.length === 0 && ClientWrapper.accountAdaptor.hasPassword()){
            setExportPage(NameDirectory.ExportOnRingStatus.WRONG_PASSWORD, "")
            return
        }

        stackedWidget.currentIndex = 1
        spinnerMovie.playing = true

        timerForExport.restart()
    }

    function slotExportOnRing(){
        ClientWrapper.accountModel.exportOnRing(ClientWrapper.utilsAdaptor.getCurrAccId(),passwordEdit.text)
    }

    function setExportPage(status, pin){
        timeOut.stop()

        if(status === NameDirectory.ExportOnRingStatus.SUCCESS){
            infoLabel.isSucessState = true
            yourPinLabel.visible = true
            exportedPIN.visible = true
            infoLabel.text = qsTr("This pin and the account password should be entered in your device within 10 minutes.")
            exportedPIN.text = pin
        } else {
            infoLabel.isSucessState = false
            yourPinLabel.visible = false
            exportedPIN.visible = false

            switch(status){
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

    title: qsTr("Link another device")
    visible: false
    modality: Qt.WindowModal
    flags: Qt.WindowStaysOnTopHint

    width: JamiTheme.preferredDialogWidth
    height: JamiTheme.preferredDialogWidth
    minimumWidth: JamiTheme.preferredDialogWidth
    minimumHeight: JamiTheme.preferredDialogHeight

    Timer {
        id: timerForExport

        repeat: false
        interval: 200

        onTriggered: {
            timeOut.restart()
            slotExportOnRing()
        }
    }

    Timer {
        id: timeOut

        repeat: false
        interval: exportTimeout

        onTriggered: {
            setExportPage(NameDirectory.ExportOnRingStatus.NETWORK_ERROR, "")
        }
    }

    Connections {
        target: ClientWrapper.nameDirectory

        function onExportOnRingEnded(status, pin){
            setExportPage(status, pin)
        }
    }

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
                    horizontalAlignment: Text.AlignLeft
                    verticalAlignment: Text.AlignVCenter

                    placeholderText: qsTr("Enter Current Password")

                    borderColorMode: InfoLineEdit.NORMAL
                }

                RowLayout {
                    Layout.alignment: Qt.AlignCenter
                    Layout.fillWidth: true
                    spacing: 16

                    Button {
                        id: btnPasswordOk

                        contentItem: Text {
                            text: qsTr("REGISTER")
                            color: JamiTheme.buttonTintedBlue
                        }

                        background: Rectangle {
                            color: "transparent"
                        }

                        onClicked: {
                            setGeneratingPage()
                        }
                    }

                    Button {
                        id: btnCancel

                        contentItem: Text {
                            text: qsTr("CANCEL")
                            color: JamiTheme.buttonTintedBlue
                        }

                        background: Rectangle {
                            color: "transparent"
                        }

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
                    text: qsTr("Exporting Account")
                    font.pointSize: JamiTheme.headerFontSize
                    font.kerning: true
                    horizontalAlignment: Text.AlignLeft
                    verticalAlignment: Text.AlignVCenter
                }

                Label {
                    id: exportingSpinner

                    Layout.alignment: Qt.AlignCenter

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
                            playing: exportingSpinner.visible
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

                RowLayout {
                    Layout.alignment: Qt.AlignCenter
                    Layout.fillWidth: true
                    Layout.margins: JamiTheme.preferredMarginSize
                    spacing: 16

                    Label {
                        id: yourPinLabel

                        Layout.alignment: Qt.AlignHCenter
                        text: qsTr("Your PIN is:")
                        font.pointSize: JamiTheme.textFontSize
                        font.kerning: true
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    Label {
                        id: exportedPIN
                        Layout.alignment: Qt.AlignHCenter
                        text: "PIN"
                        font.pointSize: JamiTheme.textFontSize
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

                    wrapMode: Text.Wrap
                    text: qsTr("This pin and the account password should be entered in your device within 10 minutes.")
                    font.pointSize: JamiTheme.textFontSize
                    font.kerning: true

                    Layout.maximumWidth: root.width - JamiTheme.preferredMarginSize * 2

                    Layout.alignment: Qt.AlignCenter
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

                Button {
                    id: btnCloseExportDialog
                    Layout.alignment: Qt.AlignCenter

                    contentItem: Text {
                        text: qsTr("CLOSE")
                        color: JamiTheme.buttonTintedBlue
                    }

                    background: Rectangle {
                        color: "transparent"
                    }

                    onClicked: {
                        if(infoLabel.isSucessState){
                            accepted()
                        }
                        close()
                    }
                }
            }
        }
    }
}

