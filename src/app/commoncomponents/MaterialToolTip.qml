/*
 * Copyright (C) 2021-2023 Savoir-faire Linux Inc.
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
import QtQuick.Controls
import net.jami.Constants 1.1

ToolTip {
    id: root
    property alias backGroundColor: background.color
    property alias textColor: label.color

    onVisibleChanged: {
        if (visible)
            animation.start();
    }

    ParallelAnimation {
        id: animation
        NumberAnimation {
            duration: JamiTheme.shortFadeDuration
            from: 0
            properties: "opacity"
            target: background
            to: 1.0
        }
        NumberAnimation {
            duration: JamiTheme.shortFadeDuration * 0.5
            from: 0.5
            properties: "scale"
            target: background
            to: 1.0
        }
    }

    background: Rectangle {
        id: background
        color: "#c4272727"
        radius: 5
    }
    contentItem: Text {
        id: label
        color: "white"
        font.pixelSize: 13
        text: root.text
    }
}
