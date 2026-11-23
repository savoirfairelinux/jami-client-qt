/*
 * Copyright (C) 2021-2026 Savoir-faire Linux Inc.
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
import Qt5Compat.GraphicalEffects
import net.jami.Constants 1.1

Rectangle {
    id: root
    property bool out: true
    property int type: MsgSeq.single
    property bool isReply: false
    property color replyBorderColor: JamiTheme.chatviewBgColor
    property alias mask: mask
    // Corner radius of the sides adjacent to other messages in the same group
    property real groupedRadius: 8

    Rectangle {
        id: maskReplyBorder
        anchors.fill: parent
        anchors.margins: -1
        radius: root.radius + 1
        color: "transparent"
        border.color: root.replyBorderColor
        border.width: isReply ? 2 : 0
    }

    Rectangle {
        id: mask

        visible: type !== MsgSeq.single && !isReply
        z: -1
        radius: root.groupedRadius
        color: root.color
        anchors {
            fill: parent
            leftMargin: out ? root.width / 2 : 0
            rightMargin: out ? 0 : root.width / 2
            topMargin: type === MsgSeq.first ? root.height / 2 : 0
            bottomMargin: type === MsgSeq.last ? root.height / 2 : 0
        }
    }
}
