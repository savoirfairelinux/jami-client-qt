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
import net.jami.Constants 1.1
import "contextmenu"

ContextMenuAutoLoader {
    id: root
    property bool customizePaste: false

    // lineEdit (TextEdit) selection will be lost when menu is opened
    property var lineEditObj
    property list<GeneralMenuItem> menuItems: [
        GeneralMenuItem {
            id: copy
            canTrigger: lineEditObj.selectedText.length
            itemName: JamiStrings.copy

            onClicked: {
                lineEditObj.copy();
            }
        },
        GeneralMenuItem {
            id: cut
            canTrigger: lineEditObj.selectedText.length && !selectOnly
            itemName: JamiStrings.cut

            onClicked: {
                lineEditObj.cut();
            }
        },
        GeneralMenuItem {
            id: paste
            canTrigger: !selectOnly
            itemName: JamiStrings.paste

            onClicked: {
                if (customizePaste)
                    root.contextMenuRequirePaste();
                else
                    lineEditObj.paste();
            }
        }
    ]
    property bool selectOnly: false
    property var selectionEnd
    property var selectionStart

    contextMenuItemPreferredHeight: JamiTheme.lineEditContextMenuItemsHeight
    contextMenuItemPreferredWidth: JamiTheme.lineEditContextMenuItemsWidth
    contextMenuSeparatorPreferredHeight: JamiTheme.lineEditContextMenuSeparatorsHeight

    signal contextMenuRequirePaste
    function openMenuAt(mouseEvent) {
        if (lineEditObj.selectedText.length === 0 && selectOnly)
            return;
        x = mouseEvent.x;
        y = mouseEvent.y;
        selectionStart = lineEditObj.selectionStart;
        selectionEnd = lineEditObj.selectionEnd;
        root.openMenu();
        lineEditObj.select(selectionStart, selectionEnd);
    }

    Component.onCompleted: menuItemsToLoad = menuItems

    Connections {
        enabled: root.status === Loader.Ready
        target: root.item

        function onOpened() {
            lineEditObj.select(selectionStart, selectionEnd);
        }
    }
}
