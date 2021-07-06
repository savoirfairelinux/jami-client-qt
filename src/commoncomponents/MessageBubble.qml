/*
 * Copyright (C) 2021 by Savoir-faire Linux
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

import QtQuick 2.15
import QtGraphicalEffects 1.0

import net.jami.Constants 1.1

Item {
    id: root

    property bool out: true
    property alias radius: bubble.radius
    property int type: MsgSeq.single

    property string color1: "lightgrey"
    property string color2: Qt.lighter(color1, 1.3)

    Rectangle {
        id: bubble

        anchors.fill: parent
        radius: root.radius
        color: color1

        Rectangle {
            id: mask

            visible: type !== MsgSeq.single
            z: -1
            radius: 2
            color: color1

            anchors {
                fill: parent
                leftMargin: out ? root.width - root.radius : 0
                rightMargin: out ? 0 : root.width - root.radius
                topMargin: type === MsgSeq.first ? root.height - root.radius : 0
                bottomMargin: type === MsgSeq.last ? root.height - root.radius : 0
            }

//            width: root.radius
//            height: type === MsgSeq.middle ? parent.height : width
//            anchors {
//                left: out ? undefined : bubble.left
//                right: out ? bubble.right : undefined
//                top: type !== MsgSeq.first ? bubble.top : undefined
//                bottom: type !== MsgSeq.last ? bubble.bottom : undefined
//            }
        }
    }

//    LinearGradient  {
//        anchors.fill: bubble
//        source: bubble
//        gradient: Gradient {
//            orientation: Gradient.Horizontal
//            GradientStop { position: 0; color: color1 }
//            GradientStop { position: 1; color: color2 }
//        }
//    }
}
