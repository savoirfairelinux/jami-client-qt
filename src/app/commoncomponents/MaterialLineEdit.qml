/*
 * Copyright (C) 2021-2025 Savoir-faire Linux Inc.
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
import net.jami.Constants 1.1

TextField {
    id: root

    property int fontSize: JamiTheme.materialLineEditPointSize

    property var backgroundColor: JamiTheme.secondaryBackgroundColor
    property var borderColor: JamiTheme.greyBorderColor

    property bool loseFocusWhenEnterPressed: false
    property bool underlined: false

    padding: JamiTheme.materialLineEditPadding
    horizontalAlignment: Text.AlignLeft
    verticalAlignment: Text.AlignVCenter

    wrapMode: Text.Wrap
    readOnly: false
    selectByMouse: true
    mouseSelectionMode: TextInput.SelectCharacters

    font.pointSize: fontSize
    font.kerning: true
    color: JamiTheme.textColor

    placeholderTextColor: JamiTheme.placeholderTextColor

    LineEditContextMenu {
        id: lineEditContextMenu

        lineEditObj: root
        selectOnly: readOnly
    }

    background: Rectangle {

        anchors.fill: root
        radius: JamiTheme.primaryRadius

        border.color: readOnly || underlined ? "transparent" : borderColor
        color: {
            if (readOnly)
                return "transparent";
            if (underlined)
                return borderColor;
            return backgroundColor;
        }

        Rectangle {
            visible: true
            anchors {
                fill: parent
                topMargin: 0
                rightMargin: -1
                bottomMargin: 1
                leftMargin: -1
            }
            color: root.backgroundColor
        }
    }

    onReleased: function (event) {
        if (event.button === Qt.RightButton)
            lineEditContextMenu.openMenuAt(event);
    }

    // Enter/Return keys intervention
    // Now, both editingFinished and accepted
    // signals will be emitted with focus set to false
    // Use editingFinished when the info is saved by focus lost
    // (since losing focus will also emit editingFinished)
    // Use accepted when the info is not saved by focus lost
    Keys.onPressed: function (event) {
        if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return) {
            if (loseFocusWhenEnterPressed)
                root.focus = false;
            root.accepted();
            event.accepted = true;
        }
    }
}
