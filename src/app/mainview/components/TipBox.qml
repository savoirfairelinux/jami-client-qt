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

Item {
    id: root
    property string backupTip: "BackupTipBox {" + "    onIgnore: {" + "        root.ignoreClicked()" + "    }" + "}"
    property bool clicked: false
    property string customizeTip: "CustomizeTipBox {}"
    property string description: ""
    property bool hovered: false
    property string infoTip: "InformativeTipBox {}"
    property bool opened: false
    property int tipId: 0
    property string title: ""
    property string type: ""

    height: tipColumnLayout.implicitHeight + 2 * JamiTheme.preferredMarginSize
    width: 200

    signal ignoreClicked

    Rectangle {
        id: rect
        anchors.fill: parent
        border.color: JamiTheme.tipBoxBorderColor
        color: opened || hovered ? JamiTheme.tipBoxBackgroundColor : "transparent"
        radius: 20

        Column {
            id: tipColumnLayout
            anchors.top: parent.top
            anchors.topMargin: 10
            width: parent.width

            Component.onCompleted: {
                if (type === "customize") {
                    Qt.createQmlObject(customizeTip, this, 'tip');
                } else if (type === "backup") {
                    Qt.createQmlObject(backupTip, this, 'tip');
                } else {
                    Qt.createQmlObject(infoTip, this, 'tip');
                }
            }
        }
    }
    HoverHandler {
        cursorShape: Qt.PointingHandCursor
        target: rect

        onHoveredChanged: root.hovered = hovered
    }
    TapHandler {
        target: rect

        onTapped: opened = !opened
    }
    DropShadow {
        color: Qt.rgba(0, 0.34, 0.6, 0.16)
        height: root.height
        horizontalOffset: 3.0
        radius: 16
        source: rect
        transparentBorder: true
        verticalOffset: 3.0
        visible: hovered || opened
        width: root.width
        z: -1
    }
    PushButton {
        id: btnClose
        anchors.margins: 14
        anchors.right: parent.right
        anchors.top: parent.top
        circled: true
        height: 20
        imageColor: Qt.rgba(0, 86 / 255, 153 / 255, 1)
        imageContainerHeight: 20
        imageContainerWidth: 20
        normalColor: "transparent"
        source: JamiResources.round_close_24dp_svg
        toolTipText: JamiStrings.dismiss
        visible: opened
        width: 20

        onClicked: root.ignoreClicked()
    }
}
