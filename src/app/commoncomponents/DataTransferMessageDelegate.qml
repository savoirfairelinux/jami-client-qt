/*
 * Copyright (C) 2021-2023 Savoir-faire Linux Inc.
 * Author: Trevor Tabah <trevor.tabah@savoirfairelinux.com>
 * Author: Andreas Traczyk <andreas.traczyk@savoirfairelinux.com>
 * Author: Mingrui Zhang <mingrui.zhang@savoirfairelinux.com>
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
import net.jami.Constants 1.1
import net.jami.Adapters 1.1

Loader {
    id: root

    property var mediaInfo
    property bool showTime
    property bool showDay
    property int timestamp: Timestamp
    property string formattedTime: MessagesAdapter.getFormattedTime(Timestamp)
    property string formattedDay: MessagesAdapter.getFormattedDay(Timestamp)

    property int seq: MsgSeq.single
    property string author: Author

    width: ListView.view ? ListView.view.width : 0

    sourceComponent: {
        if (Status === Interaction.Status.TRANSFER_FINISHED) {
            mediaInfo = MessagesAdapter.getMediaInfo(Body)
            if (Object.keys(mediaInfo).length !== 0 && WITH_WEBENGINE)
                return localMediaMsgComp
        }
        return dataTransferMsgComp
    }

    opacity: 0
    Behavior on opacity { NumberAnimation { duration: 100 } }
    onLoaded: opacity = 1

    Component {
        id: dataTransferMsgComp

        SBSMessageBase {
            id: dataTransferItem

            property var transferStats: MessagesAdapter.getTransferStats(Id, Status)
            property bool canOpen: Status === Interaction.Status.TRANSFER_FINISHED || isOutgoing
            property real maxMsgWidth: root.width - senderMargin -
                                       2 * hPadding - avatarBlockWidth
                                       - buttonsLoader.width - 24 - 6 - 24

            isOutgoing: Author === CurrentAccount.uri
            showTime: root.showTime
            seq: root.seq
            author: Author
            location: Body
            transferName: TransferName
            transferId: Id
            readers: Readers
            timestamp: root.timestamp
            formattedTime: root.formattedTime
            formattedDay: root.formattedTime
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
                            if (enabled && hovered) {
                                dataTransferItem.hoveredLink = UtilsAdapter.urlFromLocalPath(Body)
                            } else {
                                dataTransferItem.hoveredLink = ""
                            }
                        }
                        cursorShape: enabled ?
                                         Qt.PointingHandCursor :
                                         Qt.ArrowCursor
                    }
                    Loader {
                        id: buttonsLoader

                        property string iconSourceA
                        property string iconSourceB

                        Layout.margins: 9

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

                            Control {
                                width: 50
                                height: 50
                                padding: 13

                                background: Rectangle {
                                    color: JamiTheme.blackColor
                                    opacity: 0.15
                                    radius: msgRadius
                                }

                                contentItem: ResponsiveImage {
                                    source: buttonsLoader.iconSourceA
                                    color: JamiTheme.fileIconColor
                                }
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
                                    visible: !CurrentConversation.isSwarm
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
                        spacing: 4
                        TextEdit {
                            id: transferName

                            width: Math.min(implicitWidth, maxMsgWidth)
                            topPadding: 10
                            text: CurrentConversation.isSwarm ?
                                      TransferName :
                                      Body
                            wrapMode: Label.WrapAtWordBoundaryOrAnywhere
                            font.pointSize: 11
                            renderType: Text.NativeRendering
                            readOnly: true
                            color: UtilsAdapter.luma(bubble.color)
                                   ? JamiTheme.chatviewTextColorLight
                                   : JamiTheme.chatviewTextColorDark
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: canOpen ?
                                                 Qt.PointingHandCursor :
                                                 Qt.ArrowCursor
                                onClicked: function (mouse) {
                                    if (canOpen) {
                                        dataTransferItem.hoveredLink = UtilsAdapter.urlFromLocalPath(Body)
                                        Qt.openUrlExternally(new Url(dataTransferItem.hoveredLink))
                                    } else {
                                        dataTransferItem.hoveredLink = ""
                                    }
                                }
                            }
                        }
                        Label {
                            id: transferInfo

                            width: Math.min(implicitWidth, maxMsgWidth)
                            bottomPadding: 10
                            text: {
                                var res = ""
                                if (transferStats.totalSize !== undefined) {
                                    if (transferStats.progress !== 0 &&
                                            transferStats.progress !== transferStats.totalSize) {
                                        res += UtilsAdapter.humanFileSize(transferStats.progress) + " / "
                                    }
                                    var totalSize = transferStats.totalSize !== 0 ? transferStats.totalSize : TotalSize
                                    res += UtilsAdapter.humanFileSize(totalSize)
                                }
                                return res
                            }
                            wrapMode: Label.WrapAtWordBoundaryOrAnywhere
                            font.pointSize: 10
                            renderType: Text.NativeRendering
                            color: UtilsAdapter.luma(bubble.color)
                                   ? JamiTheme.chatviewTextColorLight
                                   : JamiTheme.chatviewTextColorDark
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
            id: localMediaMsgItem

            isOutgoing: Author === CurrentAccount.uri
            property var transferStats: MessagesAdapter.getTransferStats(Id, Status)
            showTime: root.showTime
            seq: root.seq
            author: Author
            location: Body
            transferName: TransferName
            transferId: Id
            readers: Readers
            formattedTime: MessagesAdapter.getFormattedTime(Timestamp)
            formattedDay: MessagesAdapter.getFormattedDay(Timestamp)

            Component.onCompleted: {
                if (transferStats.totalSize !== undefined) {
                    var totalSize = transferStats.totalSize !== 0 ? transferStats.totalSize : TotalSize
                    var txt = UtilsAdapter.humanFileSize(totalSize)
                }
                bubble.timestampItem.timeLabel.text += " - " + txt

                bubble.color = "transparent"
                bubble.timestampItem.timeColor = JamiTheme.whiteColor
                bubble.z = 1

            }

            innerContent.children: [
                Loader {
                    id: localMediaCompLoader

                    anchors.right: isOutgoing ? parent.right : undefined
                    asynchronous: true
                    width: sourceComponent.width
                    height: sourceComponent.height
                    sourceComponent: {
                        if (mediaInfo.isImage)
                            return imageComp
                        if (mediaInfo.isAnimatedImage)
                            return animatedImageComp
                        return avComp
                    }
                    Component {
                        id: avComp

                        Loader {
                            Component.onCompleted: {
                                var qml = WITH_WEBENGINE ?
                                            "qrc:/webengine/MediaPreviewBase.qml" :
                                            "qrc:/nowebengine/MediaPreviewBase.qml"
                                setSource( qml, { isVideo: mediaInfo.isVideo, html:mediaInfo.html } )
                            }
                        }
                    }
                    Component {
                        id: animatedImageComp

                        AnimatedImage {
                            id: animatedImg

                            anchors.right: isOutgoing ? parent.right : undefined
                            property real minSize: 192
                            property real maxSize: 256
                            cache: false
                            fillMode: Image.PreserveAspectCrop
                            mipmap: true
                            antialiasing: true
                            autoTransform: true
                            asynchronous: true
                            source: UtilsAdapter.urlFromLocalPath(Body)
                            property real aspectRatio: implicitWidth / implicitHeight
                            property real adjustedWidth: Math.min(maxSize,
                                                                  Math.max(minSize,
                                                                           innerContent.width - senderMargin))
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
                                    width: animatedImg.width
                                    height: animatedImg.height
                                    radius: msgRadius
                                }
                            }
                            HoverHandler {
                                target : parent
                                onHoveredChanged: {
                                    localMediaMsgItem.hoveredLink = hovered ? animatedImg.source : ""
                                }
                                cursorShape: Qt.PointingHandCursor
                            }
                        }
                    }

                    Component {
                        id: imageComp

                        Image {
                            id: img

                            anchors.right: isOutgoing ? parent.right : undefined
                            cache: true
                            fillMode: Image.PreserveAspectFit
                            mipmap: true
                            antialiasing: true
                            autoTransform: true
                            asynchronous: true
                            source: Body !== undefined ? UtilsAdapter.urlFromLocalPath(Body) : ''

                            // The sourceSize represents the maximum source dimensions.
                            // This should not be a dynamic binding, as property changes
                            // (resizing the chat view) here will trigger a reload of the image.
                            sourceSize: Qt.size(256, 256)

                            // Now we setup bindings for the destination image component size.
                            // This based on the width available (width of the chat view), and
                            // a restriction on the height.
                            readonly property real aspectRatio: paintedWidth / paintedHeight
                            readonly property real idealWidth: innerContent.width - senderMargin
                            onStatusChanged: {
                                if (status == Image.Ready && aspectRatio) {
                                    height = Qt.binding(() => JamiQmlUtils.clamp(idealWidth / aspectRatio, 64, 256))
                                    width = Qt.binding(() => height * aspectRatio)
                                }
                            }

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
                                    localMediaMsgItem.hoveredLink = hovered ? img.source : ""
                                }
                                cursorShape: Qt.PointingHandCursor
                            }
                        }
                    }
                }
            ]
        }
    }
}
