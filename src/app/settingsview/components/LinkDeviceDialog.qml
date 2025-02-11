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
import QtMultimedia
import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import "../../commoncomponents"
import "../../mainview/components"

BaseModalDialog {
    id: root

    signal accepted

    title: "Link New Device"

    property bool darkTheme: UtilsAdapter.useApplicationTheme()

    // Set larger dialog size
    // width: 600
    // height: 400

    popupContent: Item {
        id: root
        width: 300
        height: 300

        // Control the Page
        Row {
            id: controls
            anchors.top: parent.top
            anchors.right: parent.right
            z: 1  // Ensure controls stay on top

            Button {
                text: "<"
                onClicked: stackLayout.currentIndex -= 1
                enabled: stackLayout.currentIndex > 0
            }
            Button {
                text: ">"
                onClicked: stackLayout.currentIndex += 1
                enabled: stackLayout.currentIndex < stackLayout.count - 1
            }
        }

        // Scrollable container for StackLayout
        ScrollView {
            id: scrollView
            anchors.fill: parent
            anchors.topMargin: controls.height + 10
            clip: true
            
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
            ScrollBar.vertical.policy: ScrollBar.AsNeeded
            ScrollBar.vertical.visible: stackLayout.height > height

            StackLayout {
                id: stackLayout
                width: scrollView.width
                height: children[currentIndex].implicitHeight
                implicitHeight: height
                
                onCurrentIndexChanged: {
                    if (currentIndex === 1 && qrScanner) {
                        qrScanner.startScanner()
                    }
                }
                
                Rectangle {
                    color: 'teal'
                    implicitWidth: stackLayout.width
                    implicitHeight: 600
                }
                Item {
                    implicitWidth: stackLayout.width
                    implicitHeight: qrScanner.height

                    QRCodeScanner {
                        id: qrScanner
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 200
                        height: width * aspectRatio
                        visible: VideoDevices.listSize !== 0

                        onQrCodeDetected: function(code) {
                            console.log("QR code detected:", code)
                            DeviceLinkingModel.addDevice(code)
                        }
                    }
                }
                Rectangle {
                    color: 'plum'
                    implicitWidth: stackLayout.width
                    implicitHeight: 20
                }
            }
        }
    }

//     popupContent: StackLayout {
//         id: stackedWidget

// //        function setGeneratingPage() {
// //            if (passwordEdit.length === 0 && DeviceLinkingModel.isPasswordRequired) {
// //                setExportPage(false, "");
// //                return;
// //            }
// //            stackedWidget.currentIndex = exportingSpinnerPage.pageIndex;
// //            spinnerMovie.playing = true;
// //            DeviceLinkingModel.startExport(passwordEdit.dynamicText);
// //        }

//         function setExportPage(success, pin) {
//             if (success) {
//                 infoLabel.success = true;
//                 pinRectangle.visible = true
//                 exportedPIN.text = pin;
//             } else {
//                 infoLabel.success = false;
//                 infoLabel.visible = true;
//                 infoLabel.text = DeviceLinkingModel.errorMessage;
//             }
//             stackedWidget.currentIndex = exportingInfoPage.pageIndex;
//             stackedWidget.height = exportingLayout.implicitHeight;
//         }

//         Connections {
//             target: DeviceLinkingModel

//             function onDeviceAuthStateChanged() {
//                 switch (DeviceLinkingModel.deviceAuthState) {
//                 case DeviceLinkingModel.TokenAvailable:
//                     setExportPage(true, DeviceLinkingModel.exportedPIN);
//                     break;
//                 case DeviceLinkingModel.Error:
//                     setExportPage(false, "");
//                     break;
//                 case DeviceLinkingModel.Done:
//                     root.accepted();
//                     root.close();
//                     break;
//                 }
//             }
//         }

// //        onVisibleChanged: {
// //            if (visible) {
// //                if (DeviceLinkingModel.isPasswordRequired) {
// //                    stackedWidget.currentIndex = enterPinPage.pageIndex;
// //                } else {
// //                    setGeneratingPage();
// //                }
// //            }
// //        }

//         // Connections {
//         //     target: NameDirectory

//         //     function onExportOnRingEnded(status, pin) {
//         //         stackedWidget.setExportPage(status, pin);
//         //     }
//         // }

//         // Index = 0 - Enter PIN page
//         Item {
//             id: enterPinPage

//             readonly property int pageIndex: 0

//             Component.onCompleted: pinInput.forceActiveFocus()

//             ColumnLayout {
//                 id: pinEntryLayout
//                 spacing: JamiTheme.preferredMarginSize
//                 anchors.centerIn: parent
//                 width: parent.width - 2 * 40
//                 height: parent.height - 2 * 40

//                 Label {
//                     Layout.alignment: Qt.AlignCenter
//                     Layout.maximumWidth: root.width - 4 * JamiTheme.preferredMarginSize
//                     wrapMode: Text.Wrap
//                     text: "Enter PIN"
//                     color: JamiTheme.textColor
//                     font.pointSize: JamiTheme.textFontSize
//                     font.kerning: true
//                     horizontalAlignment: Text.AlignHCenter
//                 }

//                 TabBar {
//                     id: pinEntryTabBar
//                     Layout.fillWidth: true
//                     Layout.topMargin: JamiTheme.preferredMarginSize

//                     TabButton {
//                         text: "Scan QR Code"
//                         width: implicitWidth
//                         onCheckedChanged: {
//                             if (checked) {
//                                 if (camera && camera.cameraDevice) {
//                                     camera.start()
//                                     if (qrScanner) {
//                                         qrScanner.startScanning()
//                                         console.log("QR scanning started")
//                                     }
//                                 }
//                             } else {
//                                 if (camera && camera.cameraDevice) {
//                                     camera.stop()
//                                     if (qrScanner) {
//                                         qrScanner.stopScanning()
//                                         console.log("QR scanning stopped")
//                                     }
//                                 }
//                             }
//                         }
//                     }

//                     TabButton {
//                         text: "Enter PIN"
//                         width: implicitWidth
//                     }
//                 }

//                 StackLayout {
//                     Layout.fillWidth: true
//                     currentIndex: pinEntryTabBar.currentIndex

//                     // QR Code Scanner view
//                     Item {
//                         Layout.preferredHeight: parent.height - 40  // Increased height
//                         Layout.preferredWidth: parent.width - 40  // Take full width
//                         Layout.fillWidth: true

//                         Rectangle {
//                             anchors.fill: parent
//                             anchors.margins: JamiTheme.preferredMarginSize
//                             color: "transparent"

//                             // Camera viewfinder
//                             Rectangle {
//                                 id: cameraViewfinder
//                                 anchors.fill: parent
//                                 color: JamiTheme.backgroundColor
//                                 border.color: JamiTheme.greyBorder
//                                 border.width: 1
//                                 radius: 5

//                                 Rectangle {
//                                     anchors.fill: parent
//                                     anchors.margins: JamiTheme.preferredMarginSize
//                                     color: "black"

//                                     MediaDevices {
//                                         id: mediaDevices
//                                     }

//                                     CaptureSession {
//                                         id: captureSession

//                                         camera: Camera {
//                                             id: camera
//                                             cameraDevice: mediaDevices.defaultVideoInput

//                                             onErrorOccurred: function(error, errorString) {
//                                                 console.warn("Camera error:", errorString)
//                                             }

//                                             onActiveChanged: {
//                                                 if (active && pinEntryTabBar.currentIndex === 0) {
//                                                     console.log("Camera active, starting QR scanning")
//                                                     qrScanner.startScanning()
//                                                 } else {
//                                                     qrScanner.stopScanning()
//                                                 }
//                                             }

//                                             Component.onCompleted: {
//                                                 if (pinEntryTabBar.currentIndex === 0 && cameraDevice) {
//                                                     start()
//                                                 }
//                                             }
//                                         }

//                                         imageCapture: ImageCapture {
//                                             id: imageCapture
//                                             onImageCaptured: function(requestId, preview) {
//                                                 console.log("Image captured, scanning for QR code...")
//                                             }
//                                         }

//                                         videoOutput: output
//                                     }

//                                     VideoOutput {
//                                         id: output
//                                         anchors.fill: parent
//                                         fillMode: VideoOutput.PreserveAspectFit
//                                         visible: camera && camera.active
//                                     }

//                                     Item {
//                                         anchors.fill: parent
//                                         visible: !camera || !camera.cameraDevice || !camera.active || camera.error !== Camera.NoError

//                                         Column {
//                                             anchors.centerIn: parent
//                                             spacing: JamiTheme.preferredMarginSize
//                                             width: parent.width - 40

//                                             // Show message when camera is not available or error occurred
//                                             Label {
//                                                 width: parent.width
//                                                 text: !camera || !camera.cameraDevice ?
//                                                       "No camera available" :
//                                                       camera.error !== Camera.NoError ?
//                                                       "Camera error occurred" :
//                                                       !camera.active ?
//                                                       "Camera access denied" :
//                                                       "Camera error"
//                                                 color: JamiTheme.redColor
//                                                 font.pointSize: JamiTheme.textFontSize
//                                                 horizontalAlignment: Text.AlignHCenter
//                                                 wrapMode: Text.Wrap
//                                             }

//                                             // Switch to manual entry suggestion
//                                             Label {
//                                                 width: parent.width
//                                                 text: "If you can't scan the QR code, switch to manual PIN entry"
//                                                 color: JamiTheme.textColor
//                                                 font.pointSize: JamiTheme.smallFontSize
//                                                 horizontalAlignment: Text.AlignHCenter
//                                                 wrapMode: Text.Wrap
//                                             }
//                                         }
//                                     }

//                                     QRCodeScanner {
//                                         id: qrScanner
//                                         anchors.fill: parent
//                                         captureSession: captureSession
//                                         videoOutput: output

//                                         onQrCodeDetected: function(code) {
//                                             // Stop scanning
//                                             qrScanner.stopScanning()
//                                             camera.stop()

//                                             // Add device using detected PIN
//                                             DeviceLinkingModel.addDevice(code)
//                                         }

//                                         Connections {
//                                             target: camera
//                                             function onErrorOccurred(error, errorString) {
//                                                 qrScanner.setError(errorString || "Camera error occurred")
//                                             }
//                                         }
//                                     }
//                                 }
//                             }

//                             Label {
//                                 anchors.top: cameraViewfinder.bottom
//                                 anchors.left: parent.left
//                                 anchors.right: parent.right
//                                 anchors.margins: JamiTheme.preferredMarginSize
//                                 text: camera.error !== Camera.NoError ?
//                                       "Camera error" :
//                                       "Scan the QR code displayed on your other device"
//                                 color: camera.error !== Camera.NoError ?
//                                       JamiTheme.redColor :
//                                       JamiTheme.textColor
//                                 font.pointSize: JamiTheme.textFontSize
//                                 horizontalAlignment: Text.AlignHCenter
//                                 wrapMode: Text.Wrap
//                             }
//                         }
//                     }

//                     // Manual PIN entry view
//                     Item {
//                         Layout.preferredHeight: 400
//                         Layout.fillWidth: true

//                         ColumnLayout {
//                             anchors.fill: parent
//                             spacing: JamiTheme.preferredMarginSize
//                             anchors.margins: JamiTheme.preferredMarginSize

//                             MaterialLineEdit {
//                                 id: pinInput
//                                 Layout.fillWidth: true
//                                 Layout.preferredHeight: 40
//                                 placeholderText: "Enter PIN code"
//                                 font.pointSize: JamiTheme.textFontSize
//                                 backgroundColor: JamiTheme.editBackgroundColor
//                                 color: JamiTheme.textColor
//                                 selectByMouse: true
//                                 maximumLength: 6
//                                 validator: RegularExpressionValidator { regularExpression: /[0-9]{0,6}/ }

//                                 onTextChanged: {
//                                     submitButton.enabled = text.length === 6
//                                 }
//                             }

//                             Label {
//                                 Layout.fillWidth: true
//                                 text: "Enter the PIN code displayed on your other device"
//                                 color: JamiTheme.textColor
//                                 font.pointSize: JamiTheme.smallFontSize
//                                 wrapMode: Text.Wrap
//                                 horizontalAlignment: Text.AlignHCenter
//                             }

//                             Item {
//                                 Layout.fillHeight: true
//                             }

//                             JamiPushButton {
//                                 id: submitButton
//                                 Layout.alignment: Qt.AlignHCenter
//                                 Layout.preferredWidth: 120
//                                 Layout.preferredHeight: 40
//                                 text: "Submit"
//                                 enabled: pinEntryTabBar.currentIndex === 1 ? pinInput.text.length === 6 : false
//                                 onClicked: {
//                                     if (pinEntryTabBar.currentIndex === 1) {
//                                         DeviceLinkingModel
//                                         .addDevice(pinInput.text)
//                                     }
//                                 }
//                             }

//                             Label {
//                                 id: errorLabel
//                                 Layout.fillWidth: true
//                                 visible: DeviceLinkingModel.deviceAuthState === DeviceLinkingModel.Error
//                                 text: DeviceLinkingModel.errorMessage
//                                 color: JamiTheme.redColor
//                                 font.pointSize: JamiTheme.smallFontSize
//                                 wrapMode: Text.Wrap
//                                 horizontalAlignment: Text.AlignHCenter
//                             }
//                         }
//                     }
//                 }
//             }
//         }

//         // Index = 1
//         Item {
//             id: exportingSpinnerPage

//             readonly property int pageIndex: 1

//             onHeightChanged: {
//                 stackedWidget.height = spinnerLayout.implicitHeight
//             }
//             onWidthChanged: stackedWidget.width = exportingLayout.implicitWidth

//             ColumnLayout {
//                 id: spinnerLayout

//                 spacing: JamiTheme.preferredMarginSize
//                 anchors.centerIn: parent

//                 Label {
//                     Layout.alignment: Qt.AlignCenter

//                     text: "Link Device"
//                     color: JamiTheme.textColor
//                     font.pointSize: JamiTheme.headerFontSize
//                     font.kerning: true
//                     horizontalAlignment: Text.AlignLeft
//                     verticalAlignment: Text.AlignVCenter
//                 }

//                 AnimatedImage {
//                     id: spinnerMovie

//                     Layout.alignment: Qt.AlignCenter

//                     Layout.preferredWidth: 30
//                     Layout.preferredHeight: 30

//                     source: JamiResources.jami_rolling_spinner_gif
//                     playing: visible
//                     fillMode: Image.PreserveAspectFit
//                     mipmap: true
//                 }
//             }
//         }

//         // Index = 2
//         Item {
//             id: exportingInfoPage

//             readonly property int pageIndex: 2

//             width: childrenRect.width
//             height: childrenRect.height

//             onHeightChanged: {
//                 stackedWidget.height = exportingLayout.implicitHeight
//             }
//             onWidthChanged: stackedWidget.width = exportingLayout.implicitWidth

//             ColumnLayout {
//                 id: exportingLayout

//                 spacing: JamiTheme.preferredMarginSize

//                 Label {
//                     id: instructionLabel

//                     Layout.maximumWidth: Math.min(root.maximumPopupWidth, root.width) - 2 * root.popupMargins
//                     Layout.alignment: Qt.AlignLeft

//                     color: JamiTheme.textColor

//                     wrapMode: Text.Wrap
//                     text: "Linking Instructions"
//                     font.pointSize: JamiTheme.textFontSize
//                     font.kerning: true
//                     verticalAlignment: Text.AlignVCenter

//                 }

//                 RowLayout {
//                     spacing: 10
//                     Layout.maximumWidth: Math.min(root.maximumPopupWidth, root.width) - 2 * root.popupMargins

//                     Rectangle {
//                         Layout.alignment: Qt.AlignCenter

//                         radius: 5
//                         color: JamiTheme.backgroundRectangleColor
//                         width: 100
//                         height: 100

//                         Rectangle {
//                             width: qrImage.width + 4
//                             height: qrImage.height + 4
//                             anchors.centerIn: parent
//                             radius: 5
//                             color: JamiTheme.whiteColor
//                             Image {
//                                  id: qrImage
//                                  anchors.centerIn: parent
//                                  mipmap: false
//                                  smooth: false
//                                  source: "image://qrImage/raw_" + exportedPIN.text
//                                  sourceSize.width: 80
//                                  sourceSize.height: 80
//                             }
//                         }

//                     }

//                     Rectangle {
//                         id: pinRectangle

//                         radius: 5
//                         color: JamiTheme.backgroundRectangleColor
//                         Layout.fillWidth: true
//                         height: 100
//                         Layout.minimumWidth: exportedPIN.width + 20

//                         Layout.alignment: Qt.AlignCenter

//                         MaterialLineEdit {
//                             id: exportedPIN

//                             padding: 10
//                             anchors.centerIn: parent

//                             text: "Enter PIN"
//                             wrapMode: Text.NoWrap

//                             backgroundColor: JamiTheme.backgroundRectangleColor

//                             color: darkTheme ? JamiTheme.editLineColor : JamiTheme.darkTintedBlue
//                             selectByMouse: true
//                             readOnly: true
//                             font.pointSize: JamiTheme.tinyCreditsTextSize
//                             font.kerning: true
//                             horizontalAlignment: Text.AlignHCenter
//                             verticalAlignment: Text.AlignVCenter
//                         }
//                     }
//                 }

//                 Rectangle {
//                     radius: 5
//                     color: JamiTheme.infoRectangleColor
//                     Layout.fillWidth: true
//                     Layout.preferredHeight: infoLabels.height + 38

//                     RowLayout {
//                         id: infoLayout

//                         anchors.centerIn: parent
//                         anchors.fill: parent
//                         anchors.margins: 14
//                         spacing: 10

//                         ResponsiveImage{
//                             Layout.fillWidth: true

//                             source: JamiResources.outline_info_24dp_svg
//                             fillMode: Image.PreserveAspectFit

//                             color: darkTheme ? JamiTheme.editLineColor : JamiTheme.darkTintedBlue
//                             Layout.fillHeight: true
//                         }

//                         ColumnLayout{
//                             id: infoLabels

//                             Layout.fillHeight: true
//                             Layout.fillWidth: true

//                             Label {
//                                 id: otherDeviceLabel

//                                 Layout.alignment: Qt.AlignLeft
//                                 color: JamiTheme.textColor
//                                 text: "On Another Device"

//                                 font.pointSize: JamiTheme.smallFontSize
//                                 font.kerning: true
//                                 font.bold: true
//                             }

//                             Label {
//                                 id: otherInstructionLabel

//                                 Layout.fillWidth: true
//                                 Layout.alignment: Qt.AlignLeft

//                                 wrapMode: Text.Wrap
//                                 color: JamiTheme.textColor
//                                 text: "On Another Device Instruction"

//                                 font.pointSize: JamiTheme.smallFontSize
//                                 font.kerning: true
//                             }
//                         }
//                     }
//                 }

//                 // Displays error messages
//                 Label {
//                     id: infoLabel

//                     visible: false

//                     property bool success: false
//                     property int borderWidth: success ? 1 : 0
//                     property int borderRadius: success ? 15 : 0
//                     property string backgroundColor: success ? "whitesmoke" : "transparent"
//                     property string borderColor: success ? "lightgray" : "transparent"

//                     Layout.maximumWidth: JamiTheme.preferredDialogWidth
//                     Layout.margins: JamiTheme.preferredMarginSize

//                     Layout.alignment: Qt.AlignCenter

//                     color: success ? JamiTheme.successLabelColor : JamiTheme.redColor
//                     padding: success ? 8 : 0

//                     wrapMode: Text.Wrap
//                     font.pointSize: success ? JamiTheme.textFontSize : JamiTheme.textFontSize + 3
//                     font.kerning: true
//                     horizontalAlignment: Text.AlignHCenter
//                     verticalAlignment: Text.AlignVCenter

//                     background: Rectangle {
//                         id: infoLabelBackground

//                         border.width: infoLabel.borderWidth
//                         border.color: infoLabel.borderColor
//                         radius: infoLabel.borderRadius
//                         color: JamiTheme.secondaryBackgroundColor
//                     }
//                 }
//             }
//         }

//         Component.onDestruction: {
//             if (camera) {
//                 camera.stop()
//                 qrScanner.stopScanning()
//             }
//         }
//    }
}
