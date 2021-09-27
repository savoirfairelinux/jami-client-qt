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
        id: itemMouseArea
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        onClicked: {
            if (root.hoveredLink)
                Qt.openUrlExternally(root.hoveredLink)
        }
    }

    Loader {
        id: loader

        width: root.width
        height: sourceComponent.height

        sourceComponent: {
            switch (Type) {
            case Interaction.Type.TEXT: return txtMsgComp
            case Interaction.Type.CALL:
            case Interaction.Type.CONTACT: return generatedMsgComp
            case Interaction.Type.DATA_TRANSFER:
                if (Status === Interaction.Status.TRANSFER_FINISHED &&
                        isLocalImage) { // or A/V
                    return localMediaMsgComp
                } else {
                    return dataTransferMsgComp
                }
            default:
                // if this happens, adjust FilteredMsgListModel
                console.warn("Invalid message type has not been filtered.")
                return null
            }
        }
    }

    Component {
        id: txtMsgComp

        SBSMessageBase {
            readonly property bool isRemoteImage: MessagesAdapter.isRemoteImage(Body)
            property real maxMsgWidth: root.width - senderMargin - 2 * hMargin - avatarBlockWidth
            isOutgoing: root.isOutgoing
            showTime: root.showTime
            seq: root.seq
            author: root.author
            formattedTime: root.formattedTime
            extraHeight: extraContent.active ? msgRadius : 0
            innerContent.children: [
                TextEdit {
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
                    onLinkActivated: Qt.openUrlExternally(hoveredLink)
                    readOnly: true
                    color: isOutgoing ?
                               JamiTheme.messageOutTxtColor :
                               JamiTheme.messageInTxtColor
                },
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
                            target: previewContent
                            onHoveredChanged: {
                                root.hoveredLink = hovered ? linkPreviewInfo.url : ""
                            }
                            cursorShape: Qt.PointingHandCursor
                        }
                        Image {
                            id: img
                            cache: true
                            source: hasImage ? linkPreviewInfo.image : ""
                            fillMode: Image.PreserveAspectCrop
                            mipmap: true
                            antialiasing: true
                            readonly property bool hasImage: linkPreviewInfo.image !== null
                            property real aspectRatio: implicitWidth / implicitHeight
                            property real adjustedWidth: Math.min(extraContent.maxSize,
                                                                  Math.max(extraContent.minSize,
                                                                           maxMsgWidth))
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
                                visible: linkPreviewInfo.title !== null
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

    Component {
        id: generatedMsgComp

        Column {
            width: root.width
            spacing: 2

            Label {
                width: parent.width
                text: body
                horizontalAlignment: Qt.AlignHCenter
                font.pointSize: 12
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
                    font.pointSize: 9

                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }

            bottomPadding: 12
        }
    }

    Component {
        id: dataTransferMsgComp

        SBSMessageBase {
            id: dataTransferItem
            property var transferStats: MessagesAdapter.getTransferStats(Id, Status)
            property bool canOpen: Status === Interaction.Status.TRANSFER_FINISHED || isOutgoing
            property real maxMsgWidth: root.width - senderMargin -
                                       2 * hMargin - avatarBlockWidth
                                       - buttonsLoader.width - 24 - 6 - 24
            isOutgoing: root.isOutgoing
            showTime: root.showTime
            seq: root.seq
            author: root.author
            formattedTime: root.formattedTime
            extraHeight: progressBar.visible ? 18 : 0
            innerContent.children: [
                RowLayout {
                    id: transferItem
                    spacing: 6
                    anchors.right: isOutgoing ? parent.right : undefined
                    HoverHandler {
                        target: parent
                        enabled: canOpen
                        onHoveredChanged: {
                            root.hoveredLink = enabled && hovered ?
                                        ("file:///" + body) :
                                        ""
                        }
                        cursorShape: enabled ?
                                         Qt.PointingHandCursor :
                                         Qt.ArrowCursor
                    }
                    Loader {
                        id: buttonsLoader

                        property string iconSourceA
                        property string iconSourceB

                        Layout.margins: 12

                        sourceComponent: {
                            switch (Status) {
                            case Interaction.Status.TRANSFER_CANCELED:
                            case Interaction.Status.TRANSFER_ERROR:
                            case Interaction.Status.TRANSFER_UNJOINABLE_PEER:
                            case Interaction.Status.TRANSFER_TIMEOUT_EXPIRED:
                                iconSourceA = JamiResources.error_outline_black_24dp_svg
                                return terminatedComp
                            case Interaction.Status.TRANSFER_CREATED:
                            case Interaction.Status.TRANSFER_FINISHED:
                                iconSourceA = JamiResources.link_black_24dp_svg
                                return terminatedComp
                            case Interaction.Status.TRANSFER_AWAITING_HOST:
                                iconSourceA = JamiResources.download_black_24dp_svg
                                iconSourceB = JamiResources.close_black_24dp_svg
                                return optionsComp
                            case Interaction.Status.TRANSFER_ONGOING:
                                iconSourceA = JamiResources.close_black_24dp_svg
                                return optionsComp
                            default:
                                iconSourceA = JamiResources.error_outline_black_24dp_svg
                                return terminatedComp
                            }
                        }
                        Component {
                            id: terminatedComp
                            ResponsiveImage {
                                source: buttonsLoader.iconSourceA
                                Layout.leftMargin: 12
                                Layout.preferredWidth: 24
                                Layout.preferredHeight: 24
                            }
                        }
                        Component {
                            id: optionsComp
                            ColumnLayout {
                                Layout.leftMargin: 12
                                PushButton {
                                    source: buttonsLoader.iconSourceA
                                    normalColor: JamiTheme.chatviewBgColor
                                    imageColor: JamiTheme.chatviewButtonColor
                                    onClicked: {
                                        switch (Status) {
                                        case Interaction.Status.TRANSFER_ONGOING:
                                            return MessagesAdapter.cancelFile(Id)
                                        case Interaction.Status.TRANSFER_AWAITING_HOST:
                                            return MessagesAdapter.acceptFile(Id)
                                        default: break
                                        }
                                    }
                                }
                                PushButton {
                                    visible: !CurrentConversation.isSwarm//source !== ""
                                    height: visible * implicitHeight
                                    source: buttonsLoader.iconSourceB
                                    normalColor: JamiTheme.chatviewBgColor
                                    imageColor: JamiTheme.chatviewButtonColor
                                    onClicked: {
                                        switch (Status) {
                                        case Interaction.Status.TRANSFER_AWAITING_HOST:
                                            return MessagesAdapter.cancelFile(Id)
                                        default: break
                                        }
                                    }
                                }
                            }
                        }
                    }
                    Column {
                        Layout.rightMargin: 24
                        spacing: 6
                        TextEdit {
                            id: transferName
                            width: Math.min(implicitWidth, maxMsgWidth)
                            topPadding: 10
                            text: CurrentConversation.isSwarm ?
                                      TransferName :
                                      body
                            wrapMode: Label.WrapAtWordBoundaryOrAnywhere
                            font.weight: Font.DemiBold
                            font.pointSize: 11
                            renderType: Text.NativeRendering
                            readOnly: true
                            color: isOutgoing ?
                                       JamiTheme.messageOutTxtColor :
                                       JamiTheme.messageInTxtColor
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: canOpen ?
                                                 Qt.PointingHandCursor :
                                                 Qt.ArrowCursor
                                onClicked: if(canOpen) itemMouseArea.clicked(mouse)
                            }
                        }
                        Label {
                            id: transferInfo
                            width: Math.min(implicitWidth, maxMsgWidth)
                            bottomPadding: 10
                            text: {
                                var res = formattedTime + " - "
                                if (transferStats.totalSize !== undefined) {
                                    if (transferStats.progress !== 0 &&
                                            transferStats.progress !== transferStats.totalSize) {
                                        res += UtilsAdapter.humanFileSize(transferStats.progress) + " / "
                                    }
                                    res += UtilsAdapter.humanFileSize(transferStats.totalSize)
                                }
                                return res + " - " + MessagesAdapter.getStatusString(Status)
                            }
                            wrapMode: Label.WrapAtWordBoundaryOrAnywhere
                            font.pointSize: 10
                            renderType: Text.NativeRendering
                            color: Qt.lighter((isOutgoing ?
                                       JamiTheme.messageOutTxtColor :
                                       JamiTheme.messageInTxtColor), 1.5)
                        }
                    }
                }
                ,ProgressBar {
                    id: progressBar
                    visible: Status === Interaction.Status.TRANSFER_ONGOING
                    height: visible * implicitHeight
                    value: transferStats.progress / transferStats.totalSize
                    width: transferItem.width
                    anchors.right: isOutgoing ? parent.right : undefined
                }
            ]
        }
    }

    Component {
        id: localMediaMsgComp

        SBSMessageBase {
            isOutgoing: root.isOutgoing
            showTime: root.showTime
            seq: root.seq
            author: root.author
            formattedTime: root.formattedTime
            bubbleVisible: false
            innerContent.children: [
                AnimatedImage {
                    id: img
                    anchors.right: isOutgoing ? parent.right : undefined
                    property real minSize: 192
                    property real maxSize: 256
                    cache: true
                    fillMode: Image.PreserveAspectCrop
                    mipmap: true
                    antialiasing: true
                    autoTransform: false
                    asynchronous: true
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
                            width: img.width
                            height: img.height
                            radius: msgRadius
                        }
                    }
                    HoverHandler {
                        target : parent
                        onHoveredChanged: {
                            root.hoveredLink = hovered ? img.source : ""
                        }
                        cursorShape: Qt.PointingHandCursor
                    }
                }
            ]
        }
    }

    opacity: 0
    Behavior on opacity { NumberAnimation { duration: 40 } }
    Component.onCompleted: opacity = 1
}
