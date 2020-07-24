
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
import QtQuick.Controls 2.14
import QtQuick.Layouts 1.14
import QtQuick.Controls.Universal 2.12
import QtGraphicalEffects 1.14
import net.jami.Models 1.0

import "../../commoncomponents"

Rectangle {
    id: hoverParticipant
    border.color: "red"
    border.width: 1
    color: "transparent"

    function setPartipantName(name) {
        participantName.text = name
    }

    Row {
        id: bottomLabel

        anchors.centerIn: parent
        anchors.bottom: parent

        Rectangle {
            color: Qt.rgba(0, 7, 71, 0.5)

            Text {
                id: participantName

                text: "Participant"
                font.pointSize: JamiTheme.textFontSize
                horizontalAlignment: Text.AlignCenter
                verticalAlignment: Text.AlignVCenter
            }
        }
    }
}