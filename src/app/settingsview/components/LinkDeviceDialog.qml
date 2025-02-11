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
import "../../commoncomponents"
import "../../mainview/components"

BaseModalDialog {
    id: root

    title: "Link New Device"

    property bool darkTheme: UtilsAdapter.useApplicationTheme()

    popupContent: Item {
        width: 400
        height: 450

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
           // anchors.topMargin: controls.height + 10
            clip: true
            
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
            ScrollBar.vertical.policy: ScrollBar.AsNeeded
            ScrollBar.vertical.visible: stackLayout.height > height

            StackLayout {
                id: stackLayout
                width: scrollView.width
                height: children[currentIndex].implicitHeight
                implicitHeight: height
                currentIndex: scanAndEnterCodeView.StackLayout.index  // Default view

                Item {
                    id: deviceLinkErrorView
                    implicitWidth: stackLayout.width
                    implicitHeight: childrenRect.height

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 20

                        // Red circle with cross
                        Rectangle {
                            Layout.alignment: Qt.AlignHCenter
                            width: 50
                            height: 50
                            radius: width/2  // Makes it a perfect circle
                            color: JamiTheme.refuseRed

                            Text {
                                anchors.centerIn: parent
                                text: "✕"  // Unicode cross mark
                                color: "white"
                                font.pointSize: 24
                                font.bold: true
                            }
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "Link Device Failed"
                            color: JamiTheme.textColor
                            font.pointSize: JamiTheme.headerFontSize
                            font.bold: true
                            font.pixelSize: JamiTheme.wizardViewDescriptionFontPixelSize
                            lineHeight: JamiTheme.wizardViewTextLineHeight
                        }
                    }
                }

                Item {
                    id: deviceLinkSuccessView
                    implicitWidth: stackLayout.width
                    implicitHeight: childrenRect.height

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 20

                        // Green circle with checkmark
                        Rectangle {
                            Layout.alignment: Qt.AlignHCenter
                            width: 50
                            height: 50
                            radius: width/2  // Makes it a perfect circle
                            color: JamiTheme.acceptGreen

                            Text {
                                anchors.centerIn: parent
                                text: "✓"  // Unicode checkmark
                                color: "white"
                                font.pointSize: 24
                                font.bold: true
                            }
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "All Set!"
                            color: JamiTheme.textColor
                            font.pointSize: JamiTheme.headerFontSize
                            font.bold: true
                            font.pixelSize: JamiTheme.wizardViewDescriptionFontPixelSize
                            lineHeight: JamiTheme.wizardViewTextLineHeight
                        }
                    }
                }

                Item {
                    id: deviceLinkLoadingView
                    implicitWidth: stackLayout.width
                    implicitHeight: childrenRect.height

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 10

                        BusyIndicator {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.preferredWidth: 50
                            Layout.preferredHeight: 50
                            running: true
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "Connecting"
                            color: JamiTheme.textColor
                            font.pointSize: JamiTheme.mediumFontSize
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
                    implicitWidth: stackLayout.width
                    implicitHeight: childrenRect.height

                    ColumnLayout {
                        width: parent.width
                        spacing: 20

                        Text {
                            id: explanationConnect

                            Layout.alignment: Qt.AlignCenter
                            Layout.preferredWidth: scrollView.width

                            text: "New device found at address below. Is that you?\nClicking on confirm will continue transfering account."
                            color: JamiTheme.textColor
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.WordWrap

                            font.pixelSize: JamiTheme.wizardViewDescriptionFontPixelSize
                            lineHeight: JamiTheme.wizardViewTextLineHeight
                        }

                        // address text
                        RowLayout {
                            Layout.alignment: Qt.AlignHCenter
                            spacing: 8

                            Text {
                                id: ipAddressTextAreaExplanation
                                text: "IP Address:"
                                font.pointSize: JamiTheme.mediumFontSize
                                color: JamiTheme.textColor
                                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                                font.pixelSize: JamiTheme.wizardViewDescriptionFontPixelSize
                                lineHeight: JamiTheme.wizardViewTextLineHeight
                                font.weight: Font.Bold
                            }

                            Text {
                                id: ipAddressTextArea
                                //text: DeviceLinkingModel.ipAddress
                                font.pointSize: JamiTheme.mediumFontSize
                                color: JamiTheme.textColor
                                wrapMode: Text.WrapAtWordBoundaryOrAnywhere

                                font.pixelSize: JamiTheme.wizardViewDescriptionFontPixelSize
                                lineHeight: JamiTheme.wizardViewTextLineHeight
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
                    implicitWidth: stackLayout.width
                    implicitHeight: childrenRect.height

                    Component.onDestruction: {
                        if (qrScanner) {
                            qrScanner.stopScanner()
                        }
                    }

                    ColumnLayout {
                        width: parent.width
                        spacing: 20

                        Text {
                            id: explanationScan

                            Layout.alignment: Qt.AlignCenter
                            Layout.preferredWidth: scrollView.width

                            text: "On the new device, initiate a new account.\nSelect Add Account > Connect from another device.\nWhen ready, scan the QR Code"
                            color: JamiTheme.textColor
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.WordWrap
                            font.pixelSize: JamiTheme.wizardViewDescriptionFontPixelSize
                            lineHeight: JamiTheme.wizardViewTextLineHeight
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
                                color: JamiTheme.textColor
                                horizontalAlignment: Text.AlignHCenter
                                wrapMode: Text.WordWrap
                                font.pixelSize: JamiTheme.wizardViewDescriptionFontPixelSize
                                lineHeight: JamiTheme.wizardViewTextLineHeight
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
                                visible: true
                                text: "New device identifier is not recognized.\nPlease follow above instruction."
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

    Connections {
        target: DeviceLinkingModel

        function onDeviceAuthStateChanged() {
            // switch (DeviceLinkingModel.deviceAuthState) {
            // case DeviceAuthState.INIT:
            //     stackLayout.currentItem = scanAndEnterCodeView
            //     break
            // case DeviceAuthState.CONNECTING:
            //     stackLayout.currentItem = deviceLinkLoadingView
            //     break
            // case DeviceAuthState.AUTHENTICATING:
            //     stackLayout.currentItem = deviceConfirmationView
            //     break
            // case DeviceAuthState.IN_PROGRESS:
            //     stackLayout.currentItem = deviceLinkLoadingView
            //     break
            // case DeviceAuthState.DONE:
            //     stackLayout.currentItem = deviceLinkSuccessView
            //     root.close()
            //     break
            // case DeviceAuthState.ERROR:
            //     stackLayout.currentItem = deviceLinkErrorView
            //     break
            // case DeviceAuthState.TOKEN_AVAILABLE:
            //     stackLayout.currentItem = scanAndEnterCodeView
            //     break
            // }
        }
    }
}
