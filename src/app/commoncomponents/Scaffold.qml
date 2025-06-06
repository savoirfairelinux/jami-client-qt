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
import QtQuick.Controls
import QtQuick.Layouts

// UI dev tool to visualize components/layouts
Rectangle {
    property alias name: label.text
    property bool stretchParent: false
    property string tag: parent.toString() + " (w:" + width + ", h: " + height + ")"
    signal moveX(real dx)
    signal moveY(real dy)
    property real ox: 0
    property real oy: 0
    property real step: 0.5

    border.width: 1
    color: {
        var r = Math.random() * 0.5 + 0.5;
        var g = Math.random() * 0.5 + 0.5;
        var b = Math.random() * 0.5 + 0.5;
        Qt.rgba(r, g, b, 0.5);
    }

    anchors.fill: parent instanceof Layout ? undefined : parent

    focus: false
    Keys.onPressed: {
        if (event.key === Qt.Key_Left)
            moveX(-step)
        else if (event.key === Qt.Key_Right)
            moveX(step)
        else if (event.key === Qt.Key_Down)
            moveY(step)
        else if (event.key === Qt.Key_Up)
            moveY(-step)
        console.log(tag, ox, oy)
        event.accepted = true;
    }

    Component.onCompleted: {
        if (parent instanceof Layout) {
            width = Qt.binding(() => { return parent.width })
            height = Qt.binding(() => { return parent.height })
        }

        // fallback to some description of the object
        if (label.text === "")
            label.text = tag;

        // force the parent to be at least the dimensions of children
        if (stretchParent) {
            parent.width = Math.max(parent.width, parent.childrenRect.width);
            parent.height = Math.max(parent.height, parent.childrenRect.height);
        }
    }

    onMoveX: {
        parent.anchors.leftMargin += dx
        parent.x += dx
        ox += dx;
    }
    onMoveY: {
        parent.anchors.topMargin += dy
        parent.y += dy
        oy += dy
    }

    Label {
        id: label
        anchors.centerIn: parent
    }

    MouseArea {
        anchors.fill: parent
        onPressed: parent.forceActiveFocus()
    }
}
