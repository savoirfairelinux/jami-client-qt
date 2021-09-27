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
import QtGraphicalEffects 1.15

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
    readonly property bool isLocalImage: MessagesAdapter.isLocalImage(Body)
    readonly property var linkPreviewInfo: LinkPreviewInfo

    readonly property real senderMargin: 64
    readonly property real avatarSize: 32
    readonly property real msgRadius: 18
    readonly property real hMargin: 12

    property bool showTime: false
    property int seq: MsgSeq.single

    width: parent ? parent.width : 0
    height: loader.height

    // message interaction
    property string hoveredLink
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        onClicked: {
            if (root.hoveredLink)
                Qt.openUrlExternally(root.hoveredLink)
        }
        cursorShape: root.hoveredLink ?
                         Qt.PointingHandCursor :
                         Qt.ArrowCursor
    }

    Loader {
        id: loader

        property alias isOutgoing: root.isOutgoing
        property alias isGenerated: root.isGenerated
        readonly property var author: Author
        readonly property var body: Body

        width: root.width
        height: sourceComponent.height

        sourceComponent: {
            switch (Type) {
            case Interaction.Type.CALL:
            case Interaction.Type.CONTACT:
                return generatedMsgComp
            case Interaction.Type.DATA_TRANSFER:
                if (Status === Interaction.Status.TRANSFER_FINISHED) {
                    if (isLocalImage)
                        return dataMsgComp
                    else
                        return txtMsgComp
                } else {
                    return txtMsgComp
                }
            case Interaction.Type.TEXT:
                return txtMsgComp
            default:
                // if this happens, adjust FilteredMsgListModel
                console.warn("Invalid message type has not been filtered.")
                return null
            }
        }
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
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }

            bottomPadding: 12
        }
    }

    Component {
        id: dataMsgComp

        SBSMessageBase {
            isOutgoing: root.isOutgoing
            showTime: root.showTime
            seq: root.seq
            author: root.author
            bubbleVisible: false
            innerContent.children: [
                AnimatedImage {
                    id: img
                    anchors.right: isOutgoing ? parent.right : undefined
                    property real minSize: 192
                    property real maxSize: 320
                    cache: true
                    fillMode: Image.PreserveAspectCrop
                    mipmap: true
                    antialiasing: true
                    autoTransform: true
                    source: "file:///" + body
                    property real aspectRatio: implicitWidth / implicitHeight
                    property real adjustedWidth: Math.min(maxSize,
                                                          Math.max(minSize,
                                                                   parent.width - senderMargin))
                    width: adjustedWidth
                    height: Math.ceil(adjustedWidth / aspectRatio)
                    Rectangle {
                        color: JamiTheme.previewImageBackgroundColor
                        z: -1
                        anchors.fill: parent
                    }
                    layer.enabled: true
                    layer.effect: OpacityMask {
                        maskSource: MessageBubble {
                            out: isOutgoing
                            type: seq
                            width: innerContent.width
                            height: innerContent.height
                            radius: msgRadius
                        }
                    }
                }
            ]
        }
    }

    Component {
        id: txtMsgComp

        SBSMessageBase {
            readonly property bool isRemoteImage: MessagesAdapter.isRemoteImage(Body)
            isOutgoing: root.isOutgoing
            showTime: root.showTime
            seq: root.seq
            author: root.author
            extraHeight: extraContent.active ? msgRadius : 0
            innerContent.children: [
                TextEdit {
                    id: messageText
                    padding: 10
                    anchors.right: isOutgoing ? parent.right : undefined
                    text: '<span style="white-space: pre-wrap">' + body + '</span>'
                    width: {
                        if (extraContent.active)
                            Math.max(extraContent.width,
                                     Math.min(implicitWidth - avatarBlockWidth,
                                              extraContent.minSize) - senderMargin)
                        else
                            Math.min(implicitWidth, innerContentWidth - senderMargin)
                    }
                    height: implicitHeight
                    wrapMode: Label.WrapAtWordBoundaryOrAnywhere
                    selectByMouse: true
                    font.pointSize: 11
                    font.hintingPreference: Font.PreferNoHinting
                    renderType: Text.NativeRendering
                    textFormat: TextEdit.RichText
                    onLinkHovered: root.hoveredLink = hoveredLink
                    readOnly: true
                    color: isOutgoing ?
                               JamiTheme.messageOutTxtColor :
                               JamiTheme.messageInTxtColor
                }
                ,
                Loader {
                    id: extraContent
                    width: sourceComponent.width
                    height: sourceComponent.height
                    anchors.right: isOutgoing ? parent.right : undefined
                    property real minSize: 192
                    property real maxSize: 320
                    active: linkPreviewInfo.url !== undefined && !isRemoteImage
                    sourceComponent: ColumnLayout {
                        id: previewContent
                        spacing: 12
                        HoverHandler {
                            target : previewContent
                            onHoveredChanged: {
                                root.hoveredLink = hovered ? linkPreviewInfo.url : ""
                            }
                            cursorShape: Qt.PointingHandCursor
                        }
                        Image {
                            id: img
                            cache: true
                            source: linkPreviewInfo.image !== null ?
                                        linkPreviewInfo.image :
                                        ""
                            fillMode: Image.PreserveAspectCrop
                            mipmap: true
                            antialiasing: true
                            property real aspectRatio: implicitWidth / implicitHeight
                            property real adjustedWidth: Math.min(extraContent.maxSize,
                                                                  Math.max(extraContent.minSize,
                                                                           innerContentWidth - senderMargin))
                            autoTransform: true
                            Layout.preferredWidth: adjustedWidth
                            Layout.preferredHeight: Math.ceil(adjustedWidth / aspectRatio)
                            Rectangle {
                                color: JamiTheme.previewImageBackgroundColor
                                z: -1
                                anchors.fill: parent
                            }
                        }
                        Column {
                            opacity: img.status !== Image.Loading
                            Layout.preferredWidth: img.width - 2 * hMargin
                            Layout.leftMargin: hMargin
                            Layout.rightMargin: hMargin
                            spacing: 6
                            Label {
                                width: parent.width
                                font.pointSize: 10
                                font.hintingPreference: Font.PreferNoHinting
                                wrapMode: Label.WrapAtWordBoundaryOrAnywhere
                                renderType: Text.NativeRendering
                                textFormat: TextEdit.RichText
                                color: JamiTheme.previewTitleColor
                                text: linkPreviewInfo.title
                            }
                            Label {
                                width: parent.width
                                font.pointSize: 11
                                font.hintingPreference: Font.PreferNoHinting
                                wrapMode: Label.WrapAtWordBoundaryOrAnywhere
                                renderType: Text.NativeRendering
                                textFormat: TextEdit.RichText
                                color: JamiTheme.previewSubtitleColor
                                visible: linkPreviewInfo.description !== null
                                text: '<a href=" " style="text-decoration: ' +
                                      ( hoveredLink ? 'underline' : 'none') + ';"' +
                                      '>' + linkPreviewInfo.description + '</a>'
                            }
                            Label {
                                width: parent.width
                                font.pointSize: 10
                                font.hintingPreference: Font.PreferNoHinting
                                wrapMode: Label.WrapAtWordBoundaryOrAnywhere
                                renderType: Text.NativeRendering
                                textFormat: TextEdit.RichText
                                color: JamiTheme.previewSubtitleColor
                                text: linkPreviewInfo.domain
                            }
                        }
                    }
                }
            ]
            Component.onCompleted: {
                if (!Linkified && !isRemoteImage) {
                    MessagesAdapter.parseMessageUrls(Id, Body)
                }
            }
        }
    }

    opacity: 0
    Behavior on opacity { NumberAnimation { duration: 40 } }
    Component.onCompleted: opacity = 1
}
