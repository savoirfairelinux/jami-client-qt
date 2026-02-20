/*
 * Copyright (C) 2021-2026 Savoir-faire Linux Inc.
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
    Accessible.role: Accessible.StaticText

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
    readonly property real msgRadius: 22
    readonly property real hPadding: JamiTheme.sbsMessageBasePreferredPadding
    property bool textHovered: false
    property alias replyAnimation: selectAnimation
    width: listView.width

    property real textContentWidth
    property real textContentHeight
    property bool isReply: ReplyTo !== ""
    property real timeWidth: timestampItem.width
    property real editedWidth: editedRow.visible ? editedRow.width + 10 : 0

    property real maxMsgWidth: root.width - senderMargin - 2 * hPadding - avatarBlockWidth
    property bool bigMsg
    property bool timeUnderBubble: false
    property var type: Type
    property var shouldBeVisible: msgRowlayout.msgHovered || root.activeFocus || reply.activeFocus
                                  || more.activeFocus || share.activeFocus

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

    background: Rectangle {
        id: focusIndicator
        visible: root.activeFocus
        radius: 4
        border.color: JamiTheme.tintedBlue
        border.width: 2
        color: "transparent"
        z: 1
    }

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

        Label {
            id: username

            wrapMode: Text.NoWrap
            text: textMetricsUsername.elidedText
            TextMetrics {
                id: textMetricsUsername

                text: UtilsAdapter.getBestNameForUri(CurrentAccount.id, Author)
                elideWidth: 200
                elide: Qt.ElideMiddle
            }
            visible: (seq === MsgSeq.first || seq === MsgSeq.single) && !isOutgoing && !isReply

            font.pointSize: JamiTheme.smallFontSize
            color: JamiTheme.chatviewSecondaryInformationColor
            leftPadding: JamiTheme.usernameBlockPadding
            textFormat: TextEdit.PlainText
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

                    spacing: replyItem.isSelf ? 2 : 4
                    Layout.alignment: isOutgoing ? Qt.AlignRight : Qt.AlignLeft
                    Layout.leftMargin: msgRadius
                    Layout.rightMargin: msgRadius
                    property var replyUserName: UtilsAdapter.getBestNameForUri(CurrentAccount.id,
                                                                               ReplyToAuthor)

                    Label {
                        id: replyTo

                        wrapMode: Text.NoWrap
                        text: textMetricsUsername1.elidedText
                        TextMetrics {
                            id: textMetricsUsername1
                            text: isOutgoing ? JamiStrings.inReplyTo : JamiStrings.repliedTo.arg(
                                                   UtilsAdapter.getBestNameForUri(CurrentAccount.id,
                                                                                  Author))
                            elideWidth: 200
                            elide: Qt.ElideMiddle
                        }

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

                        wrapMode: Text.NoWrap
                        text: textMetricsUsername2.elidedText
                        TextMetrics {
                            id: textMetricsUsername2
                            text: replyItem.isSelf ? JamiStrings.inReplyToYou :
                                                     replyToLayout.replyUserName
                            elideWidth: 200
                            elide: Qt.ElideMiddle
                        }

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

            HoverHandler {
                id: parenthandler
            }

            property bool msgHovered: CurrentAccount.type !== Profile.Type.SIP && root.type
                                      !== Interaction.Type.CALL && Body !== "" && (
                                          bubbleArea.bubbleHovered || hovered || more.hovered
                                          || share.hovered || parenthandler.hovered)

            Layout.preferredHeight: {
                var h = innerContent.height + root.extraHeight;
                if (emojiReactions.emojis !== "")
                    h += emojiReactions.height - 8;
                if ((IsEmojiOnly && (root.seq === MsgSeq.last || root.seq === MsgSeq.single)
                     && emojiReactions.emojis === ""))
                    h += 15;
                if (root.timeUnderBubble)
                    h += 25;
                return h;
            }
            Layout.topMargin: ((seq === MsgSeq.first || seq === MsgSeq.single) && !root.isReply)
                              ? 3.5 : 0
            Layout.bottomMargin: root.bigMsg ? timestampItem.timeLabel.height : 0

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

                Column {
                    id: innerContent

                    width: parent.width
                    visible: true
                }

                Item {
                    id: optionButtonItem

                    anchors.right: isOutgoing ? bubble.left : undefined
                    anchors.left: !isOutgoing ? bubble.right : undefined
                    width: JamiTheme.emojiPushButtonSize * 4
                    height: JamiTheme.emojiPushButtonSize
                    anchors.verticalCenter: bubble.verticalCenter

                    NewIconButton {
                        id: more
                        objectName: "more"

                        property bool isOpen: false
                        property var obj: undefined

                        function setBindings() {
                            more.isOpen = false;
                            visible = Qt.binding(() => shouldBeVisible);
                        }

                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: !isOutgoing ? optionButtonItem.left : undefined
                        anchors.leftMargin: !isOutgoing ? 10 : 0
                        anchors.rightMargin: isOutgoing ? 10 : 0
                        anchors.right: isOutgoing ? optionButtonItem.right : undefined

                        iconSource: JamiResources.more_vert_24dp_svg
                        iconSize: JamiTheme.iconButtonMedium
                        toolTipText: JamiStrings.moreOptions

                        visible: shouldBeVisible

                        onClicked: {
                            if (more.isOpen) {
                                more.setBindings();
                                obj.close();
                            } else {
                                var component = Qt.createComponent(
                                            "qrc:/commoncomponents/ShowMoreMenu.qml");
                                obj = component.createObject(more, {
                                                                 "emojiReactions": emojiReactions,
                                                                 "isOutgoing": isOutgoing,
                                                                 "msgId": Id,
                                                                 "msgBody": Body,
                                                                 "type": root.type,
                                                                 "transferName": TransferName,
                                                                 "msgBubble": bubble,
                                                                 "listView": listView
                                                             });
                                obj.open();
                                more.isOpen = true;
                                visible = true; // the button stay visible as long the popup is open even if it's not hovered
                            }
                        }
                    }

                    NewIconButton {
                        id: reply
                        objectName: "reply"

                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: !isOutgoing ? more.right : undefined
                        anchors.rightMargin: 5
                        anchors.right: isOutgoing ? more.left : undefined

                        iconSize: JamiTheme.iconButtonMedium
                        iconSource: JamiResources.reply_black_24dp_svg
                        toolTipText: JamiStrings.reply

                        visible: shouldBeVisible

                        onClicked: {
                            MessagesAdapter.editId = "";
                            MessagesAdapter.replyToId = Id;
                        }
                    }

                    NewIconButton {
                        id: share
                        objectName: "share"

                        property bool isOpen: false
                        property var obj: undefined

                        function setBindings(
                            ) { // when the popup is closed, setBindings is called to reset the icon's visual settings
                            share.isOpen = false;
                            visible = Qt.binding(() => shouldBeVisible);
                        }

                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: !isOutgoing ? reply.right : undefined
                        anchors.right: isOutgoing ? reply.left : undefined
                        anchors.rightMargin: 5

                        iconSize: JamiTheme.iconButtonMedium
                        iconSource: JamiResources.share_black_24dp_svg
                        toolTipText: JamiStrings.share

                        visible: shouldBeVisible

                        onClicked: {
                            if (share.isOpen) {
                                share.setBindings();
                                obj.close();
                            } else {
                                if (root.type === 2 || root.type === 5) {
                                    // 2=TEXT and 5=DATA_TRANSFER (any kind of file) defined in interaction.h
                                    var component = Qt.createComponent(
                                                "qrc:/commoncomponents/ShareMessageMenu.qml");
                                    obj = component.createObject(share, {
                                                                     "isOutgoing": isOutgoing,
                                                                     "msgId": Id,
                                                                     "msgBody": Body,
                                                                     "type": root.type,
                                                                     "transferName": TransferName,
                                                                     "msgBubble": bubble,
                                                                     "listView": listView,
                                                                     "author": UtilsAdapter.getBestNameForUri(
                                                                                   CurrentAccount.id,
                                                                                   Author),
                                                                     "formattedTime": formattedTime
                                                                 });
                                    obj.open();
                                    share.isOpen = true;
                                    visible = true; // the PushButton stay visible as long the popup is open even if it's not hovered
                                }
                            }
                        }
                    }
                }

                MessageBubble { //Scaffold {}
                    id: bubble

                    property bool isEdited: PreviousBodies.length !== 0
                    property bool isDeleted: false
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
                    property bool bubbleHovered
                    property string imgSource

                    width: (root.type === Interaction.Type.TEXT || isDeleted
                            ? root.textContentWidth + (IsEmojiOnly || root.bigMsg ? 0 :
                                                                                    root.timeWidth
                                                                                    + root.editedWidth) :
                              innerContent.childrenRect.width)
                    height: innerContent.childrenRect.height + (visible ? root.extraHeight : 0) + (
                                root.bigMsg ? 15 : 0)

                    HoverHandler {
                        target: root
                        enabled: root.type === Interaction.Type.DATA_TRANSFER
                        onHoveredChanged: {
                            root.hoveredLink = enabled && hovered ? bubble.imgSource : "";
                        }
                    }

                    TimestampInfo {
                        id: timestampItem

                        showTime: IsEmojiOnly && !(root.seq === MsgSeq.last || root.seq
                                                   === MsgSeq.single) ? false : true
                        formattedTime: root.formattedTime

                        timeColor: IsEmojiOnly || root.timeUnderBubble ? (JamiTheme.darkTheme
                                                                          ? "white" : "dark") : (
                                                                             UtilsAdapter.luma(
                                                                                 bubble.color)
                                                                             ? "white" : "dark")
                        timeLabel.opacity: 0.5

                        anchors.bottom: parent.bottom
                        anchors.right: IsEmojiOnly ? (isOutgoing ? parent.right : undefined) :
                                                     parent.right
                        anchors.left: ((IsEmojiOnly || root.timeUnderBubble) && !isOutgoing)
                                      ? parent.left : undefined
                        anchors.leftMargin: (IsEmojiOnly && !isOutgoing && emojiReactions.visible)
                                            ? bubble.timePosition : 0
                        anchors.rightMargin: IsEmojiOnly ? ((isOutgoing && emojiReactions.visible)
                                                            ? bubble.timePosition : 0) : (
                                                               root.timeUnderBubble ? 0 : 10)
                        timeLabel.Layout.bottomMargin: {
                            if (IsEmojiOnly)
                                return -15;
                            if (root.timeUnderBubble)
                                return -20;
                            if (root.bigMsg || bubble.isDeleted)
                                return 5;
                            if (root.type === Interaction.Type.CALL)
                                return 8;
                            return 9;
                        }
                    }

                    RowLayout {
                        id: editedRow
                        anchors.left: root.bigMsg ? bubble.left : timestampItem.left
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: root.bigMsg ? 6 : 10
                        anchors.leftMargin: root.bigMsg ? 10 : -timestampItem.width - 16
                        visible: bubble.isEdited && !bubble.isDeleted
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
                        }

                        TapHandler {
                            acceptedButtons: Qt.LeftButton
                            onTapped: {
                                viewCoordinator.presentDialog(appWindow,
                                                              "commoncomponents/EditedPopup.qml", {
                                                                  "previousBodies": PreviousBodies
                                                              });
                            }
                        }
                    }

                    MouseArea {
                        id: bubbleArea

                        anchors.fill: parent
                        hoverEnabled: true

                        onClicked: function (mouse) {
                            if (root.hoveredLink) {
                                MessagesAdapter.openUrl(root.hoveredLink);
                            }
                        }

                        onDoubleClicked: {
                            MessagesAdapter.editId = "";
                            MessagesAdapter.replyToId = Id;
                        }
                        property bool bubbleHovered: containsMouse || textHovered
                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
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

                    state: root.isOutgoing ? "anchorsRight" : (IsEmojiOnly ? "anchorsLeft" : (
                                                                                 emojiReactions.width
                                                                                 > bubble.width
                                                                                 - JamiTheme.emojiMargins
                                                                                 ? "anchorsLeft" :
                                                                                   "anchorsRight"))

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
                property bool isAlone: CurrentConversation.members.count === 1

                Rectangle {
                    id: sending

                    radius: width / 2
                    width: 12
                    height: 12
                    border.color: JamiTheme.sending
                    border.width: 1
                    color: JamiTheme.transparentColor
                    visible: isOutgoing && Status === Interaction.Status.SENDING && !status.isAlone

                    anchors.bottom: parent.bottom
                }

                ResponsiveImage {
                    id: sent

                    containerHeight: 12
                    containerWidth: 12

                    width: 12
                    height: 12

                    visible: IsLastSent === true && root.readers.length === 0
                    anchors.bottom: parent.bottom

                    source: JamiResources.receive_svg
                }

                ReadStatus {
                    id: readsOne

                    visible: root.readers.length === 1 && CurrentAccount.sendReadReceipt

                    width: JamiTheme.avatarReadReceiptSize
                    height: JamiTheme.avatarReadReceiptSize

                    anchors.bottom: parent.bottom
                    readers: root.readers
                }

                Component {
                    id: selfReadIconComp
                    Avatar {
                        width: JamiTheme.avatarReadReceiptSize
                        height: JamiTheme.avatarReadReceiptSize
                        mode: Avatar.Mode.Account
                        imageId: CurrentAccount.id
                        showPresenceIndicator: false
                    }
                }
                Loader {
                    active: status.isAlone && CurrentConversation.lastSelfMessageId === Id
                    sourceComponent: selfReadIconComp
                    anchors.bottom: parent.bottom
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
                visible: {
                    if (!readers)
                        return false;
                    return readers.length > 1 && CurrentAccount.sendReadReceipt;
                }
                width: {
                    if (readers.length === 0)
                        return 0;
                    var nbAvatars = readers.length;
                    var margin = JamiTheme.avatarReadReceiptSize / 3;
                    return nbAvatars * JamiTheme.avatarReadReceiptSize - (nbAvatars - 1) * margin;
                }
                height: {
                    if (readers.length === 0)
                        return 0;
                    return JamiTheme.avatarReadReceiptSize;
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
