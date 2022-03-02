/*
 * Copyright (C) 2022 Savoir-faire Linux Inc.
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
    property real invAspectRatio: (videoOutput.sourceRect.height
                                   / videoOutput.sourceRect.width) ||
                                  0.5625 // 16:9 default
    property bool crop: false

    // This rect describes the actual rendered content rectangle
    // as the VideoOutput component may use PreserveAspectFit
    // (pillarbox/letterbox).
    property rect contentRect: videoOutput.contentRect
    property real xScale: contentRect.width / videoOutput.sourceRect.width
    property real yScale: contentRect.height / videoOutput.sourceRect.height

    onRendererIdChanged: {
        videoProvider.unregisterSink(videoSink)
        if (rendererId.length !== 0) {
            videoProvider.registerSink(rendererId, videoSink)
        }
    }

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
        opacity: videoProvider.activeRenderers[rendererId] !== undefined
        visible: opacity

        fillMode: crop ?
                      VideoOutput.PreserveAspectCrop :
                      VideoOutput.PreserveAspectFit

        Behavior on opacity { NumberAnimation { duration: 150 } }

        Component.onDestruction: videoProvider.unregisterSink(videoSink)

        layer.enabled: opacity
        layer.effect: FastBlur {
            source: videoOutput
            anchors.fill: root
            radius: (1. - opacity) * 100
        }
    }
}
