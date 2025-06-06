/*
 * Copyright (C) 2019-2025 Savoir-faire Linux Inc.
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
import QtQuick.Layouts
import net.jami.Constants 1.1
import "../../commoncomponents"

RowLayout {
    id: root

    property alias labelText: title.text
    property alias comboModel: comboBoxOfLayout.model
    property alias tipText: comboBoxOfLayout.tooltipText
    property alias role: comboBoxOfLayout.textRole
    property alias placeholderText: comboBoxOfLayout.placeholderText
    property alias currentSelectionText: comboBoxOfLayout.currentSelectionText
    property alias enabled: comboBoxOfLayout.enabled
    property alias fontPointSize: comboBoxOfLayout.font.pointSize
    property alias modelIndex: comboBoxOfLayout.currentIndex
    property alias modelSize: comboBoxOfLayout.count
    property alias comboBox: comboBoxOfLayout

    property int widthOfComboBox: 50

    signal activated

    Text {
        id: title

        Layout.fillWidth: true
        Layout.rightMargin: JamiTheme.preferredMarginSize
        font.pointSize: JamiTheme.settingsFontSize
        font.kerning: true
        color: JamiTheme.textColor
        wrapMode: Text.WordWrap
        horizontalAlignment: Text.AlignLeft
        verticalAlignment: Text.AlignVCenter
    }

    SettingParaCombobox {
        id: comboBoxOfLayout

        enabled: root.enabled
        Layout.preferredWidth: widthOfComboBox

        font.pointSize: JamiTheme.buttonFontSize
        font.kerning: true

        model: comboModel

        textRole: role
        tooltipText: tipText

        onActivated: root.activated()
    }
}
