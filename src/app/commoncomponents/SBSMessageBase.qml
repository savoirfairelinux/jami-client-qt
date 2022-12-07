/*
 * Copyright (C) 2021-2022 Savoir-faire Linux Inc.
 * Author: Andreas Traczyk <andreas.traczyk@savoirfairelinux.com>
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
import Qt5Compat.GraphicalEffects

import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1


Control {
    id: root

    property alias avatarBlockWidth: avatarBlock.width
    property alias innerContent: innerContent
    property alias bubble: bubble
    property real extraHeight: 0

    // these MUST be set but we won't use the 'required' keyword yet
    property bool isOutgoing
    property bool showTime: false
    property bool showDay: false
    property int seq
    property string author
    property string transferId
    property string registeredNameText
    property string transferName
    property string formattedTime: MessagesAdapter.getFormattedTime(Timestamp)
    property string formattedDay: MessagesAdapter.getFormattedDay(Timestamp)
    property string location
    property string id: Id
    property string hoveredLink
    property var readers: []
    property int timestamp: Timestamp
    readonly property real senderMargin: 64
    readonly property real avatarSize: 20
    readonly property real msgRadius: 20
    readonly property real hPadding: JamiTheme.sbsMessageBasePreferredPadding
    property bool textHovered: false
    width: ListView.view ? ListView.view.width : 0
    height: mainColumnLayout.implicitHeight

    rightPadding: hPadding
    leftPadding: hPadding

    contentItem: ColumnLayout {
        id: mainColumnLayout

        anchors.centerIn: parent
        width: parent.width - hPadding * 2
        spacing: 0

        TimestampInfo {
            id: timestampItem

            showDay: root.showDay
            showTime: root.showTime
            formattedTime: root.formattedTime
            formattedDay: root.formattedDay
            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: true
            Layout.fillHeight: true
        }

        Item {
            id: usernameblock
            Layout.preferredHeight: (seq === MsgSeq.first || seq === MsgSeq.single) ? 10 : 0

            Label {
                id: username
                text: UtilsAdapter.getBestNameForUri(CurrentAccount.id, Author)
                font.bold: true
                visible:(seq === MsgSeq.first || seq === MsgSeq.single) && !isOutgoing
                font.pixelSize: JamiTheme.usernameBlockFontSize
                color: JamiTheme.chatviewUsernameColor
                lineHeight: JamiTheme.usernameBlockLineHeight
                leftPadding: JamiTheme.usernameBlockPadding
            }
        }


        RowLayout {
            id: msgRowlayout

            Layout.preferredHeight: innerContent.height + root.extraHeight
            Layout.topMargin: (seq === MsgSeq.first || seq === MsgSeq.single) ? 6 : 0

            Item {
                id: avatarBlock

                Layout.preferredWidth: isOutgoing ? 0 : avatar.width + hPadding/3
                Layout.preferredHeight: isOutgoing ? 0 : bubble.height
                Avatar {
                    id: avatar
                    visible: !isOutgoing && (seq === MsgSeq.last || seq === MsgSeq.single)
                    anchors.bottom: parent.bottom
                    width: avatarSize
                    height: avatarSize
                    imageId: root.author
                    showPresenceIndicator: false
                    mode: Avatar.Mode.Contact
                }
            }

            Item {
                id: itemRowMessage

                Layout.fillHeight: true
                Layout.fillWidth: true

                MouseArea {
                    id: bubbleArea

                    anchors.fill: bubble
                    hoverEnabled: true
                    onClicked: function (mouse) {
                        MessagesAdapter.openUrl(root.hoveredLink)
                        if (root.hoveredLink) {
                            MessagesAdapter.openUrl(root.hoveredLink)
                        }
                    }
                    property bool bubbleHovered: containsMouse || textHovered
                }

                Column {
                    id: innerContent

                    width: parent.width
                    visible: true

                    // place actual content here
                    ReplyToRow {}
                }

                Item {
                    id: optionButtonItem

                    anchors.right: isOutgoing ? bubble.left : undefined
                    anchors.left: !isOutgoing ? bubble.right : undefined
                    width: JamiTheme.emojiPushButtonSize * 2
                    height: JamiTheme.emojiPushButtonSize
                    anchors.verticalCenter: bubble.verticalCenter

                    HoverHandler {
                        id: bgHandler
                    }

                    PushButton {
                        id: more

                        anchors.rightMargin: isOutgoing ? 10 : 0
                        anchors.leftMargin: !isOutgoing ? 10 : 0

                        imageColor: JamiTheme.emojiReactPushButtonColor
                        normalColor: JamiTheme.transparentColor
                        toolTipText: JamiStrings.moreOptions
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: isOutgoing ? optionButtonItem.right : undefined
                        anchors.left: !isOutgoing ? optionButtonItem.left : undefined
                        visible: bubbleArea.bubbleHovered || hovered || reply.hovered || bgHandler.hovered
                        source: JamiResources.more_vert_24dp_svg
                        width: optionButtonItem.width / 2
                        height: optionButtonItem.height

                        onClicked: {
                            messageOptionPopup.setPosition()
                            messageOptionPopup.open()
                        }
                    }

                    PushButton {
                        id: reply

                        imageColor: JamiTheme.emojiReactPushButtonColor
                        normalColor: JamiTheme.transparentColor
                        toolTipText: JamiStrings.reply
                        source: JamiResources.reply_svg
                        width: optionButtonItem.width / 2
                        height: optionButtonItem.height
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: isOutgoing ? more.left : undefined
                        anchors.left: !isOutgoing ? more.right : undefined
                        visible: bubbleArea.bubbleHovered || hovered || more.hovered || bgHandler.hovered

                        onClicked: {
                            MessagesAdapter.editId = ""
                            MessagesAdapter.replyToId = Id
                        }
                    }
                }


                ChatviewmessageOptions {
                    id: messageOptionPopup

                    emojiReplied: emojiReaction.emojiTexts
                    out: isOutgoing
                    msgId: Id
                    msg: Body

                    function setPosition() {
                        var mappedCoord = bubble.mapToItem(appWindow.contentItem,0, 0)
                        var distBottomScreen = appWindow.height - mappedCoord.y - height
                        if (distBottomScreen < 0) {
                            y = distBottomScreen
                        } else {
                            y = 0
                        }

                        var distBorders = root.width - bubble.width - width
                        if (isOutgoing) {
                            if (distBorders > 0)
                                x = bubble.x - width
                            else
                                x = bubble.x
                        }else {
                            if (distBorders > 0)
                                x = bubble.x + bubble.width
                            else
                                x = bubble.x + bubble.width - width
                        }
                    }
                }


                MessageBubble {
                    id: bubble

                    visible: !IsEmojiOnly
                    z:-1
                    out: isOutgoing
                    type: seq
                    function getBaseColor() {
                        var baseColor = isOutgoing ? JamiTheme.messageOutBgColor
                                                   : CurrentConversation.isCoreDialog ?
                                                         JamiTheme.messageInBgColor : Qt.lighter(CurrentConversation.color, 1.5)
                        if (Id === MessagesAdapter.replyToId || Id === MessagesAdapter.editId) {
                            // If we are replying to or editing the message
                            return Qt.darker(baseColor, 1.5)
                        }
                        return baseColor
                    }
                    color: getBaseColor()
                    radius: msgRadius
                    anchors.right: isOutgoing ? parent.right : undefined
                    anchors.top: parent.top
                    width: innerContent.childrenRect.width
                    height: innerContent.childrenRect.height + (visible ? root.extraHeight : 0)
                }

                Rectangle {
                    id: bg

                    color: bubble.getBaseColor()
                    anchors.fill: parent
                    visible: false
                }

                SequentialAnimation {
                    id: selectAnimation

                    PropertyAnimation {
                        properties: "opacity"
                        target: opacityMask
                        from: 0
                        to: 1
                        duration: JamiTheme.longFadeDuration
                    }
                    PropertyAnimation {
                        properties: "opacity"
                        target: opacityMask
                        from: 1
                        to: 0
                        duration: JamiTheme.longFadeDuration
                    }
                }

                OpacityMask {
                    id: opacityMask

                    opacity: 0
                    anchors.fill: bubble
                    source: bubble
                    maskSource: bg
                }

                Connections {
                    target: CurrentConversation
                    function onScrollTo(id) {
                        if (id !== root.id)
                            return
                        selectAnimation.start()
                    }
                }
            }

            Item {
                id: status
                Layout.alignment: Qt.AlignBottom
                width: JamiTheme.avatarReadReceiptSize

                Rectangle {
                    id: sending

                    radius: width / 2
                    width: 12
                    height: 12
                    border.color: JamiTheme.tintedBlue
                    border.width: 1
                    color: JamiTheme.transparentColor
                    visible: isOutgoing && Status === Interaction.Status.SENDING

                    anchors.bottom: parent.bottom
                }

                ReadStatus {
                    id: readsOne

                    visible: root.readers.length === 1 && CurrentAccount.sendReadReceipt

                    width: {
                        if (root.readers.length === 0)
                            return 0
                        var nbAvatars = root.readers.length
                        var margin = JamiTheme.avatarReadReceiptSize / 3
                        return nbAvatars * JamiTheme.avatarReadReceiptSize - (nbAvatars - 1) * margin
                    }
                    height: JamiTheme.avatarReadReceiptSize

                    anchors.bottom: parent.bottom
                    readers: root.readers
                }
            }
        }

        EmojiReactions {
            id: emojiReaction

            visible: Reactions && Object.entries(Reactions).length
            property bool isOutgoing: Author === ""


            Layout.alignment: isOutgoing ? Qt.AlignRight : Qt.AlignLeft
            Layout.rightMargin: isOutgoing ? status.width : undefined
            Layout.leftMargin: !isOutgoing ? avatarBlock.width : undefined
            Layout.topMargin: - contentHeight/4
            Layout.preferredHeight: contentHeight + 5
            Layout.preferredWidth: contentWidth
            emojiReaction: Reactions

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    reactionPopup.open()
                }
            }
        }

        ListView {
            id: infoCell

            Layout.fillWidth: true
            orientation: ListView.Horizontal
            Layout.preferredHeight: {
                if (showTime || seq === MsgSeq.last)
                    return contentHeight + timestampItem.contentHeight
                else if (readsMultiple.visible)
                    return JamiTheme.avatarReadReceiptSize
                return 0
            }

            ReadStatus {
                id: readsMultiple
                visible: root.readers.length > 1 && CurrentAccount.sendReadReceipt
                width: {
                    if (root.readers.length === 0)
                        return 0
                    var nbAvatars = root.readers.length
                    var margin = JamiTheme.avatarReadReceiptSize / 3
                    return nbAvatars * JamiTheme.avatarReadReceiptSize - (nbAvatars - 1) * margin
                }

                anchors.right: parent.right
                anchors.top : parent.top
                anchors.topMargin: 1
                readers: root.readers
            }
        }
    }

    EmojiReactionPopup {
        id: reactionPopup

        emojiReaction: Reactions

    }
}
