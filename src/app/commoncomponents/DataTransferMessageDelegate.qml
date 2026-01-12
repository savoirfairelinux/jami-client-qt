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
import net.jami.Constants 1.1
import net.jami.Adapters 1.1

Loader {
    id: rootDelegate

    property var mediaInfo
    property bool showTime
    property bool showDay
    property int timestamp: Timestamp
    property string formattedTime: MessagesAdapter.getFormattedTime(rootDelegate.timestamp)
    property string formattedDay: MessagesAdapter.getFormattedDay(rootDelegate.timestamp)

    property int seq: MsgSeq.single
    property string author: Author
    property string body: Body
    property var tid: TID
    property int transferStatus: TransferStatus

    Accessible.name: {
        let name = UtilsAdapter.getBestNameForUri(CurrentAccount.id, Author);
        return JamiStrings.dataTransfer + name + ": " + JamiStrings.status + TransferStatus + Body + " " + formattedTime + " " + formattedDay;
    }
    Accessible.description: {
        let status = "";
        if (IsLastSent)
            status += JamiStrings.sent + " ";
        return status;
    }

    onTidChanged: {
        if (tid === "") {
            sourceComponent = deletedMsgComp;
        }
    }
    onTransferStatusChanged: {
        if (tid === "") {
            sourceComponent = deletedMsgComp;
            return;
        } else if (transferStatus === Interaction.TransferStatus.TRANSFER_FINISHED) {
            mediaInfo = MessagesAdapter.getMediaInfo(rootDelegate.body);
            if (Object.keys(mediaInfo).length !== 0 && WITH_WEBENGINE) {
                sourceComponent = localMediaMsgComp;
                return;
            }
        }
        sourceComponent = dataTransferMsgComp;
    }

    width: ListView.view ? ListView.view.width : 0

    opacity: 0
    Behavior on opacity {
        NumberAnimation {
            duration: 100
        }
    }
    onLoaded: opacity = 1

    Component {
        id: deletedMsgComp

        SBSMessageBase {
            id: deletedItem

            isOutgoing: Author === CurrentAccount.uri
            showTime: rootDelegate.showTime
            seq: rootDelegate.seq
            author: Author
            readers: Readers
            timestamp: rootDelegate.timestamp
            formattedTime: rootDelegate.formattedTime
            formattedDay: rootDelegate.formattedTime
            extraHeight: 0
            textContentWidth: textEditId.width
            textContentHeight: textEditId.height
            innerContent.children: [
                TextEdit {
                    id: textEditId

                    anchors.right: isOutgoing ? parent.right : undefined
                    anchors.rightMargin: isOutgoing ? timeWidth : 0
                    bottomPadding: 6
                    topPadding: 6
                    leftPadding: 10
                    text: JamiStrings.deletedMedia.arg(UtilsAdapter.getBestNameForUri(CurrentAccount.id, Author))
                    horizontalAlignment: Text.AlignLeft
                    width: Math.min((2 / 3) * parent.width, implicitWidth + 18, innerContent.width - senderMargin + 18)

                    font.pointSize: JamiTheme.smallFontSize
                    font.hintingPreference: Font.PreferNoHinting
                    renderType: Text.NativeRendering
                    textFormat: Text.RichText
                    clip: true
                    readOnly: true
                    color: getBaseColor()
                    opacity: 0.5

                    function getBaseColor() {
                        bubble.isDeleted = true;
                        return UtilsAdapter.luma(bubble.color) ? "white" : "dark";
                    }
                }
            ]
        }
    }

    Component {
        id: dataTransferMsgComp

        SBSMessageBase {
            id: dataTransferItem

            transferId: Id
            property var transferStats: MessagesAdapter.getTransferStats(transferId, rootDelegate.transferStatus)
            property bool canOpen: rootDelegate.transferStatus === Interaction.TransferStatus.TRANSFER_FINISHED || isOutgoing
            property real maxMsgWidth: rootDelegate.width - senderMargin - 2 * hPadding - avatarBlockWidth - buttonsLoader.width - 24 - 6 - 24

            // Timer to update the translation bar
            Loader {
                id: timerLoader
                active: rootDelegate.transferStatus === Interaction.TransferStatus.TRANSFER_ONGOING
                sourceComponent: Timer {
                    interval: 1000 // Update every second
                    running: true
                    repeat: true
                    onTriggered: {
                        transferStats = MessagesAdapter.getTransferStats(transferId, rootDelegate.transferStatus);
                    }
                }
            }

            isOutgoing: Author === CurrentAccount.uri
            showTime: rootDelegate.showTime
            seq: rootDelegate.seq
            author: Author
            location: Body
            transferName: TransferName
            readers: Readers
            timestamp: rootDelegate.timestamp
            formattedTime: rootDelegate.formattedTime
            formattedDay: rootDelegate.formattedTime
            extraHeight: progressBar.visible ? 25 : 0

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
                                dataTransferItem.hoveredLink = UtilsAdapter.urlFromLocalPath(location);
                            } else {
                                dataTransferItem.hoveredLink = "";
                            }
                        }
                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    }
                    Loader {
                        id: buttonsLoader
                        objectName: "buttonsLoader"

                        property string iconSource

                        Layout.margins: 8

                        sourceComponent: {
                            switch (rootDelegate.transferStatus) {
                            case Interaction.TransferStatus.TRANSFER_CREATED:
                            case Interaction.TransferStatus.TRANSFER_FINISHED:
                                iconSource = JamiResources.link_black_24dp_svg;
                                return terminatedComp;
                            case Interaction.TransferStatus.TRANSFER_CANCELED:
                            case Interaction.TransferStatus.TRANSFER_ERROR:
                            case Interaction.TransferStatus.TRANSFER_UNJOINABLE_PEER:
                            case Interaction.TransferStatus.TRANSFER_TIMEOUT_EXPIRED:
                            case Interaction.TransferStatus.TRANSFER_AWAITING_HOST:
                                iconSource = JamiResources.download_black_24dp_svg;
                                return optionsComp;
                            case Interaction.TransferStatus.TRANSFER_ONGOING:
                                iconSource = JamiResources.close_black_24dp_svg;
                                return optionsComp;
                            default:
                                iconSource = JamiResources.error_outline_black_24dp_svg;
                                return terminatedComp;
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
                                    if (rootDelegate.transferStatus === Interaction.TransferStatus.TRANSFER_ONGOING) {
                                        MessagesAdapter.cancelFile(transferId);
                                    } else {
                                        buttonsLoader.iconSource = JamiResources.connecting_black_24dp_svg;
                                        MessagesAdapter.acceptFile(transferId);
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
                            text: CurrentConversation.isSwarm ? transferName : location
                            wrapMode: Label.WrapAtWordBoundaryOrAnywhere
                            font.pointSize: 11
                            renderType: Text.NativeRendering
                            readOnly: true
                            color: UtilsAdapter.luma(bubble.color) ? JamiTheme.chatviewTextColorLight : JamiTheme.chatviewTextColorDark
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: canOpen ? Qt.PointingHandCursor : Qt.ArrowCursor
                                onClicked: function (mouse) {
                                    if (canOpen) {
                                        dataTransferItem.hoveredLink = UtilsAdapter.urlFromLocalPath(location);
                                        Qt.openUrlExternally(new URL(dataTransferItem.hoveredLink));
                                    } else {
                                        dataTransferItem.hoveredLink = "";
                                    }
                                }
                            }
                        }
                        Label {
                            id: transferInfo

                            bottomPadding: 10
                            rightPadding: dataTransferItem.bubble.timestampItem.width

                            text: {
                                var res = "";
                                if (transferStats.totalSize !== undefined) {
                                    if (transferStats.progress !== 0 && transferStats.progress !== transferStats.totalSize) {
                                        res += UtilsAdapter.humanFileSize(transferStats.progress) + " / ";
                                    }
                                    var totalSize = transferStats.totalSize !== 0 ? transferStats.totalSize : TotalSize;
                                    res += UtilsAdapter.humanFileSize(totalSize);
                                }
                                return res;
                            }
                            wrapMode: Label.WrapAtWordBoundaryOrAnywhere
                            font.pointSize: 10
                            renderType: Text.NativeRendering
                            color: UtilsAdapter.luma(bubble.color) ? JamiTheme.chatviewTextColorLight : JamiTheme.chatviewTextColorDark
                        }
                    }
                },
                ProgressBar {
                    id: progressBar

                    visible: rootDelegate.transferStatus === Interaction.TransferStatus.TRANSFER_ONGOING
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
            property var transferStats: MessagesAdapter.getTransferStats(transferId, rootDelegate.transferStatus)
            showTime: rootDelegate.showTime
            seq: rootDelegate.seq
            author: Author
            location: Body
            transferName: TransferName
            readers: Readers
            formattedTime: MessagesAdapter.getFormattedTime(rootDelegate.timestamp)
            formattedDay: MessagesAdapter.getFormattedDay(rootDelegate.timestamp)

            property real contentWidth

            Component.onCompleted: {
                if (transferStats.totalSize !== undefined) {
                    var totalSize = transferStats.totalSize !== 0 ? transferStats.totalSize : TotalSize;
                    var txt = UtilsAdapter.humanFileSize(totalSize);
                }
                bubble.timestampItem.timeLabel.text += " - " + txt;
                bubble.color = "transparent";
                if (mediaInfo.isImage)
                    bubble.z = 1;
                else
                    timeUnderBubble = true;
            }

            onContentWidthChanged: {
                if (bubble.timestampItem.timeLabel.width > contentWidth)
                    timeUnderBubble = true;
                else {
                    bubble.timestampItem.timeColor = JamiTheme.whiteColor;
                    bubble.timestampItem.timeLabel.opacity = 1;
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
                            return imageComp;
                        if (mediaInfo.isAnimatedImage)
                            return animatedImageComp;
                        return avComp;
                    }

                    Component {
                        id: avComp

                        Loader {
                            Component.onCompleted: {
                                var qml = WITH_WEBENGINE ? "qrc:/webengine/MediaPreviewBase.qml" : "qrc:/nowebengine/MediaPreviewBase.qml";
                                setSource(qml, {
                                        isVideo: mediaInfo.isVideo,
                                        html: mediaInfo.html
                                    });
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
                            property real adjustedWidth: Math.min(maxSize, Math.max(minSize, innerContent.width - senderMargin))
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
                                localMediaMsgItem.contentWidth = width;
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

                        Rectangle {
                            border.color: img.useBox ? (JamiTheme.darkTheme ? "white" : JamiTheme.blackColor) : JamiTheme.transparentColor
                            color: JamiTheme.transparentColor
                            anchors.right: isOutgoing ? parent.right : undefined
                            border.width: 1
                            radius: msgRadius

                            implicitWidth: img.width + (img.useBox ? 20 : 0)
                            implicitHeight: img.height + (img.useBox ? 20 : 0)
                            onWidthChanged: {
                                localMediaMsgItem.contentWidth = width;
                            }

                            Image {
                                id: img

                                anchors.centerIn: parent
                                cache: true
                                fillMode: Image.PreserveAspectFit
                                mipmap: true
                                antialiasing: true
                                autoTransform: true
                                asynchronous: true

                                Component.onCompleted: {
                                    source = UtilsAdapter.urlFromLocalPath(Body);
                                    localMediaMsgItem.bubble.imgSource = source;
                                }

                                // Scale down the image if it's too wide or too tall.
                                property real maxWidth: localMediaMsgItem.width - 170
                                property bool xOverflow: sourceSize.width > maxWidth
                                property bool yOverflow: sourceSize.height > JamiTheme.maxImageHeight
                                property real scaleFactor: (xOverflow || yOverflow) ? Math.min(maxWidth / sourceSize.width, JamiTheme.maxImageHeight / sourceSize.height) : 1
                                width: sourceSize.width * scaleFactor
                                height: sourceSize.height * scaleFactor

                                // Add a bounding box around the image if it's small (along at least one
                                // dimension) to ensure that it's easy for users to see it and click on it.
                                property bool useBox: (paintedWidth < 40) || (paintedHeight < 40)
                                layer.enabled: !useBox
                                layer.effect: OpacityMask {
                                    maskSource: MessageBubble {
                                        out: isOutgoing
                                        type: seq
                                        width: img.width
                                        height: img.height
                                        radius: msgRadius
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
