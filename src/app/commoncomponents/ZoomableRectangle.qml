/*
 * Copyright (C) 2020-2024 Savoir-faire Linux Inc.
 * Author: Mingrui Zhang <mingrui.zhang@savoirfairelinux.com>
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
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import net.jami.Helpers 1.1
import QtQuick 2.15

Item {
    id: zoomableRectangle
    property real scaleFactor: 1.0
    readonly property real dimension: 250
    readonly property real maxScaleFactor: 1.5
    readonly property real minScaleFactor: 0.5
    property real initialY: 0
    property bool dragActive: false
    property real dragThreshold: 10

    property string imagePath: ""

    // Dynamically load content
    property var contentItem

    Control {
        padding: 10
        width: parent.width
        height: parent.height

        contentItem: Rectangle {
            id: innerRectangle
            width: parent.width
            height: parent.height
            // color: "#666666"
            anchors.centerIn: parent
            color: "transparent"

            // Container for dynamic content
            Item {
                id: contentContainer
                width: dimension * scaleFactor
                height: dimension * scaleFactor
                anchors.centerIn: parent

                // Dynamically loaded content
                // Loader {
                Image {
                    id: contentLoader
                    source: zoomableRectangle.imagePath
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectFit
                    width: parent.width
                    height: parent.height
                    smooth: false
                }

                Behavior on width {
                    NumberAnimation {
                        duration: 150  // Duration for the animation
                        easing.type: Easing.OutQuad
                    }
                }
                Behavior on height {
                    NumberAnimation {
                        duration: 150  // Duration for the animation
                        easing.type: Easing.OutQuad
                    }
                }
            }

            MouseArea {
                id: mouseArea
                anchors.fill: parent

                onWheel: {
                    console.warn("[LinkDevice] scrolling")
                    if (wheel.angleDelta.y > 0) {
                        scaleFactor = Math.min(maxScaleFactor, scaleFactor * 1.2); // Zoom in
                    } else {
                        scaleFactor = Math.max(minScaleFactor, scaleFactor / 1.2); // Zoom out
                    }
                }

                onPressed: {
                    initialY = mouse.y
                }

                onPositionChanged: {
                    if (drag.active) {
                        console.warn("[LinkDevice] dragging")
                        var deltaY = mouse.y - initialY
                        if (Math.abs(deltaY) > dragThreshold) {
                            if (deltaY > 0) {
                                scaleFactor = Math.max(minScaleFactor, scaleFactor / 1.1); // Zoom out
                            } else {
                                scaleFactor = Math.min(maxScaleFactor, scaleFactor * 1.1); // Zoom in
                            }
                            initialY = mouse.y // Reset initialY to avoid continuous scaling
                        }
                    }
                }
            }
        }
    }
}
