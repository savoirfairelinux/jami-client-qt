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

    property int btnSize: 40
    property int curveRadius: 6
    property int duration: 0
    property bool isPhoto: false
    property bool isVideo: false
    property int offset: 3
    property string pathRecorder: ""
    property string photo: ""
    property int preferredHeight: 240
    property int preferredWidth: 320
    property bool showVideo: (root.isVideo && VideoDevices.listSize !== 0)
    property int spikeHeight: 10 + offset
    property int state: RecordBox.States.INIT

    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent
    height: isVideo ? previewWidget.height + 80 : preferredHeight
    modal: true
    width: preferredWidth

    function closeRecorder() {
        if (isVideo) {
            localVideo.startWithId("");
        }
        if (!root.isPhoto)
            stopRecording();
        close();
    }
    function openRecorder(vid) {
        isVideo = vid;
        updateState(RecordBox.States.INIT);
        if (isVideo) {
            localVideo.startWithId(VideoDevices.getDefaultDevice());
        }
        open();
    }
    function sendRecord() {
        if (pathRecorder !== "") {
            MessagesAdapter.sendFile(pathRecorder);
            MessagesAdapter.replyToId = "";
        }
    }
    function startRecording() {
        timer.start();
        pathRecorder = AVModel.startLocalMediaRecorder(isVideo ? VideoDevices.getDefaultDevice() : "");
        if (pathRecorder == "") {
            timer.stop();
        }
    }
    function stopRecording() {
        if (pathRecorder !== "") {
            AVModel.stopLocalRecorder(pathRecorder);
        }
    }
    function updateState(new_state) {
        state = new_state;
        if (isPhoto) {
            screenshotBtn.visible = (state === RecordBox.States.INIT);
            recordButton.visible = false;
            btnStop.visible = false;
        } else {
            screenshotBtn.visible = false;
            recordButton.visible = (state === RecordBox.States.INIT);
            btnStop.visible = (state === RecordBox.States.RECORDING);
        }
        btnRestart.visible = (state === RecordBox.States.REC_SUCCESS);
        btnSend.visible = (state === RecordBox.States.REC_SUCCESS);
        if (state === RecordBox.States.INIT) {
            duration = 0;
            time.text = "00:00";
            timer.stop();
        } else if (state === RecordBox.States.REC_SUCCESS) {
            timer.stop();
        }
    }
    function updateTimer() {
        duration += 1;
        var m = Math.trunc(duration / 60);
        var s = (duration % 60);
        var min = (m < 10) ? "0" + String(m) : String(m);
        var sec = (s < 10) ? "0" + String(s) : String(s);
        time.text = min + ":" + sec;
    }
    signal validatePhoto(string photo)

    onActiveFocusChanged: {
        if (visible) {
            closeRecorder();
        }
    }
    onVisibleChanged: {
        if (!visible) {
            closeRecorder();
        }
    }

    Rectangle {
        id: box
        anchors.fill: parent
        color: JamiTheme.backgroundColor
        radius: 5

        PushButton {
            id: cancelBtn
            anchors.margins: 8
            anchors.right: box.right
            anchors.top: box.top
            hoveredColor: Qt.rgba(255, 255, 255, 0.2)
            imageColor: isVideo ? JamiTheme.whiteColor : JamiTheme.textColor
            normalColor: "transparent"
            preferredSize: 12
            source: JamiResources.round_close_24dp_svg
            toolTipText: JamiStrings.back
            z: 1

            onClicked: {
                closeRecorder();
                updateState(RecordBox.States.INIT);
            }
        }
        Item {
            // Else it will be resized by the layer effect
            id: photoMask
            anchors.fill: parent
            visible: false

            Rectangle {
                anchors.centerIn: parent
                height: parent.height
                radius: height / 2
                width: parent.height
            }
        }
        Rectangle {
            id: rectBox
            anchors.fill: parent
            radius: 5
            visible: false
        }
        ColumnLayout {
            id: recordItem
            Layout.alignment: Qt.AlignTop
            anchors.fill: parent
            spacing: 0

            // Video
            Image {
                id: screenshotImg
                Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
                source: root.photo === "" ? "" : "data:image/png;base64," + root.photo
                sourceSize.height: width * localVideo.invAspectRatio
                sourceSize.width: parent.width
                visible: root.showVideo && root.isPhoto && btnSend.visible
            }

            // video Preview
            Rectangle {
                id: previewWidget
                Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
                color: JamiTheme.primaryForegroundColor
                height: localVideo.width * localVideo.invAspectRatio
                visible: root.showVideo && !screenshotImg.visible
                width: parent.width

                LocalVideo {
                    id: localVideo
                    anchors.fill: parent
                    layer.enabled: true

                    Rectangle {
                        anchors.fill: parent
                        color: "black"
                        layer.enabled: true
                        opacity: 0.6
                        visible: root.isPhoto

                        layer.effect: OpacityMask {
                            anchors.centerIn: parent
                            invert: true
                            maskSource: photoMask
                        }
                    }

                    layer.effect: OpacityMask {
                        maskSource: rectBox
                    }
                }
            }
            RowLayout {
                id: controls
                Layout.alignment: Qt.AlignCenter
                Layout.bottomMargin: isVideo ? 8 : 0
                Layout.fillWidth: true
                spacing: 24

                PushButton {
                    id: recordButton
                    Layout.alignment: Qt.AlignCenter
                    hoveredColor: Qt.rgba(255, 255, 255, 0.2)
                    imageColor: JamiTheme.recordIconColor
                    normalColor: isVideo ? "transparent" : JamiTheme.backgroundColor
                    preferredSize: btnSize
                    source: JamiResources.fiber_manual_record_24dp_svg

                    onClicked: {
                        updateState(RecordBox.States.RECORDING);
                        if (!root.isPhoto)
                            startRecording();
                    }
                }
                PushButton {
                    id: screenshotBtn
                    Layout.alignment: Qt.AlignCenter
                    border.color: imageColor
                    border.width: 1
                    hoveredColor: Qt.rgba(255, 255, 255, 0.2)
                    imageColor: UtilsAdapter.luma(JamiTheme.backgroundColor) ? "white" : JamiTheme.redColor
                    normalColor: isVideo ? "transparent" : JamiTheme.backgroundColor
                    preferredSize: btnSize
                    source: JamiResources.fiber_manual_record_24dp_svg

                    onClicked: {
                        root.photo = videoProvider.captureVideoFrame(VideoDevices.getDefaultDevice());
                        updateState(RecordBox.States.REC_SUCCESS);
                    }
                }
                PushButton {
                    id: btnStop
                    Layout.alignment: Qt.AlignCenter
                    border.color: imageColor
                    border.width: 1
                    hoveredColor: Qt.rgba(255, 255, 255, 0.2)
                    imageColor: UtilsAdapter.luma(JamiTheme.backgroundColor) ? "white" : JamiTheme.buttonTintedBlue
                    normalColor: isVideo ? "transparent" : JamiTheme.backgroundColor
                    preferredSize: btnSize
                    source: JamiResources.stop_24dp_red_svg

                    onClicked: {
                        if (!root.isPhoto)
                            stopRecording();
                        updateState(RecordBox.States.REC_SUCCESS);
                    }
                }
                PushButton {
                    id: btnRestart
                    Layout.alignment: Qt.AlignCenter
                    border.color: imageColor
                    border.width: 1
                    hoveredColor: Qt.rgba(255, 255, 255, 0.2)
                    imageColor: UtilsAdapter.luma(JamiTheme.backgroundColor) ? "white" : JamiTheme.buttonTintedBlue
                    normalColor: isVideo ? "transparent" : JamiTheme.backgroundColor
                    preferredSize: btnSize
                    source: JamiResources.re_record_24dp_svg

                    onClicked: {
                        if (!root.isPhoto)
                            stopRecording();
                        updateState(RecordBox.States.INIT);
                    }
                }
                PushButton {
                    id: btnSend
                    Layout.alignment: Qt.AlignCenter
                    border.color: imageColor
                    border.width: 1
                    imageColor: UtilsAdapter.luma(JamiTheme.backgroundColor) ? "white" : JamiTheme.buttonTintedBlue
                    normalColor: isVideo ? "transparent" : JamiTheme.backgroundColor
                    preferredSize: btnSize
                    source: JamiResources.check_black_24dp_svg

                    onClicked: {
                        if (!root.isPhoto) {
                            stopRecording();
                            sendRecord();
                        } else if (root.photo !== "") {
                            root.validatePhoto(root.photo);
                        }
                        closeRecorder();
                        updateState(RecordBox.States.INIT);
                    }
                }
                Timer {
                    id: timer
                    interval: 1000
                    repeat: true
                    running: false

                    onTriggered: updateTimer()
                }
                Text {
                    id: time
                    Layout.alignment: Qt.AlignCenter
                    color: JamiTheme.textColor
                    font.pointSize: (isVideo ? 12 : 20)
                    text: "00:00"
                    visible: !root.isPhoto
                }
            }
        }
    }

    background: Item {
    } // Computed by id: box, to do the layer on LocalVideo
}
