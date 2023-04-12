/*
 * Copyright (C) 2021-2023 Savoir-faire Linux Inc.
 * Author: Trevor Tabah <trevor.tabah@savoirfairelinux.com>
 * Author: Andreas Traczyk <andreas.traczyk@savoirfairelinux.com>
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
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import net.jami.Adapters 1.1
import net.jami.Constants 1.1

Column {
    id: root
    property alias font: textLabel.font
    property string formattedDay: MessagesAdapter.getFormattedDay(Timestamp)
    property string formattedTime: MessagesAdapter.getFormattedTime(Timestamp)
    property int seq: MsgSeq.single
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
        width: parent.width

        TimestampInfo {
            id: timestampItem
            Layout.alignment: Qt.AlignHCenter
            formattedDay: root.formattedDay
            formattedTime: root.formattedTime
            showDay: root.showDay
            showTime: root.showTime
        }
        Label {
            id: textLabel
            Layout.alignment: Qt.AlignHCenter
            color: JamiTheme.chatviewTextColor
            font.pointSize: 12
            text: Body
        }
    }

    Behavior on opacity  {
        NumberAnimation {
            duration: 100
        }
    }
}
