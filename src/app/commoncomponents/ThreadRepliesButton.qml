/*
 * Copyright (C) 2026 Savoir-faire Linux Inc.
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
import QtQuick.Controls.impl
import QtQuick.Layouts
import net.jami.Adapters 1.1
import net.jami.Constants 1.1

// Opens a thread root's thread in the thread panel.
AbstractButton {
    id: root
    objectName: "threadRepliesButton"

    property string rootId
    property int replyCount: 0
    property bool inThread: false
    property color borderColor: JamiTheme.chatviewBgColor

    visible: MessagesAdapter.threadedView && replyCount > 0 && !inThread
    text: replyCount === 1 ? JamiStrings.oneReply : JamiStrings.replies.arg(replyCount)
    padding: 5
    hoverEnabled: true

    contentItem: RowLayout {
        spacing: 4
        opacity: root.hovered || root.activeFocus ? 1.0 : 0.8

        Behavior on opacity {
            NumberAnimation {
                duration: JamiTheme.shortFadeDuration
            }
        }

        IconImage {
            objectName: "threadRepliesIcon"
            Layout.preferredWidth: JamiTheme.iconButtonSmall
            Layout.preferredHeight: JamiTheme.iconButtonSmall
            source: JamiResources.bidirectional_reply_black_24dp_svg
            sourceSize.width: JamiTheme.iconButtonSmall
            sourceSize.height: JamiTheme.iconButtonSmall
            color: JamiTheme.chatviewTextColor
        }

        Text {
            objectName: "threadRepliesText"
            Layout.alignment: Qt.AlignVCenter
            text: root.text
            color: JamiTheme.chatviewTextColor
            font.pixelSize: JamiTheme.timestampFont
            font.underline: root.activeFocus
        }
    }

    background: Rectangle {
        objectName: "threadRepliesBackground"
        color: JamiTheme.emojiReactBubbleBgColor
        radius: 5
        border.color: root.borderColor
        border.width: 1
    }

    onClicked: MessagesAdapter.threadMessageListModel.threadId = rootId

    Accessible.role: Accessible.Button
    Accessible.name: text
    Accessible.description: JamiStrings.openThread

    HoverHandler {
        cursorShape: Qt.PointingHandCursor
    }
}
