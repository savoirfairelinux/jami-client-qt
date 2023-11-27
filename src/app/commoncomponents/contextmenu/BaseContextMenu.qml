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

    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside | Popup.CloseOnPressOutsideParent

    property int menuPreferredWidth: 0
    property int menuItemsPreferredHeight: 0
    property int menuSeparatorPreferredHeight: 0

    property GeneralMenuSeparator menuTopBorder: GeneralMenuSeparator {
        separatorPreferredWidth: menuPreferredWidth ? menuPreferredWidth : JamiTheme.menuItemsPreferredWidth
        separatorPreferredHeight: menuSeparatorPreferredHeight ? menuSeparatorPreferredHeight : JamiTheme.menuBorderPreferredHeight
        separatorColor: "transparent"
    }

    property GeneralMenuSeparator menuBottomBorder: GeneralMenuSeparator {
        separatorPreferredWidth: menuPreferredWidth ? menuPreferredWidth : JamiTheme.menuItemsPreferredWidth
        separatorPreferredHeight: menuSeparatorPreferredHeight ? menuSeparatorPreferredHeight : JamiTheme.menuBorderPreferredHeight
        separatorColor: "transparent"
    }

    property var generalMenuSeparatorList: []

    function loadMenuItems(menuItems) {
        root.addItem(menuTopBorder);
        for (var j = 0; j < menuItems.length; ++j) {
            var currentItemWidth = menuItems[j].itemPreferredWidth;
            if (currentItemWidth !== JamiTheme.menuItemsPreferredWidth && currentItemWidth > menuPreferredWidth && menuItems[j].canTrigger)
                menuPreferredWidth = currentItemWidth;
        }
        for (var i = 0; i < menuItems.length; ++i) {
            if (menuItems[i].canTrigger) {
                menuItems[i].parentMenu = root;
                root.addItem(menuItems[i]);
                if (menuPreferredWidth)
                    menuItems[i].itemRealWidth = menuPreferredWidth;
                if (menuItemsPreferredHeight)
                    menuItems[i].itemPreferredHeight = menuItemsPreferredHeight;
                var menuSeparatorComponent, menuSeparatorComponentObj;
                if (i !== menuItems.length - 1) {
                    menuSeparatorComponent = Qt.createComponent("GeneralMenuSeparator.qml", Component.PreferSynchronous, root);
                    menuSeparatorComponentObj = menuSeparatorComponent.createObject();
                    generalMenuSeparatorList.push(menuSeparatorComponentObj);
                    root.addItem(menuSeparatorComponentObj);
                }
                if (menuItems[i].addMenuSeparatorAfter) {
                    menuSeparatorComponent = Qt.createComponent("GeneralMenuSeparator.qml", Component.PreferSynchronous, root);
                    menuSeparatorComponentObj = menuSeparatorComponent.createObject(root, {
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
        root.addItem(menuBottomBorder);
    }

    font.pointSize: JamiTheme.menuFontSize

    background: Rectangle {

        implicitWidth: menuPreferredWidth ? menuPreferredWidth : JamiTheme.menuItemsPreferredWidth

        color: JamiTheme.primaryBackgroundColor
        radius: 5

        layer.enabled: true
        layer.effect: DropShadow {
            z: -1
            horizontalOffset: 0.0
            verticalOffset: 3.0
            radius: 6
            color: "#29000000"
            transparentBorder: true
            samples: radius + 1
        }
    }

    Component.onDestruction: {
        for (var i = 0; i < generalMenuSeparatorList.length; ++i) {
            generalMenuSeparatorList[i].destroy();
        }
    }
}
