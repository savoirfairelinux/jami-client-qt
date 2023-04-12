/*
 * Copyright (C) 2019-2023 Savoir-faire Linux Inc.
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
    property string comboBoxBackgroundColor: JamiTheme.editBackgroundColor
    property string currentSelectionText: currentText
    property string placeholderText
    property bool selection: currentIndex < 0 && !count
    property alias tooltipText: toolTip.text

    displayText: {
        // If the index is -1 and the model is empty, display the placeholder text.
        // The placeholder text is either the placeholderText property or a default text.
        // Otherwise, display the currentSelectionText property.
        if (currentIndex < 0 && !count) {
            return placeholderText !== "" ? placeholderText : JamiStrings.notAvailable;
        }
        return currentSelectionText;
    }

    MaterialToolTip {
        id: toolTip
        delay: Qt.styleHints.mousePressAndHoldInterval
        parent: root
        visible: hovered && (text.length > 0)
    }

    background: Rectangle {
        id: selectOption
        border.color: popup.visible ? JamiTheme.comboboxBorderColorActive : JamiTheme.comboboxBorderColor
        border.width: root.visualFocus ? 2 : 1
        color: JamiTheme.transparentColor
        implicitHeight: contentItem.implicitHeight + JamiTheme.buttontextHeightMargin
        implicitWidth: 120
        radius: 5
    }
    contentItem: Text {
        color: JamiTheme.comboboxTextColor
        elide: Text.ElideRight
        font.pixelSize: JamiTheme.settingsDescriptionPixelSize
        font.weight: Font.Medium
        horizontalAlignment: Text.AlignLeft
        leftPadding: root.indicator.width
        text: root.displayText
        verticalAlignment: Text.AlignVCenter
    }
    delegate: ItemDelegate {
        width: root.width

        background: Rectangle {
            color: hovered ? JamiTheme.comboboxBackgroundColorHovered : JamiTheme.transparentColor
        }
        contentItem: Text {
            color: hovered ? JamiTheme.comboboxTextColorHovered : JamiTheme.textColor
            elide: Text.ElideRight
            font.pointSize: JamiTheme.settingsFontSize
            text: {
                if (index < 0)
                    return '';
                var currentItem = root.delegateModel.items.get(index);
                const value = currentItem.model[root.textRole];
                return value === undefined ? '' : value.toString();
            }
            verticalAlignment: Text.AlignVCenter
        }
    }
    indicator: ResponsiveImage {
        anchors.right: parent.right
        anchors.rightMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        color: JamiTheme.comboboxIconColor
        containerHeight: 6
        containerWidth: 10
        height: 20
        source: popup.visible ? JamiResources.expand_less_24dp_svg : JamiResources.expand_more_24dp_svg
        width: 20
    }
    popup: Popup {
        id: popup
        height: Math.min(contentItem.implicitHeight, 5 * selectOption.implicitHeight)
        padding: 1
        width: root.width
        y: root.height - 1

        background: Rectangle {
            border.color: JamiTheme.comboboxBorderColorActive
            color: JamiTheme.primaryBackgroundColor
            radius: 5
        }
        contentItem: JamiListView {
            id: listView
            implicitHeight: contentHeight
            model: root.delegateModel
        }
    }
}
