/*
 * Copyright (C) 2023 Savoir-faire Linux Inc.
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
    property int duration
    property int fadingTime
    property string message

    anchors.horizontalCenter: parent.horizontalCenter
    anchors.top: parent.top
    anchors.topMargin: 10
    color: JamiTheme.toastRectColor
    height: textMessage.height + 10
    radius: 15
    width: textMessage.width + 20

    Component.onCompleted: {
        anim.start();
    }

    Text {
        id: textMessage
        anchors.centerIn: root
        color: JamiTheme.toastColor
        font.pointSize: JamiTheme.toastFontSize
        text: message
    }

    SequentialAnimation on opacity  {
        id: anim
        running: false

        onRunningChanged: {
            if (!running)
                root.destroy();
        }

        NumberAnimation {
            duration: root.fadingTime
            to: 0.9
        }
        PauseAnimation {
            duration: root.duration
        }
        NumberAnimation {
            duration: root.fadingTime
            to: 0
        }
    }
}
