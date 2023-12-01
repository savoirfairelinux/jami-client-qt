/*
 * Copyright (C) 2021-2023 Savoir-faire Linux Inc.
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
    readonly property real msgRadius: 10
    readonly property real hPadding: JamiTheme.sbsMessageBasePreferredPadding
    property bool textHovered: false
    property alias replyAnimation: selectAnimation
    width: listView.width
    height: mainColumnLayout.implicitHeight

    property real textContentWidth
    property real textContentHeight
    property bool isReply: ReplyTo !== ""
    property real timeWidth: timestampItem.width
    property real editedWidth: editedRow.visible ? editedRow.width + 10 : 0

    property real maxMsgWidth: root.width - senderMargin - 2 * hPadding - avatarBlockWidth
    property bool bigMsg

    // If the ListView attached properties are not available,
    // then the root delegate is likely a Loader.
    readonly property ListView listView: ListView.view ? ListView.view : parent.ListView.view

    function getBaseColor() {
        var baseColor = isOutgoing ? CurrentConversation.color : JamiTheme.messageInBgColor;
        if (Id === MessagesAdapter.replyToId || Id === MessagesAdapter.editId) {
            // If we are replying to or editing the message
            return Qt.darker(baseColor, 1.5);
        }
        return baseColor;
    }

    rightPadding: hPadding
    leftPadding: hPadding

    contentItem: ColumnLayout {
        id: mainColumnLayout

        anchors.centerIn: parent
        width: parent.width - hPadding * 2
        spacing: 0

        TimestampInfo {
            id: dateItem
            showDay: root.showDay
            formattedDay: root.formattedDay
            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: true
            Layout.fillHeight: true
        }

        Item {
            id: usernameblock
            Layout.preferredHeight: (seq === MsgSeq.first || seq === MsgSeq.single) ? 10 : 0
            visible: !isReply

            Label {
                id: username
                text: UtilsAdapter.getBestNameForUri(CurrentAccount.id, Author)
                visible: (seq === MsgSeq.first || seq === MsgSeq.single) && !isOutgoing
                font.pointSize: JamiTheme.smallFontSize
                color: JamiTheme.chatviewSecondaryInformationColor
                lineHeight: JamiTheme.usernameBlockLineHeight
                leftPadding: JamiTheme.usernameBlockPadding
                textFormat: TextEdit.PlainText
            }
        }

        Item {
            id: replyItem
            property bool isSelf: ReplyToAuthor === CurrentAccount.uri

            visible: root.isReply
            width: parent.width

            Layout.fillWidth: true
            Layout.preferredHeight: childrenRect.height

            Layout.topMargin: visible ? JamiTheme.sbsMessageBaseReplyTopMargin : 0
            Layout.leftMargin: isOutgoing ? undefined : JamiTheme.sbsMessageBaseReplyMargin
            Layout.rightMargin: !isOutgoing ? undefined : JamiTheme.sbsMessageBaseReplyMargin

            transform: Translate {
                y: JamiTheme.sbsMessageBaseReplyBottomMargin
            }

            ColumnLayout {
                width: parent.width
                spacing: 2

                RowLayout {
                    id: replyToLayout

                    Layout.alignment: isOutgoing ? Qt.AlignRight : Qt.AlignLeft
                    property var replyUserName: UtilsAdapter.getBestNameForUri(CurrentAccount.id, ReplyToAuthor)

                    Label {
                        id: replyTo

                        text: isOutgoing ? JamiStrings.inReplyTo : UtilsAdapter.getBestNameForUri(CurrentAccount.id, Author) + JamiStrings.repliedTo
                        color: JamiTheme.messageReplyColor
                        font.pointSize: JamiTheme.textFontSize
                        font.kerning: true
                        font.bold: true
                    }

                    Avatar {
                        id: avatarReply

                        visible: !replyItem.isSelf
                        Layout.preferredWidth: JamiTheme.avatarReadReceiptSize
                        Layout.preferredHeight: JamiTheme.avatarReadReceiptSize
                        showPresenceIndicator: false
                        imageId: {
                            if (replyItem.isSelf)
                                return CurrentAccount.id;
                            return ReplyToAuthor;
                        }
                        mode: replyItem.isSelf ? Avatar.Mode.Account : Avatar.Mode.Contact
                    }

                    Label {
                        id: replyToUserName

                        text: replyItem.isSelf ? JamiStrings.inReplyToMe : replyToLayout.replyUserName
                        color: JamiTheme.messageReplyColor
                        font.pointSize: JamiTheme.textFontSize
                        font.kerning: true
                        font.bold: true
                    }
                }

                Rectangle {
                    id: replyBubble

                    z: -2
                    color: replyItem.isSelf ? CurrentConversation.color : JamiTheme.messageInBgColor
                    radius: msgRadius

                    Layout.preferredWidth: replyToRow.width + 2 * JamiTheme.preferredMarginSize
                    Layout.preferredHeight: replyToRow.height + 2 * JamiTheme.preferredMarginSize
                    Layout.alignment: isOutgoing ? Qt.AlignRight : Qt.AlignLeft

                    // place actual content here
                    ReplyToRow {
                        id: replyToRow

                        anchors.centerIn: parent
                    }

                    MouseArea {
                        z: 2
                        anchors.fill: parent
                        onClicked: function (mouse) {
                            CurrentConversation.scrollToMsg(ReplyTo);
                        }
                    }
                }
            }
        }

        RowLayout {
            id: msgRowlayout

            Layout.preferredHeight: innerContent.height + root.extraHeight + (emojiReactions.emojis === "" ? 0 : emojiReactions.height - 8) + (IsEmojiOnly && (root.seq === MsgSeq.last || root.seq === MsgSeq.single) && emojiReactions.emojis === "" ? 15 : 0)
            Layout.topMargin: ((seq === MsgSeq.first || seq === MsgSeq.single) && !root.isReply) ? 6 : 0

            Item {
                id: avatarBlock

                Layout.preferredWidth: isOutgoing ? 0 : avatar.width + hPadding / 3
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
                        if (root.hoveredLink) {
                            MessagesAdapter.openUrl(root.hoveredLink);
                        }
                    }
                    property bool bubbleHovered: containsMouse || textHovered
                }

                Column {
                    id: innerContent

                    width: parent.width
                    visible: true
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

                        imageColor: hovered ? JamiTheme.chatViewFooterImgHoverColor : JamiTheme.chatViewFooterImgColor
                        normalColor: JamiTheme.primaryBackgroundColor
                        toolTipText: JamiStrings.moreOptions
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: isOutgoing ? optionButtonItem.right : undefined
                        anchors.left: !isOutgoing ? optionButtonItem.left : undefined
                        visible: CurrentAccount.type !== Profile.Type.SIP && Body !== "" && (bubbleArea.bubbleHovered || hovered || reply.hovered || bgHandler.hovered)
                        source: JamiResources.more_vert_24dp_svg
                        width: optionButtonItem.width / 2
                        height: optionButtonItem.height
                        circled: false
                        property bool isOpen: false
                        property var obj: undefined

                        function bind() {
                            more.isOpen = false;
                            visible = Qt.binding(() => CurrentAccount.type !== Profile.Type.SIP && Body !== "" && (bubbleArea.bubbleHovered || hovered || reply.hovered || bgHandler.hovered));
                            imageColor = Qt.binding(() => hovered ? JamiTheme.chatViewFooterImgHoverColor : JamiTheme.chatViewFooterImgColor);
                            normalColor = Qt.binding(() => JamiTheme.primaryBackgroundColor);
                        }

                        onClicked: {
                            if (more.isOpen) {
                                more.bind();
                                obj.close();
                            } else {
                                var component = Qt.createComponent("qrc:/commoncomponents/ShowMoreMenu.qml");
                                obj = component.createObject(more, {
                                        "emojiReactions": emojiReactions,
                                        "isOutgoing": isOutgoing,
                                        "msgId": Id,
                                        "msgBody": Body,
                                        "type": Type,
                                        "transferName": TransferName,
                                        "msgBubble": bubble,
                                        "listView": listView
                                    });
                                obj.open();
                                more.isOpen = true;
                                visible = true;
                                imageColor = JamiTheme.chatViewFooterImgHoverColor;
                                normalColor = JamiTheme.hoveredButtonColor;
                            }
                        }
                    }

                    PushButton {
                        id: reply

                        circled: false
                        imageColor: hovered ? JamiTheme.chatViewFooterImgHoverColor : JamiTheme.chatViewFooterImgColor
                        normalColor: JamiTheme.primaryBackgroundColor
                        toolTipText: JamiStrings.reply
                        source: JamiResources.reply_black_24dp_svg
                        width: optionButtonItem.width / 2
                        height: optionButtonItem.height
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.rightMargin: 5
                        anchors.right: isOutgoing ? more.left : undefined
                        anchors.left: !isOutgoing ? more.right : undefined
                        visible: CurrentAccount.type !== Profile.Type.SIP && Body !== "" && (bubbleArea.bubbleHovered || hovered || more.hovered || bgHandler.hovered)

                        onClicked: {
                            MessagesAdapter.editId = "";
                            MessagesAdapter.replyToId = Id;
                        }
                    }
                }

                MessageBubble {
                    id: bubble

                    property bool isEdited: PreviousBodies.length !== 0
                    z: -1
                    out: isOutgoing
                    type: seq
                    isReply: root.isReply
                    color: IsEmojiOnly ? "transparent" : root.getBaseColor()
                    radius: msgRadius
                    anchors.right: isOutgoing ? parent.right : undefined
                    anchors.top: parent.top

                    property real timePosition: JamiTheme.emojiMargins + emojiReactions.width + 8
                    property alias timestampItem: timestampItem

                    width: (Type === Interaction.Type.TEXT ? root.textContentWidth : innerContent.childrenRect.width)
                    height: innerContent.childrenRect.height + (visible ? root.extraHeight : 0) + (root.bigMsg ? 15 : 0)

                    TimestampInfo {
                        id: timestampItem

                        showTime: IsEmojiOnly && !(root.seq === MsgSeq.last || root.seq === MsgSeq.single) ? false : true
                        formattedTime: root.formattedTime

                        timeColor: IsEmojiOnly ? (JamiTheme.darkTheme ? "white" : "dark") : (UtilsAdapter.luma(bubble.color) ? "white" : "dark")
                        timeLabel.opacity: 0.5

                        anchors.bottom: parent.bottom
                        anchors.right: IsEmojiOnly ? (isOutgoing ? parent.right : undefined) : parent.right
                        anchors.left: (IsEmojiOnly && !isOutgoing) ? parent.left : undefined
                        anchors.leftMargin: (IsEmojiOnly && !isOutgoing && emojiReactions.visible) ? bubble.timePosition : 0
                        anchors.rightMargin: IsEmojiOnly ? ((isOutgoing && emojiReactions.visible) ? bubble.timePosition : 0) : 10
                        timeLabel.Layout.bottomMargin: {
                            if (IsEmojiOnly)
                                return -15;
                            if (root.bigMsg)
                                return 5;
                            return 9;
                        }
                    }

                    RowLayout {
                        id: editedRow
                        anchors.left: root.bigMsg ? bubble.left : timestampItem.left
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: root.bigMsg ? 6 : 10
                        anchors.leftMargin: root.bigMsg ? 10 : - timestampItem.width - 10
                        visible: bubble.isEdited
                        z: 1
                        ResponsiveImage {
                            id: editedImage
                            source: JamiResources.round_edit_24dp_svg
                            width: 12
                            height: 12
                            color: editedLabel.color
                            opacity: 0.5
                        }
                        Text {
                            id: editedLabel
                            text: JamiStrings.edited
                            color: UtilsAdapter.luma(bubble.color) ? "white" : "dark"
                            opacity: 0.5
                            font.pixelSize: JamiTheme.timestampFont
                            TapHandler {
                                acceptedButtons: Qt.LeftButton
                                onTapped: {
                                    viewCoordinator.presentDialog(appWindow, "commoncomponents/EditedPopup.qml", {
                                            "previousBodies": PreviousBodies
                                        });
                                }
                            }
                        }
                    }
                }

                EmojiReactions {
                    id: emojiReactions

                    anchors.top: bubble.bottom
                    anchors.topMargin: -8

                    height: contentHeight + 5
                    reactions: Reactions
                    borderColor: root.getBaseColor()
                    maxWidth: 2 / 3 * maxMsgWidth - JamiTheme.emojiMargins

                    state: root.isOutgoing ? "anchorsRight" : (IsEmojiOnly ? "anchorsLeft" :(emojiReactions.width > bubble.width - JamiTheme.emojiMargins ? "anchorsLeft" : "anchorsRight"))

                    TapHandler {
                        onTapped: {
                            reactionPopup.open();
                        }
                    }

                    states: [
                        State {
                            name: "anchorsRight"
                            AnchorChanges {
                                target: emojiReactions
                                anchors.right: bubble.right
                                anchors.left: undefined
                            }
                            PropertyChanges {
                                target: emojiReactions
                                anchors.rightMargin: JamiTheme.emojiMargins
                                anchors.leftMargin: 0
                            }
                        },
                        State {
                            name: "anchorsLeft"
                            AnchorChanges {
                                target: emojiReactions
                                anchors.right: undefined
                                anchors.left: bubble.left
                            }
                            PropertyChanges {
                                target: emojiReactions
                                anchors.rightMargin: 0
                                anchors.leftMargin: JamiTheme.emojiMargins
                            }
                        }
                    ]
                }

                Rectangle {
                    id: bg

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
                            return;
                        selectAnimation.start();
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
                            return 0;
                        var nbAvatars = root.readers.length;
                        var margin = JamiTheme.avatarReadReceiptSize / 3;
                        return nbAvatars * JamiTheme.avatarReadReceiptSize - (nbAvatars - 1) * margin;
                    }
                    height: JamiTheme.avatarReadReceiptSize

                    anchors.bottom: parent.bottom
                    readers: root.readers
                }
            }
        }

        ListView {
            id: infoCell

            Layout.fillWidth: true
            orientation: ListView.Horizontal
            Layout.preferredHeight: {
                if (showTime || seq === MsgSeq.last)
                    return contentHeight + dateItem.contentHeight;
                else if (readsMultiple.visible)
                    return JamiTheme.avatarReadReceiptSize;
                return 0;
            }

            ReadStatus {
                id: readsMultiple
                visible: root.readers.length > 1 && CurrentAccount.sendReadReceipt
                width: {
                    if (root.readers.length === 0)
                        return 0;
                    var nbAvatars = root.readers.length;
                    var margin = JamiTheme.avatarReadReceiptSize / 3;
                    return nbAvatars * JamiTheme.avatarReadReceiptSize - (nbAvatars - 1) * margin;
                }

                anchors.right: parent.right
                anchors.top: parent.top
                anchors.topMargin: 1
                readers: root.readers
            }
        }
    }

    EmojiReactionPopup {
        id: reactionPopup

        reactions: Reactions
        msgId: Id
    }
}
