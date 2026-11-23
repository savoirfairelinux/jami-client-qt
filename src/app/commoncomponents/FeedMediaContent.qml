/*
 * Copyright (C) 2026 Savoir-faire Linux Inc.
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

// The file of a feed post or comment: finished images and video stills inline, other files as a row.
Loader {
    id: root

    property string transferId
    property string tid
    property string author
    property string path
    property string transferName
    property int transferStatus
    property real totalSize
    property real maxMediaHeight: JamiTheme.maxImageHeight

    readonly property bool isFinished: transferStatus === Interaction.TransferStatus.TRANSFER_FINISHED
    readonly property var mediaInfo: isFinished ? MessagesAdapter.getMediaInfo(path) : ({})
    // Videos are shown as a still frame and played externally.
    readonly property bool isVideoStill: !!mediaInfo.isVideo
    readonly property bool isImage: !!mediaInfo.isImage || !!mediaInfo.isAnimatedImage || isVideoStill
    readonly property string fileUrl: UtilsAdapter.urlFromLocalPath(path)

    sourceComponent: tid === "" ? deletedComp : (isImage ? imageComp : fileComp)

    Component {
        id: deletedComp

        Label {
            text: JamiStrings.deletedMedia.arg(UtilsAdapter.getBestNameForUri(CurrentAccount.id, root.author))
            color: JamiTheme.textColor
            opacity: 0.5
            font.pointSize: JamiTheme.smallFontSize
            wrapMode: Text.Wrap
        }
    }

    Component {
        id: imageComp

        Item {
            objectName: "feedMediaImage"

            readonly property Item img: imgLoader.item
            readonly property bool ready: img !== null && img.status === Image.Ready && img.implicitWidth > 0 && img.implicitHeight > 0
            // Whole image, scaled down (never up) to fit the post's width and the height cap.
            readonly property real fitScale: ready ? Math.min(1, root.width / img.implicitWidth, root.maxMediaHeight / img.implicitHeight) : 1

            implicitHeight: ready ? Math.ceil(img.implicitHeight * fitScale) : 160

            Rectangle {
                id: frame
                objectName: "feedMediaFrame"

                width: parent.ready ? Math.ceil(parent.img.implicitWidth * parent.fitScale) : parent.width
                height: parent.height
                radius: JamiTheme.feedPostRadius
                color: JamiTheme.messageInBgColor
                // clip ignores radius; the mask rounds the corners.
                layer.enabled: true
                layer.effect: OpacityMask {
                    maskSource: Rectangle {
                        width: frame.width
                        height: frame.height
                        radius: frame.radius
                    }
                }

                Loader {
                    id: imgLoader

                    anchors.fill: parent
                    // AnimatedImage ignores EXIF orientation, so stills use Image.
                    sourceComponent: root.mediaInfo.isAnimatedImage ? animatedComp : stillComp
                }
            }

            Component {
                id: stillComp

                Image {
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    mipmap: true
                    autoTransform: true
                    source: root.isVideoStill ? "image://videothumbnail/" + encodeURIComponent(root.path) : root.fileUrl
                }
            }

            Component {
                id: animatedComp

                AnimatedImage {
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    mipmap: true
                    source: root.fileUrl
                }
            }

            ResponsiveImage {
                visible: root.isVideoStill && parent.ready
                anchors.centerIn: frame
                width: 48
                height: width
                source: JamiResources.play_arrow_24dp_svg
                color: JamiTheme.whiteColor
            }

            Item {
                anchors.fill: frame

                HoverHandler {
                    cursorShape: Qt.PointingHandCursor
                }

                TapHandler {
                    onTapped: Qt.openUrlExternally(root.fileUrl)
                }
            }
        }
    }

    Component {
        id: fileComp

        Rectangle {
            id: fileRow
            objectName: "feedMediaFile"

            readonly property bool canOpen: root.isFinished || root.author === CurrentAccount.uri
            readonly property bool isOngoing: root.transferStatus === Interaction.TransferStatus.TRANSFER_ONGOING
            readonly property bool canAccept: {
                switch (root.transferStatus) {
                case Interaction.TransferStatus.TRANSFER_CANCELED:
                case Interaction.TransferStatus.TRANSFER_ERROR:
                case Interaction.TransferStatus.TRANSFER_UNJOINABLE_PEER:
                case Interaction.TransferStatus.TRANSFER_TIMEOUT_EXPIRED:
                case Interaction.TransferStatus.TRANSFER_AWAITING_HOST:
                    return true;
                default:
                    return false;
                }
            }
            property var transferStats: MessagesAdapter.getTransferStats(root.transferId, root.transferStatus)

            implicitWidth: root.width
            implicitHeight: fileLayout.implicitHeight + 16
            radius: 12
            color: JamiTheme.messageInBgColor

            Timer {
                interval: 1000
                repeat: true
                running: fileRow.isOngoing
                onTriggered: fileRow.transferStats = MessagesAdapter.getTransferStats(root.transferId, root.transferStatus)
            }

            RowLayout {
                id: fileLayout

                anchors.fill: parent
                anchors.margins: 8
                spacing: 8

                NewIconButton {
                    objectName: "feedFileActionButton"

                    iconSize: JamiTheme.iconButtonMedium
                    iconSource: fileRow.isOngoing ? JamiResources.close_black_24dp_svg
                                                  : fileRow.canAccept ? JamiResources.download_black_24dp_svg
                                                                      : JamiResources.link_black_24dp_svg
                    toolTipText: fileRow.isOngoing ? JamiStrings.cancel : fileRow.canAccept ? JamiStrings.download : JamiStrings.open
                    enabled: fileRow.isOngoing || fileRow.canAccept || fileRow.canOpen
                    onClicked: {
                        if (fileRow.isOngoing)
                            MessagesAdapter.cancelFile(root.transferId);
                        else if (fileRow.canAccept)
                            MessagesAdapter.acceptFile(root.transferId);
                        else
                            Qt.openUrlExternally(root.fileUrl);
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Label {
                        Layout.fillWidth: true
                        text: root.transferName
                        elide: Text.ElideMiddle
                        color: JamiTheme.textColor
                    }

                    Label {
                        Layout.fillWidth: true
                        text: {
                            const stats = fileRow.transferStats;
                            if (stats.totalSize === undefined)
                                return "";
                            const total = UtilsAdapter.humanFileSize(stats.totalSize !== 0 ? stats.totalSize : root.totalSize);
                            if (fileRow.isOngoing && stats.progress !== 0)
                                return UtilsAdapter.humanFileSize(stats.progress) + " / " + total;
                            return total;
                        }
                        visible: text !== ""
                        color: JamiTheme.chatviewSecondaryInformationColor
                        font.pointSize: JamiTheme.smallFontSize
                    }

                    ProgressBar {
                        Layout.fillWidth: true
                        visible: fileRow.isOngoing
                        value: fileRow.transferStats.totalSize ? fileRow.transferStats.progress / fileRow.transferStats.totalSize : 0
                    }
                }
            }
        }
    }
}
