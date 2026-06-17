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
    height: 600

    NewMaterialTextField {
        id: uut

        Layout.alignment: Qt.AlignHCenter
        Layout.preferredWidth: root.width
        Layout.maximumWidth: JamiTheme.chatViewMaximumWidth

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

    // Second field for multi-field navigation tests
    NewMaterialTextField {
        id: field1

        objectName: "field1"

        Layout.alignment: Qt.AlignHCenter
        Layout.preferredWidth: root.width

        textFieldContent: ""
        placeholderText: "Field 1"
    }

    NewMaterialTextField {
        id: field2

        objectName: "field2"

        Layout.alignment: Qt.AlignHCenter
        Layout.preferredWidth: root.width

        textFieldContent: ""
        placeholderText: "Field 2"
    }

    NewMaterialTextField {
        id: field3

        objectName: "field3"

        Layout.alignment: Qt.AlignHCenter
        Layout.preferredWidth: root.width

        textFieldContent: ""
        placeholderText: "Field 3"
    }

    TestCase {
        name: "Multi-field Tab navigation emits editingFinished and moves focus"
        when: windowShown

        function test_tabNavigation_emitsEditingFinished_and_movesFocus() {
            const tf1 = findChild(field1, "textField")
            const tf2 = findChild(field2, "textField")
            const tf3 = findChild(field3, "textField")

            // Focus the first field and type text
            mouseClick(tf1)
            verify(tf1.activeFocus, "field1 should have focus after click")
            keyClick("a")
            keyClick("b")
            keyClick("c")
            compare(field1.modifiedTextFieldContent, "abc")

            // Set up a spy on field1's editingFinished signal
            const spy1 = Qt.createQmlObject('import QtTest 1.0; SignalSpy {}', field1)
            spy1.target = field1
            spy1.signalName = "editingFinished"

            // Tab to field2 — this should emit editingFinished on field1
            keyClick(Qt.Key_Tab)
            spy1.wait(500)

            compare(spy1.count, 1, "field1 should emit editingFinished when focus leaves via Tab")
            verify(tf2.activeFocus, "field2 should have focus after Tab from field1")

            // Type into field2
            keyClick("d")
            keyClick("e")
            compare(field2.modifiedTextFieldContent, "de")

            // Set up spy on field2's editingFinished signal
            const spy2 = Qt.createQmlObject('import QtTest 1.0; SignalSpy {}', field2)
            spy2.target = field2
            spy2.signalName = "editingFinished"

            // Tab to field3
            keyClick(Qt.Key_Tab)
            spy2.wait(500)

            compare(spy2.count, 1, "field2 should emit editingFinished when focus leaves via Tab")
            verify(tf3.activeFocus, "field3 should have focus after Tab from field2")

            // Verify field1 still has its text and field2 wasn't disrupted
            compare(field1.modifiedTextFieldContent, "abc")
            compare(field2.modifiedTextFieldContent, "de")

            // Clean up
            spy1.destroy()
            spy2.destroy()

            // Reset fields
            field1.modifiedTextFieldContent = ""
            field2.modifiedTextFieldContent = ""
            field3.modifiedTextFieldContent = ""
        }
    }
}
