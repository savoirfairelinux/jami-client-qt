/*
 * Copyright (C) 2019-2024 Savoir-faire Linux Inc.
 * Author: Yang Wang   <yang.wang@savoirfairelinux.com>
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
import net.jami.Constants 1.1

ComboBox {
    id: root

    property alias tooltipText: toolTip.text
    property string placeholderText
    property string currentSelectionText: currentText
    property string comboBoxBackgroundColor: JamiTheme.editBackgroundColor
    property bool selection: currentIndex < 0 && !count

    MaterialToolTip {
        id: toolTip

        parent: root
        visible: hovered && (text.length > 0)
        delay: Qt.styleHints.mousePressAndHoldInterval
    }

    displayText: {
        // If the index is -1 and the model is empty, display the placeholder text.
        // The placeholder text is either the placeholderText property or a default text.
        // Otherwise, display the currentSelectionText property.
        if (currentIndex < 0 && !count) {
            return placeholderText !== "" ? placeholderText : JamiStrings.notAvailable;
        }
        return currentSelectionText;
    }

    delegate: ItemDelegate {
        width: root.width

        contentItem: Text {
            text: {
                if (index < 0)
                    return '';
                var currentItem = root.delegateModel.items.get(index);
                const value = currentItem.model[root.textRole];
                return value === undefined ? '' : value.toString();
            }

            color: hovered ? JamiTheme.comboboxTextColorHovered : JamiTheme.textColor
            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter
            font.pointSize: JamiTheme.settingsFontSize
        }

        background: Rectangle {
            color: hovered ? JamiTheme.comboboxBackgroundColorHovered : JamiTheme.transparentColor
        }
    }

    indicator: ResponsiveImage {
        containerHeight: 6
        containerWidth: 10
        width: 20
        height: 20

        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.rightMargin: 16

        source: popup.visible ? JamiResources.expand_less_24dp_svg : JamiResources.expand_more_24dp_svg

        color: JamiTheme.comboboxIconColor
    }

    contentItem: Text {

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: root.indicator.width
        width: parent.width - root.indicator.width * 2
        anchors.rightMargin: root.indicator.width * 2
        font.pixelSize: JamiTheme.settingsDescriptionPixelSize
        text: root.displayText
        color: JamiTheme.comboboxTextColor
        font.weight: Font.Medium
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignLeft
        elide: Text.ElideRight
    }

    background: Rectangle {
        id: selectOption
        color: JamiTheme.transparentColor
        implicitWidth: 120
        implicitHeight: contentItem.implicitHeight + JamiTheme.buttontextHeightMargin
        border.color: popup.visible ? JamiTheme.comboboxBorderColorActive : JamiTheme.comboboxBorderColor
        border.width: root.visualFocus ? 2 : 1
        radius: 5
    }

    popup: Popup {
        id: popup

        y: root.height - 1
        width: root.width
        padding: 1
        height: Math.min(contentItem.implicitHeight, 5 * selectOption.implicitHeight)

        contentItem: JamiListView {
            id: listView

            implicitHeight: contentHeight
            model: root.delegateModel
        }

        background: Rectangle {
            color: JamiTheme.primaryBackgroundColor
            border.color: JamiTheme.comboboxBorderColorActive
            radius: 5
        }
    }
}
