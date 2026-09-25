/*
 * Copyright (C) 2026 Savoir-faire Linux Inc.
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
import QtQuick.Layouts
import QtQuick.Effects
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import "../../commoncomponents"

Item {
    id: root

    Layout.fillWidth: true
    Layout.fillHeight: true

    Rectangle {
        id: innerRect

        anchors.fill: parent
        anchors.margins: (typeof viewCoordinator !== "undefined" && viewCoordinator.isInSinglePaneMode) ? JamiTheme.sidePanelIslandsSinglePaneModePadding : JamiTheme.sidePanelIslandsPadding
        anchors.topMargin: JamiTheme.qwkTitleBarHeight + JamiTheme.sidePanelIslandsPadding * 2

        color: JamiTheme.globalIslandColor
        radius: JamiTheme.avatarBasedRadius

        Item {
            id: panelHeader

            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right

            height: 64

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 20
                anchors.right: closeButton.left
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter

                text: JamiStrings.thread
                elide: Text.ElideRight
                font.weight: Font.DemiBold
                font.pixelSize: 16

                color: JamiTheme.textColor
            }

            NewIconButton {
                id: closeButton

                anchors.right: parent.right
                anchors.rightMargin: 16
                anchors.verticalCenter: parent.verticalCenter

                iconSize: JamiTheme.iconButtonMedium
                iconSource: JamiResources.round_close_24dp_svg
                iconColor: JamiTheme.textColor
                toolTipText: JamiStrings.close

                onClicked: MessagesAdapter.threadRootId = ""
            }
        }

        MessageListView {
            id: threadListView

            anchors.top: panelHeader.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.bottomMargin: innerRect.radius / 2

            topMargin: 0

            model: MessagesAdapter.threadMessageListModel

            header: null
        }

        Rectangle {
            id: gradientRectTop

            readonly property color baseColor: innerRect.color
            readonly property bool shouldShow: !threadListView.atYBeginning

            anchors.top: threadListView.top

            width: threadListView.width
            height: JamiTheme.smartListItemHeight

            z: threadListView.z + 1

            gradient: Gradient {
                orientation: Gradient.Vertical
                GradientStop {
                    position: 0.0
                    color: Qt.rgba(gradientRectTop.baseColor.r, gradientRectTop.baseColor.g,
                                   gradientRectTop.baseColor.b, 1.0)
                }
                GradientStop {
                    position: 0.25
                    color: Qt.rgba(gradientRectTop.baseColor.r, gradientRectTop.baseColor.g,
                                   gradientRectTop.baseColor.b, 0.75)
                }
                GradientStop {
                    position: 1.0
                    color: Qt.rgba(gradientRectTop.baseColor.r, gradientRectTop.baseColor.g,
                                   gradientRectTop.baseColor.b, 0.0)
                }
            }

            visible: opacity > 0
            opacity: shouldShow ? 1.0 : 0.0

            Behavior on opacity {
                NumberAnimation {
                    duration: 200
                    easing.type: Easing.InOutQuad
                }
            }
        }

        layer.enabled: true
        layer.effect: MultiEffect {
            anchors.fill: innerRect

            shadowEnabled: true
            shadowBlur: JamiTheme.shadowBlur
            shadowColor: JamiTheme.shadowColor
            shadowHorizontalOffset: JamiTheme.shadowHorizontalOffset
            shadowVerticalOffset: JamiTheme.shadowVerticalOffset
            shadowOpacity: JamiTheme.shadowOpacity
        }
    }
}
