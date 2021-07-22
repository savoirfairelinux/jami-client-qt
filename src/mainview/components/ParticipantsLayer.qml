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

import QtQuick 2.14
import QtQml 2.14
import QtQuick.Layouts 1.14
import QtQuick.Controls 2.15

import net.jami.Adapters 1.0
import net.jami.Models 1.0

Item {
    id: root

    property int count: commonParticipants.count + activeParticipants.count

    Connections {
        target: CallParticipantsModel

        function onLayoutChanged() {
            ActiveParticipantsFilterModel.reset()
            GenericParticipantsFilterModel.reset()
        }
    }

    Component {
       id: callVideoMedia

       ParticipantOverlay {
           anchors.fill: parent
           anchors.centerIn: parent

           sinkId: sinkId_

            Component.onCompleted: {
                setMenu(uri_, bestName_, isLocal_, active_, true)
                setAvatar(videoMuted_, uri_, isLocal_)
            }
       }
    }

    SplitView {
        anchors.fill: parent

        orientation: Qt.Vertical
        handle: Rectangle {
            implicitWidth: root.width
            implicitHeight: 10
            color: "transparent"
            Rectangle {
                anchors.centerIn: parent
                height: 1
                width: parent.implicitWidth - 40
                color: "yellow"
            }

            ColumnLayout {
                anchors.centerIn: parent
                height: 10
                width: 45
                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: "yellow"
                }
                Rectangle {
                    Layout.topMargin: 5
                    Layout.fillWidth: true
                    height: 1
                    color: "yellow"
                }
            }
        }

        // GENERIC
        Flow {
            id: commonParticipantsFlow

            SplitView.preferredHeight: (parent.height / 6)
            SplitView.minimumHeight: (parent.height / 6)

            spacing: 8
            property int columns: CallParticipantsModel.conferenceLayout === CallParticipantsModel.ONE_WITH_SMALL ? commonParticipants.count : Math.max(1, Math.ceil(Math.sqrt(commonParticipants.count)))
            property int rows: Math.max(1, Math.ceil(commonParticipants.count/columns))
            property int columnsSpacing: 5 * (columns - 1)
            property int rowsSpacing: 5 * (rows - 1)

            visible: CallParticipantsModel.conferenceLayout === CallParticipantsModel.ONE_WITH_SMALL || CallParticipantsModel.conferenceLayout === CallParticipantsModel.GRID
            Repeater {
                id: commonParticipants
                anchors.fill: parent
                anchors.centerIn: parent

                model: GenericParticipantsFilterModel
                delegate: Loader {
                    sourceComponent: callVideoMedia
                    width: Math.ceil(commonParticipantsFlow.width / commonParticipantsFlow.columns) - commonParticipantsFlow.columnsSpacing
                    height: Math.ceil(commonParticipantsFlow.height / commonParticipantsFlow.rows) - commonParticipantsFlow.rowsSpacing
                    
                    property string uri_: Uri
                    property string bestName_: BestName
                    property string avatar_: Avatar ? Avatar : ""
                    property string sinkId_: SinkId ? SinkId : ""
                    property bool isLocal_: IsLocal
                    property bool active_: Active
                    property bool videoMuted_: VideoMuted
                    property bool isContact_: IsContact
                }
            }
        }

        // ACTIVE
        Flow {
            id: activeParticipantsFlow

            SplitView.minimumHeight: (parent.height / 4)
            SplitView.fillHeight: true

            spacing: 8
            property int columns: Math.max(1, Math.ceil(Math.sqrt(activeParticipants.count)))
            property int rows: Math.max(1, Math.ceil(activeParticipants.count/columns))
            property int columnsSpacing: 5 * (columns - 1)
            property int rowsSpacing: 5 * (rows - 1)

            visible: CallParticipantsModel.conferenceLayout === CallParticipantsModel.ONE_WITH_SMALL || CallParticipantsModel.conferenceLayout === CallParticipantsModel.ONE

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
                }
            }
        }
    }
}
