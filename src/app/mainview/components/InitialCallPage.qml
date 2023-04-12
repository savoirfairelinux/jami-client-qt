/*
 * Copyright (C) 2020-2023 Savoir-faire Linux Inc.
 * Author: Mingrui Zhang <mingrui.zhang@savoirfairelinux.com>
 *         Aline Gondim Santos <aline.gondimsantos@savoirfairelinux.com>
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

Rectangle {
    id: root
    color: "black"

    signal callAccepted
    signal callCanceled
    function fillIncomingControls() {
        incomingControlsModel.clear();
        incomingControlsModel.append({
                "type": "refuse",
                "image": JamiResources.round_close_24dp_svg
            });
        incomingControlsModel.append({
                "type": "mic",
                "image": JamiResources.place_audiocall_24dp_svg
            });
        if (CurrentAccount.videoEnabled_Video && VideoDevices.listSize !== 0)
            incomingControlsModel.append({
                    "type": "cam",
                    "image": JamiResources.videocam_24dp_svg
                });
    }

    onCallAccepted: CallAdapter.acceptACall(CurrentAccount.id, CurrentConversation.id)
    onCallCanceled: CallAdapter.hangUpACall(CurrentAccount.id, CurrentConversation.id)

    LocalVideo {
        id: previewRenderer
        anchors.centerIn: parent
        anchors.fill: parent
        opacity: 0.5
        visible: !CurrentCall.isAudioOnly && CurrentAccount.videoEnabled_Video && VideoDevices.listSize !== 0 && ((CurrentCall.status >= Call.Status.INCOMING_RINGING && CurrentCall.status <= Call.Status.SEARCHING) || CurrentCall.status === Call.Status.CONNECTED)

        onVisibleChanged: {
            controlPreview.stop();
            if (visible) {
                controlPreview.startVideo = true;
                controlPreview.interval = 1000;
            } else {
                controlPreview.startVideo = false;
                controlPreview.interval = 0;
            }
            controlPreview.start();
        }

        // HACK: this is a workaround to the preview video starting
        // and stopping a few times. The root cause should be investigated ASAP.
        Timer {
            id: controlPreview
            property bool startVideo

            interval: 1000

            onTriggered: {
                var rendId = visible && startVideo ? VideoDevices.getDefaultDevice() : "";
                previewRenderer.startWithId(rendId);
            }
        }
    }
    ListModel {
        id: incomingControlsModel
        Component.onCompleted: {
            fillIncomingControls();
        }
    }
    Connections {
        target: CurrentAccount

        function onVideoEnabledVideoChanged() {
            fillIncomingControls();
        }
    }
    Connections {
        target: VideoDevices

        function onListSizeChanged() {
            fillIncomingControls();
        }
    }
    ListModel {
        id: outgoingControlsModel
        Component.onCompleted: {
            append({
                    "type": "cancel",
                    "image": JamiResources.ic_call_end_white_24dp_svg
                });
        }
    }

    // Prevent right click propagate to VideoCallPage.
    MouseArea {
        acceptedButtons: Qt.AllButtons
        anchors.fill: parent
        propagateComposedEvents: false

        onDoubleClicked: function (mouse) {
            mouse.accepted = true;
        }
    }
    ColumnLayout {
        anchors.horizontalCenter: root.horizontalCenter
        anchors.verticalCenter: root.verticalCenter

        ConversationAvatar {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredHeight: JamiTheme.avatarSizeInCall
            Layout.preferredWidth: JamiTheme.avatarSizeInCall
            animationMode: SpinningAnimation.Mode.Radial
            imageId: CurrentConversation.id
            showPresenceIndicator: false
        }
        Text {
            property string title: CurrentConversation.title

            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: JamiTheme.preferredFieldWidth
            Layout.topMargin: 32
            color: "white"
            elide: Text.ElideRight
            font.pointSize: JamiTheme.titleFontSize
            horizontalAlignment: Text.AlignHCenter
            maximumLineCount: !CurrentCall.isOutgoing ? 2 : 1
            text: {
                if (!CurrentCall.isOutgoing)
                    return CurrentCall.isAudioOnly ? JamiStrings.incomingAudioCallFrom.replace("{}", title) : JamiStrings.incomingVideoCallFrom.replace("{}", title);
                else
                    return title;
            }
            verticalAlignment: Text.AlignVCenter
            wrapMode: Text.WordWrap
        }
        Text {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: root.width
            Layout.topMargin: 8
            color: JamiTheme.whiteColor
            font.pointSize: JamiTheme.smartlistItemFontSize
            horizontalAlignment: Text.AlignHCenter
            text: UtilsAdapter.getCallStatusStr(CurrentCall.status) + "…"
            verticalAlignment: Text.AlignVCenter
            visible: CurrentCall.isOutgoing
        }
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 32

            Repeater {
                id: controlButtons
                model: !CurrentCall.isOutgoing ? incomingControlsModel : outgoingControlsModel

                delegate: ColumnLayout {
                    visible: (type === "cam" && CurrentCall.isAudioOnly) ? false : true

                    PushButton {
                        id: actionButton
                        Layout.alignment: Qt.AlignHCenter
                        Layout.leftMargin: 10
                        Layout.rightMargin: 10
                        hoveredColor: {
                            if (type === "cam" || type === "mic")
                                return JamiTheme.acceptGreen;
                            return JamiTheme.refuseRed;
                        }
                        imageColor: JamiTheme.whiteColor
                        implicitHeight: JamiTheme.callButtonPreferredSize
                        implicitWidth: JamiTheme.callButtonPreferredSize
                        normalColor: {
                            if (type === "cam" || type === "mic")
                                return JamiTheme.acceptGreenTransparency;
                            return JamiTheme.refuseRedTransparent;
                        }
                        pressedColor: {
                            if (type === "cam" || type === "mic")
                                return JamiTheme.acceptGreen;
                            return JamiTheme.refuseRed;
                        }
                        source: image

                        onClicked: {
                            if (type === "cam" || type === "mic") {
                                var acceptVideoMedia = true;
                                if (type === "cam")
                                    acceptVideoMedia = true;
                                else if (type === "mic")
                                    acceptVideoMedia = false;
                                CallAdapter.setCallMedia(CurrentAccount.id, CurrentConversation.id, acceptVideoMedia);
                                callAccepted();
                            } else {
                                callCanceled();
                            }
                        }
                    }
                    Label {
                        id: buttonLabel
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredHeight: JamiTheme.preferredFieldHeight
                        Layout.preferredWidth: JamiTheme.callButtonPreferredSize
                        color: actionButton.hovered ? JamiTheme.whiteColor : JamiTheme.whiteColorTransparent
                        font.kerning: true
                        font.pointSize: JamiTheme.smartlistItemInfoFontSize
                        horizontalAlignment: Text.AlignHCenter
                        text: {
                            if (type === "refuse")
                                return JamiStrings.refuse;
                            else if (type === "cam")
                                return JamiStrings.acceptVideo;
                            else if (type === "mic")
                                return CurrentCall.isAudioOnly ? JamiStrings.accept : JamiStrings.acceptAudio;
                            else if (type === "cancel")
                                return JamiStrings.endCall;
                            return "";
                        }
                        verticalAlignment: Text.AlignVCenter
                        wrapMode: Text.WordWrap
                    }
                }
            }
        }
    }
    Shortcut {
        context: Qt.ApplicationShortcut
        sequence: "Ctrl+Y"

        onActivated: CallAdapter.acceptACall(CurrentAccount.id, CurrentConversation.id)
    }
    Shortcut {
        context: Qt.ApplicationShortcut
        sequence: "Ctrl+Shift+D"

        onActivated: {
            CallAdapter.hangUpACall(CurrentAccount.id, CurrentConversation.id);
        }
    }
}
