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

import net.jami.Adapters 1.1

Rectangle {
    id: root

    color: "black"

    property string deviceId
    property alias videoSink: output.videoSink
    property alias underlayItems: underlay.children

    function startWithId(id, force = false) {
        videoProvider.unregisterSink(output.videoSink)
        if (id.length === 0) {
            VideoDevices.stopDevice(deviceId)
        } else {
            const rendererId = VideoDevices.startDevice(id, force)
            videoProvider.registerSink(rendererId, output.videoSink)
        }
        deviceId = id
    }

    Item {
        id: underlay
        anchors.fill: parent
    }

    VideoOutput {
        id: output

        anchors.fill: parent
        opacity: videoProvider.activeRenderers[deviceId] !== undefined
        visible: opacity != 0
        fillMode: VideoOutput.PreserveAspectCrop

        Behavior on opacity { NumberAnimation { duration: 100 } }

        Component.onDestruction: videoProvider.unregisterSink(videoSink)
    }

    onVisibleChanged: {
        const id = visible ? VideoDevices.getDefaultDevice() : ""
        startWithId(id)
    }
}


