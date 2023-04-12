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
import QtQuick.Layouts
import net.jami.Constants 1.1
import "../"

// General menu item.
// Can control top, bottom, left, right border width.
// Use onClicked slot to simulate item click event.
// Can have image icon at the left of the text.
MenuItem {
    id: menuItem
    property bool addMenuSeparatorAfter: false
    property bool autoTextSizeAdjustment: true
    property bool canTrigger: true
    property bool dangerous: false
    property string iconColor: ""
    property alias iconSource: contextMenuItemImage.source
    property bool itemHovered: menuItemContentRect.hovered
    property int itemImageLeftMargin: 24
    property string itemName: ""
    property int itemPreferredHeight: JamiTheme.menuItemsPreferredHeight
    property int itemPreferredWidth: JamiTheme.menuItemsPreferredWidth
    property int itemTextMargin: 20
    property int leftBorderWidth: JamiTheme.menuItemsCommonBorderWidth
    property BaseContextMenu parentMenu
    property int rightBorderWidth: JamiTheme.menuItemsCommonBorderWidth

    highlighted: true

    signal clicked

    background: Rectangle {
        id: contextMenuBackgroundRect
        anchors.fill: parent
        anchors.leftMargin: leftBorderWidth
        anchors.rightMargin: rightBorderWidth
        border.width: 0
        implicitHeight: itemPreferredHeight
        implicitWidth: itemPreferredWidth

        CustomBorder {
            bBorderwidth: 0
            borderColor: JamiTheme.tabbarBorderColor
            commonBorder: false
            lBorderwidth: leftBorderWidth
            rBorderwidth: rightBorderWidth
            tBorderwidth: 0
        }
    }
    contentItem: AbstractButton {
        id: menuItemContentRect
        anchors.fill: parent

        onReleased: {
            menuItem.clicked();
            parentMenu.close();
        }

        RowLayout {
            anchors.fill: menuItemContentRect
            spacing: 0

            ResponsiveImage {
                id: contextMenuItemImage
                Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
                Layout.leftMargin: status === Image.Ready ? itemImageLeftMargin : 0
                color: iconColor !== "" ? iconColor : JamiTheme.textColor
                opacity: 0.7
                visible: status === Image.Ready
            }
            Text {
                id: contextMenuItemText
                Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
                Layout.fillWidth: true
                Layout.leftMargin: contextMenuItemImage.status === Image.Ready ? itemTextMargin : itemTextMargin / 2
                Layout.preferredHeight: itemPreferredHeight
                Layout.rightMargin: contextMenuItemImage.status === Image.Ready ? itemTextMargin : itemTextMargin / 2
                color: dangerous ? JamiTheme.redColor : JamiTheme.textColor
                font.pointSize: JamiTheme.textFontSize
                horizontalAlignment: Text.AlignLeft
                text: itemName
                verticalAlignment: Text.AlignVCenter

                TextMetrics {
                    id: contextMenuItemTextMetrics
                    font: contextMenuItemText.font
                    text: contextMenuItemText.text

                    onBoundingRectChanged: {
                        var sizeToCompare = itemPreferredWidth - (contextMenuItemImage.source.toString().length > 0 ? itemTextMargin + itemImageLeftMargin + contextMenuItemImage.width : itemTextMargin / 2);
                        if (autoTextSizeAdjustment && boundingRect.width > sizeToCompare) {
                            if (boundingRect.width > JamiTheme.contextMenuItemTextMaxWidth) {
                                itemPreferredWidth += JamiTheme.contextMenuItemTextMaxWidth - JamiTheme.contextMenuItemTextPreferredWidth + itemTextMargin;
                                contextMenuItemText.elide = Text.ElideRight;
                            } else
                                itemPreferredWidth += boundingRect.width + itemTextMargin - sizeToCompare;
                        }
                    }
                }
            }
        }

        background: Rectangle {
            id: background
            anchors.fill: parent
            anchors.leftMargin: 1
            anchors.rightMargin: 1
            color: menuItemContentRect.hovered ? JamiTheme.hoverColor : JamiTheme.backgroundColor
        }
    }
}
