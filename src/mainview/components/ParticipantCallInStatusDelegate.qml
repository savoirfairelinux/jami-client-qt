/*
 * Copyright (C) 2020 by Savoir-faire Linux
 * Author: Mingrui Zhang <mingrui.zhang@savoirfairelinux.com>
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

import net.jami.Adapters 1.0
import net.jami.Models 1.0
import net.jami.Constants 1.0

import "../../commoncomponents"

Rectangle {
    id: root

    width: JamiTheme.participantCallInStatusViewWidth
    height: 100

    color: JamiTheme.darkGreyColor
    opacity: JamiTheme.participantCallInStatusOpacity
    radius: JamiTheme.participantCallInStatusDelegateRadius

    AvatarImage {
        id: avatar

        anchors.left: root.left
        anchors.leftMargin: 10
        anchors.verticalCenter: root.verticalCenter

        width: JamiTheme.participantCallInAvatarSize
        height: JamiTheme.participantCallInAvatarSize

        mode: AvatarImage.Mode.FromTemporaryName
        showPresenceIndicator: false

        imageId: "sssssss"
    }

    ColumnLayout {
        id: infoColumnLayout

        anchors.right: callCancelButton.left
        anchors.rightMargin: 5
        anchors.verticalCenter: root.verticalCenter

        implicitHeight: 50
        implicitWidth: 68

        spacing: 5

        Text {
            id: name

            Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
            Layout.preferredWidth: infoColumnLayout.implicitWidth

            font.weight: Font.ExtraBold
            font.pointSize: JamiTheme.participantCallInNameFontSize
            color: JamiTheme.participantCallInStatusTextColor
            text: qsTr("Laura")
            elide: Text.ElideRight
        }

        Text {
            id: callStatus

            Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
            Layout.preferredWidth: infoColumnLayout.implicitWidth

            font.weight: Font.Light
            font.pointSize: JamiTheme.participantCallInStatusFontSize
            color: JamiTheme.participantCallInStatusTextColor
            text: qsTr("Searching...")
            elide: Text.ElideRight
        }
    }

    PushButton {
        id: callCancelButton

        anchors.right: root.right
        anchors.rightMargin: 10
        anchors.verticalCenter: root.verticalCenter

        width: 40
        height: 40
        // To control the size of the svg
        preferredSize: 50

        pressedColor: Qt.darker(JamiTheme.participantCallInHangupButtonColor, 1.5)
        hoveredColor: Qt.lighter(JamiTheme.participantCallInHangupButtonColor, 1.5)
        normalColor: JamiTheme.participantCallInHangupButtonColor

        source: "qrc:/images/icons/Cross_Black_24dp.svg"
        imageColor: JamiTheme.whiteColor

        toolTipText: JamiStrings.optionCancel

       // onClicked: callCancelButtonIsClicked()
    }
}
