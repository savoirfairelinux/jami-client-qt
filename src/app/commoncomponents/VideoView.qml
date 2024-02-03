/*
 * Copyright (C) 2022-2024 Savoir-faire Linux Inc.
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
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
import QtQuick
import QtMultimedia
import Qt5Compat.GraphicalEffects

Item {
    id: root

    property string rendererId
    property alias videoSink: videoOutput.videoSink
    property alias underlayItems: rootUnderlayItem.children
    property alias overlayItems: rootOverlayItem.children
    property real invAspectRatio: (videoOutput.sourceRect.height / videoOutput.sourceRect.width) || 0.5625 // 16:9 default
    property bool crop: false
    property bool flip: false
    property real blurRadius: 0

    // We need to know if the frames are being rendered to the screen or not.
    readonly property bool isRendering: videoProvider.activeRenderers[rendererId] ? true : false

    // This rect describes the actual rendered content rectangle
    // as the VideoOutput component may use PreserveAspectFit
    // (pillarbox/letterbox).
    property rect contentRect: videoOutput.contentRect
    property real xScale: contentRect.width / videoOutput.sourceRect.width
    property real yScale: contentRect.height / videoOutput.sourceRect.height

    onRendererIdChanged: videoProvider.subscribe(videoSink, rendererId)

    Rectangle {
        id: bgRect
        anchors.fill: parent
        color: "black"
    }

    Item {
        id: rootUnderlayItem
        anchors.fill: parent
    }

    VideoOutput {
        id: videoOutput

        antialiasing: true
        anchors.fill: parent
        opacity: isRendering
        visible: opacity

        fillMode: crop ? VideoOutput.PreserveAspectCrop : VideoOutput.PreserveAspectFit

        Behavior on opacity  {
            NumberAnimation {
                duration: 150
            }
        }

        layer.enabled: opacity
        layer.effect: FastBlur {
            source: videoOutput
            anchors.fill: root
            radius: blurRadius ? blurRadius : (1. - opacity) * 100
        }

        transform: Scale {
            origin.x: videoOutput.width / 2
            xScale: root.flip ? -1 : 1
        }
    }

    Item {
        id: rootOverlayItem
        anchors.fill: parent
    }
}
