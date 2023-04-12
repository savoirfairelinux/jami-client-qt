/*
 * Copyright (C) 2022-2023 Savoir-faire Linux Inc.
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
    property string formattedDay: MessagesAdapter.getFormattedDay(Timestamp)
    property string formattedTime: MessagesAdapter.getFormattedTime(Timestamp)
    property alias messageToSend: textLabel.text
    property int seq: MsgSeq.single//a changer par textlabel
    property bool showDay: false
    property bool showTime: false
    property int timestamp: Timestamp

    bottomPadding: 12
    opacity: 0
    spacing: 2
    topPadding: 12
    width: ListView.view ? ListView.view.width : 0

    Component.onCompleted: opacity = 1

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width

        TimestampInfo {
            id: timestampItem
            Layout.alignment: Qt.AlignHCenter
            formattedDay: root.formattedDay
            formattedTime: root.formattedTime
            showDay: root.showDay
            showTime: root.showTime
        }
        Rectangle {
            id: msg
            Layout.alignment: Qt.AlignCenter
            border.color: CurrentConversation.isCoreDialog ? JamiTheme.messageInBgColor : CurrentConversation.color
            border.width: 1
            color: "transparent"
            height: JamiTheme.contactMessageAvatarSize + 12
            radius: JamiTheme.contactMessageAvatarSize / 2 + 6
            width: childrenRect.width

            RowLayout {
                anchors.verticalCenter: parent.verticalCenter

                Avatar {
                    Layout.leftMargin: 6
                    height: JamiTheme.contactMessageAvatarSize
                    imageId: ActionUri !== CurrentAccount.uri ? ActionUri : CurrentAccount.id
                    mode: ActionUri !== CurrentAccount.uri ? Avatar.Mode.Contact : Avatar.Mode.Account
                    showPresenceIndicator: false
                    visible: ActionUri !== ""
                    width: JamiTheme.contactMessageAvatarSize
                }
                Label {
                    id: textLabel
                    Layout.rightMargin: 6
                    color: JamiTheme.chatviewTextColor
                    font.bold: true
                    font.pointSize: JamiTheme.contactEventPointSize
                    horizontalAlignment: Qt.AlignHCenter
                    text: Body
                    textFormat: TextEdit.PlainText
                    width: parent.width
                }
            }
        }
    }

    Behavior on opacity  {
        NumberAnimation {
            duration: 100
        }
    }
}
