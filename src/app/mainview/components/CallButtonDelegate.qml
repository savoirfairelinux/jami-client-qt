/*
 * Copyright (C) 2021-2026 Savoir-faire Linux Inc.
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
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import net.jami.Models 1.1
import net.jami.Constants 1.1
import "../../commoncomponents"

ItemDelegate {
    id: root

    property bool isFirst: index < 1
    property bool isLast: index + 1 < ListView.view.count ? false : true
    property bool hasLast: ListView.view.centeredGroup !== undefined
    property bool isVertical: root.ListView.view.orientation === ListView.Vertical
    property real barWidth

    property alias subMenuVisible: menu.popup.visible

    action: ItemAction
    checkable: ItemAction.checkable
    hoverEnabled: ItemAction.enabled

    // hide the action's visual elements like the blurry looking icon
    icon.source: ""
    text: ""

    Accessible.role: Accessible.Button
    Accessible.name: ItemAction.text
    Accessible.description: {
        if (!ItemAction?.text)
            return "";
        if (ItemAction.checkable) {
            return JamiStrings.pressToToggle.arg(ItemAction.text).arg(ItemAction.checked ? JamiStrings.active : JamiStrings.inactive);
        }
        return JamiStrings.pressToAction.arg(ItemAction.text);
    }
    Accessible.pressed: pressed
    Accessible.checkable: ItemAction ? ItemAction.checkable : false
    Accessible.checked: ItemAction ? ItemAction.checked : false

    z: index

    // TODO: remove this when output volume control is implemented
    MouseArea {
        visible: ItemAction.openPopupWhenClicked !== undefined && ItemAction.openPopupWhenClicked && !menu.popup.visible
        anchors.fill: root
        onClicked: menu.popup.open()
    }

    background: HalfPill {
        anchors.fill: parent
        radius: type === HalfPill.None ? 0 : 5
        color: {
            if (supplimentaryBackground.visible)
                return "#c4272727";
            return root.down ? "#c4777777" : (root.hovered && !menu.hovered) ? "#c4444444" : "#c4272727";
        }
        type: {
            if (isVertical) {
                if (isFirst)
                    return HalfPill.Top;
                else if (isLast && hasLast)
                    return HalfPill.Bottom;
            } else {
                if (isFirst)
                    return HalfPill.Left;
                else if (isLast && hasLast)
                    return HalfPill.Right;
            }
            return HalfPill.None;
        }

        Behavior on color {
            ColorAnimation {
                duration: JamiTheme.shortFadeDuration
            }
        }
    }

    // TODO: this can be a Rectangle once multistream is done
    HalfPill {
        id: supplimentaryBackground

        visible: ItemAction.hasBg !== undefined
        color: root.down ? Qt.lighter(JamiTheme.declineRed, 1.5) : root.hovered && !menu.hovered ? JamiTheme.declineRed : JamiTheme.declineRedTransparent
        anchors.fill: parent
        radius: isLast ? 5 : width / 2
        type: isLast ? HalfPill.Right : HalfPill.None

        Behavior on color {
            ColorAnimation {
                duration: JamiTheme.shortFadeDuration
            }
        }
    }

    ResponsiveImage {
        id: icon

        // TODO: remove this when the icons are size corrected
        property real size: ItemAction.size !== undefined ? ItemAction.size : 30
        containerWidth: size
        containerHeight: size

        anchors.centerIn: parent
        source: ItemAction ? ItemAction.icon.source : ""
        color: ItemAction ? (ItemAction.enabled ? ItemAction.icon.color : Qt.lighter(ItemAction.icon.color)) : null

        SequentialAnimation on opacity {
            loops: Animation.Infinite
            running: ItemAction !== undefined && ItemAction.blinksWhenChecked !== undefined && ItemAction.blinksWhenChecked && checked
            onStopped: icon.opacity = 1
            NumberAnimation {
                from: 1
                to: 0
                duration: JamiTheme.recordBlinkDuration
            }
            NumberAnimation {
                from: 0
                to: 1
                duration: JamiTheme.recordBlinkDuration
            }
        }
    }

    // custom anchor for the tooltips
    Item {
        anchors.bottom: !isVertical ? parent.top : undefined
        anchors.topMargin: 25
        anchors.horizontalCenter: !isVertical ? parent.horizontalCenter : undefined

        anchors.right: isVertical ? parent.left : undefined
        anchors.rightMargin: isVertical ? toolTip.contentWidth / 2 + 12 : 0
        anchors.verticalCenter: isVertical ? parent.verticalCenter : undefined
        anchors.verticalCenterOffset: isVertical ? toolTip.contentHeight / 2 + 4 : 0

        MaterialToolTip {
            id: toolTip
            parent: parent
            visible: text.length > 0 && (root.hovered || menu.hovered)
            text: menu.hovered ? menuAction.text : (ItemAction !== undefined ? ItemAction.text : null)
            verticalPadding: 1
            font.pointSize: 9
        }
    }

    property var menuAction: ItemAction.menuAction

    ComboBox {
        id: menu

        indicator: null

        visible: ItemAction.enabled && menuAction !== undefined && !UrgentCount && menuAction.enabled

        y: isVertical ? 0 : -4
        x: isVertical ? -4 : 0
        anchors.horizontalCenter: isVertical ? undefined : parent.horizontalCenter
        anchors.verticalCenter: isVertical ? parent.verticalCenter : undefined

        width: 18
        height: width

        Connections {
            target: menuAction !== undefined ? menuAction : null
            function onTriggered() {
                var index;
                switch (menuAction.popupMode) {
                case CallActionBar.ActionPopupMode.MediaDevice:
                    index = menuAction.listModel.getCurrentIndex();
                    break;
                case CallActionBar.ActionPopupMode.LayoutOption:
                    index = menuAction.listModel.currentIndex;
                    break;
                case CallActionBar.ActionPopupMode.ListElement:
                    index = menuAction.listModel.currentIndex;
                    break;
                default:
                    console.warn("Unknown popup mode: " + menuAction.popupMode);
                    return;
                }
                if (index !== undefined) {
                    itemListView.currentIndex = index;
                }
            }
        }

        contentItem: ResponsiveImage {
            source: isVertical ? JamiResources.chevron_left_black_24dp_svg : JamiResources.expand_less_24dp_svg
            color: "white"
        }

        background: Rectangle {
            color: menu.down ? "#aaaaaa" : menu.hovered ? "#777777" : "#444444"
            radius: 4
        }

        onActivated: index => menuAction.accept(index)
        model: visible ? menuAction.listModel : null
        delegate: ItemDelegate {
            id: menuItem

            width: itemListView.menuItemWidth
            height: {
                if (menuAction.popupMode === CallActionBar.ActionPopupMode.LayoutOption && (!TopMargin || !BottomMargin)) {
                    return 40;
                }
                return 45;
            }
            background: Rectangle {
                anchors.fill: parent
                color: menuItem.down ? "#c4aaaaaa" : menuItem.hovered ? "#c4777777" : "transparent"
            }
            // After update to qt 6.4.3 the layout was broken, adding a Rectangle
            // as top level in the contentIntem is a workaround which removal can be
            // tested with newer qt versions
            contentItem: Rectangle {
                anchors.fill: parent
                color: "transparent"
                ColumnLayout {
                    anchors.fill: parent
                    spacing: 0

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.rightMargin: 15
                        Layout.leftMargin: 20

                        Layout.alignment: {
                            if (menuAction.popupMode !== CallActionBar.ActionPopupMode.LayoutOption || TopMargin && BottomMargin) {
                                return Qt.AlignLeft | Qt.AlignVCenter;
                            }
                            if (TopMargin) {
                                Layout.bottomMargin = 4;
                                return Qt.AlignBottom;
                            }
                            Layout.topMargin = 4;
                            return Qt.AlignTop;
                        }

                        spacing: 6
                        ResponsiveImage {
                            source: {
                                if (menuAction.popupMode === CallActionBar.ActionPopupMode.ListElement) {
                                    return IconSource || "";
                                } else if (menuAction.popupMode === CallActionBar.ActionPopupMode.LayoutOption) {
                                    return IconSource || "";
                                } else {
                                    return menuItem.ListView.isCurrentItem ? JamiResources.check_box_24dp_svg : JamiResources.check_box_outline_blank_24dp_svg;
                                }
                            }
                            color: "white"
                            width: 20
                            height: 20
                        }
                        Text {
                            id: delegateText
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignLeft
                            verticalAlignment: Text.AlignVCenter
                            text: menuAction.popupMode === CallActionBar.ActionPopupMode.ListElement || menuAction.popupMode === CallActionBar.ActionPopupMode.LayoutOption ? Name : DeviceName
                            elide: Text.ElideRight
                            font.pointSize: JamiTheme.participantFontSize
                            color: "white"
                        }
                        ResponsiveImage {
                            source: JamiResources.check_black_24dp_svg
                            color: "white"
                            width: 20
                            height: 20
                            visible: menuAction.popupMode === CallActionBar.ActionPopupMode.LayoutOption ? ActiveSetting : false
                        }
                    }
                    Rectangle {
                        id: buttonDiv
                        visible: menuAction.popupMode === CallActionBar.ActionPopupMode.LayoutOption ? SectionEnd : false
                        Layout.fillWidth: true
                        height: 1
                        opacity: 0.2
                        border.width: 0
                        color: JamiTheme.separationLine
                        Layout.alignment: Qt.AlignBottom
                    }
                }
            }
        }

        popup: Popup {
            id: itemPopup

            y: {
                // Determine the y position based on the orientation.
                if (isVertical) {
                    // For a vertical layout, adjust the y position to center the item vertically
                    // relative to the root's height, with an additional upward offset of 18 pixels.
                    return -(implicitHeight - root.height) / 2 - 18;
                } else {
                    // For non-vertical layouts, position the item fully above its normal position
                    // with an upward offset of 12 pixels from its implicit height.
                    return -implicitHeight - 12;
                }
            }

            x: {
                // Initialize the x position based on the orientation.
                if (isVertical) {
                    // If the layout is vertical, position the item to the left of its implicit width
                    // with an additional offset of 12 pixels.
                    return -implicitWidth - 12;
                } else {
                    // Note: isn't some of this logic built into the Popup?

                    // Calculate an initial x value aiming to center the item horizontally
                    // relative to the root's width, with an additional offset.
                    var xValue = -(implicitWidth - root.width) / 2 - 18;

                    // Map the adjusted x value to the coordinate space of the callOverlay to
                    // determine the actual position of the item within the overlay.
                    var pointMappedContainer = mapToItem(callOverlay, xValue, y);

                    // Calculate the difference between the right edge of the itemListView
                    // (considering its position within callOverlay) and the right edge of the callOverlay.
                    // This checks if the item extends outside the overlay.
                    var diff = pointMappedContainer.x + itemListView.implicitWidth - callOverlay.width;

                    // If the item extends beyond the overlay, adjust x value to the left to ensure
                    // it fits within the overlay, with an extra leftward margin of 24 pixels.
                    return diff > 0 ? xValue - diff - 24 : xValue;
                }
            }

            implicitWidth: contentItem.implicitWidth
            implicitHeight: contentItem.implicitHeight
            leftPadding: 0
            rightPadding: 0

            onOpened: menuAction.triggered()

            contentItem: JamiListView {
                id: itemListView

                property real menuItemWidth: 0
                property real menuItemHeight: 39

                pixelAligned: true
                orientation: ListView.Vertical
                implicitWidth: menuItemWidth
                implicitHeight: Math.min(contentHeight, menuItemHeight * 9) + 24

                model: menu.delegateModel

                TextMetrics {
                    id: itemTextMetrics

                    font.pointSize: JamiTheme.participantFontSize
                }

                // recalc list width based on max item width
                onCountChanged: {
                    var mPreferredWidth = 145;
                    if (count && menuAction.popupMode === CallActionBar.ActionPopupMode.LayoutOption) {
                        menuItemWidth = 290;
                        return;
                    }
                    for (var i = 0; i < count; ++i) {
                        if (menuAction.popupMode === CallActionBar.ActionPopupMode.ListElement)
                            itemTextMetrics.text = menuAction.listModel.get(i).Name;
                        else {
                            // Hack: use AudioDeviceModel.DeviceName role for video as well
                            var idx = menuAction.listModel.index(i, 0);
                            itemTextMetrics.text = menuAction.listModel.data(idx, AudioDeviceModel.DeviceName);
                        }
                        if (itemTextMetrics.boundingRect.width > mPreferredWidth)
                            mPreferredWidth = itemTextMetrics.boundingRect.width;
                    }
                    // 30(icon) + 5(layout spacing) + 12(margins) + 20 to avoid text elipsis
                    mPreferredWidth = mPreferredWidth + 30 + 5 + 12 + 20;
                    mPreferredWidth = Math.min(root.barWidth, mPreferredWidth);
                    menuItemWidth = mPreferredWidth;
                }
            }

            background: Rectangle {
                anchors.fill: parent
                radius: 5
                color: "#c4272727"
            }
        }

        layer.enabled: true
        layer.effect: DropShadow {
            z: -1
            horizontalOffset: 0
            verticalOffset: 0
            radius: 8.0
            color: "#80000000"
            transparentBorder: true
            samples: radius + 1
        }
    }

    BadgeNotifier {
        id: badge

        visible: count > 0
        count: UrgentCount
        anchors.horizontalCenter: parent.horizontalCenter
        width: 18
        height: width
        radius: 4
        y: -4
    }
}
