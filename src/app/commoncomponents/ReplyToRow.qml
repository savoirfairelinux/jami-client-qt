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

import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1


Item {
    id: root

    width: body.width
    height: Math.min(JamiTheme.sbsMessageBaseMaximumReplyHeight, body.height)//body.height
    clip: true

    property int requestId: -1
    property var replyTransferName: MessagesAdapter.dataForInteraction(ReplyTo, MessageList.TransferName)


    Component.onCompleted: {
        // Make sure we show the original post
        // In the future, we may just want to load the previous interaction of the thread
        // and not show it, but for now we can simplify.
        if (ReplyTo !== "") {
            // Store the request Id for later filtering.
            requestId = MessagesAdapter.loadConversationUntil(ReplyTo)
        }
    }

    Connections {
        target: MessagesAdapter

        function onMoreMessagesLoaded(loadingRequestId) {
            // Filter for the request Id we're waiting for (now the message is loaded).
            if (requestId === loadingRequestId) {
                requestId = -1
                replyTransferName = MessagesAdapter.dataForInteraction(ReplyTo, MessageList.TransferName)
            }
        }
    }

    TextEdit {
        id: body
        text: {
            return replyTransferName ?
                  replyTransferName :
                  ReplyToBody === "" && ReplyToAuthor !== "" ? "*(Deleted Message)*" : ReplyToBody
        }

        width: Math.min(JamiTheme.sbsMessageBaseMaximumReplyWidth, implicitWidth)

        horizontalAlignment: Text.AlignLeft

        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
        selectByMouse: true
        font.pixelSize: IsEmojiOnly? JamiTheme.chatviewEmojiSize : JamiTheme.emojiBubbleSize
        font.hintingPreference: Font.PreferNoHinting
        renderType: Text.NativeRendering
        textFormat: Text.MarkdownText
        readOnly: true
        color: getBaseColor()

        function getBaseColor() {
            var baseColor
            if (IsEmojiOnly) {
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

    Rectangle {
        anchors.fill: parent
        visible: body.height > JamiTheme.sbsMessageBaseMaximumReplyHeight
        gradient: Gradient {
            GradientStop {position: 0.66 ; color: "transparent"}
            GradientStop {position: 1 ; color: replyBubble.color}
        }
    }
}
