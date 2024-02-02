/*
 * Copyright (C) 2020-2024 Savoir-faire Linux Inc.
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

    property string timeText: "00:00"
    property string remoteRecordingLabel

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

    property alias callActionBar: __callActionBar

    property bool frozen: callActionBar.overflowOpen || callActionBar.barHovered || callActionBar.subMenuOpen || participantCallInStatusView.visible

    property string muteAlertMessage: ""
    property bool muteAlertActive: false

    onMuteAlertActiveChanged: {
        if (muteAlertActive) {
            alertTimer.restart();
        }
    }

    opacity: 0

    // (un)subscribe to an app-wide mouse move event trap filtered
    // for the overlay's geometry
    function setupFilter() {
        if (visible) {
            CallOverlayModel.registerFilter(appWindow, this);
        } else {
            CallOverlayModel.unregisterFilter(appWindow, this);
        }
    }
    Component.onCompleted: setupFilter()
    onVisibleChanged: setupFilter()

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
        sequence: "M"
        enabled: root.visible
        context: Qt.ApplicationShortcut
        onActivated: {
            CallAdapter.muteAudioToggle();
            root.opacity = 1;
            fadeOutTimer.restart();
        }
    }

    Shortcut {
        sequence: "V"
        enabled: root.visible
        context: Qt.ApplicationShortcut
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
        running: root.visible
        repeat: true
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
        anchors.left: parent.left
        anchors.right: parent.right
        // QWK: spacing
        anchors.leftMargin: layoutManager.qwkSystemButtonSpacing.left
        anchors.rightMargin: layoutManager.qwkSystemButtonSpacing.right

        RowLayout {
            anchors.fill: parent

            spacing: 0

            Text {
                id: jamiBestNameText

                Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
                Layout.preferredWidth: overlayUpperPartRect.width / 2
                Layout.preferredHeight: 50

                leftPadding: 16
                rightPadding: 16

                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter

                font.pointSize: JamiTheme.textFontSize
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
                color: JamiTheme.whiteColor
                elide: Qt.ElideRight
            }

            Text {
                id: callTimerText

                Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                Layout.preferredHeight: 48
                Layout.rightMargin: recordingRect.visible ? 0 : JamiTheme.preferredMarginSize

                font.pointSize: JamiTheme.textFontSize
                horizontalAlignment: Text.AlignRight
                verticalAlignment: Text.AlignVCenter

                text: timeText
                color: JamiTheme.whiteColor
                elide: Qt.ElideRight
            }

            Rectangle {
                id: recordingRect
                visible: CurrentCall.isRecordingLocally || CurrentCall.isRecordingRemotely

                Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                Layout.rightMargin: JamiTheme.preferredMarginSize

                height: 16
                width: 16

                radius: height / 2
                color: JamiTheme.recordIconColor

                SequentialAnimation on color {
                    loops: Animation.Infinite
                    running: recordingRect.visible
                    ColorAnimation {
                        from: JamiTheme.recordIconColor
                        to: "transparent"
                        duration: JamiTheme.recordBlinkDuration
                    }
                    ColorAnimation {
                        from: "transparent"
                        to: JamiTheme.recordIconColor
                        duration: JamiTheme.recordBlinkDuration
                    }
                }
            }
        }
    }

    ParticipantCallInStatusView {
        id: participantCallInStatusView

        anchors.right: root.right
        anchors.rightMargin: 10
        anchors.bottom: __callActionBar.top
        anchors.bottomMargin: 20
    }

    Rectangle {
        id: alertMessage

        anchors.bottom: __callActionBar.top
        anchors.bottomMargin: 16
        anchors.horizontalCenter: __callActionBar.horizontalCenter
        width: alertMessageTxt.width + 16
        height: alertMessageTxt.contentHeight + 16
        radius: 5
        visible: root.muteAlertActive
        color: JamiTheme.darkGreyColorOpacity

        Text {
            id: alertMessageTxt
            text: root.muteAlertMessage
            anchors.centerIn: parent
            width: Math.min(root.width, contentWidth)
            color: JamiTheme.whiteColor
            font.pointSize: JamiTheme.textFontSize
            wrapMode: Text.Wrap
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
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

        objectName: "callActionBar"

        anchors {
            bottom: parent.bottom
            bottomMargin: 26
        }

        width: parent.width
        height: 55
        parentHeight: root.height - 81
        visible: root.opacity
    }

    Behavior on opacity {
        NumberAnimation {
            duration: JamiTheme.overlayFadeDuration
        }
    }
}
