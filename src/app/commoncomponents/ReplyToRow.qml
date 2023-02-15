/*
 * Copyright (C) 2022-2023 Savoir-faire Linux Inc.
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

    visible: ReplyTo !== ""
    width: replyToRow.width
    height: replyToRow.height + JamiTheme.preferredMarginSize +8




    RowLayout {
        id: replyToRow

        property bool isSelf: ReplyToAuthor === CurrentAccount.uri || ReplyToAuthor === ""

        anchors.top: parent.top
        anchors.topMargin: JamiTheme.preferredMarginSize
        anchors.right: isOutgoing ? parent.right : undefined

        Label {
            id: replyTo

            text: JamiStrings.inReplyTo

            color: UtilsAdapter.luma(replyBubble.color) ?
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
            text: ReplyToBody === "" && ReplyToAuthor !== "" ? "*(Deleted Message)*" : ReplyToBody
            Layout.rightMargin: JamiTheme.preferredMarginSize
            elide: Text.ElideRight
            maximumLineCount: 3
            Layout.preferredWidth: Math.min(250, implicitWidth)
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            color: getBaseColor()

            function getBaseColor() {
                var baseColor
                if (isEmojiOnly) {
                    if (JamiTheme.darkTheme)
                        baseColor = JamiTheme.chatviewTextColorLight
                    else
                        baseColor = JamiTheme.chatviewTextColorDark
                } else {
                    if (UtilsAdapter.luma(replyBubble.color))
                        baseColor = JamiTheme.chatviewTextColorLight
                    else
                        baseColor = JamiTheme.chatviewTextColorDark
                }
                return baseColor
            }
        }
    }


}
