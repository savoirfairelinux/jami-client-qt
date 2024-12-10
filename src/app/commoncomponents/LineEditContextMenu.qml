/*
 * Copyright (C) 2020-2024 Savoir-faire Linux Inc.
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
import net.jami.Constants 1.1
import "contextmenu"

ContextMenuAutoLoader {
    id: root

    // lineEdit (TextEdit) selection will be lost when menu is opened
    property var lineEditObj
    property var selectionStart
    property var selectionEnd
    property bool customizePaste: false
    property bool selectOnly: false

    signal contextMenuRequirePaste

    property list<GeneralMenuItem> menuItems
    property var copyItem
    property var cutItem
    property var pasteItem

    function newMenuItems() {
        var component = Qt.createComponent("contextmenu/GeneralMenuItem.qml");
        menuItems = [];
        copyItem = component.createObject(root, {
            "canTrigger": true,
            "hasIcon": false,
            "isActif": lineEditObj.selectedText.length,
            "itemName": JamiStrings.copy
        });
        if (copyItem == null) {
            console.warn("Error creating GeneralMenuItem object");
        } else {
            copyItem.clicked.connect(lineEditObj.copy);
            menuItems.push(copyItem);
        }
        cutItem = component.createObject(root, {
            "canTrigger": true,
            "hasIcon": false,
            "isActif": lineEditObj.selectedText.length && !selectOnly,
            "itemName": JamiStrings.cut
        });
        if (cutItem == null) {
            console.warn("Error creating GeneralMenuItem object");
        } else {
            cutItem.clicked.connect(lineEditObj.cut);
            menuItems.push(cutItem);
        }
        pasteItem = component.createObject(root, {
            "canTrigger": !selectOnly,
            "hasIcon": false,
            "itemName": JamiStrings.paste
        });
        if (pasteItem == null) {
            console.warn("Error creating GeneralMenuItem object");
        } else {
            pasteItem.clicked.connect(customizePaste ? root.contextMenuRequirePaste : lineEditObj.paste);
            menuItems.push(pasteItem);
        }
    }

    function openMenuAt(mouseEvent) {
        root.newMenuItems();
        if (lineEditObj.selectedText.length === 0 && selectOnly)
            return;
        x = mouseEvent.x;
        y = mouseEvent.y;
        selectionStart = lineEditObj.selectionStart;
        selectionEnd = lineEditObj.selectionEnd;
        root.openMenu();
        lineEditObj.select(selectionStart, selectionEnd);
    }

    Connections {
        target: root.item
        enabled: root.status === Loader.Ready
        function onOpened() {
            lineEditObj.select(selectionStart, selectionEnd);
        }
    }

    Component.onCompleted: menuItemsToLoad = menuItems
}
