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
    property bool isAudio: false
    property bool showVideo: (root.isVideo && VideoDevices.listSize !== 0)
    property int preferredWidth: 320
    property int preferredHeight: 500
    property int btnSize: 40

    property int offset: 3
    property int curveRadius: 6
    property int spikeHeight: 10 + offset

    property string photo: ""

    signal validatePhoto(string photo)

    modal: true
    closePolicy: Popup.NoAutoClose

    function openRecorder(vid) {
        isVideo = vid;
        isAudio = !vid && !isPhoto;
        updateState(RecordBox.States.INIT);
        if (isVideo) {
            localVideo.startWithId(VideoDevices.getDefaultDevice());
        }
        open();
    }

    function closeRecorder() {
        if (isVideo) {
            localVideo.startWithId("");
        }
        if (!root.isPhoto)
            stopRecording();
        close();
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

    function sendRecord() {
        if (pathRecorder !== "") {
            MessagesAdapter.sendFile(pathRecorder);
            MessagesAdapter.replyToId = "";
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
        id: boxBackground
        radius: 5
        anchors.fill: parent
        width: 300
        height: 300

        Rectangle {

            radius: 5
            id: previewWidget
            anchors.centerIn: parent
            height: root.isAudio ? 100 : 300
            width: 300
            color: root.isAudio ? JamiTheme.secondaryBackgroundColor : "transparent"

            Image {
                id: screenshotImg
                visible: root.showVideo && root.isPhoto && btnSend.visible
                anchors.fill: parent
                fillMode: Image.PreserveAspectCrop // Ajuste l'image tout en préservant l'aspect

                source: root.photo === "" ? "" : "data:image/png;base64," + root.photo
            }

            LocalVideo {
                id: localVideo
                anchors.fill: parent
                visible: root.showVideo && !screenshotImg.visible

                layer.enabled: true
                layer.effect: OpacityMask {
                    maskSource: rectBox
                }

                Rectangle {
                    id: rectBox
                    visible: false
                    anchors.fill: parent
                    radius: 5
                }
            }

            Rectangle {
                anchors.fill: parent
                color: "black"
                opacity: 0.6
                visible: root.isPhoto
                radius: 5

                layer.enabled: true
                layer.effect: OpacityMask {
                    anchors.centerIn: parent
                    maskSource: photoMask
                    invert: true
                }

                Item {
                    // Else it will be resized by the layer effect
                    id: photoMask
                    visible: false
                    anchors.fill: parent
                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.top
                        anchors.topMargin: 20
                        height: 200
                        width: 200
                        radius: height / 2
                    }
                }
            }

            ColumnLayout{
                id: mainLayout

                anchors.fill: parent
                Component.onCompleted: print("mainLayout width: " + width + " height: " + height)

                JamiPushButton {
                    id: cancelBtn
                    objectName: "cancelBtn"
                    z: 1

                    Layout.alignment: Qt.AlignRight | Qt.AlignTop
                    Layout.preferredHeight: 20
                    Layout.preferredWidth: 20
                    Layout.topMargin: 5
                    Layout.rightMargin: 5

                    imageColor: hovered ? JamiTheme.whiteColor : JamiTheme.recordBoxcloseButtonColor
                    normalColor: "transparent"
                    hoveredColor: JamiTheme.recordBoxHoverColor
                    source: JamiResources.round_close_24dp_svg

                    toolTipText: JamiStrings.close
                    focusPolicy: Qt.TabFocus

                    onClicked: {
                        closeRecorder();
                        updateState(RecordBox.States.INIT);
                    }
                }

                RowLayout {
                    id: controls

                    Layout.alignment: Qt.AlignHCenter | Qt.AlignBottom
                    Layout.fillWidth: true

                    spacing: 2
                    Layout.bottomMargin: 20//isVideo ? 8 : 0
                    Component.onCompleted: print("controls width: " + width + " height: " + height)

                    JamiPushButton {
                        id: recordButton

                        objectName: "recordButton"
                        Layout.alignment: Qt.AlignCenter
                        preferredSize: btnSize


                        imageColor: JamiTheme.whiteColor

                        source: JamiResources.record_round_black_24dp_svg

                        imageContainerHeight: 25
                        imageContainerWidth: 25

                        focusPolicy: Qt.TabFocus

                        background: RoundedBorderRectangle {
                            opacity: recordButton.hovered ? 1 : 0.5
                            fillColor: JamiTheme.screenshotButtonColor //recordButton.hovered ? JamiTheme.recordBoxHoverColor : JamiTheme.recordBoxButtonColor
                            radius: {
                                "tl": 5,
                                "tr": root.isAudio ? 0 : 5,
                                "br": root.isAudio ? 0 : 5,
                                "bl": 5
                            }
                        }

                        toolTipText: JamiStrings.startRec

                        onClicked: {
                            updateState(RecordBox.States.RECORDING);
                            if (!root.isPhoto)
                                startRecording();
                        }
                    }
                    JamiPushButton {
                        id: screenshotBtn
                        objectName: "screenshotBtn"

                        Layout.alignment: Qt.AlignCenter
                        preferredSize: btnSize
                        source: JamiResources.record_black_24dp_svg


                        imageContainerHeight: 20
                        imageContainerWidth: 20
                        imageColor: JamiTheme.whiteColor
                        focusPolicy: Qt.TabFocus

                        background: RoundedBorderRectangle {
                            opacity: screenshotBtn.hovered ? 1 : 0.7
                            fillColor: screenshotBtn.hovered ? JamiTheme.recordBoxHoverColor : JamiTheme.recordBoxButtonColor
                            radius: {
                                "tl": 5,
                                "tr": root.isAudio ? 0 : 5,
                                "br": root.isAudio ? 0 : 5,
                                "bl": 5
                            }
                        }

                        onClicked: {
                            root.photo = videoProvider.captureVideoFrame(VideoDevices.getDefaultDevice());
                                         updateState(RecordBox.States.REC_SUCCESS);
                        }
                    }

                    PushButton {
                        id: btnStop
                        objectName: "btnStop"

                        Layout.alignment: Qt.AlignCenter
                        preferredSize: btnSize

                        source: JamiResources.stop_rectangle_24dp_svg

                        imageColor: JamiTheme.whiteColor
                        imageContainerHeight: 20
                        imageContainerWidth: 20

                        focusPolicy: Qt.TabFocus

                        toolTipText: JamiStrings.stopRec

                        background: RoundedBorderRectangle {
                            opacity: btnStop.hovered ? 1 : 0.7
                            fillColor: btnStop.hovered ? JamiTheme.recordBoxHoverColor : JamiTheme.recordBoxButtonColor
                            radius: {
                                "tl": 5,
                                "tr": 0,
                                "br": 0,
                                "bl": 5
                            }
                        }

                        onClicked: {
                            if (!root.isPhoto)
                                stopRecording();
                            updateState(RecordBox.States.REC_SUCCESS);
                        }
                    }

                    JamiPushButton {
                        id: btnRestart

                        objectName: "btnRestart"
                        Layout.alignment: Qt.AlignCenter
                        preferredSize: btnSize

                        source: JamiResources.restart_black_24dp_svg

                        imageColor: JamiTheme.whiteColor
                        imageContainerHeight: 25
                        imageContainerWidth: 25

                        focusPolicy: Qt.TabFocus

                        toolTipText: JamiStrings.discardRestart

                        background: RoundedBorderRectangle {
                            opacity: btnRestart.hovered ? 1 : 0.7
                            fillColor: btnRestart.hovered ? JamiTheme.recordBoxHoverColor : JamiTheme.recordBoxButtonColor
                            radius: {
                                "tl": 5,
                                "tr": 0,
                                "br": 0,
                                "bl": 5
                            }
                        }


                        onClicked: {
                            if (!root.isPhoto)
                                stopRecording();
                            updateState(RecordBox.States.INIT);
                        }
                    }

                    RoundedBorderRectangle {
                        opacity: 0.7
                        fillColor: JamiTheme.recordBoxButtonColor
                        visible: (!recordButton.visible && !root.isPhoto) || root.isAudio

                        Layout.preferredHeight: btnSend.height
                        Layout.preferredWidth: time.width + 20
                        radius: {
                            "tl": 0,
                            "tr": timer.running ? 5 : 0,
                            "br": timer.running ? 5 : 0,
                            "bl": 0
                        }

                        Text {
                            id: time

                            anchors.centerIn: parent
                            opacity: 1

                            text: "00:00"
                            color: JamiTheme.whiteColor
                            font.pointSize: (isVideo ? 12 : 20)
                        }
                    }


                    JamiPushButton {
                        id: btnSend

                        objectName: "btnSend"
                        Layout.alignment: Qt.AlignCenter
                        preferredSize: btnSize

                        imageColor: JamiTheme.whiteColor
                        imageContainerHeight: 25
                        imageContainerWidth: 25

                        source: root.isPhoto ? JamiResources.check_circle_24dp_svg : JamiResources.send_black_24dp_svg

                        focusPolicy: Qt.TabFocus

                        toolTipText: JamiStrings.send

                        background: RoundedBorderRectangle {
                            opacity: btnSend.hovered ? 1 : 0.7
                            fillColor: JamiTheme.chatViewFooterSendButtonColor //btnSend.hovered ? JamiTheme.recordBoxHoverColor : JamiTheme.recordBoxButtonColor
                            radius: {
                                "tl": 0,
                                "tr": 5,
                                "br": 5,
                                "bl": 0
                            }
                        }

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
                        running: false
                        repeat: true
                        onTriggered: updateTimer()
                    }

                    }
        }
    }
    }
}
