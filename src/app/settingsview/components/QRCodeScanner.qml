import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtMultimedia
import net.jami.Models 1.1
import net.jami.Constants 1.1
import net.jami.Adapters 1.1
import net.jami.Helpers 1.1
import "../../commoncomponents"

Item {
    id: root

    property bool isScanning: false
    property real aspectRatio: 0.5625

    onVisibleChanged: {
        if (visible) {
            startScanner()
        } else {
            stopScanner()
        }
    }

    Component.onDestruction: {
        stopScanner()
    }

    Rectangle {
        id: cameraContainer
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width
        height: parent.height
        color: JamiTheme.primaryForegroundColor
        clip: true

        LocalVideo {
            id: previewWidget
            anchors.fill: parent
            flip: true

            underlayItems: Text {
                id: noCameraText
                anchors.centerIn: parent
                font.pointSize: 18
                font.capitalization: Font.AllUppercase
                color: "white"
                text: JamiStrings.noCamera
                visible: false  // Start hidden

                // Delay "No Camera" message to avoid flashing it when camera is starting up.
                // If camera starts successfully within 5 seconds, user won't see this message.
                // If there's a camera issue, message will be shown after the delay.
                Timer {
                    id: visibilityTimer
                    interval: 5000
                    running: true
                    repeat: false
                    onTriggered: {
                        noCameraText.visible = true
                        destroy()  // Remove the timer after it's done
                    }
                }
            }
        }

        // Scanning line animation
        Rectangle {
            id: scanLine
            width: parent.width
            height: 2
            color: JamiTheme.whiteColor
            opacity: 0.8
            visible: root.isScanning && previewWidget.isRendering

            SequentialAnimation on y {
                running: root.isScanning
                loops: Animation.Infinite
                NumberAnimation {
                    from: 0
                    to: cameraContainer.height
                    duration: 2500
                    easing.type: Easing.InOutQuad
                }
                NumberAnimation {
                    from: cameraContainer.height
                    to: 0
                    duration: 2500
                    easing.type: Easing.InOutQuad
                }
            }
        }
    }

    Timer {
        id: scanTimer
        interval: 500
        repeat: true
        running: root.isScanning && previewWidget.isRendering
        onTriggered: {
            console.log("Processing captured frame for QR code...")
            var result = QRCodeScannerModel.scanImage(videoProvider.captureRawVideoFrame(VideoDevices.getDefaultDevice()));
            if (result !== "") {
                root.isScanning = false
                console.log("QR code detected:", result)
                root.qrCodeDetected(result)
            } else {
                console.log("No QR code found in frame")
            }
        }
    }

    signal qrCodeDetected(string code)

    // Start scanner
    function startScanner() {
        previewWidget.startWithId(VideoDevices.getDefaultDevice())
        root.isScanning = true
    }

    function stopScanner() {
        previewWidget.startWithId("")
        root.isScanning = true
    }
} 
