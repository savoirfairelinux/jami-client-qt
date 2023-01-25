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

Item {
    id: root
    anchors.right: isOutgoing ? parent.right : undefined

    visible: ReplyTo !== ""
    width: visible ? replyToRow.width : 0
    height: replyToRow.height + replyToRow.anchors.topMargin

    Component.onCompleted: {
        // Make sure we show the original post
        // In the future, we may just want to load the previous interaction of the thread
        // and not show it, but for now we can simplify.
        if (ReplyTo !== "")
            MessagesAdapter.loadConversationUntil(ReplyTo)
    }

    MouseArea {

        z: 2
        anchors.fill: parent
        RowLayout {
            id: replyToRow
            anchors.top: parent.top
            anchors.topMargin: JamiTheme.preferredMarginSize / 2

            property bool isSelf: ReplyToAuthor === CurrentAccount.uri || ReplyToAuthor === ""

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

                TextMetrics {
                    id: metrics
                    elide: Text.ElideRight
                    elideWidth: JamiTheme.preferredFieldWidth - JamiTheme.preferredMarginSize
                    text: ReplyToBody
                }

                textFormat: Text.MarkdownText
                text: metrics.elidedText

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
}
