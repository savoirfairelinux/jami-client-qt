/*
 * Copyright (C) 2020-2025 Savoir-faire Linux Inc.
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
import Qt5Compat.GraphicalEffects
import net.jami.Constants 1.1
import net.jami.Helpers 1.1

Item {
    id: root

    property real containerWidth: 30
    property real containerHeight: 30

    property int padding: 0
    property point offset: Qt.point(0, 0)

    property alias source: image.source
    property alias status: image.status
    property alias fillMode: image.fillMode
    property alias cache: image.cache
    property alias image: image
    property alias mirror: image.mirror
    property string color: "transparent"
    property bool hovered: false
    property bool mirrorHorizontally: false
    property bool mirrorVertically: false

    property bool isSvg: {
        var match = /[^.]+$/.exec(source);
        return match !== null && match[0] === 'svg';
    }

    anchors.horizontalCenterOffset: offset.x
    anchors.verticalCenterOffset: offset.y

    // works out to 24 if containerWidth is 30
    width: Math.trunc(containerWidth * Math.sqrt(2) * 0.5) + 3 - padding
    height: Math.trunc(containerHeight * Math.sqrt(2) * 0.5) + 3 - padding

    Connections {
        target: CurrentScreenInfo

        function onDevicePixelRatioChanged() {
            image.setSourceSize();
        }
    }

    Image {
        id: image

        anchors.fill: root

        fillMode: Image.PreserveAspectFit
        smooth: true
        antialiasing: true
        asynchronous: true
        visible: false
        mipmap: true

        function setSourceSize() {
            sourceSize = undefined;
            if (isSvg)
                sourceSize = Qt.size(width, height);
        }

        Component.onCompleted: setSourceSize()
    }

    ColorOverlay {
        anchors.fill: image
        source: image
        color: root.color
    }

    HoverHandler {
        target: parent
        onHoveredChanged: {
            root.hovered = hovered;
        }
    }
}
