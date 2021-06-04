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

import QtQuick 2.14
import QtQml 2.14
import QtQuick.Layouts 1.14

import net.jami.Adapters 1.0
import net.jami.Models 1.0

Item {
    id: root

    Connections {
        target: CallParticipantsModel

        function onUpdateParticipants() {
            participantincall.model = CallParticipantsModel
            participantsFLow.columns = Math.ceil(Math.sqrt(participantincall.count))
            participantsFLow.rows = Math.ceil(participantincall.count/participantsFLow.columns)
        }
    }


    Flow {
        id: participantsFLow
        anchors.fill: parent
        anchors.centerIn: parent
        spacing: 8
        property int columns: Math.ceil(Math.sqrt(participantincall.count))
        property int rows: Math.ceil(participantincall.count/columns)
        property int columnsSpacing: columns > 1 ? 5 : 0
        property int rowsSpacing: rows > 1 ? 5 : 0

        Repeater {
            id: participantincall

            model: CallParticipantsModel
            ParticipantOverlay {
                id: peeeeeeeeeerDel

                width: Math.ceil(participantsFLow.width / participantsFLow.columns) - participantsFLow.columnsSpacing
                height: Math.ceil(participantsFLow.height / participantsFLow.rows) - participantsFLow.rowsSpacing
                visible: !isAudioOnly
                sinkId: SinkId

                callId: callId
                Component.onCompleted: {
                    setMenu(Uri, BestName, IsLocal, Active, true)
                    if (VideoMuted)
                        setAvatar(true, Avatar, Uri, IsLocal, IsContact)
                    else
                        setAvatar(false)
                }
            }
        }
    }
}
