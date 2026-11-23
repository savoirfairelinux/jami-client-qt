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
import QtQuick.Layouts
import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1

// One comment under a feed post. Comments are listed flat; a reply to another comment names its author.
Control {
    id: root
    objectName: "feedComment"

    // The post the comment is listed under, and the feed list, which hosts the comment's popups.
    property string postId
    property ListView listView

    readonly property string commentId: Id
    readonly property bool isOutgoing: Author === CurrentAccount.uri
    readonly property bool isReplyToComment: ReplyTo !== "" && ReplyTo !== postId
    readonly property bool canReply: CurrentConversation.canReplyText || CurrentConversation.canReplyFile
    // Being replied to or edited in the composer.
    readonly property bool isTarget: Id === MessagesAdapter.replyToId || Id === MessagesAdapter.editId

    Accessible.role: Accessible.StaticText
    Accessible.name: UtilsAdapter.getBestNameForUri(CurrentAccount.id, Author) + ": " + Body + " " + MessagesAdapter.getBestFormattedDate(Timestamp)

    HoverHandler {
        id: hover
    }

    padding: 6

    background: Rectangle {

        radius: 12
        color: root.isTarget ? Qt.rgba(JamiTheme.tintedBlue.r, JamiTheme.tintedBlue.g, JamiTheme.tintedBlue.b, 0.15) : "transparent"

        Behavior on color {
            ColorAnimation {
                duration: JamiTheme.shortFadeDuration
            }
        }
    }

    contentItem: RowLayout {
        spacing: 8

        Avatar {
            Layout.alignment: Qt.AlignTop
            Layout.preferredWidth: JamiTheme.feedCommentAvatarSize
            Layout.preferredHeight: JamiTheme.feedCommentAvatarSize
            imageId: root.isOutgoing ? CurrentAccount.id : Author
            mode: root.isOutgoing ? Avatar.Mode.Account : Avatar.Mode.Contact
            showPresenceIndicator: false
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Rectangle {
                id: commentBubble

                Layout.fillWidth: true
                implicitHeight: bubbleColumn.implicitHeight + 16
                radius: 14
                color: JamiTheme.messageInBgColor

                ColumnLayout {
                    id: bubbleColumn

                    anchors.fill: parent
                    anchors.margins: 8
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 2

                    Label {
                        Layout.fillWidth: true
                        text: UtilsAdapter.getBestNameForUri(CurrentAccount.id, Author)
                        elide: Text.ElideRight
                        font.bold: true
                        font.pointSize: JamiTheme.smallFontSize
                        color: JamiTheme.textColor
                    }

                    Label {
                        objectName: "feedCommentReplyingTo"

                        Layout.fillWidth: true
                        visible: root.isReplyToComment
                        text: JamiStrings.replyingTo.arg(ReplyToAuthor === CurrentAccount.uri ? JamiStrings.inReplyToYou : UtilsAdapter.getBestNameForUri(CurrentAccount.id, ReplyToAuthor))
                        elide: Text.ElideRight
                        font.pointSize: JamiTheme.smallFontSize
                        color: JamiTheme.chatviewSecondaryInformationColor

                        HoverHandler {
                            cursorShape: Qt.PointingHandCursor
                        }

                        TapHandler {
                            onTapped: CurrentConversation.scrollToMsg(ReplyTo)
                        }
                    }

                    Loader {
                        Layout.fillWidth: true
                        sourceComponent: Type === Interaction.Type.DATA_TRANSFER ? mediaComp : textComp
                    }
                }
            }

            FeedReactionPills {
                id: reactions

                Layout.fillWidth: true
                Layout.leftMargin: 8
                reactions: Reactions
                msgId: Id
            }

            RowLayout {
                Layout.leftMargin: 8
                spacing: 12

                Label {
                    text: MessagesAdapter.getBestFormattedDate(Timestamp)
                    font.pointSize: JamiTheme.smallFontSize
                    color: JamiTheme.chatviewSecondaryInformationColor
                }

                Label {
                    visible: PreviousBodies.length !== 0
                    text: JamiStrings.edited
                    font.pointSize: JamiTheme.smallFontSize
                    color: JamiTheme.chatviewSecondaryInformationColor
                }

                Label {
                    objectName: "feedCommentReplyButton"

                    visible: root.canReply
                    text: JamiStrings.reply
                    font.pointSize: JamiTheme.smallFontSize
                    font.bold: true
                    color: JamiTheme.chatviewSecondaryInformationColor

                    Accessible.role: Accessible.Button
                    Accessible.name: text

                    HoverHandler {
                        cursorShape: Qt.PointingHandCursor
                    }

                    TapHandler {
                        onTapped: {
                            MessagesAdapter.editId = "";
                            MessagesAdapter.replyToId = root.commentId;
                        }
                    }
                }
            }
        }

        FeedMoreButton {
            Layout.alignment: Qt.AlignTop
            // Centered on the bubble, not on the reactions and date below it.
            Layout.topMargin: Math.max(0, (commentBubble.height - height) / 2)
            opacity: hover.hovered || menuOpen || activeFocus ? 1 : 0

            msgId: Id
            msgBody: Body
            type: Type
            transferName: TransferName
            isOutgoing: root.isOutgoing
            emojiReactions: reactions
            msgBubble: commentBubble
            listView: root.listView
        }
    }

    Component {
        id: textComp

        FeedTextContent {
            messageId: Id
            author: Author
            body: Body
            parsedBody: ParsedBody
            linkPreviewInfo: LinkPreviewInfo
            backgroundColor: JamiTheme.messageInBgColor
            fontSize: JamiTheme.textFontSize
            showLinkPreview: false
        }
    }

    Component {
        id: mediaComp

        FeedMediaContent {
            transferId: Id
            tid: TID
            author: Author
            path: Body
            transferName: TransferName
            transferStatus: TransferStatus
            totalSize: TotalSize
            maxMediaHeight: JamiTheme.maxImageHeight / 2
        }
    }
}
