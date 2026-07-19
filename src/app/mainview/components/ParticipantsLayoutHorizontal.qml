/*
 * Copyright (C) 2020-2026 Savoir-faire Linux Inc.
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
import QtQuick.Controls
import net.jami.Adapters 1.1
import net.jami.Models 1.1
import net.jami.Constants 1.1
import net.jami.Enums 1.1

SplitView {
    id: root

    property int layoutCount: commonParticipants.count + activeParticipants.count
    property var participantComponent

    orientation: Qt.Horizontal
    handle: Rectangle {
        implicitHeight: root.height
        implicitWidth: 11
        color: "transparent"
        Rectangle {
            anchors.centerIn: parent
            width: 1
            height: parent.implicitHeight - 40
            color: JamiTheme.darkGreyColor
        }

        Rectangle {
            height: 45
            anchors.centerIn: parent
            width: 1
            color: "black"
        }

        RowLayout {
            anchors.centerIn: parent
            height: 45
            width: 11
            Rectangle {
                Layout.fillHeight: true
                Layout.topMargin: 10
                Layout.bottomMargin: 10
                width: 2
                color: JamiTheme.darkGreyColor
            }
            Rectangle {
                Layout.fillHeight: true
                Layout.topMargin: 10
                Layout.bottomMargin: 10
                width: 2
                color: JamiTheme.darkGreyColor
            }
        }
    }

    // ACTIVE
    Flow {
        id: activeParticipantsFlow

        TapHandler {
            acceptedButtons: Qt.LeftButton | Qt.RightButton
        }

        SplitView.minimumWidth: parent.width / 4
        SplitView.maximumWidth: parent.width
        SplitView.fillWidth: true

        spacing: 8
        property int columns: Math.max(1, Math.ceil(Math.sqrt(activeParticipants.count)))
        property int rows: Math.max(1, Math.ceil(activeParticipants.count / columns))
        property int columnsSpacing: 5 * (columns - 1)
        property int rowsSpacing: 5 * (rows - 1)

        visible: inLine || CallParticipantsModel.conferenceLayout === CallParticipantsModel.ONE

        Repeater {
            id: activeParticipants
            anchors.fill: parent
            anchors.centerIn: parent

            model: activeParticipantsModel
            delegate: Loader {
                active: root.visible
                asynchronous: true
                sourceComponent: callVideoMedia
                visible: status == Loader.Ready

                width: Math.ceil(activeParticipantsFlow.width / activeParticipantsFlow.columns) - activeParticipantsFlow.columnsSpacing
                height: Math.ceil(activeParticipantsFlow.height / activeParticipantsFlow.rows) - activeParticipantsFlow.rowsSpacing

                property string uri_: Uri
                property string bestName_: BestName
                property string avatar_: Avatar ? Avatar : ""
                property string sinkId_: SinkId ? SinkId : ""
                property string deviceId_: Device
                property int leftMargin_: 0
                property bool isLocal_: IsLocal
                property bool active_: Active
                property bool videoMuted_: VideoMuted
                property bool isContact_: IsContact
                property bool isModerator_: IsModerator
                property bool audioLocalMuted_: AudioLocalMuted
                property bool audioModeratorMuted_: AudioModeratorMuted
                property bool isHandRaised_: HandRaised
                property bool voiceActive_: VoiceActivity
                property bool isRecording_: IsRecording
                property bool isSharing_: IsSharing
            }
        }
    }

    Rectangle {
        id: genericParticipantsRect

        TapHandler {
            acceptedButtons: Qt.TopButton | Qt.BottomButton
        }

        SplitView.preferredWidth: (parent.width / 4)
        SplitView.minimumWidth: parent.width / 6
        SplitView.maximumWidth: inLine ? parent.width / 2 : parent.width

        visible: commonParticipants.count > 0 && (inLine || CallParticipantsModel.conferenceLayout === CallParticipantsModel.GRID)
        color: "transparent"

        ColumnLayout {
            anchors.fill: parent
            width: parent.width

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredHeight: 30
                Layout.bottomMargin: 16
                Layout.topMargin: 16
                spacing: 8
                visible: centerItem.canScrollUp || centerItem.canScrollDown

                RoundButton {
                    Layout.preferredWidth: 30
                    Layout.preferredHeight: 30
                    radius: 10
                    text: "^"
                    enabled: centerItem.canScrollUp
                    opacity: enabled ? 1 : 0.35
                    onClicked: centerItem.scrollUp()
                    background: Rectangle {
                        anchors.fill: parent
                        color: JamiTheme.lightGrey_
                        radius: JamiTheme.primaryRadius
                    }
                }

                RoundButton {
                    Layout.preferredWidth: 30
                    Layout.preferredHeight: 30
                    radius: 10
                    text: "v"
                    enabled: centerItem.canScrollDown
                    opacity: enabled ? 1 : 0.35
                    onClicked: centerItem.scrollDown()
                    background: Rectangle {
                        anchors.fill: parent
                        color: JamiTheme.lightGrey_
                        radius: JamiTheme.primaryRadius
                    }
                }
            }

            Flickable {
                id: centerItem
                Layout.fillHeight: true
                Layout.fillWidth: true
                Layout.margins: 4

                clip: true
                interactive: inLine
                flickableDirection: Flickable.VerticalFlick
                boundsBehavior: Flickable.StopAtBounds
                contentWidth: width
                contentHeight: inLine ? commonParticipantsFlow.implicitHeight : height

                ScrollBar.vertical: ScrollBar {
                    policy: inLine ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff
                }

                readonly property bool canScrollUp: inLine && contentY > 0.5
                readonly property bool canScrollDown: inLine && contentY < contentHeight - height - 0.5
                function scrollStep() {
                    // Scroll by most of a page; robust to variable tile heights.
                    return Math.max(1, centerItem.height * 0.85);
                }
                function scrollUp() {
                    contentY = Math.max(0, contentY - scrollStep());
                }
                function scrollDown() {
                    contentY = Math.max(0, Math.min(contentHeight - height, contentY + scrollStep()));
                }

                // GENERIC
                Flow {
                    id: commonParticipantsFlow
                    width: centerItem.width
                    height: inLine ? implicitHeight : centerItem.height

                    spacing: 4
                    property int columns: {
                        if (inLine)
                            return 1;
                        var ratio = Math.round(root.width / root.height);
                        // If ratio is 2 we can have 2 times more elements on each columns
                        var wantedCol = Math.max(1, Math.round(Math.sqrt(commonParticipants.count) * ratio));
                        var cols = Math.min(commonParticipants.count, wantedCol);
                        // Optimize with the rows (eg 7 with ratio 2 should have 4 and 3 items, not 6 and 1)
                        var rows = Math.max(1, Math.ceil(commonParticipants.count / cols));
                        return Math.min(Math.ceil(commonParticipants.count / rows), cols);
                    }
                    property int rows: {
                        if (inLine)
                            return commonParticipants.count;
                        Math.max(1, Math.ceil(commonParticipants.count / columns));
                    }
                    property int componentHeight: {
                        var totalSpacing = commonParticipantsFlow.spacing * commonParticipantsFlow.rows;
                        return Math.floor((commonParticipantsFlow.height - totalSpacing) / commonParticipantsFlow.rows);
                    }
                    property int componentWidth: {
                        var totalSpacing = commonParticipantsFlow.spacing * commonParticipantsFlow.columns;
                        var w = Math.floor((commonParticipantsFlow.width - totalSpacing) / commonParticipantsFlow.columns);
                        if (inLine) {
                            w = commonParticipantsFlow.width;
                        }
                        return w;
                    }

                    Item {
                        width: parent.width
                        height: 0
                    }

                    Repeater {
                        id: commonParticipants

                        model: genericParticipantsModel
                        delegate: Loader {
                            sourceComponent: callVideoMedia
                            // Cull off-screen tiles in the scrollable side strip so
                            // their VideoView stops rendering; keep them laid out
                            // (visible + sized) so flick scrolling still reaches all.
                            active: root.visible && (!inLine || inViewport_)
                            asynchronous: true
                            visible: inLine || status === Loader.Ready
                            width: commonParticipantsFlow.componentWidth + leftMargin_
                            height: {
                                if (inLine)
                                    return Math.round(commonParticipantsFlow.componentWidth * invAspectRatio_);
                                if (commonParticipantsFlow.columns === 1)
                                    return commonParticipantsFlow.componentHeight;
                                var totalSpacing = commonParticipantsFlow.spacing * commonParticipantsFlow.rows;
                                return Math.floor((genericParticipantsRect.height - totalSpacing) / commonParticipantsFlow.rows);
                            }

                            property real invAspectRatio_: (item && item.invAspectRatio > 0) ? item.invAspectRatio : 0.5625
                            // Whether this tile is within (or near) the visible
                            // viewport of the scrollable side strip; used to cull
                            // off-screen VideoView rendering while keeping layout.
                            property bool inViewport_: {
                                if (!inLine)
                                    return true;
                                var relTop = y - centerItem.contentY;
                                var buffer = centerItem.height;
                                return (relTop + height > -buffer) && (relTop < centerItem.height + buffer);
                            }
                            property int leftMargin_: {
                                if (inLine || commonParticipantsFlow.rows === 1)
                                    return 0;
                                var lastParticipants = (commonParticipants.count % commonParticipantsFlow.columns);
                                if (lastParticipants !== 0 && index === commonParticipants.count - lastParticipants) {
                                    var compW = commonParticipantsFlow.componentWidth + commonParticipantsFlow.spacing;
                                    var lastLineW = lastParticipants * compW;
                                    return Math.floor((commonParticipantsFlow.width - lastLineW) / 2);
                                }
                                return 0;
                            }

                            property string uri_: Uri
                            property string deviceId_: Device
                            property string bestName_: BestName
                            property string avatar_: Avatar ? Avatar : ""
                            property string sinkId_: SinkId ? SinkId : ""
                            property bool isLocal_: IsLocal
                            property bool active_: Active
                            property bool videoMuted_: VideoMuted
                            property bool isContact_: IsContact
                            property bool isModerator_: IsModerator
                            property bool audioLocalMuted_: AudioLocalMuted
                            property bool audioModeratorMuted_: AudioModeratorMuted
                            property bool isHandRaised_: HandRaised
                            property bool voiceActive_: VoiceActivity
                            property bool isRecording_: IsRecording
                            property bool isSharing_: IsSharing
                        }
                    }
                }
            }

            Item {
                Layout.alignment: Qt.AlignHCenter
                width: parent.width
                height: 30
            }
        }
    }
}
