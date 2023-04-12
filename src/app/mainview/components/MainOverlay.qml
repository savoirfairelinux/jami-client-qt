/*
 * Copyright (C) 2020-2023 Savoir-faire Linux Inc.
 * Author: Mingrui Zhang <mingrui.zhang@savoirfairelinux.com>
 * Author: Sébastien Blin <sebastien.blin@savoirfairelinux.com>
 * Author: Aline Gondim Santos <aline.gondimsantos@savoirfairelinux.com>
 * Author: Andreas Traczyk <andreas.traczyk@savoirfairelinux.com>
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
import QtQuick.Layouts
import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import "../../commoncomponents"

Item {
    id: root
    property alias callActionBar: __callActionBar
    property bool frozen: callActionBar.overflowOpen || callActionBar.barHovered || callActionBar.subMenuOpen || participantCallInStatusView.visible
    property bool muteAlertActive: false
    property string muteAlertMessage: ""
    property string remoteRecordingLabel
    property string timeText: "00:00"

    opacity: 0

    onMuteAlertActiveChanged: {
        if (muteAlertActive) {
            alertTimer.restart();
        }
    }

    // (un)subscribe to an app-wide mouse move event trap filtered
    // for the overlay's geometry
    onVisibleChanged: {
        visible ? CallOverlayModel.registerFilter(appWindow, this) : CallOverlayModel.unregisterFilter(appWindow, this);
    }

    Connections {
        target: CurrentCall

        function onIsRecordingRemotelyChanged() {
            var label = "";
            if (CurrentCall.isRecordingRemotely) {
                label = CurrentCall.remoteRecorderNameList.join(", ") + " ";
                label += (CurrentCall.remoteRecorderNameList.length > 1) ? JamiStrings.areRecording : JamiStrings.isRecording;
            }
            root.remoteRecordingLabel = label;
        }
    }
    Connections {
        target: CallOverlayModel

        function onMouseMoved(item) {
            if (item === root) {
                root.opacity = 1;
                fadeOutTimer.restart();
            }
        }
    }
    Shortcut {
        context: Qt.ApplicationShortcut
        enabled: root.visible
        sequence: "M"

        onActivated: {
            CallAdapter.muteAudioToggle();
            root.opacity = 1;
            fadeOutTimer.restart();
        }
    }
    Shortcut {
        context: Qt.ApplicationShortcut
        enabled: root.visible
        sequence: "V"

        onActivated: {
            CallAdapter.muteCameraToggle();
            root.opacity = 1;
            fadeOutTimer.restart();
        }
    }

    // control overlay fade out.
    Timer {
        id: fadeOutTimer
        interval: JamiTheme.overlayFadeDelay

        onTriggered: {
            if (frozen)
                return;
            root.opacity = 0;
            resetLabelsTimer.restart();
        }
    }

    // Timer to reset recording label and call duration time
    Timer {
        id: resetLabelsTimer
        interval: 1000
        repeat: true
        running: root.visible

        onTriggered: {
            root.timeText = CallAdapter.getCallDurationTime(LRCInstance.currentAccountId, LRCInstance.selectedConvUid);
            if (!root.opacity && !CurrentCall.isRecordingRemotely)
                root.remoteRecordingLabel = "";
        }
    }
    Item {
        id: overlayUpperPartRect
        anchors.top: parent.top
        height: 50
        width: parent.width

        RowLayout {
            anchors.fill: parent
            spacing: 0

            Text {
                id: jamiBestNameText
                Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
                Layout.preferredHeight: 50
                Layout.preferredWidth: overlayUpperPartRect.width / 2
                color: JamiTheme.whiteColor
                elide: Qt.ElideRight
                font.pointSize: JamiTheme.textFontSize
                horizontalAlignment: Text.AlignLeft
                leftPadding: 16
                text: {
                    if (!CurrentCall.isAudioOnly) {
                        if (root.remoteRecordingLabel === "") {
                            return CurrentConversation.title;
                        } else {
                            return root.remoteRecordingLabel;
                        }
                    }
                    return "";
                }
                verticalAlignment: Text.AlignVCenter
            }
            Text {
                id: callTimerText
                Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                Layout.preferredHeight: 48
                Layout.rightMargin: recordingRect.visible ? 0 : JamiTheme.preferredMarginSize
                color: JamiTheme.whiteColor
                elide: Qt.ElideRight
                font.pointSize: JamiTheme.textFontSize
                horizontalAlignment: Text.AlignRight
                text: timeText
                verticalAlignment: Text.AlignVCenter
            }
            Rectangle {
                id: recordingRect
                Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                Layout.rightMargin: JamiTheme.preferredMarginSize
                color: JamiTheme.recordIconColor
                height: 16
                radius: height / 2
                visible: CurrentCall.isRecordingLocally || CurrentCall.isRecordingRemotely
                width: 16

                SequentialAnimation on color  {
                    loops: Animation.Infinite
                    running: recordingRect.visible

                    ColorAnimation {
                        duration: JamiTheme.recordBlinkDuration
                        from: JamiTheme.recordIconColor
                        to: "transparent"
                    }
                    ColorAnimation {
                        duration: JamiTheme.recordBlinkDuration
                        from: "transparent"
                        to: JamiTheme.recordIconColor
                    }
                }
            }
        }
    }
    ParticipantCallInStatusView {
        id: participantCallInStatusView
        anchors.bottom: __callActionBar.top
        anchors.bottomMargin: 20
        anchors.right: root.right
        anchors.rightMargin: 10
    }
    Rectangle {
        id: alertMessage
        anchors.bottom: __callActionBar.top
        anchors.bottomMargin: 16
        anchors.horizontalCenter: __callActionBar.horizontalCenter
        color: JamiTheme.darkGreyColorOpacity
        height: alertMessageTxt.contentHeight + 16
        radius: 5
        visible: root.muteAlertActive
        width: alertMessageTxt.width + 16

        Text {
            id: alertMessageTxt
            anchors.centerIn: parent
            color: JamiTheme.whiteColor
            font.pointSize: JamiTheme.textFontSize
            horizontalAlignment: Text.AlignHCenter
            text: root.muteAlertMessage
            verticalAlignment: Text.AlignVCenter
            width: Math.min(root.width, contentWidth)
            wrapMode: Text.Wrap
        }

        // Timer to decide when ParticipantOverlay fade out
        Timer {
            id: alertTimer
            interval: JamiTheme.overlayFadeDelay

            onTriggered: {
                root.muteAlertActive = false;
            }
        }
    }
    CallActionBar {
        id: __callActionBar
        height: 55
        parentHeight: root.height - 81
        visible: root.opacity
        width: parent.width

        anchors {
            bottom: parent.bottom
            bottomMargin: 26
        }
    }

    Behavior on opacity  {
        NumberAnimation {
            duration: JamiTheme.overlayFadeDuration
        }
    }
}
