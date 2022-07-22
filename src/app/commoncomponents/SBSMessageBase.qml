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
    property alias selectAnimation: selectAnimation
    property real extraHeight: 0

    // these MUST be set but we won't use the 'required' keyword yet
    property bool isOutgoing
    property bool showTime
    property int seq
    property string author
    property string transferId
    property string registeredNameText
    property string transferName
    property string formattedTime
    property string location
    property string id: Id
    property string hoveredLink
    property var readers: []

    readonly property real senderMargin: 64
    readonly property real avatarSize: 20
    readonly property real msgRadius: 20
    readonly property real hPadding: JamiTheme.sbsMessageBasePreferredPadding

    width: ListView.view ? ListView.view.width : 0
    height: mainColumnLayout.implicitHeight

    rightPadding: hPadding
    leftPadding: hPadding

    contentItem: ColumnLayout {
        id: mainColumnLayout

        anchors.centerIn: parent

        width: parent.width - hPadding * 2

        spacing: 0

        Item {

            id: usernameblock
            Layout.preferredHeight: (seq === MsgSeq.first || seq === MsgSeq.single) ? 10 : 0

            Label {
                id: username
                text: UtilsAdapter.getBestNameForUri(CurrentAccount.id, Author)
                font.bold: true
                visible: (seq === MsgSeq.first || seq === MsgSeq.single) && !isOutgoing
                font.pixelSize: JamiTheme.usernameBlockFontSize
                color: JamiTheme.chatviewUsernameColor
                lineHeight: JamiTheme.usernameBlockLineHeight
                leftPadding: JamiTheme.usernameBlockPadding
            }
        }


        RowLayout {
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
                    imageId: author
                    showPresenceIndicator: false
                    mode: Avatar.Mode.Contact
                }
            }


            MouseArea {
                id: itemMouseArea
            
                Layout.fillWidth: true
                Layout.fillHeight: true

                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: function (mouse) {
                    if (mouse.button === Qt.RightButton
                        && (transferId !== "" || Type === Interaction.Type.TEXT)) {
                        // Context Menu for Transfers
                        ctxMenu.x = mouse.x
                        ctxMenu.y = mouse.y
                        ctxMenu.openMenu()
                    } else if (root.hoveredLink) {
                        MessagesAdapter.openUrl(root.hoveredLink)
                    }
                }

                RowLayout {
                    id: replyToRow
                    z: 2
                    anchors.right: isOutgoing ? parent.right : undefined
                    Layout.topMargin: JamiTheme.tinyFontSize
                    Layout.bottomMargin: JamiTheme.tinyFontSize

                    // TODO connect to data changed for interaction
                    Connections {
                        target: MessagesAdapter.messageListModel
                        enabled: replyToRow.visible

                        function onRowsInserted() {
                            replyToRow.author = replyToRow.getAuthor()
                            replyToRow.body = replyToRow.getBody()
                        }
                    }

                    visible: {
                        if (ReplyTo !== "") {
                            MessagesAdapter.loadConversationUntil(ReplyTo)
                            return true
                        }
                        return false
                    }
                    property var isSelf: false
                    property var author: getAuthor()
                    property var body: getBody()

                    function getBody() {
                        if (ReplyTo === "")
                            return ""
                        // TODO MessageList.Role.Body
                        var a = MessagesAdapter.dataForInteraction(ReplyTo, 260)
                        return a === undefined ? "" : a
                    }

                    function getAuthor() {
                        if (ReplyTo === "")
                            return ""
                        // TODO MessageList.Role.Author
                        var a = MessagesAdapter.dataForInteraction(ReplyTo, 259)
                        isSelf = a === "" || a === undefined
                        return isSelf ? CurrentAccount.uri : a
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

                        imageId: parent.isSelf ? CurrentAccount.id : parent.author
                        mode: parent.isSelf ? Avatar.Mode.Account : Avatar.Mode.Contact
                    }

                    Text {
                        id: body
                        Layout.maximumWidth: JamiTheme.preferredFieldWidth - JamiTheme.preferredMarginSize
                        Layout.rightMargin: JamiTheme.preferredMarginSize

                        text: replyToRow.body
                        elide: Text.ElideRight

                        color:  UtilsAdapter.luma(bubble.color) ?
                            JamiTheme.chatviewTextColorLight :
                            JamiTheme.chatviewTextColorDark
                        font.pointSize: JamiTheme.textFontSize
                        font.kerning: true
                        font.bold: true
                    }

                    MouseArea {
                        anchors.fill: parent

                        onClicked: function(mouse) {
                            CurrentConversation.scrollToMsg(ReplyTo)
                        }
                    }
                }

                Column {
                    id: innerContent
                    width: parent.width

                    // place actual content here
                }
                MessageBubble {
                    id: bubble
                    z:-1
                    out: isOutgoing
                    type: seq
                    function getBaseColor() {
                        var baseColor = isOutgoing ? JamiTheme.messageOutBgColor
                                            : CurrentConversation.isCoreDialog ?
                                                JamiTheme.messageInBgColor : Qt.lighter(CurrentConversation.color, 1.5)
                        if (Id === MessagesAdapter.replyToId) {
                            // If we are replying to
                            return Qt.darker(baseColor, 1.5)
                        }
                        return baseColor
                    }
                    color: getBaseColor()
                    radius: msgRadius
                    anchors.right: isOutgoing ? parent.right : undefined
                    anchors.top: parent.top
                    width: Math.max(innerContent.childrenRect.width, replyToRow.implicitWidth)
                    height: innerContent.childrenRect.height + (visible ? root.extraHeight : 0)
                }

                SequentialAnimation {
                    id: selectAnimation
                    ColorAnimation {
                        target: bubble; property: "color"
                        to: Qt.darker(bubble.getBaseColor(), 1.5); duration: 240
                    }
                    ColorAnimation {
                        target: bubble; property: "color"
                        to: bubble.getBaseColor(); duration: 240
                    }
                }
            }

        }

        ListView {
            id: infoCell

            Layout.fillWidth: true
            orientation: ListView.Horizontal
            Layout.preferredHeight: {
                if (showTime || seq === MsgSeq.last)
                    return contentHeight + formattedTimeLabel.contentHeight
                else if (reads.visible)
                    return JamiTheme.avatarReadReceiptSize
                return 0
            }


            Label {
                id: formattedTimeLabel

                text: formattedTime
                color: JamiTheme.timestampColor
                visible: showTime || seq === MsgSeq.last
                height: visible * implicitHeight
                font.pointSize: 9
                topPadding : 4
                anchors.right: !isOutgoing ? undefined : reads.left
                anchors.rightMargin: 8
                anchors.left: isOutgoing ? undefined : parent.left
                anchors.leftMargin: avatarBlockWidth + 6
            }

            ReadStatus {

                id: reads
                visible: root.readers.length !== 0 && CurrentAccount.sendReadReceipt
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

    SBSContextMenu {
        id: ctxMenu

        msgId: Id
        location: root.location
        transferId: root.transferId
        transferName: root.transferName
    }
}
