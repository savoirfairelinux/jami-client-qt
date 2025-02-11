/*
 * Copyright (C) 2020-2024 Savoir-faire Linux Inc.
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
import net.jami.Enums 1.1
import "../../commoncomponents"
import "../../mainview/components"

BaseModalDialog {
    id: root

    signal accepted

    title: JamiStrings.linkNewDevice

    property bool darkTheme: UtilsAdapter.useApplicationTheme()

    popupContent: Item {
        id: content
        width: 350
        height: 400

        // Control the Page
        // Row {
        //     id: controls
        //     anchors.top: parent.top
        //     anchors.right: parent.right
        //     z: 1  // Ensure controls stay on top

        //     Button {
        //         text: "<"
        //         onClicked: stackLayout.currentIndex -= 1
        //         enabled: stackLayout.currentIndex > 0
        //     }
        //     Button {
        //         text: ">"
        //         onClicked: stackLayout.currentIndex += 1
        //         enabled: stackLayout.currentIndex < stackLayout.count - 1
        //     }
        // }

        // Scrollable container for StackLayout
        ScrollView {
            id: scrollView
            anchors.fill: parent
            anchors.leftMargin: 20
            anchors.rightMargin: 20
            anchors.bottomMargin: 20
           // anchors.topMargin: controls.height + 10
            clip: true
            
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
            ScrollBar.vertical.policy: ScrollBar.AsNeeded
            ScrollBar.vertical.visible: stackLayout.height > height

            StackLayout {
                id: stackLayout
                width: scrollView.width
                
                height: Math.max(deviceLinkErrorView.height,
                               deviceLinkSuccessView.height,
                               deviceLinkLoadingView.height,
                               deviceConfirmationView.height,
                               scanAndEnterCodeView.height)

                currentIndex: scanAndEnterCodeView.StackLayout.index  // Default view

                Connections {
                    target: DeviceLinkingModel

                    function onDeviceAuthStateChanged() {
                        switch (DeviceLinkingModel.deviceAuthState) {
                        case DeviceAuthStateEnum.INIT:
                            stackLayout.currentIndex = scanAndEnterCodeView.index
                            break
                        case DeviceAuthStateEnum.CONNECTING:
                            stackLayout.currentIndex = deviceLinkLoadingView.index
                            deviceLinkLoadingView.loadingText = "Connecting to your new device…"
                            break
                        case DeviceAuthStateEnum.AUTHENTICATING:
                            stackLayout.currentIndex = deviceConfirmationView.index
                            break
                        case DeviceAuthStateEnum.IN_PROGRESS:
                            stackLayout.currentIndex = deviceLinkLoadingView.index
                            deviceLinkLoadingView.loadingText = "Your account is exporting to your new device.\nPlease confirm import on the new device."
                            break
                        case DeviceAuthStateEnum.DONE:
                            stackLayout.currentIndex = deviceLinkSuccessView.index
                            break
                        case DeviceAuthStateEnum.ERROR:
                            stackLayout.currentIndex = deviceLinkErrorView.index
                            break
                        default:
                            break
                        }
                    }
                }

                Item {
                    id: deviceLinkErrorView
                    property int index: 0
                    Layout.fillWidth: true
                    Layout.preferredHeight: errorColumn.height

                    ColumnLayout {
                        id: errorColumn
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        spacing: 20

                        Rectangle {
                            Layout.alignment: Qt.AlignHCenter
                            width: 50
                            height: 50
                            radius: width/2
                            color: JamiTheme.refuseRed

                            Text {
                                anchors.centerIn: parent
                                text: "✕"
                                color: "white"
                                font.pointSize: 24
                                font.bold: true
                            }
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: DeviceLinkingModel.linkDeviceError
                            color: JamiTheme.textColor
                            font.pointSize: JamiTheme.textFontSize
                            font.bold: true
                        }
                    }
                }

                Item {
                    id: deviceLinkSuccessView
                    property int index: 1
                    Layout.fillWidth: true
                    Layout.preferredHeight: successColumn.height

                    ColumnLayout {
                        id: successColumn
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        spacing: 20

                        Rectangle {
                            Layout.alignment: Qt.AlignHCenter
                            width: 50
                            height: 50
                            radius: width/2
                            color: JamiTheme.acceptGreen

                            Text {
                                anchors.centerIn: parent
                                text: "✓"
                                color: "white"
                                font.pointSize: 24
                                font.bold: true
                            }
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "All Set!"
                            color: JamiTheme.textColor
                            font.pointSize: JamiTheme.textFontSize
                            font.bold: true
                        }
                    }
                }

                Item {
                    id: deviceLinkLoadingView
                    property int index: 2
                    Layout.fillWidth: true
                    Layout.preferredHeight: loadingColumn.height

                    property string loadingText: ""

                    ColumnLayout {
                        id: loadingColumn
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        spacing: 10

                        BusyIndicator {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.preferredWidth: 50
                            Layout.preferredHeight: 50
                            running: true
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: deviceLinkLoadingView.loadingText
                            color: JamiTheme.textColor
                            font.pointSize: JamiTheme.textFontSize
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.WordWrap
                            opacity: 1

                            SequentialAnimation on opacity {
                                running: true
                                loops: Animation.Infinite
                                NumberAnimation {
                                    from: 1
                                    to: 0.3
                                    duration: 1000
                                    easing.type: Easing.InOutQuad
                                }
                                NumberAnimation {
                                    from: 0.3
                                    to: 1
                                    duration: 1000
                                    easing.type: Easing.InOutQuad
                                }
                            }
                        }
                    }
                }

                Item {
                    id: deviceConfirmationView
                    property int index: 3
                    Layout.fillWidth: true
                    Layout.preferredHeight: confirmColumn.height

                    ColumnLayout {
                        id: confirmColumn
                        width: parent.width
                        spacing: 20

                        Text {
                            id: explanationConnect

                            Layout.alignment: Qt.AlignCenter
                            Layout.preferredWidth: scrollView.width

                            text: "New device found at address below. Is that you?\nClicking on confirm will continue transfering account."
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.WordWrap
                            color: JamiTheme.textColor
                            font.pointSize: JamiTheme.mediumFontSize
                        }

                        // address text
                        RowLayout {
                            Layout.alignment: Qt.AlignHCenter
                            spacing: 8

                            Text {
                                id: ipAddressTextAreaExplanation
                                text: "New device IP:"
                                horizontalAlignment: Text.AlignHCenter
                                wrapMode: Text.WordWrap
                                color: JamiTheme.textColor
                                font.pointSize: JamiTheme.mediumFontSize
                                font.weight: Font.Bold
                            }

                            Text {
                                id: ipAddressTextArea
                                text: DeviceLinkingModel.ipAddress
                                horizontalAlignment: Text.AlignHCenter
                                wrapMode: Text.WordWrap
                                color: JamiTheme.textColor
                                font.pointSize: JamiTheme.mediumFontSize
                                font.weight: Font.Bold
                            }
                        }

                        RowLayout {
                            Layout.alignment: Qt.AlignHCenter
                            spacing: 16

                            MaterialButton {
                                id: confirm

                                objectName: "confirm"
                                primary: true

                                Layout.alignment: Qt.AlignCenter

                                text: "Confirm"
                                toolTipText: "Confirm"
                                onClicked: {
                                    DeviceLinkingModel.confirmAddDevice()
                                }
                            }

                            MaterialButton {
                                id: cancell

                                objectName: "cancell"
                                Layout.alignment: Qt.AlignCenter
                                secondary: true
                                toolTipText: "Cancel"
                                textLeftPadding: JamiTheme.buttontextWizzardPadding / 2
                                textRightPadding: JamiTheme.buttontextWizzardPadding / 2
                                text: "Cancel"
                                onClicked: {
                                    DeviceLinkingModel.cancelAddDevice()
                                }
                            }
                        }
                    }
                }

                Item {
                    id: scanAndEnterCodeView
                    property int index: 4
                    Layout.fillWidth: true
                    Layout.preferredHeight: scanColumn.height

                    Component.onDestruction: {
                        if (qrScanner) {
                            qrScanner.stopScanner()
                        }
                    }

                    ColumnLayout {
                        id: scanColumn
                        width: parent.width
                        spacing: 20

                        Text {
                            id: explanationScan

                            Layout.alignment: Qt.AlignCenter
                            Layout.preferredWidth: scrollView.width

                            text: "On the new device, initiate a new account.\nSelect Add account -> Connect from another device.\nWhen ready, scan the QR Code."
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.WordWrap
                            color: JamiTheme.textColor
                            font.pointSize: JamiTheme.mediumFontSize
                        }

                        QRCodeScanner {
                            id: qrScanner
                            Layout.alignment: Qt.AlignHCenter
                            width: 250
                            height: width * aspectRatio
                            visible: VideoDevices.listSize !== 0

                            onQrCodeDetected: function(code) {
                                console.log("QR code detected:", code)
                                DeviceLinkingModel.addDevice(code)
                            }
                        }


                        // Manual Entry
                        ColumnLayout {
                            id: manualEntry
                            Layout.alignment: Qt.AlignHCenter
                            Layout.preferredWidth: scrollView.width
                            spacing: 10

                            Text {
                                id: explanation

                                Layout.alignment: Qt.AlignCenter
                                Layout.preferredWidth: scrollView.width

                                text: "Aletrnatively you could enter a code manually."
                                horizontalAlignment: Text.AlignHCenter
                                wrapMode: Text.WordWrap
                                color: JamiTheme.textColor
                                font.pointSize: JamiTheme.mediumFontSize
                            }

                            ModalTextEdit {
                                id: codeInput

                                Layout.preferredWidth: scrollView.width
                                Layout.preferredHeight: JamiTheme.preferredFieldHeight

                                placeholderText: "Enter a code"
                            }

                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                Layout.maximumWidth: parent.width - 40
                                visible: DeviceLinkingModel.tokenErrorMessage.length > 0
                                text: DeviceLinkingModel.tokenErrorMessage
                                font.pointSize: JamiTheme.tinyFontSize
                                color: JamiTheme.redColor
                                horizontalAlignment: Text.AlignHCenter
                                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                            }

                            MaterialButton {
                                id: connect

                                objectName: "connect"
                                primary: true

                                Layout.alignment: Qt.AlignCenter

                                text: "Connect"
                                toolTipText: "Connect"
                                enabled: codeInput.dynamicText.length > 0

                                onClicked: {
                                    DeviceLinkingModel.addDevice(codeInput.text)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    //Reset everything when dialog is closed
    onClosed: {
        DeviceLinkingModel.reset()
    }
}
