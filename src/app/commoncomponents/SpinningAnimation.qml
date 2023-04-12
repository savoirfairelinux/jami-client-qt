/*
 * Copyright (C) 2021-2023 Savoir-faire Linux Inc.
 * Author: Aline Gondim Santos <aline.gondimsantos@savoirfairelinux.com>
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
import Qt5Compat.GraphicalEffects

Item {
    id: root
    enum Mode {
        Disabled,
        Radial,
        BiRadial
    }

    property int mode: SpinningAnimation.Mode.Disabled
    property real outerCutRadius: root.height / 2
    property int spinningAnimationDuration: 1000
    property int spinningAnimationWidth: 4

    layer.enabled: mode !== SpinningAnimation.Mode.Disabled
    visible: mode !== SpinningAnimation.Mode.Disabled

    ConicalGradient {
        id: conicalGradientOne
        anchors.fill: parent
        angle: 0.0
        layer.enabled: true

        RotationAnimation on angle  {
            duration: spinningAnimationDuration
            from: 0
            loops: Animation.Infinite
            running: root.visible
            to: 360
        }
        gradient: Gradient {
            GradientStop {
                color: "transparent"
                position: 0.5
            }
            GradientStop {
                color: "white"
                position: 1.0
            }
        }
        layer.effect: OpacityMask {
            invert: true

            maskSource: Item {
                height: conicalGradientOne.height
                width: conicalGradientOne.width

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
        angle: 180.0
        layer.enabled: true
        visible: mode === SpinningAnimation.Mode.BiRadial

        RotationAnimation on angle  {
            duration: spinningAnimationDuration
            from: 180.0
            loops: Animation.Infinite
            running: root.visible
            to: 540.0
        }
        gradient: Gradient {
            GradientStop {
                color: "transparent"
                position: 0.75
            }
            GradientStop {
                color: "white"
                position: 1.0
            }
        }
        layer.effect: OpacityMask {
            invert: true

            maskSource: Item {
                height: conicalGradientTwo.height
                width: conicalGradientTwo.width

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: spinningAnimationWidth
                    radius: outerCutRadius
                }
            }
        }
    }

    layer.effect: OpacityMask {
        maskSource: Rectangle {
            height: root.height
            radius: outerCutRadius
            width: root.width
        }
    }
}
