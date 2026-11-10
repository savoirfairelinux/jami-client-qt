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
import Jami as JamiStyle
import net.jami.Constants 1.1

JamiStyle.Menu {
    id: root

    property int menuPreferredWidth: 0
    property int menuItemsPreferredHeight: 0
    property int menuSeparatorPreferredHeight: 0

    property var generalMenuSeparatorList: []

    function loadMenuItems(menuItems) {
        var visibleItems = menuItems.filter(item => item.canTrigger);

        // Establish the preferred width of the menu by taking the maximum width of the items
        for (var j = 0; j < visibleItems.length; ++j) {
            var currentItemWidth = visibleItems[j].itemPreferredWidth;
            if (currentItemWidth !== JamiTheme.menuItemsPreferredWidth && currentItemWidth > menuPreferredWidth)
                menuPreferredWidth = currentItemWidth;
        }

        // Add the items to the menu
        for (var i = 0; i < visibleItems.length; ++i) {
            visibleItems[i].parentMenu = root;
            root.addItem(visibleItems[i]);
            if (menuPreferredWidth)
                visibleItems[i].itemRealWidth = menuPreferredWidth;
            if (menuItemsPreferredHeight)
                visibleItems[i].itemPreferredHeight = menuItemsPreferredHeight;
            var menuSeparatorComponent, menuSeparatorComponentObj;
            if (i !== visibleItems.length - 1) {
                menuSeparatorComponent = Qt.createComponent("GeneralMenuSeparator.qml", Component.PreferSynchronous, root);
                menuSeparatorComponentObj = menuSeparatorComponent.createObject();
                generalMenuSeparatorList.push(menuSeparatorComponentObj);
                root.addItem(menuSeparatorComponentObj);
            }
            if (visibleItems[i].addMenuSeparatorAfter) {
                menuSeparatorComponent = Qt.createComponent("GeneralMenuSeparator.qml", Component.PreferSynchronous, root);
                menuSeparatorComponentObj = menuSeparatorComponent.createObject(null, {
                    "separatorColor": JamiTheme.menuSeparatorColor,
                    "separatorPreferredHeight": 0
                });
                generalMenuSeparatorList.push(menuSeparatorComponentObj);
                root.addItem(menuSeparatorComponentObj);
                menuSeparatorComponentObj = menuSeparatorComponent.createObject();
                generalMenuSeparatorList.push(menuSeparatorComponentObj);
                root.addItem(menuSeparatorComponentObj);
            }
        }
    }

    font.pointSize: JamiTheme.menuFontSize

    background.implicitWidth: menuPreferredWidth ? menuPreferredWidth : JamiTheme.menuItemsPreferredWidth

    Component.onDestruction: {
        if (typeof menuItemsToLoad !== "undefined" && menuItemsToLoad)
            menuItemsToLoad.forEach(item => item.parent = null)
    }
}
