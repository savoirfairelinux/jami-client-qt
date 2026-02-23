/*
 * Copyright (C) 2020-2026 Savoir-faire Linux Inc.
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
import Qt.labs.platform
import "../../commoncomponents"
import "../../mainview/components"

BaseModalDialog {
    id: root

    signal accepted

    title: JamiStrings.linkNewDevice

    property bool darkTheme: UtilsAdapter.useApplicationTheme()

    autoClose: false
    closeButtonVisible: false

    // Function to check if dialog can be closed directly
    function canCloseDirectly() {
        return LinkDeviceModel.deviceAuthState === DeviceAuthStateEnum.INIT || LinkDeviceModel.deviceAuthState === DeviceAuthStateEnum.DONE;
    }

    // Close button. Use custom close button to show a confirmation dialog.
    NewIconButton {
        id: closeButton

        anchors {
            top: parent.top
            right: parent.right
            topMargin: 5
            rightMargin: 6
        }

        iconSize: JamiTheme.iconButtonMedium
        iconSource: JamiResources.round_close_24dp_svg
        toolTipText: JamiStrings.close

        onClicked: {
            if (canCloseDirectly()) {
                root.close();
            } else {
                confirmCloseDialog.open();
            }
        }

        Accessible.role: Accessible.Button
        Accessible.name: JamiStrings.close
    }

    MessageDialog {
        id: confirmCloseDialog

        text: JamiStrings.linkDeviceCloseWarningTitle
        informativeText: JamiStrings.linkDeviceCloseWarningMessage
        buttons: MessageDialog.Ok | MessageDialog.Cancel

        onOkClicked: function (button) {
            root.close();
        }
    }

    popupContent: Item {
        id: content
        width: 400
        height: 450

        // Scrollable container for StackLayout
        ScrollView {
            id: scrollView

            anchors.fill: parent

            anchors.leftMargin: 20
            anchors.rightMargin: 20
            anchors.bottomMargin: 20
            clip: true

            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
            ScrollBar.vertical.policy: ScrollBar.AsNeeded
            contentHeight: stackLayout.implicitHeight

            StackLayout {
                id: stackLayout
                width: Math.min(scrollView.width, scrollView.availableWidth)

                currentIndex: scanAndEnterCodeView.index

                Connections {
                    target: LinkDeviceModel

                    function onDeviceAuthStateChanged() {
                        switch (LinkDeviceModel.deviceAuthState) {
                        case DeviceAuthStateEnum.INIT:
                            stackLayout.currentIndex = scanAndEnterCodeView.index;
                            break;
                        case DeviceAuthStateEnum.CONNECTING:
                            stackLayout.currentIndex = deviceLinkLoadingView.index;
                            deviceLinkLoadingView.loadingText = JamiStrings.linkDeviceConnecting;
                            break;
                        case DeviceAuthStateEnum.AUTHENTICATING:
                            stackLayout.currentIndex = deviceConfirmationView.index;
                            break;
                        case DeviceAuthStateEnum.IN_PROGRESS:
                            stackLayout.currentIndex = deviceLinkLoadingView.index;
                            deviceLinkLoadingView.loadingText = JamiStrings.linkDeviceInProgress;
                            break;
                        case DeviceAuthStateEnum.DONE:
                            if (LinkDeviceModel.linkDeviceError.length > 0) {
                                stackLayout.currentIndex = deviceLinkErrorView.index;
                            } else {
                                stackLayout.currentIndex = deviceLinkSuccessView.index;
                            }
                            break;
                        default:
                            break;
                        }
                    }
                }

                StackViewBase {
                    id: deviceLinkErrorView
                    property int index: 0
                    title: "Error"

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: LinkDeviceModel.linkDeviceError
                        Layout.preferredWidth: scrollView.width
                        color: JamiTheme.textColor
                        font.pixelSize: JamiTheme.wizardViewDescriptionFontPixelSize
                        lineHeight: JamiTheme.wizardViewTextLineHeight
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    }

                    MaterialButton {
                        Layout.alignment: Qt.AlignHCenter
                        text: JamiStrings.close
                        toolTipText: JamiStrings.optionTryAgain
                        primary: true
                        onClicked: {
                            root.close();
                        }
                    }
                }

                StackViewBase {
                    id: deviceLinkSuccessView
                    property int index: 1
                    title: "Success"

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: scrollView.width
                        text: JamiStrings.linkDeviceAllSet
                        color: JamiTheme.textColor
                        font.pixelSize: JamiTheme.wizardViewDescriptionFontPixelSize
                        lineHeight: JamiTheme.wizardViewTextLineHeight
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    }

                    MaterialButton {
                        Layout.alignment: Qt.AlignHCenter
                        text: JamiStrings.close
                        toolTipText: JamiStrings.close
                        primary: true
                        onClicked: {
                            root.close();
                        }
                    }
                }

                StackViewBase {
                    id: deviceLinkLoadingView
                    property int index: 2
                    title: "Loading"
                    property string loadingText: ""

                    BusyIndicator {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: 50
                        Layout.preferredHeight: 50
                        running: true
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: scrollView.width
                        text: deviceLinkLoadingView.loadingText
                        color: JamiTheme.textColor
                        font.pixelSize: JamiTheme.wizardViewDescriptionFontPixelSize
                        lineHeight: JamiTheme.wizardViewTextLineHeight
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    }
                }

                StackViewBase {
                    id: deviceConfirmationView
                    property int index: 3
                    title: "Confirmation"

                    Text {
                        id: explanationConnect
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: scrollView.width
                        text: JamiStrings.linkDeviceFoundAddress
                        font.pixelSize: JamiTheme.wizardViewDescriptionFontPixelSize
                        lineHeight: JamiTheme.wizardViewTextLineHeight
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                        color: JamiTheme.textColor
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: scrollView.width
                        text: JamiStrings.linkDeviceNewDeviceIP.arg(LinkDeviceModel.ipAddress)
                        font.pixelSize: JamiTheme.wizardViewDescriptionFontPixelSize
                        lineHeight: JamiTheme.wizardViewTextLineHeight
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                        color: JamiTheme.textColor
                        font.weight: Font.Bold
                    }

                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 16

                        MaterialButton {
                            id: confirm
                            primary: true
                            Layout.alignment: Qt.AlignCenter
                            text: JamiStrings.optionConfirm
                            toolTipText: JamiStrings.optionConfirm
                            onClicked: {
                                LinkDeviceModel.confirmAddDevice();
                            }
                        }

                        MaterialButton {
                            id: cancel
                            Layout.alignment: Qt.AlignCenter
                            secondary: true
                            toolTipText: JamiStrings.cancel
                            textLeftPadding: JamiTheme.buttontextWizzardPadding / 2
                            textRightPadding: JamiTheme.buttontextWizzardPadding / 2
                            text: JamiStrings.cancel
                            onClicked: {
                                LinkDeviceModel.cancelAddDevice();
                            }
                        }
                    }
                }

                StackViewBase {
                    id: scanAndEnterCodeView
                    property int index: 4
                    title: "Scan"

                    Component.onDestruction: {
                        if (qrScanner) {
                            qrScanner.stopScanner();
                        }
                    }

                    Text {
                        id: explanationScan
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: scrollView.width
                        text: JamiStrings.linkDeviceScanQR
                        font.pixelSize: JamiTheme.wizardViewDescriptionFontPixelSize
                        lineHeight: JamiTheme.wizardViewTextLineHeight
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                        color: JamiTheme.textColor
                    }

                    QRCodeScanner {
                        id: qrScanner
                        Layout.alignment: Qt.AlignHCenter
                        width: 250
                        height: width * aspectRatio
                        visible: VideoDevices.listSize !== 0

                        onQrCodeDetected: function (code) {
                            console.log("QR code detected:", code);
                            LinkDeviceModel.addDevice(code);
                        }
                    }

                    ColumnLayout {
                        id: manualEntry
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: scrollView.width
                        spacing: 10

                        Text {
                            id: explanation
                            Layout.alignment: Qt.AlignHCenter
                            Layout.preferredWidth: scrollView.width
                            text: JamiStrings.linkDeviceEnterManually
                            font.pixelSize: JamiTheme.wizardViewDescriptionFontPixelSize
                            lineHeight: JamiTheme.wizardViewTextLineHeight
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                            color: JamiTheme.textColor
                        }

                        NewMaterialTextField {
                            id: codeInput

                            Layout.alignment: Qt.AlignHCenter
                            Layout.maximumWidth: scrollView.width

                            placeholderText: JamiStrings.linkDeviceEnterCodePlaceholder
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.maximumWidth: parent.width - 40
                            visible: LinkDeviceModel.tokenErrorMessage.length > 0
                            text: LinkDeviceModel.tokenErrorMessage
                            font.pointSize: JamiTheme.tinyFontSize
                            color: JamiTheme.redColor
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                        }
                    }

                    MaterialButton {
                        id: connect
                        Layout.alignment: Qt.AlignHCenter
                        primary: true
                        text: JamiStrings.connect
                        toolTipText: JamiStrings.connect
                        enabled: codeInput.modifiedTextFieldContent.length > 0
                        onClicked: {
                            LinkDeviceModel.addDevice(codeInput.modifiedTextFieldContent);
                        }
                    }
                }
            }
        }
    }

    // Common base component for stack layout items
    component StackViewBase: Item {
        id: baseItem

        required property string title
        default property alias content: contentLayout.data

        Layout.fillWidth: true
        Layout.alignment: Qt.AlignHCenter
        implicitHeight: contentLayout.implicitHeight

        ColumnLayout {
            id: contentLayout
            anchors {
                left: parent.left
                right: parent.right
                verticalCenter: parent.verticalCenter
            }
            Layout.preferredWidth: scrollView.width
            spacing: 20
        }
    }

    //Reset everything when dialog is closed
    onClosed: {
        LinkDeviceModel.reset();
    }
}
