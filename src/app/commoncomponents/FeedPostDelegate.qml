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

// A feed post: a centered card with its author, content and actions, and its comments shown in place.
Item {
    id: root
    objectName: "feedPost"

    readonly property ListView listView: ListView.view
    readonly property string postId: Id
    readonly property bool isOutgoing: Author === CurrentAccount.uri
    readonly property int commentCount: ThreadReplyCount ?? 0
    // Kept by the list, so it survives the delegate being recycled.
    readonly property bool expanded: listView ? listView.expandedPosts[postId] === true : false
    readonly property bool canComment: CurrentConversation.canReplyText || CurrentConversation.canReplyFile

    // The list grows upward from the bottom, so a post would rise as its comments open.
    // While its comments button is in view, scroll along so it stays put and newer posts move down.
    // When shrinking, stop at the bottom of the list rather than scrolling past it.
    function keepInPlace(delta) {
        if (delta === 0 || !listView)
            return;
        const y = commentsButton.mapToItem(listView, 0, 0).y;
        if (y + commentsButton.height < 0 || y > listView.height)
            return;
        listView.contentY -= delta > 0 ? delta : Math.max(delta, -listView.getDistanceToBottom());
    }

    // Opens the comments and, when allowed, starts a comment on the post in the composer.
    function openComments() {
        if (canComment) {
            MessagesAdapter.editId = "";
            MessagesAdapter.replyToId = postId;
        }
        listView.setExpanded(postId, true);
    }

    // Closes the comments, cancelling a comment in progress on this post or one of its comments.
    function closeComments() {
        const replyTo = MessagesAdapter.replyToId;
        if (replyTo !== "" && (MessagesAdapter.threadedMessageListModel.threadRootOf(replyTo) || replyTo) === postId)
            MessagesAdapter.replyToId = "";
        listView.setExpanded(postId, false);
    }

    width: listView ? listView.width : 0
    implicitHeight: card.height + JamiTheme.feedPostSpacing

    Accessible.role: Accessible.StaticText
    Accessible.name: UtilsAdapter.getBestNameForUri(CurrentAccount.id, Author) + ": " + Body + " " + timeLabel.text

    HoverHandler {
        id: hover
    }

    Rectangle {
        id: card
        objectName: "feedPostCard"
        anchors.horizontalCenter: parent.horizontalCenter
        y: JamiTheme.feedPostSpacing / 2
        width: Math.min(parent.width - 2 * JamiTheme.feedPostSpacing, JamiTheme.feedPostMaxWidth)
        height: column.implicitHeight + 2 * JamiTheme.feedPostPadding
        radius: JamiTheme.feedPostRadius
        color: JamiTheme.feedPostBgColor
        border.color: root.postId === MessagesAdapter.replyToId || root.postId === MessagesAdapter.editId ? JamiTheme.tintedBlue : JamiTheme.feedPostBorderColor
        border.width: 1

        // Pins the post while its comments open, close or change (see keepInPlace).
        property real lastHeight: 0
        property bool hadComments: false
        onHeightChanged: {
            const hasComments = commentsLoader.active;
            if (hasComments || hadComments)
                root.keepInPlace(height - lastHeight);
            lastHeight = height;
            hadComments = hasComments;
        }

        ColumnLayout {
            id: column

            anchors.fill: parent
            anchors.margins: JamiTheme.feedPostPadding
            spacing: 12

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Avatar {
                    Layout.preferredWidth: JamiTheme.feedPostAvatarSize
                    Layout.preferredHeight: JamiTheme.feedPostAvatarSize
                    imageId: root.isOutgoing ? CurrentAccount.id : Author
                    mode: root.isOutgoing ? Avatar.Mode.Account : Avatar.Mode.Contact
                    showPresenceIndicator: false
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    Label {
                        Layout.fillWidth: true
                        text: UtilsAdapter.getBestNameForUri(CurrentAccount.id, Author)
                        elide: Text.ElideRight
                        font.bold: true
                        color: JamiTheme.textColor
                    }

                    RowLayout {
                        spacing: 4

                        Label {
                            id: timeLabel
                            text: MessagesAdapter.getFormattedDay(Timestamp) + " · " + MessagesAdapter.getFormattedTime(Timestamp)
                            font.pointSize: JamiTheme.smallFontSize
                            color: JamiTheme.chatviewSecondaryInformationColor
                        }

                        Label {
                            objectName: "feedPostEdited"

                            visible: PreviousBodies.length !== 0
                            text: "· " + JamiStrings.edited
                            font.pointSize: JamiTheme.smallFontSize
                            color: JamiTheme.chatviewSecondaryInformationColor

                            HoverHandler {
                                cursorShape: Qt.PointingHandCursor
                            }

                            TapHandler {
                                onTapped: viewCoordinator.presentDialog(appWindow, "commoncomponents/EditedPopup.qml", {
                                    "previousBodies": PreviousBodies,
                                    "showOriginal": false
                                })
                            }
                        }
                    }
                }

                FeedMoreButton {
                    Layout.alignment: Qt.AlignTop
                    opacity: hover.hovered || menuOpen || activeFocus ? 1 : 0

                    msgId: Id
                    msgBody: Body
                    type: Type
                    transferName: TransferName
                    isOutgoing: root.isOutgoing
                    emojiReactions: reactions
                    msgBubble: card
                    listView: root.listView
                }
            }

            Loader {
                Layout.fillWidth: true
                sourceComponent: Type === Interaction.Type.DATA_TRANSFER ? mediaComp : textComp
            }

            FeedReactionPills {
                id: reactions

                Layout.fillWidth: true
                reactions: Reactions
                msgId: Id
            }

            AbstractButton {
                id: commentsButton
                objectName: "feedCommentsButton"

                Layout.alignment: Qt.AlignLeft
                visible: root.commentCount > 0 || root.canComment
                text: root.commentCount === 0 ? JamiStrings.comment : root.commentCount === 1 ? JamiStrings.oneComment : JamiStrings.comments.arg(root.commentCount)
                onClicked: root.expanded ? root.closeComments() : root.openComments()

                padding: 6
                leftPadding: 10
                rightPadding: 12
                hoverEnabled: true

                Accessible.role: Accessible.Button
                Accessible.name: text

                background: Rectangle {
                    radius: height / 2
                    color: JamiTheme.hoveredButtonColor
                    opacity: commentsButton.hovered || commentsButton.visualFocus ? 1.0 : 0.0
                    Behavior on opacity {
                        NumberAnimation {
                            duration: JamiTheme.shortFadeDuration
                        }
                    }
                }

                contentItem: RowLayout {
                    spacing: 6

                    ResponsiveImage {
                        Layout.preferredWidth: 18
                        Layout.preferredHeight: 18
                        source: JamiResources.comment_24dp_svg
                        color: JamiTheme.chatviewSecondaryInformationColor
                    }

                    Label {
                        text: commentsButton.text
                        font.pointSize: JamiTheme.smallFontSize
                        color: JamiTheme.chatviewSecondaryInformationColor
                    }
                }

                HoverHandler {
                    cursorShape: Qt.PointingHandCursor
                }
            }

            // Comments slide open and closed; they stay loaded until fully closed.
            Item {
                id: commentsArea
                objectName: "feedCommentsArea"

                property real reveal: root.expanded ? 1 : 0

                Behavior on reveal {
                    NumberAnimation {
                        duration: JamiTheme.overlayFadeDuration
                        easing.type: Easing.OutCubic
                    }
                }

                Layout.fillWidth: true
                Layout.preferredHeight: commentsLoader.implicitHeight * reveal
                visible: reveal > 0
                opacity: reveal
                clip: true

                Loader {
                    id: commentsLoader
                    objectName: "feedComments"

                    width: parent.width
                    active: root.expanded || commentsArea.reveal > 0

                    sourceComponent: ColumnLayout {
                        spacing: 10

                        Repeater {
                            model: ThreadRepliesModel {
                                threads: MessagesAdapter.threadedMessageListModel
                                rootId: root.postId
                            }

                            delegate: FeedCommentDelegate {
                                Layout.fillWidth: true
                                postId: root.postId
                                listView: root.listView
                            }
                        }
                    }
                }
            }
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
        }
    }
}
