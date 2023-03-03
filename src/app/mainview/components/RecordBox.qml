/*
 * Copyright (C) 2020-2023 Savoir-faire Linux Inc.
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
    property bool showVideo: (root.isVideo && VideoDevices.listSize !== 0)
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
        updateState(RecordBox.States.INIT)

        if (isVideo) {
            localVideo.startWithId(VideoDevices.getDefaultDevice())
        }
        open()
    }

    function closeRecorder() {
        if (isVideo) {
            localVideo.startWithId("")
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
            MessagesAdapter.replyToId = ""
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

    background: Item {} // Computed by id: box, to do the layer on LocalVideo

    width: preferredWidth
    height: isVideo? previewWidget.height + 80 : preferredHeight
    Rectangle {
        id: box
        radius: 5
        anchors.fill: parent
        color: JamiTheme.backgroundColor

        PushButton {
            id: cancelBtn
            z: 1

            normalColor: "transparent"
            hoveredColor: Qt.rgba(255, 255, 255, 0.2)
            imageColor: isVideo ? JamiTheme.whiteColor : JamiTheme.textColor

            preferredSize: 12

            source: JamiResources.round_close_24dp_svg
            toolTipText: JamiStrings.back

            anchors.right: box.right
            anchors.top: box.top
            anchors.margins: 8

            onClicked: {
                closeRecorder()
                updateState(RecordBox.States.INIT)
            }
        }

        Item {
            // Else it will be resized by the layer effect
            id: photoMask
            visible: false
            anchors.fill: parent
            Rectangle {
                anchors.centerIn: parent
                height: parent.height
                width: parent.height
                radius: height / 2
            }
        }

        Rectangle {
            id: rectBox
            visible: false
            anchors.fill: parent
            radius: 5
        }

        ColumnLayout {
            id: recordItem
            anchors.fill: parent
            spacing: 0
            Layout.alignment: Qt.AlignTop

            // Video
            Image {
                id: screenshotImg
                visible: root.showVideo && root.isPhoto && btnSend.visible
                Layout.alignment: Qt.AlignHCenter | Qt.AlignTop

                sourceSize.width: parent.width
                sourceSize.height: width * localVideo.invAspectRatio

                source: root.photo === "" ? "" : "data:image/png;base64," + root.photo
            }

            // video Preview
            Rectangle {
                id: previewWidget
                visible: root.showVideo && !screenshotImg.visible

                Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
                height: localVideo.width * localVideo.invAspectRatio
                width: parent.width

                color: JamiTheme.primaryForegroundColor

                LocalVideo {
                    id: localVideo
                    anchors.fill: parent

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

            RowLayout {
                id: controls
                Layout.alignment: Qt.AlignCenter
                Layout.fillWidth: true
                spacing: 24
                Layout.bottomMargin: isVideo ? 8 : 0

                PushButton {
                    id: recordButton

                    Layout.alignment: Qt.AlignCenter

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

                    Layout.alignment: Qt.AlignCenter

                    preferredSize: btnSize

                    normalColor: isVideo ? "transparent" : JamiTheme.backgroundColor
                    hoveredColor: Qt.rgba(255, 255, 255, 0.2)
                    border.width: 1
                    border.color: imageColor

                    source: JamiResources.fiber_manual_record_24dp_svg
                    imageColor: UtilsAdapter.luma(JamiTheme.backgroundColor) ? "white" : JamiTheme.redColor

                    onClicked: {
                        root.photo = videoProvider.captureVideoFrame(VideoDevices.getDefaultDevice())
                        updateState(RecordBox.States.REC_SUCCESS)
                    }
                }

                PushButton {
                    id: btnStop

                    Layout.alignment: Qt.AlignCenter

                    preferredSize: btnSize

                    normalColor: isVideo ? "transparent" : JamiTheme.backgroundColor
                    hoveredColor: Qt.rgba(255, 255, 255, 0.2)

                    source: JamiResources.stop_24dp_red_svg
                    imageColor: UtilsAdapter.luma(JamiTheme.backgroundColor) ? "white" : JamiTheme.buttonTintedBlue
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

                    Layout.alignment: Qt.AlignCenter

                    preferredSize: btnSize

                    normalColor: isVideo ? "transparent" : JamiTheme.backgroundColor

                    source: JamiResources.re_record_24dp_svg
                    hoveredColor: Qt.rgba(255, 255, 255, 0.2)
                    imageColor: UtilsAdapter.luma(JamiTheme.backgroundColor) ? "white" : JamiTheme.buttonTintedBlue
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

                    Layout.alignment: Qt.AlignCenter

                    preferredSize: btnSize

                    normalColor: isVideo ? "transparent" : JamiTheme.backgroundColor

                    source: JamiResources.check_black_24dp_svg
                    imageColor: UtilsAdapter.luma(JamiTheme.backgroundColor) ? "white" : JamiTheme.buttonTintedBlue
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

                Timer {
                    id: timer

                    interval: 1000
                    running: false
                    repeat: true

                    onTriggered: updateTimer()
                }

                Text {
                    id: time

                    Layout.alignment: Qt.AlignCenter

                    visible: !root.isPhoto
                    text: "00:00"
                    color: JamiTheme.textColor
                    font.pointSize: (isVideo ? 12 : 20)
                }
            }
        }
    }
}
