/*
 * Copyright (C) 2024-2026 Savoir-faire Linux Inc.
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
import net.jami.Constants 1.1

Control {
    id: root

    property int duration
    property int fadingTime
    property string message

    anchors.top: parent.top
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.topMargin: 10

    implicitWidth: Math.min(textMessage.implicitWidth + leftPadding + rightPadding, parent.width - 20)
    implicitHeight: textMessage.implicitHeight + topPadding + bottomPadding

    topPadding: 10
    bottomPadding: 10
    leftPadding: background.radius
    rightPadding: background.radius

    contentItem: Text {
        id: textMessage

        text: message
        elide: Text.ElideRight
        font.pointSize: JamiTheme.toastFontSize
        color: JamiTheme.toastColor
    }


    Component.onCompleted: {
        anim.start();
    }

    background: Rectangle {
        radius: height / 2
        color: JamiTheme.toastRectColor
    }

    SequentialAnimation on opacity  {
        id: anim

        running: false

        NumberAnimation {
            to: 0.9
            duration: root.fadingTime
        }
        PauseAnimation {
            duration: root.duration
        }
        NumberAnimation {
            to: 0
            duration: root.fadingTime
        }

        onRunningChanged: {
            if (!running)
                root.destroy();
        }
    }
}
