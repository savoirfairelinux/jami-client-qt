/*
 * Copyright (C) 2024 Savoir-faire Linux Inc.
 * Author: Vengeon Nicolas <nicolas.vengeon@savoirfairelinux.com>
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
import net.jami.Constants 1.1

Rectangle {
    id: root

    anchors.top: parent.top
    anchors.horizontalCenter: parent.horizontalCenter
    width: textMessage.width + 20
    height: textMessage.height + 10
    anchors.topMargin: 10
    radius: 15
    color: JamiTheme.toastRectColor

    property int duration
    property int fadingTime
    property string message

    Component.onCompleted: {
        anim.start();
    }

    Text {
        id: textMessage

        anchors.centerIn: root
        text: message
        font.pointSize: JamiTheme.toastFontSize
        color: JamiTheme.toastColor
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
