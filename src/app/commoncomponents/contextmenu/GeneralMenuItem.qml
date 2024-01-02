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

    property string itemName: ""
    property alias iconSource: contextMenuItemImage.source
    property string iconColor: ""
    property bool canTrigger: true
    property bool hasIcon: true
    property bool addMenuSeparatorAfter: false
    property bool autoTextSizeAdjustment: true
    property bool dangerous: false
    property BaseContextMenu parentMenu
    property bool isActif: true

    property int itemPreferredWidth: hasIcon ? 50 + contextMenuItemText.contentWidth + contextMenuItemImage.width : 35 + contextMenuItemText.contentWidth
    property int itemRealWidth: itemPreferredWidth
    property int itemPreferredHeight: JamiTheme.menuItemsPreferredHeight
    property int leftBorderWidth: JamiTheme.menuItemsCommonBorderWidth
    property int rightBorderWidth: JamiTheme.menuItemsCommonBorderWidth

    property int itemImageLeftMargin: 10
    property int itemTextMargin: 10

    signal clicked
    property bool itemHovered: menuItemContentRect.hovered

    width: itemRealWidth

    contentItem: PushButton {
        id: menuItemContentRect

        enabled: isActif
        hoverEnabled: isActif

        hoveredColor: JamiTheme.hoverColor
        normalColor: JamiTheme.primaryBackgroundColor
        circled: false
        radius: 5

        //duration: 1000
        anchors.leftMargin: 6
        anchors.rightMargin: 6

        anchors.fill: parent

        RowLayout {
            spacing: 0

            anchors.fill: menuItemContentRect

            ResponsiveImage {
                id: contextMenuItemImage

                Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
                Layout.leftMargin: status === Image.Ready ? itemImageLeftMargin : 0

                visible: status === Image.Ready

                color: menuItemContentRect.hovered ? JamiTheme.textColor : JamiTheme.chatViewFooterImgColor
            }

            Item {
                Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
                Layout.leftMargin: contextMenuItemImage.status === Image.Ready ? itemTextMargin : itemTextMargin
                Layout.rightMargin: contextMenuItemImage.status === Image.Ready ? itemImageLeftMargin : itemTextMargin
                Layout.preferredHeight: itemPreferredHeight
                Layout.fillWidth: true

                Text {
                    id: contextMenuItemText
                    height: parent.height
                    text: itemName
                    color: dangerous ? JamiTheme.redColor : isActif ? JamiTheme.textColor : JamiTheme.chatViewFooterImgColor
                    font.pointSize: JamiTheme.textFontSize
                    horizontalAlignment: Text.AlignLeft
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                }
            }
        }

        onReleased: {
            menuItem.clicked();
            parentMenu.close();
        }
    }

    highlighted: true

    background: Rectangle {
        id: contextMenuBackgroundRect

        anchors.fill: parent
        anchors.leftMargin: leftBorderWidth
        anchors.rightMargin: rightBorderWidth

        color: JamiTheme.primaryBackgroundColor

        implicitWidth: itemRealWidth
        implicitHeight: itemPreferredHeight

        border.width: 0

        CustomBorder {
            commonBorder: false
            lBorderwidth: leftBorderWidth
            rBorderwidth: rightBorderWidth
            tBorderwidth: 0
            bBorderwidth: 0
            borderColor: JamiTheme.primaryBackgroundColor
        }
    }
}
