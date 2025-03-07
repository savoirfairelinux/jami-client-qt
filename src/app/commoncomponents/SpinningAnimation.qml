/*
 * Copyright (C) 2021-2025 Savoir-faire Linux Inc.
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

Item {
    id: root

    enum Mode {
        Disabled,
        Radial,
        BiRadial
    }

    property int mode: SpinningAnimation.Mode.Disabled
    property int spinningAnimationWidth: 4
    property real outerCutRadius: root.height / 2
    property int spinningAnimationDuration: 1000
    property color color: "white"
    visible: mode !== SpinningAnimation.Mode.Disabled
    ConicalGradient {
        id: conicalGradientOne

        anchors.fill: parent

        angle: 0.0
        gradient: Gradient {
            GradientStop {
                position: 0.5
                color: "transparent"
            }
            GradientStop {
                position: 1.0
                color: mode === SpinningAnimation.Mode.Disabled ? "transparent" : root.color
            }
        }

        RotationAnimation on angle  {
            running: root.visible
            loops: Animation.Infinite
            duration: spinningAnimationDuration
            from: 0
            to: 360
        }

        layer.enabled: true
        layer.effect: OpacityMask {
            invert: true
            maskSource: Item {
                width: conicalGradientOne.width
                height: conicalGradientOne.height

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: spinningAnimationWidth
                    radius: outerCutRadius
                }
            }
        }
    }

    ConicalGradient {
        id: conicalGradientTwo

        anchors.fill: parent

        visible: mode === SpinningAnimation.Mode.BiRadial
        angle: 180.0
        gradient: Gradient {
            GradientStop {
                position: 0.75
                color: "transparent"
            }
            GradientStop {
                position: 1.0
                color: mode === SpinningAnimation.Mode.Disabled ? "transparent" : root.color
            }
        }

        RotationAnimation on angle  {
            running: root.visible
            loops: Animation.Infinite
            duration: spinningAnimationDuration
            from: 180.0
            to: 540.0
        }

        layer.enabled: true
        layer.effect: OpacityMask {
            invert: true
            maskSource: Item {
                width: conicalGradientTwo.width
                height: conicalGradientTwo.height

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: spinningAnimationWidth
                    radius: outerCutRadius
                }
            }
        }
    }

    layer.enabled: mode !== SpinningAnimation.Mode.Disabled
    layer.effect: OpacityMask {
        maskSource: Rectangle {
            width: root.width
            height: root.height
            radius: outerCutRadius
        }
    }
}
