/*
 * Copyright (C) 2025-2026 Savoir-faire Linux Inc.
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
pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Controls.impl
import QtQuick.Templates as T
import net.jami.Constants 1.1

T.ComboBox {
    id: control

    // Accessibility name and description for the combobox itself
    required property string accessibilityName
    required property string accessibilityDescription

    // Content specific requirements
    required property real comboBoxPointSize

    // Accessibility
    Accessible.role: Accessible.ComboBox
    Accessible.name: accessibilityName
    Accessible.description: accessibilityDescription.arg(displayText)
    Accessible.focusable: true

    hoverEnabled: true

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset, leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset, topPadding + bottomPadding, implicitIndicatorHeight + topPadding + bottomPadding)
    leftPadding: padding + (!control.mirrored || !indicator || !indicator.visible ? 0 : indicator.width + spacing)
    rightPadding: padding + (control.mirrored || !indicator || !indicator.visible ? 0 : indicator.width + spacing)

    // The delegate defines a template for how each item in the dropdown should appear
    delegate: ItemDelegate {
        id: controlDelegate

        required property var model
        required property int index

        Accessible.role: Accessible.ListItem
        Accessible.name: controlDelegate.model[control.textRole]
        Accessible.description: {
            if (control.currentIndex === control.highlightedIndex) {
                return JamiStrings.selectedDescription.arg(control.accessibilityName);
            } else if (highlightedIndex === -1) {
                return JamiStrings.hasBeenSelectedDescription.arg(control.displayText).arg(control.accessibilityName);
            } else {
                return JamiStrings.availableOptionDescription.arg(control.accessibilityName);
            }
        }
        Accessible.focused: control.highlightedIndex === index

        width: ListView.view.width

        contentItem: Text {
            text: controlDelegate.model[control.textRole]
            color: JamiTheme.textColor
            font.weight: control.currentIndex === index ? Font.DemiBold : Font.Normal
            font.pointSize: comboBoxPointSize
            elide: Text.ElideRight
            clip: true
        }

        background: Rectangle {
            color: controlDelegate.highlighted ? JamiTheme.hoverColor : "transparent"
            radius: 5
        }

        highlighted: control.highlightedIndex === index
        hoverEnabled: control.hoverEnabled
    }

    // Arrow symbol
    indicator: ResponsiveImage {
        x: control.mirrored ? control.padding : control.width - width - control.padding
        y: control.topPadding + (control.availableHeight - height) / 2
        color: control.enabled ? JamiTheme.comboboxIconColor : JamiTheme.grey_
        source: popup.visible ? JamiResources.expand_less_24dp_svg : JamiResources.expand_more_24dp_svg
        opacity: enabled ? 1 : 0.3
    }

    // Defines the manner in which the text appears
    contentItem: Text {
        leftPadding: !control.mirrored ? 12 : activeFocus ? 3 : 1
        rightPadding: control.mirrored ? 12 : activeFocus ? 3 : 1

        text: control.displayText
        color: JamiTheme.comboboxTextColor

        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignLeft

        elide: Text.ElideRight
        clip: true
    }

    // Defines how the actual background of the combobox appears
    background: Rectangle {
        implicitWidth: control.width
        implicitHeight: control.contentItem.implicitHeight + JamiTheme.buttontextHeightMargin

        color: JamiTheme.transparentColor
        border.width: control.visualFocus ? 2 : 1
        border.color: JamiTheme.comboboxBorderColor
        visible: !control.flat || control.down
        radius: 5
    }

    popup: T.Popup {
        y: control.height
        width: control.width
        height: Math.min(contentItem.implicitHeight, 5 * control.background.implicitHeight)
        topMargin: 6
        bottomMargin: 6

        background: Rectangle {
            color: JamiTheme.backgroundColor // or appropriate theme color
            border.color: JamiTheme.comboboxBorderColorActive
            border.width: 1
            radius: 5
        }

        contentItem: ListView {
            clip: true
            implicitHeight: contentHeight
            model: control.delegateModel
            currentIndex: control.highlightedIndex
            highlightMoveDuration: 0

            ScrollBar.vertical: JamiScrollBar {}
        }
    }

    Keys.onShortcutOverride: event => {
        if (event.key === Qt.Key_Escape && popup.visible) {
            event.accepted = true;
            popup.close();
        }
    }
}
