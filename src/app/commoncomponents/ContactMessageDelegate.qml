/*
 * Copyright (C) 2022 Savoir-faire Linux Inc.
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

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1

Column {
    id: root

    property bool showTime: false
    property int seq: MsgSeq.single
    property alias font: textLabel.font

    width: ListView.view ? ListView.view.width : 0

    spacing: 2
    topPadding: 12
    bottomPadding: 12

    Rectangle {
        id: msg

        anchors.horizontalCenter: parent.horizontalCenter

        width: childrenRect.width
        height: JamiTheme.contactMessageAvatarSize + 12
        radius: JamiTheme.contactMessageAvatarSize / 2 + 6

        color: "transparent"
        border.width: 1
        border.color: CurrentConversation.isCoreDialog ? JamiTheme.messageInBgColor : CurrentConversation.color

        RowLayout {
            anchors.verticalCenter: parent.verticalCenter

            Avatar {
                Layout.leftMargin: 6

                width: JamiTheme.contactMessageAvatarSize
                height: JamiTheme.contactMessageAvatarSize
                visible: ActionUri !== ""

                imageId: ActionUri !== CurrentAccount.uri ? ActionUri : CurrentAccount.id
                showPresenceIndicator: false
                mode: ActionUri !== CurrentAccount.uri ? Avatar.Mode.Contact : Avatar.Mode.Account
            }

            Label {
                Layout.rightMargin: 6

                id: textLabel
                width: parent.width
                text: Body
                horizontalAlignment: Qt.AlignHCenter
                font.pointSize: JamiTheme.contactEventPointSize
                font.bold: true
                color: JamiTheme.chatviewTextColor
            }
        }
    }

    Item {
        id: infoCell

        width: parent.width
        height: childrenRect.height

        Label {
            text: MessagesAdapter.getFormattedTime(Timestamp)
            color: JamiTheme.timestampColor
            visible: showTime || seq === MsgSeq.last
            height: visible * implicitHeight
            font.pointSize: 9

            anchors.horizontalCenter: parent.horizontalCenter
        }
    }

    opacity: 0
    Behavior on opacity { NumberAnimation { duration: 100 } }
    Component.onCompleted: opacity = 1
}
