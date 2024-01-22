/*
 * Copyright (C) 2021-2024 Savoir-faire Linux Inc.
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
    property string formattedTime: MessagesAdapter.getFormattedTime(root.timestamp)
    property string formattedDay: MessagesAdapter.getFormattedDay(root.timestamp)

    property int seq: MsgSeq.single
    property string author: Author
    property string body: Body
    property var transferStatus: Status

    width: ListView.view ? ListView.view.width : 0

    sourceComponent: {
        if (root.transferStatus === Interaction.Status.TRANSFER_FINISHED) {
            mediaInfo = MessagesAdapter.getMediaInfo(root.body)
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

            transferId: Id
            property var transferStats: MessagesAdapter.getTransferStats(transferId, root.transferStatus)
            property bool canOpen: root.transferStatus === Interaction.Status.TRANSFER_FINISHED || isOutgoing
            property real maxMsgWidth: root.width - senderMargin -
                                       2 * hPadding - avatarBlockWidth
                                       - buttonsLoader.width - 24 - 6 - 24

            isOutgoing: Author === CurrentAccount.uri
            showTime: root.showTime
            seq: root.seq
            author: Author
            location: Body
            transferName: TransferName
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
                                dataTransferItem.hoveredLink = UtilsAdapter.urlFromLocalPath(location)
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
                        objectName: "buttonsLoader"

                        property string iconSource

                        Layout.margins: 8

                        sourceComponent: {
                            switch (root.transferStatus) {
                            case Interaction.Status.TRANSFER_CREATED:
                            case Interaction.Status.TRANSFER_FINISHED:
                                iconSource = JamiResources.link_black_24dp_svg
                                return terminatedComp
                            case Interaction.Status.TRANSFER_CANCELED:
                            case Interaction.Status.TRANSFER_ERROR:
                            case Interaction.Status.TRANSFER_UNJOINABLE_PEER:
                            case Interaction.Status.TRANSFER_TIMEOUT_EXPIRED:
                            case Interaction.Status.TRANSFER_AWAITING_HOST:
                                iconSource = JamiResources.download_black_24dp_svg
                                return optionsComp
                            case Interaction.Status.TRANSFER_ONGOING:
                                iconSource = JamiResources.close_black_24dp_svg
                                return optionsComp
                            default:
                                iconSource = JamiResources.error_outline_black_24dp_svg
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
                                    source: buttonsLoader.iconSource
                                    color: UtilsAdapter.luma(bubble.color) ? JamiTheme.fileIconLightColor : JamiTheme.fileIconDarkColor
                                }
                            }
                        }
                        Component {
                            id: optionsComp
                            PushButton {
                                source: buttonsLoader.iconSource
                                normalColor: JamiTheme.chatviewBgColor
                                imageColor: JamiTheme.chatviewButtonColor
                                onClicked: {
                                    if (root.transferStatus === Interaction.Status.TRANSFER_ONGOING) {
                                        return MessagesAdapter.cancelFile(transferId)
                                    } else {
                                        return MessagesAdapter.acceptFile(transferId)
                                    }
                                }
                            }
                        }
                    }
                    Column {
                        Layout.rightMargin: 24
                        spacing: 4
                        TextEdit {
                            width: Math.min(implicitWidth, maxMsgWidth)
                            topPadding: 10
                            text: CurrentConversation.isSwarm ?
                                      transferName :
                                      location
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
                                        dataTransferItem.hoveredLink = UtilsAdapter.urlFromLocalPath(location)
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

                    visible: root.transferStatus === Interaction.Status.TRANSFER_ONGOING
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
            transferId: Id
            property var transferStats: MessagesAdapter.getTransferStats(transferId, root.transferStatus)
            showTime: root.showTime
            seq: root.seq
            author: Author
            location: Body
            transferName: TransferName
            readers: Readers
            formattedTime: MessagesAdapter.getFormattedTime(root.timestamp)
            formattedDay: MessagesAdapter.getFormattedDay(root.timestamp)

            property real contentWidth

            Component.onCompleted: {
                if (transferStats.totalSize !== undefined) {
                    var totalSize = transferStats.totalSize !== 0 ? transferStats.totalSize : TotalSize
                    var txt = UtilsAdapter.humanFileSize(totalSize)
                }
                bubble.timestampItem.timeLabel.text += " - " + txt
                bubble.color = "transparent"
                if (mediaInfo.isImage)
                    bubble.z = 1
                else
                    timeUnderBubble = true
            }

            onContentWidthChanged: {
                if (bubble.timestampItem.timeLabel.width > contentWidth)
                    timeUnderBubble = true
                else {
                    bubble.timestampItem.timeColor = JamiTheme.whiteColor
                    bubble.timestampItem.timeLabel.opacity = 1
                }
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

                            onWidthChanged: {
                                localMediaMsgItem.contentWidth = width
                            }

                            Component.onCompleted: localMediaMsgItem.bubble.imgSource = source

                            LinearGradient {
                                id: gradient
                                anchors.fill: parent
                                start: Qt.point(0, height / 3)
                                gradient: Gradient {
                                    GradientStop {
                                        position: 0.0
                                        color: JamiTheme.transparentColor
                                    }
                                    GradientStop {
                                        position: 1.0
                                        color: JamiTheme.darkGreyColorOpacityFade
                                    }
                                }
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

                            Component.onCompleted: localMediaMsgItem.bubble.imgSource = source

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
                                if (img.status == Image.Ready && aspectRatio) {
                                    height = Qt.binding(() => JamiQmlUtils.clamp(idealWidth / aspectRatio, 64, 256))
                                    width = Qt.binding(() => height * aspectRatio)

                                }
                            }

                            onWidthChanged: {
                                localMediaMsgItem.contentWidth = width
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

                            LinearGradient {
                                id: gradient
                                anchors.fill: parent
                                start: Qt.point(0, height / 3)
                                gradient: Gradient {
                                    GradientStop {
                                        position: 0.0
                                        color: JamiTheme.transparentColor
                                    }
                                    GradientStop {
                                        position: 1.0
                                        color: JamiTheme.darkGreyColorOpacityFade
                                    }
                                }
                            }
                        }
                    }
                }
            ]
        }
    }
}
