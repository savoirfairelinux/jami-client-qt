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

import "../../../src/app/"
import "../../../src/app/mainview/components"

TestWrapper {
    Item {
        id: root

        width: 240
        height: 80

        Action {
            id: popupAction

            text: "Menu"
            enabled: true
            property int popupMode: CallActionBar.ActionPopupMode.ListElement
            property var listModel: ListModel {
                property int currentIndex: 1

                ListElement { Name: "First"; IconSource: ""; IsCheckable: false }
                ListElement { Name: "Second"; IconSource: ""; IsCheckable: false }
            }
        }

        Action {
            id: itemAction

            text: "Button"
            enabled: true
            property var menuAction: popupAction
        }

        ListView {
            id: buttonList

            width: 80
            height: 80
            orientation: ListView.Horizontal
            model: [{ "ItemAction": itemAction, "UrgentCount": 0 }]
            delegate: CallButtonDelegate {
                objectName: "callButtonDelegate"
                width: 80
                height: 80
                barWidth: root.width
            }
        }
    }

    TestCase {
        name: "CallButtonDelegate"
        when: windowShown

        function test_syncMenuCurrentIndex() {
            const delegate = findChild(root, "callButtonDelegate");
            verify(delegate);

            const menuListView = findChild(delegate, "callButtonMenuListView");
            verify(menuListView);

            popupAction.listModel.currentIndex = 1;
            delegate.syncMenuCurrentIndex();
            compare(menuListView.currentIndex, 1);

            popupAction.listModel.currentIndex = 0;
            delegate.syncMenuCurrentIndex();
            compare(menuListView.currentIndex, 0);
        }
    }
}
