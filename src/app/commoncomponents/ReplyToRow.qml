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
    property real bubbleWidth
    /*property real replyRowWidth: body.width + replyTo.width + JamiTheme.avatarReadReceiptSize +
                                 JamiTheme.preferredMarginSize + JamiTheme.preferredMarginSize + 10*/

    property real replyRowWidth: replyToBodyMetrics.width + replyTo.width + JamiTheme.avatarReadReceiptSize +
                                     JamiTheme.preferredMarginSize + JamiTheme.preferredMarginSize + 10




    id: root
    anchors.right: isOutgoing ? parent.right : undefined
    visible: ReplyTo !== ""
    width: visible ? bubbleWidth : 0
    height: replyToRow.height + replyToRow.anchors.topMargin


    /*Component.onCompleted: {
        // Make sure we show the original post
        // In the future, we may just want to load the previous interaction of the thread
        // and not show it, but for now we can simplify.
        if (ReplyTo !== "")
            MessagesAdapter.loadConversationUntil(ReplyTo)
        console.warn("replyRowWidth :" + replyRowWidth +" rowlayou width " + replyToRow.width)

    }*/

    Rectangle {
        id: ls
        z:-2
        color: "green"
        anchors.fill: parent
        visible: true
    }



    MouseArea {

        z: 2
        anchors.fill: parent


        RowLayout {
            property bool isSelf: ReplyToAuthor === CurrentAccount.uri || ReplyToAuthor === ""

            id: replyToRow
            anchors.top: parent.top
            anchors.topMargin: JamiTheme.preferredMarginSize / 2
            anchors.right: isOutgoing ? parent.right : undefined

            Component.onCompleted: {

                console.warn("replyRowWidth :" + replyRowWidth +" rowlayou width " + replyToRow.width)

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



                Rectangle {
                    id: bg
                    z:-1
                    color: "red"
                    anchors.fill: parent
                    visible: true
                }





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
                //Layout.maximumWidth: bubbleWidth -  replyTo.width - JamiTheme.avatarReadReceiptSize - 42
                Layout.rightMargin: JamiTheme.preferredMarginSize

                TextMetrics {
                    id: metrics
                    elide: Text.ElideRight
                    elideWidth: {
                        if(bubbleWidth !== JamiTheme.sbsMessageBaseMinimumReplyWidth)
                            bubbleWidth - replyTo.width - JamiTheme.avatarReadReceiptSize
                        else
                            bubbleWidth - replyTo.width - JamiTheme.avatarReadReceiptSize - 25

                    }

                    text: ReplyToBody === "" && ReplyToAuthor !== "" ? "*(Deleted Message)*" : ReplyToBody
                    font.pointSize: JamiTheme.textFontSize
                    font.kerning: true
                    font.bold: true

                }

                TextMetrics {
                    id: replyToBodyMetrics
                    text: ReplyToBody === "" && ReplyToAuthor !== "" ? "*(Deleted Message)*" : ReplyToBody
                    font.pointSize: JamiTheme.textFontSize
                    font.kerning: true
                    font.bold: true

                }

                textFormat: Text.MarkdownText
                text: metrics.elidedText
                //text: ReplyToBody === "" && ReplyToAuthor !== "" ? "*(Deleted Message)*" : ReplyToBody

                color:  UtilsAdapter.luma(bubble.color) ?
                    JamiTheme.chatviewTextColorLight :
                    JamiTheme.chatviewTextColorDark
                font.pointSize: JamiTheme.textFontSize
                font.kerning: true
                font.bold: true

                Component.onCompleted: {

                    //console.warn("elideWidth :" + metrics.elideWidth + " bubble width :" + bubbleWidth)
                    //console.warn("Width :" + body.width + " height :" + body.height + " " + ReplyToBody )


                }


            }


        }

        onClicked: function(mouse) {
            CurrentConversation.scrollToMsg(ReplyTo)
        }
    }


}
