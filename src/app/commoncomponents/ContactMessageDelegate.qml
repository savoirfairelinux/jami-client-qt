/*
 * Copyright (C) 2022-2024 Savoir-faire Linux Inc.
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
    property bool showDay: false
    property int timestamp: Timestamp
    property string formattedTime: MessagesAdapter.getFormattedTime(Timestamp)
    property string formattedDay: MessagesAdapter.getFormattedDay(Timestamp)
    property int seq: MsgSeq.single
    property alias messageToSend: textLabel.text

    width: ListView.view ? ListView.view.width : 0
    height: timestampItem.height + textLabel.height
    spacing: 0

    Item {
        anchors.horizontalCenter: parent.horizontalCenter
        height: timestampItem.height + textLabel.height

        TimestampInfo {
            id: timestampItem

            showDay: root.showDay
            showTime: root.showTime
            formattedTime: root.formattedTime
            formattedDay: root.formattedDay

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top

        }

        Label {
            id: textLabel

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: timestampItem.bottom

            text: Body
            horizontalAlignment: Qt.AlignHCenter
            font.pointSize: JamiTheme.smallFontSize
            color: JamiTheme.chatviewSecondaryInformationColor
            textFormat: TextEdit.PlainText
        }
    }
    opacity: 0
    Behavior on opacity  {
        NumberAnimation {
            duration: 100
        }
    }
    Component.onCompleted: opacity = 1
}
