/*
 * Copyright (C) 2020-2023 Savoir-faire Linux Inc.
 * Authors: Sébastien Blin <sebastien.blin@savoirfairelinux.com>
 *          Aline Gondim Santos <aline.gondimsantos@savoirfairelinux.com>
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

    // ACTIVE
    Flow {
        id: activeParticipantsFlow
        property int columns: Math.max(1, Math.ceil(Math.sqrt(activeParticipants.count)))
        property int columnsSpacing: 5 * (columns - 1)
        property int rows: Math.max(1, Math.ceil(activeParticipants.count / columns))
        property int rowsSpacing: 5 * (rows - 1)

        SplitView.fillWidth: true
        SplitView.maximumWidth: parent.width
        SplitView.minimumWidth: parent.width / 4
        spacing: 8
        visible: inLine || CallParticipantsModel.conferenceLayout === CallParticipantsModel.ONE

        TapHandler {
            acceptedButtons: Qt.LeftButton | Qt.RightButton
        }
        Repeater {
            id: activeParticipants
            anchors.centerIn: parent
            anchors.fill: parent
            model: activeParticipantsModel

            delegate: Loader {
                property bool active_: Active
                property bool audioLocalMuted_: AudioLocalMuted
                property bool audioModeratorMuted_: AudioModeratorMuted
                property string avatar_: Avatar ? Avatar : ""
                property string bestName_: BestName
                property string deviceId_: Device
                property bool isContact_: IsContact
                property bool isHandRaised_: HandRaised
                property bool isLocal_: IsLocal
                property bool isModerator_: IsModerator
                property bool isRecording_: IsRecording
                property bool isSharing_: IsSharing
                property int leftMargin_: 0
                property string sinkId_: SinkId ? SinkId : ""
                property string uri_: Uri
                property bool videoMuted_: VideoMuted
                property bool voiceActive_: VoiceActivity

                active: root.visible
                asynchronous: true
                height: Math.ceil(activeParticipantsFlow.height / activeParticipantsFlow.rows) - activeParticipantsFlow.rowsSpacing
                sourceComponent: callVideoMedia
                visible: status == Loader.Ready
                width: Math.ceil(activeParticipantsFlow.width / activeParticipantsFlow.columns) - activeParticipantsFlow.columnsSpacing
            }
        }
    }
    Rectangle {
        id: genericParticipantsRect
        property int currentPos: 0
        property int lowLimit: 0
        property int showable: {
            if (!inLine)
                return commonParticipants.count;
            if (commonParticipantsFlow.componentHeight === 0)
                return 1;
            var placeableElements = Math.floor((height * 0.9) / commonParticipantsFlow.componentHeight);
            if (commonParticipants.count - placeableElements < currentPos)
                currentPos = Math.max(commonParticipants.count - placeableElements, 0);
            return Math.max(1, placeableElements);
        }
        property int topLimit: commonParticipants.count

        SplitView.maximumWidth: inLine ? parent.width / 2 : parent.width
        SplitView.minimumWidth: parent.width / 6
        SplitView.preferredWidth: (parent.width / 4)
        color: "transparent"
        visible: commonParticipants.count > 0 && (inLine || CallParticipantsModel.conferenceLayout === CallParticipantsModel.GRID)

        TapHandler {
            acceptedButtons: Qt.TopButton | Qt.BottomButton
        }
        ColumnLayout {
            anchors.fill: parent
            width: parent.width

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                Layout.bottomMargin: 16
                Layout.topMargin: 16
                height: 30
                spacing: 8
                visible: (genericParticipantsRect.currentPos > 0 && activeParticipantsFlow.visible) || (genericParticipantsRect.topLimit - genericParticipantsRect.showable > genericParticipantsRect.currentPos && activeParticipantsFlow.visible)
                width: parent.width

                RoundButton {
                    height: 30
                    radius: 10
                    text: "^"
                    visible: genericParticipantsRect.currentPos > 0 && activeParticipantsFlow.visible
                    width: 30

                    onClicked: {
                        if (genericParticipantsRect.currentPos > 0)
                            genericParticipantsRect.currentPos--;
                    }

                    background: Rectangle {
                        anchors.fill: parent
                        color: JamiTheme.lightGrey_
                        radius: JamiTheme.primaryRadius
                    }
                }
                RoundButton {
                    height: 30
                    radius: 10
                    text: "v"
                    visible: genericParticipantsRect.topLimit - genericParticipantsRect.showable > genericParticipantsRect.currentPos && activeParticipantsFlow.visible
                    width: 30

                    onClicked: {
                        if (genericParticipantsRect.topLimit - genericParticipantsRect.showable > genericParticipantsRect.currentPos)
                            genericParticipantsRect.currentPos++;
                    }

                    background: Rectangle {
                        anchors.fill: parent
                        color: JamiTheme.lightGrey_
                        radius: JamiTheme.primaryRadius
                    }
                }
            }
            Item {
                id: centerItem
                Layout.fillHeight: true
                Layout.fillWidth: true
                Layout.margins: 4

                // GENERIC
                Flow {
                    id: commonParticipantsFlow
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
                    property int componentHeight: {
                        var totalSpacing = commonParticipantsFlow.spacing * commonParticipantsFlow.rows;
                        var h = Math.floor((commonParticipantsFlow.height - totalSpacing) / commonParticipantsFlow.rows);
                        if (inLine) {
                            h = Math.max(width, h);
                            h = Math.min(width, h * 4 / 3); // Avoid too high elements
                        }
                        return h;
                    }
                    property int componentWidth: {
                        var totalSpacing = commonParticipantsFlow.spacing * commonParticipantsFlow.columns;
                        var w = Math.floor((commonParticipantsFlow.width - totalSpacing) / commonParticipantsFlow.columns);
                        if (inLine) {
                            w = commonParticipantsFlow.width;
                        }
                        return w;
                    }
                    property int rows: {
                        if (inLine)
                            return commonParticipants.count;
                        Math.max(1, Math.ceil(commonParticipants.count / columns));
                    }

                    anchors.fill: parent
                    spacing: 4

                    Item {
                        height: {
                            if (!inLine)
                                return 0;
                            var showed = Math.min(genericParticipantsRect.showable, commonParticipantsFlow.rows);
                            return Math.max(0, Math.ceil((centerItem.height - commonParticipantsFlow.componentHeight * showed) / 2));
                        }
                        width: parent.width
                    }
                    Repeater {
                        id: commonParticipants
                        model: genericParticipantsModel

                        delegate: Loader {
                            property bool active_: Active
                            property bool audioLocalMuted_: AudioLocalMuted
                            property bool audioModeratorMuted_: AudioModeratorMuted
                            property string avatar_: Avatar ? Avatar : ""
                            property string bestName_: BestName
                            property string deviceId_: Device
                            property bool isContact_: IsContact
                            property bool isHandRaised_: HandRaised
                            property bool isLocal_: IsLocal
                            property bool isModerator_: IsModerator
                            property bool isRecording_: IsRecording
                            property bool isSharing_: IsSharing
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
                            property string sinkId_: SinkId ? SinkId : ""
                            property string uri_: Uri
                            property bool videoMuted_: VideoMuted
                            property bool voiceActive_: VoiceActivity

                            active: root.visible
                            asynchronous: true
                            height: {
                                if (inLine || commonParticipantsFlow.columns === 1)
                                    return commonParticipantsFlow.componentHeight;
                                var totalSpacing = commonParticipantsFlow.spacing * commonParticipantsFlow.rows;
                                return Math.floor((genericParticipantsRect.height - totalSpacing) / commonParticipantsFlow.rows);
                            }
                            sourceComponent: callVideoMedia
                            visible: {
                                if (status !== Loader.Ready)
                                    return false;
                                if (inLine)
                                    return index >= genericParticipantsRect.currentPos && index < genericParticipantsRect.currentPos + genericParticipantsRect.showable;
                                return true;
                            }
                            width: commonParticipantsFlow.componentWidth + leftMargin_
                        }
                    }
                }
            }
            Item {
                Layout.alignment: Qt.AlignHCenter
                height: 30
                width: parent.width
            }
        }
    }

    handle: Rectangle {
        color: "transparent"
        implicitHeight: root.height
        implicitWidth: 11

        Rectangle {
            anchors.centerIn: parent
            color: JamiTheme.darkGreyColor
            height: parent.implicitHeight - 40
            width: 1
        }
        Rectangle {
            anchors.centerIn: parent
            color: "black"
            height: 45
            width: 1
        }
        RowLayout {
            anchors.centerIn: parent
            height: 45
            width: 11

            Rectangle {
                Layout.bottomMargin: 10
                Layout.fillHeight: true
                Layout.topMargin: 10
                color: JamiTheme.darkGreyColor
                width: 2
            }
            Rectangle {
                Layout.bottomMargin: 10
                Layout.fillHeight: true
                Layout.topMargin: 10
                color: JamiTheme.darkGreyColor
                width: 2
            }
        }
    }
}
