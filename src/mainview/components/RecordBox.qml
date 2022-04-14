/*
 * Copyright (C) 2020-2022 Savoir-faire Linux Inc.
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
import Qt5Compat.GraphicalEffects

import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1

import "../../commoncomponents"

Popup {
    id: root

    enum States {
        INIT,
        RECORDING,
        REC_SUCCESS
    }

    property string pathRecorder: ""
    property int duration: 0
    property int state: RecordBox.States.INIT
    property bool isVideo: false
    property bool isPhoto: false
    property int preferredWidth: 320
    property int preferredHeight: 240
    property int btnSize: 40

    property int offset: 3
    property int curveRadius: 6
    property int spikeHeight: 10 + offset

    property string photo: ""

    signal validatePhoto(string photo)

    function openRecorder(vid) {
        isVideo = vid

        scaleHeight()
        updateState(RecordBox.States.INIT)

        if (isVideo) {
            previewWidget.startWithId(VideoDevices.getDefaultDevice())
        }
        open()
    }

    function scaleHeight() {
        height = preferredHeight
        if (isVideo) {
            var resolution = VideoDevices.defaultRes
            var resVec = resolution.split("x")
            var aspectRatio = resVec[1] / resVec[0]
            if (aspectRatio) {
                height = preferredWidth * aspectRatio
            } else {
                console.error("Could not scale recording video preview")
            }
        }
    }

    function closeRecorder() {
        if (isVideo) {
            VideoDevices.stopDevice(previewWidget.deviceId)
        }
        if (!root.isPhoto)
            stopRecording()
        close()
    }

    function updateState(new_state) {
        state = new_state
        if (isPhoto) {
            screenshotBtn.visible = (state === RecordBox.States.INIT)
            recordButton.visible = false
            btnStop.visible = false
        } else {
            screenshotBtn.visible = false
            recordButton.visible = (state === RecordBox.States.INIT)
            btnStop.visible = (state === RecordBox.States.RECORDING)
        }
        btnRestart.visible = (state === RecordBox.States.REC_SUCCESS)
        btnSend.visible = (state === RecordBox.States.REC_SUCCESS)

        if (state === RecordBox.States.INIT) {
            duration = 0
            time.text = "00:00"
            timer.stop()
        } else if (state === RecordBox.States.REC_SUCCESS) {
            timer.stop()
        }
    }

    function startRecording() {
        timer.start()
        pathRecorder = AVModel.startLocalMediaRecorder(isVideo? VideoDevices.getDefaultDevice() : "")
        if (pathRecorder == "") {
            timer.stop()
        }
    }

    function stopRecording() {
        if (pathRecorder !== "") {
            AVModel.stopLocalRecorder(pathRecorder)
        }
    }

    function sendRecord() {
        if (pathRecorder !== "") {
            MessagesAdapter.sendFile(pathRecorder)
        }
    }

    function updateTimer() {

        duration += 1

        var m = Math.trunc(duration / 60)
        var s = (duration % 60)

        var min = (m < 10) ? "0" + String(m) : String(m)
        var sec = (s < 10) ? "0" + String(s) : String(s)

        time.text = min + ":" + sec
    }

    width: 320
    height: 240
    modal: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent

    onActiveFocusChanged: {
        if (visible) {
            closeRecorder()
        }
    }

    onVisibleChanged: {
        if (!visible) {
            closeRecorder()
        }
    }

    background: Rectangle {
        anchors.fill: parent
        visible: !root.isVideo
        radius: 5
        border.color: JamiTheme.tabbarBorderColor
        color: JamiTheme.backgroundColor
    }

    Item {
        anchors.fill: parent
        anchors.margins: 0

        Rectangle {
            id: rectBox

            anchors.fill: parent

            visible: (isVideo && VideoDevices.listSize !== 0)
            color: JamiTheme.blackColor
            radius: 5

            Item {
                // Else it will be resized by the layer effect
                id: photoMask
                visible: false
                anchors.fill: rectBox
                Rectangle {
                    anchors.centerIn: parent
                    height: parent.height
                    width: parent.height
                    radius: height / 2
                }
            }

            Image {
                id: screenshotImg
                visible: parent.visible && root.isPhoto && btnSend.visible

                anchors.fill: parent

                layer.enabled: true
                layer.effect: OpacityMask {
                    maskSource: rectBox
                }

                Rectangle {
                    anchors.fill: parent
                    color: "black"
                    opacity: 0.6

                    layer.enabled: true
                    layer.effect: OpacityMask {
                        anchors.centerIn: parent
                        maskSource: photoMask
                        invert: true
                    }
                }
                source: root.photo === "" ? "" : "data:image/png;base64," + root.photo
            }

            LocalVideo {
                id: previewWidget

                visible: parent.visible && !screenshotImg.visible

                anchors.fill: rectBox
                anchors.margins: 1

                rendererId: VideoDevices.getDefaultDevice()

                layer.enabled: true
                layer.effect: OpacityMask {
                    maskSource: rectBox
                }

                Rectangle {
                    anchors.fill: parent
                    color: "black"
                    opacity: 0.6
                    visible: root.isPhoto

                    layer.enabled: true
                    layer.effect: OpacityMask {
                        anchors.centerIn: parent
                        maskSource: photoMask
                        invert: true
                    }
                }
            }
        }

        Label {
            anchors.centerIn: parent

            width: root.width

            visible: (isVideo && VideoDevices.listSize === 0)

            onVisibleChanged: {
                if (visible) {
                    closeRecorder()
                }
            }

            text: JamiStrings.previewUnavailable
            font.pointSize: JamiTheme.settingsFontSize
            font.kerning: true
            color: JamiTheme.primaryForegroundColor
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        Timer {
            id: timer

            interval: 1000
            running: false
            repeat: true

            onTriggered: updateTimer()
        }

        Text {
            id: time

            anchors.centerIn: recordButton
            anchors.horizontalCenterOffset: (isVideo ? 100 : 0)
            anchors.verticalCenterOffset: (isVideo ? 0 : -100)

            visible: !root.isPhoto
            text: "00:00"
            color: (isVideo ? JamiTheme.whiteColor : JamiTheme.textColor)
            font.pointSize: (isVideo ? 12 : 20)
        }

        PushButton {
            id: recordButton

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 5

            preferredSize: btnSize

            normalColor: isVideo ? "transparent" : JamiTheme.backgroundColor
            hoveredColor: Qt.rgba(255, 255, 255, 0.2)

            source: JamiResources.fiber_manual_record_24dp_svg
            imageColor: JamiTheme.recordIconColor

            onClicked: {
                updateState(RecordBox.States.RECORDING)
                if (!root.isPhoto)
                    startRecording()
            }
        }

        PushButton {
            id: screenshotBtn

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 5

            preferredSize: btnSize

            normalColor: isVideo ? "transparent" : JamiTheme.backgroundColor
            hoveredColor: Qt.rgba(255, 255, 255, 0.2)
            border.width: 1
            border.color: imageColor

            source: JamiResources.fiber_manual_record_24dp_svg
            imageColor: JamiTheme.whiteColor

            onClicked: {
                root.photo = videoProvider.captureVideoFrame(previewWidget.videoSink)
                updateState(RecordBox.States.REC_SUCCESS)
            }
        }

        PushButton {
            id: btnStop

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 5

            preferredSize: btnSize

            normalColor: isVideo ? "transparent" : JamiTheme.backgroundColor
            hoveredColor: Qt.rgba(255, 255, 255, 0.2)

            source: JamiResources.stop_24dp_red_svg
            imageColor: isVideo ? JamiTheme.whiteColor : JamiTheme.textColor
            border.width: 1
            border.color: imageColor

            onClicked: {
                if (!root.isPhoto)
                    stopRecording()
                updateState(RecordBox.States.REC_SUCCESS)
            }
        }

        PushButton {
            id: btnRestart

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.horizontalCenterOffset: -25
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 5

            preferredSize: btnSize

            normalColor: isVideo ? "transparent" : JamiTheme.backgroundColor

            source: JamiResources.re_record_24dp_svg
            hoveredColor: Qt.rgba(255, 255, 255, 0.2)
            imageColor: isVideo ? JamiTheme.whiteColor : JamiTheme.textColor
            border.width: 1
            border.color: imageColor

            onClicked: {
                if (!root.isPhoto)
                    stopRecording()
                updateState(RecordBox.States.INIT)
            }
        }

        PushButton {
            id: btnSend

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.horizontalCenterOffset: 25
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 5

            preferredSize: btnSize

            normalColor: isVideo ? "transparent" : JamiTheme.backgroundColor

            source: JamiResources.check_black_24dp_svg
            imageColor: isVideo ? JamiTheme.whiteColor : JamiTheme.textColor
            border.width: 1
            border.color: imageColor

            onClicked: {
                if (!root.isPhoto) {
                    stopRecording()
                    sendRecord()
                } else if (root.photo !== "") {
                    root.validatePhoto(root.photo)
                }
                closeRecorder()
                updateState(RecordBox.States.INIT)
            }
        }

        PushButton {
            id: cancelBtn

            normalColor: "transparent"
            hoveredColor: Qt.rgba(255, 255, 255, 0.2)
            imageColor: JamiTheme.primaryForegroundColor

            preferredSize: 12

            source: JamiResources.round_close_24dp_svg
            toolTipText: JamiStrings.back

            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 8

            onClicked: {
                closeRecorder()
                updateState(RecordBox.States.INIT)
            }
        }
    }
}
