/*
 * Copyright (C) 2020-2022 Savoir-faire Linux Inc.
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

import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15

import net.jami.Adapters 1.1
import net.jami.Models 1.1
import net.jami.Constants 1.1

Item {
    id: root

    property int count: commonParticipants.count + activeParticipants.count
    property bool inLine: CallParticipantsModel.conferenceLayout === CallParticipantsModel.ONE_WITH_SMALL

    Component {
        id: callVideoMedia

        ParticipantOverlay {
            anchors.fill: parent
            anchors.leftMargin: leftMargin_

            sinkId: sinkId_
            uri: uri_
            deviceId: deviceId_
            isMe: isLocal_
            participantIsModerator: isModerator_
            bestName: bestName_
            videoMuted: videoMuted_
            participantIsActive: active_
            isLocalMuted: audioLocalMuted_
            participantIsModeratorMuted: audioModeratorMuted_
            participantHandIsRaised: isHandRaised_
        }
    }

    SplitView {
        anchors.fill: parent

        orientation: Qt.Vertical
        handle: Rectangle {
            implicitWidth: root.width
            implicitHeight: 11
            color: "transparent"
            Rectangle {
                anchors.centerIn: parent
                height: 1
                width: parent.implicitWidth - 40
                color: JamiTheme.darkGreyColor
            }

            Rectangle {
                width: 45
                anchors.centerIn: parent
                height: 1
                color: "black"
            }

            ColumnLayout {
                anchors.centerIn: parent
                height: 11
                width: 45
                Rectangle {
                    Layout.fillWidth: true
                    Layout.leftMargin: 10
                    Layout.rightMargin: 10
                    height: 2
                    color: JamiTheme.darkGreyColor
                }
                Rectangle {
                    Layout.fillWidth: true
                    Layout.leftMargin: 10
                    Layout.rightMargin: 10
                    height: 2
                    color: JamiTheme.darkGreyColor
                }
            }
        }

        Rectangle {
            id: genericParticipantsRect

            TapHandler { acceptedButtons: Qt.LeftButton | Qt.RightButton }

            SplitView.preferredHeight: (parent.height / 4)
            SplitView.minimumHeight: parent.height / 6
            SplitView.maximumHeight: inLine? parent.height / 2 : parent.height

            visible: inLine || CallParticipantsModel.conferenceLayout === CallParticipantsModel.GRID
            color: "transparent"

            property int lowLimit: 0
            property int topLimit: commonParticipants.count
            property int currentPos: 0
            property int showable: {
                if (!inLine)
                    return commonParticipants.count
                if (commonParticipantsFlow.componentWidth === 0)
                    return 1
                var placeableElements = Math.floor((width * 0.9)/commonParticipantsFlow.componentWidth)
                if (commonParticipants.count - placeableElements < currentPos)
                    currentPos = Math.max(commonParticipants.count - placeableElements, 0)
                return Math.max(1, placeableElements)
            }

            RowLayout {
                anchors.fill: parent

                RoundButton {
                    Layout.alignment: Qt.AlignVCenter
                    width : 30
                    height : 30
                    radius: 10
                    text: "<"
                    visible: genericParticipantsRect.currentPos > 0
                    onClicked: {
                        if (genericParticipantsRect.currentPos > 0)
                            genericParticipantsRect.currentPos--
                    }
                    background: Rectangle {
                        anchors.fill: parent
                        color: JamiTheme.lightGrey_
                        radius: JamiTheme.primaryRadius
                    }
                }

                Item {
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    Layout.margins: 4

                    // GENERIC
                    Flow {
                        id: commonParticipantsFlow
                        anchors.fill: parent

                        anchors.leftMargin: {
                            if (!inLine)
                                return 0
                            var showed = Math.min(genericParticipantsRect.showable, columns)
                            return Math.max(0, Math.ceil((parent.width - componentWidth * showed) / 2))
                        }

                        spacing: 4
                        property int columns: {
                            if (inLine)
                                return commonParticipants.count
                            var ratio = Math.floor(root.width / root.height)
                            // If ratio is 2 we can have 2 times more elements on each columns
                            var wantedCol = Math.max(1, Math.round(Math.sqrt(commonParticipants.count) * ratio))
                            var cols =  Math.min(commonParticipants.count, wantedCol)
                            // Optimize with the rows (eg 7 with ratio 2 should have 4 and 3 items, not 6 and 1)
                            var rows = Math.max(1, Math.ceil(commonParticipants.count/cols))
                            return Math.min(Math.ceil(commonParticipants.count / rows), cols)
                        }
                        property int rows: Math.max(1, Math.ceil(commonParticipants.count/columns))
                        property int componentWidth: {
                            var totalSpacing = commonParticipantsFlow.spacing * commonParticipantsFlow.columns
                            var w = Math.floor((commonParticipantsFlow.width - totalSpacing)/ commonParticipantsFlow.columns)
                            if (inLine)
                                w = Math.max(w, height)
                            return w
                        }

                        Repeater {
                            id: commonParticipants

                            model: GenericParticipantsFilterModel
                            delegate: Loader {
                                sourceComponent: callVideoMedia
                                active: root.visible
                                asynchronous: true
                                visible: {
                                    if (status !== Loader.Ready)
                                        return false
                                    if (inLine)
                                        return index >= genericParticipantsRect.currentPos
                                                && index < genericParticipantsRect.currentPos + genericParticipantsRect.showable
                                    return true
                                }
                                width: commonParticipantsFlow.componentWidth + leftMargin_
                                height: {
                                    if (inLine || commonParticipantsFlow.rows === 1)
                                        return genericParticipantsRect.height
                                    var totalSpacing = commonParticipantsFlow.spacing * commonParticipantsFlow.rows
                                    return Math.floor((genericParticipantsRect.height - totalSpacing)/ commonParticipantsFlow.rows)
                                }

                                property int leftMargin_: {
                                    if (inLine || commonParticipantsFlow.rows === 1)
                                        return 0
                                    var lastParticipants = (commonParticipants.count % commonParticipantsFlow.columns)
                                    if (lastParticipants !== 0 && index === commonParticipants.count - lastParticipants) {
                                        var compW = commonParticipantsFlow.componentWidth + commonParticipantsFlow.spacing
                                        var lastLineW = lastParticipants * compW
                                        return Math.floor((commonParticipantsFlow.width - lastLineW) / 2)
                                    }
                                    return 0
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
                            }
                        }
                    }
                }

                RoundButton {
                    Layout.alignment: Qt.AlignVCenter
                    width : 30
                    height : 30
                    radius: 10
                    text: ">"
                    visible: genericParticipantsRect.topLimit - genericParticipantsRect.showable > genericParticipantsRect.currentPos
                    onClicked: {
                        if (genericParticipantsRect.topLimit - genericParticipantsRect.showable > genericParticipantsRect.currentPos)
                            genericParticipantsRect.currentPos++
                    }
                    background: Rectangle {
                        anchors.fill: parent
                        color: JamiTheme.lightGrey_
                        radius: JamiTheme.primaryRadius
                    }
                }
            }
        }

        // ACTIVE
        Flow {
            id: activeParticipantsFlow

            TapHandler { acceptedButtons: Qt.LeftButton | Qt.RightButton }

            SplitView.minimumHeight: parent.height / 4
            SplitView.maximumHeight: parent.height
            SplitView.fillHeight: true

            spacing: 8
            property int columns: Math.max(1, Math.ceil(Math.sqrt(activeParticipants.count)))
            property int rows: Math.max(1, Math.ceil(activeParticipants.count/columns))
            property int columnsSpacing: 5 * (columns - 1)
            property int rowsSpacing: 5 * (rows - 1)

            visible: inLine || CallParticipantsModel.conferenceLayout === CallParticipantsModel.ONE

            Repeater {
                id: activeParticipants
                anchors.fill: parent
                anchors.centerIn: parent

                model: ActiveParticipantsFilterModel
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
                    property bool isLocal_: IsLocal
                    property bool active_: Active
                    property bool videoMuted_: VideoMuted
                    property bool isContact_: IsContact
                    property bool isModerator_: IsModerator
                    property bool audioLocalMuted_: AudioLocalMuted
                    property bool audioModeratorMuted_: AudioModeratorMuted
                    property bool isHandRaised_: HandRaised
                }
            }
        }
    }
}
