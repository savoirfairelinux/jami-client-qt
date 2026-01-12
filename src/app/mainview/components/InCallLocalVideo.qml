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
import Qt5Compat.GraphicalEffects

import net.jami.Enums 1.1
import net.jami.Constants 1.1
import net.jami.Adapters 1.1

import "../../commoncomponents"

// This component uses anchors and they are set within this component.
LocalVideo {
    id: localPreview

    required property var container
    required property real opacityModifier

    readonly property int previewMargin: 15
    readonly property int previewMarginYTop: previewMargin + 42
    readonly property int previewMarginYBottom: previewMargin + 84

    anchors.bottomMargin: previewMarginYBottom
    anchors.leftMargin: sideMargin
    anchors.rightMargin: sideMargin
    anchors.topMargin: previewMarginYTop

    visibilityCondition: (CurrentCall.isSharing || !CurrentCall.isVideoMuted) &&
                         !CurrentCall.isConference

    // Keep the area of the preview a proportion of the screen size plus a
    // modifier to allow the user to scale it.
    readonly property real containerArea: container.width * container.height
    property real scalingFactor: 1
    width: Math.sqrt(containerArea / 16) * scalingFactor
    height: width * invAspectRatio

    flip: CurrentCall.flipSelf && !CurrentCall.isSharing
    blurRadius: hidden ? 25 : 0

    opacity: hidden ? opacityModifier : 1

    // Allow hiding the preview (available when anchored)
    readonly property bool hovered: hoverHandler.hovered
    readonly property bool anchored: state !== "unanchored"
    property bool hidden: false
    readonly property real hiddenHandleSize: 32
    // Compute the margin as a function of the preview width in order to
    // apply a negative margin and expose a constant width handle.
    // If not hidden, return the previewMargin.
    property real sideMargin: !hidden ? previewMargin : -(width - hiddenHandleSize)
    // Animate the hiddenSize with a Behavior.
    Behavior on sideMargin { NumberAnimation { duration: 250; easing.type: Easing.OutExpo }}
    readonly property bool onLeft: state.indexOf("left") !== -1

    MouseArea {
        anchors.fill: parent
        enabled: !localPreview.hidden
        onWheel: function(event) {
            const delta = event.angleDelta.y / 120 * 0.1;
            if (event.modifiers & Qt.ControlModifier) {
                parent.opacity = JamiQmlUtils.clamp(parent.opacity + delta, 0.25, 1);
            } else {
                localPreview.scalingFactor = JamiQmlUtils.clamp(localPreview.scalingFactor + delta, 0.5, 4);
            }
        }
    }

    PushButton {
        id: hidePreviewButton
        objectName: "hidePreviewButton"

        width: localPreview.hiddenHandleSize
        state: localPreview.onLeft ?
                   (localPreview.hidden ? "right" : "left") :
                   (localPreview.hidden ? "left" : "right")
        states: [
            State {
                name: "left"
                AnchorChanges {
                    target: hidePreviewButton
                    anchors.left: parent.left
                }
            },
            State {
                name: "right"
                AnchorChanges {
                    target: hidePreviewButton
                    anchors.right: parent.right
                }
            }
        ]
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        opacity: (localPreview.anchored && localPreview.hovered) || localPreview.hidden
        Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutExpo }}
        visible: opacity > 0
        background: Rectangle {
            readonly property color normalColor: JamiTheme.mediumGrey
            color: JamiTheme.mediumGrey
            opacity: hidePreviewButton.hovered ? 0.7 : 0.5
            Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutExpo }}
        }
        normalImageSource: hidePreviewButton.state === "left" ?
                               JamiResources.chevron_left_black_24dp_svg :
                               JamiResources.chevron_right_black_24dp_svg
        imageColor: JamiTheme.darkGreyColor
        onClicked: localPreview.hidden = !localPreview.hidden
        toolTipText: localPreview.hidden ?
                         JamiStrings.showLocalVideo :
                         JamiStrings.hideLocalVideo
    }

    state: "anchor_top_right"
    states: [
        State {
            name: "unanchored"
            AnchorChanges {
                target: localPreview
                anchors.top: undefined
                anchors.right: undefined
                anchors.bottom: undefined
                anchors.left: undefined
            }
        },
        State {
            name: "anchor_top_left"
            AnchorChanges {
                target: localPreview
                anchors.top: localPreview.container.top
                anchors.left: localPreview.container.left
            }
        },
        State {
            name: "anchor_top_right"
            AnchorChanges {
                target: localPreview
                anchors.top: localPreview.container.top
                anchors.right: localPreview.container.right
            }
        },
        State {
            name: "anchor_bottom_right"
            AnchorChanges {
                target: localPreview
                anchors.bottom: localPreview.container.bottom
                anchors.right: localPreview.container.right
            }
        },
        State {
            name: "anchor_bottom_left"
            AnchorChanges {
                target: localPreview
                anchors.bottom: localPreview.container.bottom
                anchors.left: localPreview.container.left
            }
        }
    ]

    transitions: Transition {
        AnchorAnimation {
            duration: 250
            easing.type: Easing.OutBack
            easing.overshoot: 1.5
        }
    }

    HoverHandler {
        id: hoverHandler
    }

    DragHandler {
        id: dragHandler
        readonly property var container: localPreview.container
        target: parent
        dragThreshold: 4
        enabled: !localPreview.hidden
        xAxis.maximum: container.width - parent.width - previewMargin
        xAxis.minimum: previewMargin
        yAxis.maximum: container.height - parent.height - previewMarginYBottom
        yAxis.minimum: previewMarginYTop
        onActiveChanged: {
            if (active) {
                localPreview.state = "unanchored";
            } else {
                const center = Qt.point(target.x + target.width / 2,
                                        target.y + target.height / 2);
                const containerCenter = Qt.point(container.x + container.width / 2,
                                                 container.y + container.height / 2);
                if (center.x >= containerCenter.x) {
                    if (center.y >= containerCenter.y) {
                        localPreview.state = "anchor_bottom_right";
                    } else {
                        localPreview.state = "anchor_top_right";
                    }
                } else {
                    if (center.y >= containerCenter.y) {
                        localPreview.state = "anchor_bottom_left";
                    } else {
                        localPreview.state = "anchor_top_left";
                    }
                }
            }
        }
    }

    layer.enabled: true
    layer.effect: OpacityMask {
        maskSource: Rectangle {
            width: localPreview.width
            height: localPreview.height
            radius: JamiTheme.primaryRadius
        }
    }
}
