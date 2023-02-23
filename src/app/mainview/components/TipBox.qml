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
    property string title: ""
    property string description: ""
    property int tipId: 0
    property string type : ""
    property bool hovered: false
    property bool clicked : false
    property bool opened: false

    property string customizeTip:"CustomizeTipBox {}"

    property string backupTip: "BackupTipBox {" +
        "    onIgnore: {" +
        "        root.ignoreClicked()" +
        "    }" +
        "}"

    property string infoTip: "InformativeTipBox {}"

    width: 200
    height: tipColumnLayout.implicitHeight + 2 * JamiTheme.preferredMarginSize

    signal ignoreClicked

    Rectangle {

        id: rect
        anchors.fill: parent

        color: opened || hovered ? JamiTheme.tipBoxBackgroundColor : "transparent"
        border.color: JamiTheme.tipBoxBorderColor
        radius: 20

        Column {
            id: tipColumnLayout
            anchors.top: parent.top
            width: parent.width
            anchors.topMargin: 10

            Component.onCompleted: {
                if (type === "customize") {
                    Qt.createQmlObject(customizeTip, this, 'tip')
                } else if (type === "backup") {
                    Qt.createQmlObject(backupTip, this, 'tip')
                } else {
                    Qt.createQmlObject(infoTip, this, 'tip')
                }
            }
        }
    }

    HoverHandler {
        target : rect
        onHoveredChanged: root.hovered = hovered
        cursorShape: Qt.PointingHandCursor
    }

    TapHandler {
        target: rect
        onTapped: opened = !opened
    }

    DropShadow {
        z: -1
        visible: hovered || opened
        width: root.width
        height: root.height
        horizontalOffset: 3.0
        verticalOffset: 3.0
        radius: 16
        color: Qt.rgba(0, 0.34,0.6,0.16)
        source: rect
        transparentBorder: true
    }

    PushButton {
        id: btnClose

        width: 20
        height: 20
        imageContainerWidth: 20
        imageContainerHeight : 20
        anchors.margins: 14
        anchors.top: parent.top
        anchors.right: parent.right
        visible: opened
        circled: true

        imageColor: Qt.rgba(0, 86/255, 153/255, 1)
        normalColor: "transparent"
        toolTipText: JamiStrings.dismiss

        source: JamiResources.round_close_24dp_svg

        onClicked: root.ignoreClicked()
    }
}
