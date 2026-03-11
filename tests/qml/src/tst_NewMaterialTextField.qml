/*
 * Copyright (C) 2024-2026 Savoir-faire Linux Inc.
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
import Qt5Compat.GraphicalEffects

import QtTest

import net.jami.Models 1.1
import net.jami.Constants 1.1

import "../../../src/app/"
import "../../../src/app/commoncomponents"

ColumnLayout {
    id: root

    spacing: 0

    width: 300
    height: 300

    NewMaterialTextField {
        id: uut

        Layout.alignment: Qt.AlignHCenter
        Layout.preferredWidth: root.width
        Layout.maximumWidth: JamiTheme.chatViewMaximumWidth
        Layout.preferredHeight: root.height

        maxCharacters: 20
        textFieldContent: ""

        TestCase {
            name: "Check maxCharacters for MaterialTextField"
            when: windowShown

            function test_maxCharacters_material_text_field() {
                var textField = findChild(uut, "textField")
                compare(textField.maximumLength, 20)
            }

            function test_modifiedText_material_text_field() {
                const textField = findChild(uut, "textField")
                // Initial check that the contains no original or modified content
                compare(textField.text, "")
                compare(uut.modifiedTextFieldContent, "")

                // Simulate clicking into the TextField and input text
                mouseClick(textField)
                keyClick("t")
                keyClick("e")
                keyClick("s")
                keyClick("t")

                // Both modifiedTextFieldContent and the text property of the textfield should
                // contain the new text
                compare(uut.modifiedTextFieldContent, "test")
                compare(textField.text, "test")
                // However, the textFieldContent property of the component should still reflect
                // the original text prior to modification
                compare(uut.textFieldContent, "")
            }
        }
    }
}
