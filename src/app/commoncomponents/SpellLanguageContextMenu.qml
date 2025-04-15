/*
 * Copyright (C) 2020-2024 Savoir-faire Linux Inc.
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
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import net.jami.Models 1.1
import "contextmenu"
import "../mainview"
import "../mainview/components"

ContextMenuAutoLoader {
    id: root

    signal languageChanged(string language)

    // What is this used for?
    CachedFile {
        id: cachedFile
    }

    // Is this used?
    function openMenuAt(mouseEvent) {
        x = mouseEvent.x;
        y = mouseEvent.y;
        root.openMenu();
    }

    onOpenRequested: {
        // Create the menu items from the installed dictionaries
        menuItemsToLoad = generateMenuItems();
    }

    function generateMenuItems() {
        var menuItems = [];
        // Create new menu items
        var dictionaries = SpellCorrectorHandler.installedDictionaries();
        for (var key in dictionaries) {
            var menuItem = Qt.createComponent("qrc:/commoncomponents/contextmenu/GeneralMenuItem.qml", Component.PreferSynchronous);
            if (menuItem.status !== Component.Ready) {
                console.error("Error loading component:", menuItem.errorString());
                continue;
            }
            var menuItemObject = menuItem.createObject(root, {
                "parent": root,
                "canTrigger": true,
                "isActif": true,
                "itemName": dictionaries[key],
                "hasIcon": false
            });
            if (menuItemObject === null) {
                console.error("Error creating menu item:", menuItem.errorString());
                continue;
            }
            menuItemObject.clicked.connect(function() {
                console.log("444 menuItemObject.clicked: " + menuItemObject.itemName, menuItemObject);
                root.languageChanged(menuItemObject.itemName);
            });
            // Log the object pointer
            console.log("111 generateMenuItems: " + menuItemObject.itemName, menuItemObject);
            menuItems.push(menuItemObject);
        }
        return menuItems;
    }
}
