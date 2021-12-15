/*
 * Copyright (C) 2020 by Savoir-faire Linux
 * Author: Sébastien Blin <sebastien.blin@savoirfairelinux.com>
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

import QtQuick.Layouts 1.15
import net.jami.Adapters 1.1
import net.jami.Models 1.1

Item {
    id: root

    property alias count: participantincall.count

    Connections {
        target: CallAdapter

        function onUpdateParticipantsLayout() {
            participantsFlow.columns = Math.max(1, Math.ceil(Math.sqrt(participantincall.count)))
            participantsFlow.rows = Math.max(1, Math.ceil(participantincall.count/participantsFlow.columns))
        }
    }


    Component {
        id: callVideoMedia

        ParticipantOverlay {
            anchors.fill: parent
            anchors.centerIn: parent

            sinkId: sinkId_

            Component.onCompleted: {
                setMenu(uri_, bestName_, isLocal_, active_)
                setAvatar(videoMuted_, uri_, isLocal_)
                VideoDevices.startDevice(sinkId)
            }
        }
    }

    Flow {
        id: participantsFlow
        anchors.fill: parent
        anchors.centerIn: parent
        spacing: 8
        property int columns: Math.max(1, Math.ceil(Math.sqrt(participantincall.count)))
        property int rows: Math.max(1, Math.ceil(participantincall.count/columns))
        property int columnsSpacing: 5 * (columns - 1)
        property int rowsSpacing: 5 * (rows - 1)

        Repeater {
            id: participantincall
            anchors.fill: parent
            anchors.centerIn: parent

            model: CallParticipantsModel
            delegate: Loader {
                sourceComponent: callVideoMedia
                width: Math.ceil(participantsFlow.width / participantsFlow.columns) - participantsFlow.columnsSpacing
                height: Math.ceil(participantsFlow.height / participantsFlow.rows) - participantsFlow.rowsSpacing

                property string uri_: Uri
                property string bestName_: BestName
                property string avatar_: Avatar ? Avatar : ""
                property string sinkId_: SinkId ? SinkId : ""
                property bool isLocal_: IsLocal
                property bool active_: Active
                property bool videoMuted_: VideoMuted
                property bool isContact_: IsContact
                property bool isHandRaised_: HandRaised
            }
        }
    }
}
