/*
 * Copyright (C) 2021-2023 Savoir-faire Linux Inc.
 * Author: Mingrui Zhang <mingrui.zhang@savoirfairelinux.com>
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
import Qt5Compat.GraphicalEffects
import net.jami.Constants 1.1

Row {
    id: root
    property int currentRect: 0

    spacing: 5

    Timer {
        interval: JamiTheme.typingDotsAnimationInterval
        repeat: true
        running: root.visible

        onTriggered: {
            if (root.currentRect < 2)
                root.currentRect++;
            else
                root.currentRect = 0;
        }
    }
    Repeater {
        model: 3

        Rectangle {
            id: circleRect
            color: JamiTheme.typingDotsNormalColor
            height: JamiTheme.typingDotsSize
            radius: JamiTheme.typingDotsRadius
            width: JamiTheme.typingDotsSize

            states: State {
                id: enlargeState
                name: "enlarge"
                when: root.currentRect === index
            }
            transitions: [
                Transition {
                    to: "enlarge"

                    ParallelAnimation {
                        NumberAnimation {
                            duration: JamiTheme.typingDotsAnimationInterval
                            from: 1.0
                            property: "scale"
                            target: circleRect
                            to: 1.3
                        }
                        ColorAnimation {
                            duration: JamiTheme.typingDotsAnimationInterval
                            from: JamiTheme.typingDotsNormalColor
                            property: "color"
                            target: circleRect
                            to: JamiTheme.typingDotsEnlargeColor
                        }
                    }
                },
                Transition {
                    from: "enlarge"

                    ParallelAnimation {
                        NumberAnimation {
                            duration: JamiTheme.typingDotsAnimationInterval
                            from: 1.3
                            property: "scale"
                            target: circleRect
                            to: 1.0
                        }
                        ColorAnimation {
                            duration: JamiTheme.typingDotsAnimationInterval
                            from: JamiTheme.typingDotsEnlargeColor
                            property: "color"
                            target: circleRect
                            to: JamiTheme.typingDotsNormalColor
                        }
                    }
                }
            ]
        }
    }
}
