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
import QtQuick.Controls
import QtTest

import "../../../src/app/commoncomponents"
import "../../../src/app/mainview/components"

Column {
    id: root

    width: 300

    MaterialLineEdit {
        id: materialLineEdit

        width: root.width
        text: "text"
    }

    MaterialTextField {
        id: materialTextField

        width: root.width
        text: "text"
    }

    NewMaterialTextField {
        id: newMaterialTextField

        width: root.width
        textFieldContent: "text"
    }

    Searchbar {
        id: searchbar

        width: root.width
        height: 40
    }

    TestCase {
        name: "Text field context menu"
        when: windowShown

        function test_rightClickOpensOnlyJamiContextMenu_data() {
            return [
                {
                    "tag": "MaterialLineEdit",
                    "owner": materialLineEdit
                },
                {
                    "tag": "MaterialTextField",
                    "owner": materialTextField
                },
                {
                    "tag": "NewMaterialTextField",
                    "owner": newMaterialTextField
                },
                {
                    "tag": "Searchbar",
                    "owner": searchbar
                }
            ];
        }

        // Regression: Qt's default menu (Undo, Redo, Cut...) opened on
        // right-button press, before Jami's menu opened on release.
        function test_rightClickOpensOnlyJamiContextMenu(data) {
            const jamiMenu = findChild(data.owner, "lineEditContextMenu");
            verify(jamiMenu);
            const field = jamiMenu.lineEditObj;

            mousePress(field, field.width / 2, field.height / 2, Qt.RightButton);
            const qtMenu = field.ContextMenu.menu;
            verify(!qtMenu || !qtMenu.visible, "Qt's default context menu opened");

            mouseRelease(field, field.width / 2, field.height / 2, Qt.RightButton);
            tryVerify(() => jamiMenu.item && jamiMenu.item.opened);
            jamiMenu.item.close();
            tryCompare(jamiMenu, "active", false);
        }
    }
}
