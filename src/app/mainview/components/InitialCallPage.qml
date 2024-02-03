/*
 * Copyright (C) 2020-2024 Savoir-faire Linux Inc.
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

    signal callCanceled
    signal callAccepted

    onCallAccepted: CallAdapter.acceptACall(CurrentAccount.id, CurrentConversation.id)
    onCallCanceled: CallAdapter.hangUpACall(CurrentAccount.id, CurrentConversation.id)

    color: "black"

    LocalVideo {
        id: localPreview
        anchors.centerIn: parent
        anchors.fill: parent

        readonly property bool start: {
            if (CurrentCall.isAudioOnly || !CurrentAccount.videoEnabled_Video) {
                return false;
            }
            if (!VideoDevices.listSize) {
                return false;
            }
            const isCallStatusEligible =
                (CurrentCall.status >= Call.Status.INCOMING_RINGING &&
                 CurrentCall.status <= Call.Status.SEARCHING) ||
                CurrentCall.status === Call.Status.CONNECTED;
            if (!isCallStatusEligible) {
                return false;
            }
            return true;
        }
        onStartChanged: localPreview.startWithId(start ? VideoDevices.getDefaultDevice() : "")
        opacity: 0.5
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
        anchors.fill: parent
        propagateComposedEvents: false
        acceptedButtons: Qt.AllButtons
        onDoubleClicked: function (mouse) {
            mouse.accepted = true;
        }
    }

    ColumnLayout {
        anchors.horizontalCenter: root.horizontalCenter
        anchors.verticalCenter: root.verticalCenter

        ConversationAvatar {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: JamiTheme.avatarSizeInCall
            Layout.preferredHeight: JamiTheme.avatarSizeInCall

            showPresenceIndicator: false
            animationMode: SpinningAnimation.Mode.Radial
            imageId: CurrentConversation.id
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: JamiTheme.preferredFieldWidth
            Layout.topMargin: 32

            font.pointSize: JamiTheme.titleFontSize

            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter

            property string title: CurrentConversation.title

            text: {
                if (!CurrentCall.isOutgoing)
                    return CurrentCall.isAudioOnly ? JamiStrings.incomingAudioCallFrom.replace("{}", title) : JamiStrings.incomingVideoCallFrom.replace("{}", title);
                else
                    return title;
            }
            wrapMode: Text.WordWrap
            elide: Text.ElideRight
            maximumLineCount: !CurrentCall.isOutgoing ? 2 : 1
            color: "white"
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: root.width
            Layout.topMargin: 8

            font.pointSize: JamiTheme.mediumFontSize

            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter

            text: UtilsAdapter.getCallStatusStr(CurrentCall.status) + "…"
            color: JamiTheme.whiteColor
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
                        Layout.leftMargin: 10
                        Layout.rightMargin: 10
                        Layout.alignment: Qt.AlignHCenter
                        implicitWidth: JamiTheme.callButtonPreferredSize
                        implicitHeight: JamiTheme.callButtonPreferredSize

                        pressedColor: {
                            if (type === "cam" || type === "mic")
                                return JamiTheme.acceptGreen;
                            return JamiTheme.refuseRed;
                        }
                        hoveredColor: {
                            if (type === "cam" || type === "mic")
                                return JamiTheme.acceptGreen;
                            return JamiTheme.refuseRed;
                        }
                        normalColor: {
                            if (type === "cam" || type === "mic")
                                return JamiTheme.acceptGreenTransparency;
                            return JamiTheme.refuseRedTransparent;
                        }

                        source: image
                        imageColor: JamiTheme.whiteColor

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
                        Layout.preferredWidth: JamiTheme.callButtonPreferredSize
                        Layout.preferredHeight: JamiTheme.preferredFieldHeight

                        font.pointSize: JamiTheme.smallFontSize
                        font.kerning: true
                        color: actionButton.hovered ? JamiTheme.whiteColor : JamiTheme.whiteColorTransparent

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

                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        wrapMode: Text.WordWrap
                    }
                }
            }
        }
    }

    Shortcut {
        sequence: "Ctrl+Y"
        context: Qt.ApplicationShortcut
        onActivated: CallAdapter.acceptACall(CurrentAccount.id, CurrentConversation.id)
    }

    Shortcut {
        sequence: "Ctrl+Shift+D"
        context: Qt.ApplicationShortcut
        onActivated: {
            CallAdapter.hangUpACall(CurrentAccount.id, CurrentConversation.id);
        }
    }
}
