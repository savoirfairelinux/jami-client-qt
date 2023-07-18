/*
 * Copyright (C) 2020-2023 Savoir-faire Linux Inc.
 * Author: Fadi Shehadeh <fadi.shehadeh@savoirfairelinux.com>
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
import QtQuick.Layouts
import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import Qt5Compat.GraphicalEffects
import "../../commoncomponents"

FocusScope {
    id: root
    property string title: ""
    property string description: ""
    property int tipId: 0
    property string type: ""
    property bool hovered: false
    property bool clicked: false
    property bool opened: activeFocus
    property color backgroundColor: JamiTheme.welcomeBlockColor

    property string customizeTip: "CustomizeTipBox {}"

    property string backupTip: "BackupTipBox {" + "    onIgnore: {" + "        root.ignoreClicked()" + "    }" + "}"

    property string infoTip: "InformativeTipBox {}"

    width: JamiTheme.tipBoxWidth

    property real minimumHeight: 150
    property real maximumHeight: 250

    height: Math.max(minimumHeight, Math.min(maximumHeight, tipColumnLayout.implicitHeight + 2 * JamiTheme.preferredMarginSize))

    signal ignoreClicked

    focus: true

    Rectangle {
        id: rect
        anchors.fill: parent

        color: root.backgroundColor

        radius: 5

        focus: true

        Column {
            id: tipColumnLayout
            anchors.top: parent.top
            width: parent.width
            anchors.topMargin: 10

            Loader {
                id: loader_backupTip
                active: type === "backup"
                sourceComponent: BackupTipBox {
                    onIgnore: {
                        root.ignoreClicked();
                    }
                    maxHeight: root.maximumHeight
                }
                width: parent.width
            }
            Loader {
                id: loader_customizeTip
                active: type === "customize"
                sourceComponent: CustomizeTipBox {
                }
                width: parent.width
                focus: true
            }
            Loader {
                id: loader_infoTip
                active: type === "tip"
                sourceComponent: InformativeTipBox {
                    maxHeight: root.maximumHeight
                }
                width: parent.width
            }
        }
    }

    HoverHandler {
        target: rect
        onHoveredChanged: root.hovered = hovered
        cursorShape: Qt.PointingHandCursor
    }

    TapHandler {
        target: rect
        onTapped: {
            return opened ? focus = false : root.forceActiveFocus();
        }
    }

    DropShadow {
        z: -1
        visible: hovered || opened
        width: root.width
        height: root.height
        horizontalOffset: 3.0
        verticalOffset: 3.0
        radius: 16
        color: Qt.rgba(0, 0.34, 0.6, 0.16)
        source: rect
        transparentBorder: true
        samples: radius + 1
    }

    Loader {
        id: loader_btnClose
        active: type === "tip"
        sourceComponent: component_btnClose
        anchors.margins: 8
        anchors.bottom: root.top
        anchors.horizontalCenter: root.horizontalCenter
    }

    Component {
        id: component_btnClose
        PushButton {
            id: btnClose

            width: 20
            height: 20
            imageContainerWidth: 20
            imageContainerHeight: 20

            visible: opened
            circled: true

            imageColor: Qt.rgba(0, 86 / 255, 153 / 255, 1)
            normalColor: "transparent"
            toolTipText: JamiStrings.dismiss

            source: JamiResources.trash_black_24dp_svg

            onClicked: root.ignoreClicked()
        }
    }
}
