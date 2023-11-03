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
    property int preferredHeight: 500
    property int btnSize: 40

    property int offset: 3
    property int curveRadius: 6
    property int spikeHeight: 10 + offset

    property string photo: ""

    signal validatePhoto(string photo)

    modal: true
    closePolicy: Popup.CloseOnPressOutsideParent

    function openRecorder(vid) {
        isVideo = vid;
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

//    background: Item {
//    } // Computed by id: box, to do the layer on LocalVideo

//    width: 300
//    height: 300

    Rectangle {
        id: boxBackground
        radius: 5
        anchors.fill: parent
        width: 300
        height: 300

        Component.onCompleted: print("boxBackground width: " + width + " height: " + height)

        // Video

//        Rectangle {
//            radius: 5
//            visible: root.showVideo && root.isPhoto && btnSend.visible
//            anchors.centerIn: parent
//            height: 300
//            width: 300
//            color: "transparent"


//        }

        // video Preview
        Rectangle {
            radius: 5
            id: previewWidget
            anchors.centerIn: parent
            height: 300
            width: 300
            color: "transparent"

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
                    toolTipText: JamiStrings.back

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
                    //Layout.fillHeight: true
                    //spacing: 24
                    spacing: 0
                    Layout.bottomMargin: 20//isVideo ? 8 : 0

                    Component.onCompleted: print("controls width: " + width + " height: " + height)

                    JamiPushButton {
                        id: recordButton
                        objectName: "recordButton"
                        Layout.alignment: Qt.AlignCenter

                        preferredSize: btnSize

                        normalColor: isVideo ? "transparent" : JamiTheme.backgroundColor
                        hoveredColor: Qt.rgba(255, 255, 255, 0.2)
                        border.width: 1
                        border.color: imageColor

                        source: JamiResources.fiber_manual_record_24dp_svg
                        imageColor: UtilsAdapter.luma(JamiTheme.backgroundColor) ? "white" : JamiTheme.redColor

                        focusPolicy: Qt.TabFocus
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

                        normalColor: JamiTheme.deleteButtonRed

                        hoveredColor: JamiTheme.deleteButtonRed
                        background.opacity: hovered ? 1 : 0.5

                        source: JamiResources.record_round_black_24dp_svg
                        imageColor: JamiTheme.whiteColor

                        imageContainerHeight: 25
                        imageContainerWidth: 25

                        focusPolicy: Qt.TabFocus
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

                        normalColor: isVideo ? "transparent" : JamiTheme.backgroundColor
                        hoveredColor: Qt.rgba(255, 255, 255, 0.2)

                        source: JamiResources.stop_24dp_red_svg
                        imageColor: UtilsAdapter.luma(JamiTheme.backgroundColor) ? "white" : JamiTheme.buttonTintedBlue
                        border.width: 1
                        border.color: imageColor

                        focusPolicy: Qt.TabFocus
                        onClicked: {
                            if (!root.isPhoto)
                                stopRecording();
                            updateState(RecordBox.States.REC_SUCCESS);
                        }
                    }

                    Rectangle{
                        id: btnRestart2

                        visible: restart.visible

                        color: restart.hovered ? restart.hoveredColor : restart.normalColor
                        opacity: restart.background.opacity
                        height: restart.height
                        width: restart.width/2
                        radius: 5
                    }

                    Rectangle{
                        id: btnRestart

                        color: restart.hovered ? restart.hoveredColor : restart.normalColor
                        opacity: restart.background.opacity
                        height: restart.height
                        width: restart.width * 2/3


                        JamiPushButton {
                            id: restart

                            anchors.right: parent.right

                            objectName: "btnRestart"
                            Layout.alignment: Qt.AlignCenter

                            preferredSize: btnSize

                            normalColor: JamiTheme.recordBoxButtonColor
                            hoveredColor: JamiTheme.recordBoxHoverColor

                            source: JamiResources.restart_black_24dp_svg
                            imageColor: JamiTheme.whiteColor

                            imageContainerHeight: 25
                            imageContainerWidth: 25

                            background.opacity: hovered ? 1 : 0.7

                            focusPolicy: Qt.TabFocus
                            onClicked: {
                                if (!root.isPhoto)
                                    stopRecording();
                                updateState(RecordBox.States.INIT);
                            }
                        }
                    }



                    JamiPushButton {
                        id: btnSend
                        objectName: "btnSend"

                        Layout.alignment: Qt.AlignCenter
                                            height: 40
                                            width: 40
                        preferredSize: btnSize
                        normalColor: JamiTheme.backgroundColor

                        imageColor: JamiTheme.tintedBlue
                        source: JamiResources.check_box_24dp_svg
                        focusPolicy: Qt.TabFocus
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
}
