/*
 * Copyright (C) 2020-2023 Savoir-faire Linux Inc.
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

Menu {
    id: root
    property var generalMenuSeparatorList: []
    property GeneralMenuSeparator menuBottomBorder: GeneralMenuSeparator {
        separatorColor: "transparent"
        separatorPreferredHeight: menuSeparatorPreferredHeight ? menuSeparatorPreferredHeight : JamiTheme.menuBorderPreferredHeight
        separatorPreferredWidth: menuPreferredWidth ? menuPreferredWidth : JamiTheme.menuItemsPreferredWidth
    }
    property int menuItemsPreferredHeight: 0
    property int menuPreferredWidth: 0
    property int menuSeparatorPreferredHeight: 0
    property GeneralMenuSeparator menuTopBorder: GeneralMenuSeparator {
        separatorColor: "transparent"
        separatorPreferredHeight: menuSeparatorPreferredHeight ? menuSeparatorPreferredHeight : JamiTheme.menuBorderPreferredHeight
        separatorPreferredWidth: menuPreferredWidth ? menuPreferredWidth : JamiTheme.menuItemsPreferredWidth
    }

    font.pointSize: JamiTheme.menuFontSize
    modal: true

    function loadMenuItems(menuItems) {
        root.addItem(menuTopBorder);

        // use the maximum text width as the preferred width for menu
        for (var j = 0; j < menuItems.length; ++j) {
            var currentItemWidth = menuItems[j].itemPreferredWidth;
            if (currentItemWidth !== JamiTheme.menuItemsPreferredWidth && currentItemWidth > menuPreferredWidth)
                menuPreferredWidth = currentItemWidth;
        }
        for (var i = 0; i < menuItems.length; ++i) {
            if (menuItems[i].canTrigger) {
                menuItems[i].parentMenu = root;
                root.addItem(menuItems[i]);
                if (menuPreferredWidth)
                    menuItems[i].itemPreferredWidth = menuPreferredWidth;
                if (menuItemsPreferredHeight)
                    menuItems[i].itemPreferredHeight = menuItemsPreferredHeight;
            }
            if (menuItems[i].addMenuSeparatorAfter) {
                // If the QML file to be loaded is a local file,
                // you could omit the finishCreation() function
                var menuSeparatorComponent = Qt.createComponent("GeneralMenuSeparator.qml", Component.PreferSynchronous, root);
                var menuSeparatorComponentObj = menuSeparatorComponent.createObject();
                generalMenuSeparatorList.push(menuSeparatorComponentObj);
                root.addItem(menuSeparatorComponentObj);
            }
        }
        root.addItem(menuBottomBorder);
        root.open();
    }

    Component.onDestruction: {
        for (var i = 0; i < generalMenuSeparatorList.length; ++i) {
            generalMenuSeparatorList[i].destroy();
        }
    }
    onVisibleChanged: {
        if (!visible)
            root.close();
    }

    Overlay.modal: Rectangle {
        color: "transparent"
    }
    background: Rectangle {
        id: container
        border.color: JamiTheme.tabbarBorderColor
        border.width: JamiTheme.menuItemsCommonBorderWidth
        color: JamiTheme.backgroundColor
        implicitWidth: menuPreferredWidth ? menuPreferredWidth : JamiTheme.menuItemsPreferredWidth
        layer.enabled: true

        layer.effect: DropShadow {
            color: JamiTheme.shadowColor
            horizontalOffset: 3.0
            radius: 16.0
            transparentBorder: true
            verticalOffset: 3.0
            z: -1
        }
    }
}
