/*
 * Copyright (C) 2021 by Savoir-faire Linux
 * Author: Trevor Tabah <trevor.tabah@savoirfairelinux.com>
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

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtWebEngine 1.10

import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1

Control {
    id: root

    readonly property bool isGenerated: Type === Interaction.Type.CALL ||
                                        Type === Interaction.Type.CONTACT
    readonly property string author: Author
    readonly property var body: Body
    readonly property var timestamp: Timestamp
    readonly property bool isOutgoing: model.Author === ""
    readonly property var formattedTime: MessagesAdapter.getFormattedTime(Timestamp)
    readonly property bool isImage: MessagesAdapter.isImage(Body)
    readonly property bool isAnimatedImage: MessagesAdapter.isAnimatedImage(Body)
    readonly property var linkPreviewInfo: LinkPreviewInfo

    readonly property real senderMargin: 64
    readonly property real avatarSize: 32
    readonly property real msgRadius: 18
    readonly property real hMargin: 12

    property bool showTime: false
    property int seq: MsgSeq.single

    width: parent ? parent.width : 0
    height: loader.height

    Loader {
        id: loader

        property alias isOutgoing: root.isOutgoing
        property alias isGenerated: root.isGenerated
        readonly property var author: Author
        readonly property var body: Body

        width: root.width
        height: sourceComponent.height

        sourceComponent: isGenerated ?
                             generatedMsgComp :
                             userMsgComp
    }

    Component {
        id: generatedMsgComp

        Column {
            width: root.width
            spacing: 2

            TextArea {
                width: parent.width
                text: body
                horizontalAlignment: Qt.AlignHCenter
                readOnly: true
                font.pointSize: 11
                color: JamiTheme.chatviewTextColor
            }

            Item {
                id: infoCell

                width: parent.width
                height: childrenRect.height

                Label {
                    text: formattedTime
                    color: JamiTheme.timestampColor
                    visible: showTime || seq === MsgSeq.last
                    height: visible * implicitHeight
                    anchors.horizontalCenter: isGenerated ? parent.horizontalCenter : undefined
                }
            }

            bottomPadding: 12
        }
    }

    Component {
        id: userMsgComp

        // txt delegate
        ColumnLayout {
            id: txtItem
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: hMargin
            anchors.rightMargin: hMargin
            spacing: 2
            RowLayout {
                Layout.preferredWidth: parent.width
                Layout.preferredHeight: content.height
                Layout.topMargin: (seq === MsgSeq.first || seq === MsgSeq.single) ? 6 : 0
                spacing: 0
                Item {
                    id: avatarBlock
                    Layout.preferredWidth: isOutgoing ? 0 : avatar.width + hMargin
                    Layout.preferredHeight: isOutgoing ? 0 : content.height
                    Avatar {
                        id: avatar
                        visible: !isOutgoing
                        anchors.bottom: parent.bottom
                        width: avatarSize
                        height: avatarSize
                        imageId: author
                        showPresenceIndicator: false
                        mode: Avatar.Mode.Contact
                    }
                }
                Item {
                    id: contentBlock
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Column {
                        id: content
                        width: parent.width
                        TextEdit {
                            id: messageText
                            padding: 10
                            anchors.right: isOutgoing ? parent.right : undefined
                            text: body
                            width: Math.min(implicitWidth, content.width - senderMargin)
                            height: implicitHeight
                            wrapMode: Label.WrapAtWordBoundaryOrAnywhere
                            selectByMouse: true
                            font.pointSize: 11
                            font.hintingPreference: Font.PreferNoHinting
                            renderType: Text.NativeRendering
                            textFormat: TextEdit.RichText
                            onLinkActivated: Qt.openUrlExternally(link)
                            readOnly: true
                            color: isOutgoing ?
                                       JamiTheme.messageOutTxtColor :
                                       JamiTheme.messageInTxtColor
                        }
                    }
                    MessageBubble {
                        id: bubble
                        z:-1
                        out: isOutgoing
                        type: seq
                        color: isOutgoing ?
                                   JamiTheme.messageOutBgColor :
                                   JamiTheme.messageInBgColor
                        radius: msgRadius
                        anchors.right: isOutgoing ? parent.right : undefined
                        width: content.childrenRect.width
                        height: content.childrenRect.height
                    }
                }
            }
            Item {
                id: infoCell

                Layout.preferredWidth: parent.width
                Layout.preferredHeight: childrenRect.height

                Label {
                    text: formattedTime
                    color: JamiTheme.timestampColor

                    visible: showTime || seq === MsgSeq.last
                    height: visible * implicitHeight

                    anchors.right: !isOutgoing ? undefined : parent.right
                    anchors.rightMargin: msgRadius - 2
                    anchors.left: isOutgoing ? undefined : parent.left
                    anchors.leftMargin: avatarSize + msgRadius - 2
                }
            }
        }
    }

    opacity: 0
    Behavior on opacity { NumberAnimation { duration: 40 } }

    Component.onCompleted: {
        opacity = 1
        if (!Linkified && !isImage && !isAnimatedImage) {
            MessagesAdapter.parseMessageUrls(Id, Body)
        }
    }
}
