/*
 * Copyright (C) 2021-2023 Savoir-faire Linux Inc.
 * Author: Andreas Traczyk <andreas.traczyk@savoirfairelinux.com>
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
    property real barWidth
    property bool hasLast: ListView.view.centeredGroup !== undefined
    property bool isFirst: index < 1
    property bool isLast: index + 1 < ListView.view.count ? false : true
    property bool isVertical: root.ListView.view.orientation === ListView.Vertical
    property var menuAction: ItemAction.menuAction
    property alias subMenuVisible: menu.popup.visible

    Accessible.description: text
    Accessible.name: text
    Accessible.role: Accessible.Button
    action: ItemAction
    checkable: ItemAction.checkable
    hoverEnabled: ItemAction.enabled

    // hide the action's visual elements like the blurry looking icon
    icon.source: ""
    text: ""
    z: index

    // TODO: remove this when output volume control is implemented
    MouseArea {
        anchors.fill: root
        visible: ItemAction.openPopupWhenClicked !== undefined && ItemAction.openPopupWhenClicked && !menu.popup.visible

        onClicked: menu.popup.open()
    }

    // TODO: this can be a Rectangle once multistream is done
    HalfPill {
        id: supplimentaryBackground
        anchors.fill: parent
        color: root.down ? Qt.lighter(JamiTheme.refuseRed, 1.5) : root.hovered && !menu.hovered ? JamiTheme.refuseRed : JamiTheme.refuseRedTransparent
        radius: isLast ? 5 : width / 2
        type: isLast ? HalfPill.Right : HalfPill.None
        visible: ItemAction.hasBg !== undefined

        Behavior on color  {
            ColorAnimation {
                duration: JamiTheme.shortFadeDuration
            }
        }
    }
    ResponsiveImage {
        id: icon

        // TODO: remove this when the icons are size corrected
        property real size: ItemAction.size !== undefined ? ItemAction.size : 30

        anchors.centerIn: parent
        color: ItemAction ? (ItemAction.enabled ? ItemAction.icon.color : Qt.lighter(ItemAction.icon.color)) : null
        containerHeight: size
        containerWidth: size
        source: ItemAction ? ItemAction.icon.source : ""

        SequentialAnimation on opacity  {
            loops: Animation.Infinite
            running: ItemAction !== undefined && ItemAction.blinksWhenChecked !== undefined && ItemAction.blinksWhenChecked && checked

            onStopped: icon.opacity = 1

            NumberAnimation {
                duration: JamiTheme.recordBlinkDuration
                from: 1
                to: 0
            }
            NumberAnimation {
                duration: JamiTheme.recordBlinkDuration
                from: 0
                to: 1
            }
        }
    }

    // custom anchor for the tooltips
    Item {
        anchors.bottom: !isVertical ? parent.top : undefined
        anchors.horizontalCenter: !isVertical ? parent.horizontalCenter : undefined
        anchors.right: isVertical ? parent.left : undefined
        anchors.rightMargin: isVertical ? toolTip.contentWidth / 2 + 12 : 0
        anchors.topMargin: 25
        anchors.verticalCenter: isVertical ? parent.verticalCenter : undefined
        anchors.verticalCenterOffset: isVertical ? toolTip.contentHeight / 2 + 4 : 0

        MaterialToolTip {
            id: toolTip
            font.pointSize: 9
            parent: parent
            text: menu.hovered ? menuAction.text : (ItemAction !== undefined ? ItemAction.text : null)
            verticalPadding: 1
            visible: text.length > 0 && (root.hovered || menu.hovered)
        }
    }
    ComboBox {
        id: menu
        anchors.horizontalCenter: isVertical ? undefined : parent.horizontalCenter
        anchors.verticalCenter: isVertical ? parent.verticalCenter : undefined
        height: width
        indicator: null
        layer.enabled: true
        model: visible ? menuAction.listModel : null
        visible: ItemAction.enabled && menuAction !== undefined && !UrgentCount && menuAction.enabled
        width: 18
        x: isVertical ? -4 : 0
        y: isVertical ? 0 : -4

        onActivated: index => menuAction.accept(index);

        Connections {
            target: menuAction !== undefined ? menuAction : null

            function onTriggered() {
                if (menuAction.popupMode !== CallActionBar.ActionPopupMode.ListElement)
                    itemListView.currentIndex = menuAction.listModel.getCurrentIndex();
            }
        }

        background: Rectangle {
            color: menu.down ? "#aaaaaa" : menu.hovered ? "#777777" : "#444444"
            radius: 4
        }
        contentItem: ResponsiveImage {
            color: "white"
            source: isVertical ? JamiResources.chevron_left_black_24dp_svg : JamiResources.expand_less_24dp_svg
        }
        delegate: ItemDelegate {
            id: menuItem
            height: {
                if (menuAction.popupMode === CallActionBar.ActionPopupMode.LayoutOption && (!TopMargin || !BottomMargin)) {
                    return 40;
                }
                return 45;
            }
            width: itemListView.menuItemWidth

            background: Rectangle {
                anchors.fill: parent
                color: menuItem.down ? "#c4aaaaaa" : menuItem.hovered ? "#c4777777" : "transparent"
            }
            contentItem: ColumnLayout {
                anchors.fill: parent
                spacing: 0

                RowLayout {
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
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    Layout.leftMargin: 20
                    Layout.rightMargin: 15
                    spacing: 6

                    ResponsiveImage {
                        color: "white"
                        height: 20
                        source: menuAction.popupMode === CallActionBar.ActionPopupMode.ListElement || menuAction.popupMode === CallActionBar.ActionPopupMode.LayoutOption ? IconSource : (menuItem.ListView.isCurrentItem ? JamiResources.check_box_24dp_svg : JamiResources.check_box_outline_blank_24dp_svg)
                        width: 20
                    }
                    Text {
                        id: delegateText
                        Layout.fillWidth: true
                        color: "white"
                        elide: Text.ElideRight
                        font.pointSize: JamiTheme.participantFontSize
                        horizontalAlignment: Text.AlignLeft
                        text: menuAction.popupMode === CallActionBar.ActionPopupMode.ListElement || menuAction.popupMode === CallActionBar.ActionPopupMode.LayoutOption ? Name : DeviceName
                        verticalAlignment: Text.AlignVCenter
                    }
                    ResponsiveImage {
                        color: "white"
                        height: 20
                        source: JamiResources.check_black_24dp_svg
                        visible: menuAction.popupMode === CallActionBar.ActionPopupMode.LayoutOption ? ActiveSetting : false
                        width: 20
                    }
                }
                Rectangle {
                    id: buttonDiv
                    Layout.alignment: Qt.AlignBottom
                    Layout.fillWidth: true
                    border.width: 0
                    color: JamiTheme.separationLine
                    height: 1
                    opacity: 0.2
                    visible: menuAction.popupMode === CallActionBar.ActionPopupMode.LayoutOption ? SectionEnd : false
                }
            }
        }
        layer.effect: DropShadow {
            color: "#80000000"
            horizontalOffset: 0
            radius: 8.0
            transparentBorder: true
            verticalOffset: 0
            z: -1
        }
        popup: Popup {
            id: itemPopup
            implicitHeight: contentItem.implicitHeight
            implicitWidth: contentItem.implicitWidth
            leftPadding: 0
            rightPadding: 0
            x: {
                if (isVertical)
                    return -implicitWidth - 12;
                var xValue = -(implicitWidth - root.width) / 2 - 18;
                var mainPoint = mapToItem(viewCoordinator.rootView, xValue, y);
                var diff = mainPoint.x + itemListView.implicitWidth - viewCoordinator.rootView.width;
                return diff > 0 ? xValue - diff - 24 : xValue;
            }
            y: isVertical ? -(implicitHeight - root.height) / 2 - 18 : -implicitHeight - 12

            onOpened: menuAction.triggered()

            background: Rectangle {
                anchors.fill: parent
                color: "#c4272727"
                radius: 5
            }
            contentItem: JamiListView {
                id: itemListView
                property real menuItemHeight: 39
                property real menuItemWidth: 0

                implicitHeight: Math.min(contentHeight, menuItemHeight * 9) + 24
                implicitWidth: menuItemWidth
                model: menu.delegateModel
                orientation: ListView.Vertical
                pixelAligned: true

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

                TextMetrics {
                    id: itemTextMetrics
                    font.pointSize: JamiTheme.participantFontSize
                }
            }
        }
    }
    BadgeNotifier {
        id: badge
        anchors.horizontalCenter: parent.horizontalCenter
        count: UrgentCount
        height: width
        radius: 4
        visible: count > 0
        width: 18
        y: -4
    }

    background: HalfPill {
        anchors.fill: parent
        color: {
            if (supplimentaryBackground.visible)
                return "#c4272727";
            return root.down ? "#c4777777" : (root.hovered && !menu.hovered) ? "#c4444444" : "#c4272727";
        }
        radius: type === HalfPill.None ? 0 : 5
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

        Behavior on color  {
            ColorAnimation {
                duration: JamiTheme.shortFadeDuration
            }
        }
    }
}
