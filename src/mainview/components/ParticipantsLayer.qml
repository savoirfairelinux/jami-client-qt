/*
 * Copyright (C) 2020-2021 by Savoir-faire Linux
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

import QtQuick 2.15
import QtQml 2.15

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
            anchors.centerIn: parent

            sinkId: sinkId_
            uri: uri_
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

            SplitView.preferredHeight: (parent.height / 5)
            SplitView.minimumHeight: parent.height / 10
            SplitView.maximumHeight: inLine? parent.height / 3 : parent.height

            visible: inLine || CallParticipantsModel.conferenceLayout === CallParticipantsModel.GRID
            color: "transparent"

            property int lowLimit: 0
            property int topLimit: commonParticipants.count
            property int currentPos: 0
            property int showable: {
                var placeableElements = inLine ? Math.floor((width * 0.95)/commonParticipantsFlow.componentWidth) : commonParticipants.count
                if (commonParticipants.count - placeableElements < currentPos)
                    currentPos = Math.max(commonParticipants.count - placeableElements, 0)
                return placeableElements
            }

            RowLayout {
                anchors.fill: parent
                anchors.centerIn: parent
                z: 1

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
                }
                Item {
                    Layout.fillHeight: true
                    Layout.fillWidth: true
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
                }
            }

            Rectangle {
                z:0
                anchors.centerIn: parent
                property int elements: inLine ? Math.min(genericParticipantsRect.showable, commonParticipants.count) : commonParticipantsFlow.columns
                width: commonParticipantsFlow.componentWidth * elements + elements - 1
                implicitHeight: parent.height + commonParticipantsFlow.rows - 1
                color: "transparent"

                // GENERIC
                Flow {
                    id: commonParticipantsFlow
                    anchors.centerIn: parent
                    anchors.fill: parent

                    spacing: 1
                    property int columns: inLine ? commonParticipants.count : Math.max(1, Math.ceil(Math.sqrt(commonParticipants.count)))
                    property int rows: Math.max(1, Math.ceil(commonParticipants.count/columns))
                    property int componentWidth: inLine ? height : Math.floor(genericParticipantsRect.width / commonParticipantsFlow.columns) - 1

                    Repeater {
                        id: commonParticipants

                        model: GenericParticipantsFilterModel
                        delegate: Loader {
                            sourceComponent: callVideoMedia
                            visible: inLine ? index >= genericParticipantsRect.currentPos && index < genericParticipantsRect.currentPos + genericParticipantsRect.showable : true
                            width: {
                                var lastLine = commonParticipants.count % commonParticipantsFlow.columns
                                var horComponents = ((commonParticipants.count - index) > lastLine || index < 0) ? commonParticipantsFlow.columns : lastLine
                                if (horComponents === lastLine)
                                    return Math.floor(commonParticipantsFlow.width / horComponents) - 1
                                else
                                    return commonParticipantsFlow.componentWidth
                            }
                            height: inLine ? commonParticipantsFlow.componentWidth : Math.floor(genericParticipantsRect.height / commonParticipantsFlow.rows) - 1

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

        // ACTIVE
        Flow {
            id: activeParticipantsFlow

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
                    sourceComponent: callVideoMedia
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
