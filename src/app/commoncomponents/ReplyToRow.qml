/*
 * Copyright (C) 2022 Savoir-faire Linux Inc.
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

MouseArea {
    id: root

    anchors.right: isOutgoing ? parent.right : undefined
    z: 2
    width: replyToRow.width
    height: replyToRow.height
    RowLayout {
        id: replyToRow

        anchors.top: parent.top
        anchors.topMargin: JamiTheme.preferredMarginSize / 2
        width: visible ? undefined : 0
        height: visible ? undefined : 0
        visible: ReplyTo !== ""
        property bool isSelf: ReplyToAuthor === CurrentAccount.uri || ReplyToAuthor === ""

        onVisibleChanged: {
            if (visible) {
                // Make sure we show the original post
                // In the future, we may just want to load the previous interaction of the thread
                // and not show it, but for now we can simplify.
                MessagesAdapter.loadConversationUntil(ReplyTo)
            }
        }

        Label {
            id: replyTo

            text: JamiStrings.inReplyTo

            color: UtilsAdapter.luma(bubble.color) ?
                JamiTheme.chatviewTextColorLight :
                JamiTheme.chatviewTextColorDark
            font.pointSize: JamiTheme.textFontSize
            font.kerning: true
            font.bold: true
            Layout.leftMargin: JamiTheme.preferredMarginSize
        }

        Avatar {
            id: avatarReply

            Layout.preferredWidth: JamiTheme.avatarReadReceiptSize
            Layout.preferredHeight: JamiTheme.avatarReadReceiptSize

            showPresenceIndicator: false

            imageId: {
                if (replyToRow.isSelf)
                    return CurrentAccount.id
                return ReplyToAuthor
            }
            mode: replyToRow.isSelf ? Avatar.Mode.Account : Avatar.Mode.Contact
        }

        Text {
            id: body
            Layout.maximumWidth: JamiTheme.preferredFieldWidth - JamiTheme.preferredMarginSize
            Layout.rightMargin: JamiTheme.preferredMarginSize

            text: ReplyToBody
            elide: Text.ElideRight

            color:  UtilsAdapter.luma(bubble.color) ?
                JamiTheme.chatviewTextColorLight :
                JamiTheme.chatviewTextColorDark
            font.pointSize: JamiTheme.textFontSize
            font.kerning: true
            font.bold: true
        }
    }
    onClicked: function(mouse) {
        CurrentConversation.scrollToMsg(ReplyTo)
    }
}