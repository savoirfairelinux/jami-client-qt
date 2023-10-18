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

    function loadMenuItems(menuItems) {
        root.addItem(menuTopBorder);
        for (var i = 0; i < menuItems.length; ++i) {
            if (menuItems[i].canTrigger) {
                menuItems[i].parentMenu = root;
                root.addItem(menuItems[i]);
                if (menuPreferredWidth)
                    menuItems[i].itemPreferredWidth = menuPreferredWidth;
                if (menuItemsPreferredHeight)
                    menuItems[i].itemPreferredHeight = menuItemsPreferredHeight;
            }
        }
        root.addItem(menuBottomBorder);
        root.open();
    }

    onVisibleChanged: {
        if (!visible)
            root.close();
    }

    modal: true
    Overlay.modal: Rectangle {
        color: "transparent"
    }

    font.pointSize: JamiTheme.menuFontSize

    background: Rectangle {

        implicitWidth: menuPreferredWidth ? menuPreferredWidth : JamiTheme.menuItemsPreferredWidth

        color: JamiTheme.primaryBackgroundColor
        radius: 5

        layer.enabled: true
        layer.effect: DropShadow {
            z: -1
            horizontalOffset: 3.0
            verticalOffset: 3.0
            radius: 6
            color: JamiTheme.shadowColor
            transparentBorder: true
            samples: radius + 1
        }
    }
}
