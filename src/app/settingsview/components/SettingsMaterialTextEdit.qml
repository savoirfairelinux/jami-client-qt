/*
 * Copyright (C) 2020-2026 Savoir-faire Linux Inc.
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
import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import "../../commoncomponents"

RowLayout {
    id: root

    property alias titleField: title.text
    property string staticText
    property string placeholderText
    property string dynamicText
    property string leadingIconSource: ""
    property string trailingIconSource: ""

    property bool isPassword: false

    property int itemWidth

    signal editFinished
    signal accepted

    Text {
        id: title

        Layout.fillWidth: true
        Layout.rightMargin: JamiTheme.preferredMarginSize / 2
        font.pointSize: JamiTheme.settingsFontSize
        font.kerning: true
        wrapMode: Text.WordWrap
        horizontalAlignment: Text.AlignLeft
        verticalAlignment: Text.AlignVCenter

        color: JamiTheme.textColor
    }

    NewMaterialTextField {
        id: modalTextEdit

        Layout.alignment: Qt.AlignCenter
        Layout.maximumWidth: itemWidth

        leadingIconSource: root.leadingIconSource

        placeholderText: root.placeholderText ? root.placeholderText : root.titleField
        textFieldContent: root.staticText

        trailingIconSource: root.trailingIconSource

        visible: !root.isPassword

        onAccepted: root.accepted()

        onActiveFocusChanged: {
            if (!activeFocus) {
                root.accepted()
            }
        }
    }

    PasswordTextEdit {
        id: passwordTextEdit

        Layout.alignment: Qt.AlignCenter
        Layout.maximumWidth: itemWidth

        visible: root.isPassword

        placeholderText: root.placeholderText ? root.placeholderText : root.titleField
        textFieldContent: root.staticText

        onAccepted: root.accepted()

        onActiveFocusChanged: {
            if (!activeFocus) {
                root.accepted()
            }
        }
    }
}
