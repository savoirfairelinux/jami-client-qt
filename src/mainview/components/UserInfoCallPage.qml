/*
 * Copyright (C) 2020 by Savoir-faire Linux
 * Author: Albert Babí <albert.babi@savoirfairelinux.com>
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
import QtQuick.Controls.Universal 2.14

import net.jami.Models 1.0
import net.jami.Adapters 1.0
import net.jami.Constants 1.0

import "../../commoncomponents"

// Common element for IncomingCallPage and OutgoingCallPage
Rectangle {
    id: userInfoCallRect

    property int buttonPreferredSize: 48
    property bool isIncoming: false
    property string bestName: "Best Name"

    function updateUI(accountId, convUid, incomingCall) {
        userInfoCallRect.bestName = UtilsAdapter.getBestName(accountId, convUid)
        userInfoCallRect.isIncoming = incomingCall
    }

    color: "transparent"

    ColumnLayout {
        id: userInfoCallColumnLayout

        anchors.fill: parent

        AvatarImage {
            id: contactImg

            Layout.alignment: Qt.AlignCenter
            Layout.topMargin: 60

            Layout.preferredWidth: 100
            Layout.preferredHeight: 100

            mode: AvatarImage.Mode.FromConvUid
            showPresenceIndicator: false
        }

        Rectangle {
            id: userInfoCallPageTextRect

            Layout.alignment: Qt.AlignCenter
            Layout.topMargin: 8

            Layout.preferredWidth: userInfoCallRect.width
            Layout.preferredHeight: jamiBestNameText.height + jamiComplementarText.height + 50

            color: "transparent"

            
        }
    }
}
