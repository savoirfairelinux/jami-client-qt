/*
 * Copyright (C) 2026 Savoir-faire Linux Inc.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
import QtQuick
import Qt5Compat.GraphicalEffects
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import "../../commoncomponents"

Rectangle {
    id: root

    required property string filePath
    property color fallbackColor: JamiTheme.transparentColor
    property real margin: 2
    property bool videoStills: false
    property int thumbnailSize: 0
    readonly property url fileUrl: filePath ? UtilsAdapter.urlFromLocalPath(filePath) : ""
    readonly property var mediaInfo: filePath ? MessagesAdapter.getMediaInfo(filePath) : ({})
    readonly property bool showingPreview: animatedImage.status === Image.Ready || stillImage.status === Image.Ready

    radius: JamiTheme.chatViewFooterButtonRadius
    color: showingPreview ? JamiTheme.transparentColor : fallbackColor
    layer.enabled: true
    layer.effect: OpacityMask {
        maskSource: Rectangle {
            width: root.width
            height: root.height
            radius: root.radius
        }
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: root.showingPreview ? 0 : root.margin
        radius: root.radius
        color: JamiTheme.secondaryBackgroundColor

        ResponsiveImage {
            anchors.centerIn: parent
            width: Math.max(0, Math.min(parent.width - 16, root.thumbnailSize > 0 ? JamiTheme.iconButtonLarge : parent.width))
            height: Math.max(0, Math.min(parent.height - 16, root.thumbnailSize > 0 ? JamiTheme.iconButtonLarge : parent.height))
            visible: !root.showingPreview
            source: {
                if (root.mediaInfo.isVideo)
                    return JamiResources.video_file_24dp_svg;
                if (root.mediaInfo.isAudio)
                    return JamiResources.audio_file_24dp_svg;
                return JamiResources.attached_file_24dp_svg;
            }
            cache: false
            color: JamiTheme.textColor
        }
    }

    AnimatedImage {
        id: animatedImage

        anchors.fill: parent
        // AnimatedImage can resize frames to the exact sourceSize, distorting them before cropping.
        source: root.mediaInfo.isAnimatedImage || (root.thumbnailSize === 0 && root.mediaInfo.isImage)
                ? root.fileUrl : ""
        asynchronous: true
        cache: false
        fillMode: Image.PreserveAspectCrop
    }

    Image {
        id: stillImage

        anchors.fill: parent
        source: {
            if (root.videoStills && root.mediaInfo.isVideo)
                return "image://videothumbnail/" + encodeURIComponent(root.filePath);
            return root.thumbnailSize > 0 && root.mediaInfo.isImage ? root.fileUrl : "";
        }
        sourceSize: root.thumbnailSize > 0 ? Qt.size(root.thumbnailSize, root.thumbnailSize) : Qt.size(-1, -1)
        autoTransform: true
        asynchronous: true
        cache: false
        fillMode: Image.PreserveAspectCrop
    }
}
