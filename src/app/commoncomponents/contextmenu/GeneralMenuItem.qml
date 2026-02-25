/*
 * Copyright (C) 2020-2026 Savoir-faire Linux Inc.
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
import net.jami.Constants 1.1
import "../"

// General menu item.
// Can control top, bottom, left, right border width.
// Use onClicked slot to simulate item click event.
// Can have image icon at the left of the text.
MenuItem {
    id: root

    property string itemName: ""
    property bool bold: false
    property string iconSource: ""
    property bool canTrigger: true
    property bool dangerous: false
    property BaseContextMenu parentMenu
    property int itemRealWidth: implicitWidth
    property alias isActif: root.enabled

    height: JamiTheme.generalMenuItemHeight

    indicator: Button {
        anchors.left: root.left
        anchors.leftMargin: JamiTheme.generalMenuItemPadding
        anchors.verticalCenter: root.verticalCenter

        icon.width: JamiTheme.iconButtonMedium
        icon.height: JamiTheme.iconButtonMedium
        icon.source: iconSource
        icon.color: JamiTheme.textColor

        enabled: false

        opacity: root.hovered ? 1.0 : 0.6

        Behavior on opacity {
            NumberAnimation {
                duration: JamiTheme.shortFadeDuration
            }
        }

        // We dont want a background for the button itself
        background.visible: false

        visible: iconSource.length > 0
    }

    contentItem: Text {
        anchors.left: root.indicator.visible ? root.indicator.right : root.background.left
        anchors.right: root.background.right
        anchors.leftMargin: root.indicator.visible ? JamiTheme.generalMenuItemPadding / 2 : background.radius
        anchors.rightMargin: JamiTheme.generalMenuItemPadding / 2
        anchors.verticalCenter: root.verticalCenter

        text: itemName
        elide: Text.ElideRight
        font.pointSize: JamiTheme.textFontSize
        font.bold: root.bold
        verticalAlignment: Text.AlignVCenter
        color: dangerous ? JamiTheme.redColor : JamiTheme.textColor
    }

    highlighted: true

    background: Rectangle {
        anchors.fill: root
        anchors.leftMargin: JamiTheme.generalMenuItemPadding
        anchors.rightMargin: JamiTheme.generalMenuItemPadding

        radius: JamiTheme.generalMenuItemRadius
        color: root.hovered || root.activeFocus ? JamiTheme.hoveredButtonColor : JamiTheme.globalIslandColor

        Behavior on color {
            ColorAnimation {
                duration: JamiTheme.shortFadeDuration
            }
        }
    }

    onReleased: Qt.callLater(() => parentMenu && parentMenu.close())
}
