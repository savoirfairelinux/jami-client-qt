/*
 * Copyright (C) 2026 Savoir-faire Linux Inc.
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
import QtQuick

// A ring that keeps growing out of its parent and fading while running, to
// tell that something is live, such as a contact sending its position.
Rectangle {
    id: root
    objectName: "pulseRing"

    property bool running: false
    property real startOpacity: 0.55

    anchors.fill: parent
    color: "transparent"
    border.width: 1.5
    visible: running
    opacity: 0

    // Grows and fades, then rests a moment.
    SequentialAnimation {
        running: root.running
        loops: Animation.Infinite

        ParallelAnimation {
            NumberAnimation {
                target: root
                property: "scale"
                from: 1
                to: 1.45
                duration: 1800
                easing.type: Easing.OutCubic
            }

            NumberAnimation {
                target: root
                property: "opacity"
                from: root.startOpacity
                to: 0
                duration: 1800
                easing.type: Easing.OutQuad
            }
        }

        PauseAnimation {
            duration: 700
        }
    }
}
