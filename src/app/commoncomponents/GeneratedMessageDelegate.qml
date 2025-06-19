/*
 * Copyright (C) 2021-2025 Savoir-faire Linux Inc.
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

    property bool showTime: false
    property bool showDay: false
    property int seq: MsgSeq.single
    property alias font: textLabel.font
    property int timestamp: Timestamp
    property string formattedTime: MessagesAdapter.getFormattedTime(Timestamp)
    property string formattedDay: MessagesAdapter.getFormattedDay(Timestamp)
    width: ListView.view ? ListView.view.width : 0
    spacing: 2
    topPadding: 12
    bottomPadding: 12

    Accessible.name: {
        let name = UtilsAdapter.getBestNameForUri(CurrentAccount.id, Author);
        return name + ": " + Body + " " + formattedTime + " " + formattedDay;
    }
    Accessible.description: {
        let status = "";
        if (IsLastSent)
            status += JamiStrings.sent + " ";
        return status;
    }

    Rectangle {
        id: focusIndicator
        visible: root.activeFocus
        border.color: JamiTheme.tintedBlue
        border.width: 2
        color: "transparent"
        // Only anchor after parent item is ready
        anchors {
            fill: parent
            margins: -2 // Offset to show border outside the bubble
        }
        z: -2 // Keep behind message content
    }

    ColumnLayout {

        width: parent.width
        spacing: 0

        TimestampInfo {
            id: timestampItem

            showDay: root.showDay
            showTime: root.showTime
            formattedTime: root.formattedTime
            formattedDay: root.formattedDay
            Layout.alignment: Qt.AlignHCenter
        }

        Label {
            id: textLabel

            text: Body
            Layout.alignment: Qt.AlignHCenter
            font.pointSize: 12
            color: JamiTheme.chatviewTextColor
        }
    }

    opacity: 0
    Behavior on opacity {
        NumberAnimation {
            duration: 100
        }
    }
    Component.onCompleted: opacity = 1
}
