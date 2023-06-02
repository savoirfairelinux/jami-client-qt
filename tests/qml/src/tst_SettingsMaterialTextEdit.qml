/*
 * Copyright (C) 2023 Savoir-faire Linux Inc.
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

import QtTest

import "../../../src/app/"
import "../../../src/app/settingsview/components"

ColumnLayout {
    id: root

    spacing: 0
    width: 300
    height: 300

    Item {
        id: dummy
    }

    SettingsMaterialTextEdit {
        id: uut

        property bool focusLeft: false
        isPassword: true

        TestCase {
            name: "Test password un-focus"
            when: windowShown

            function test_unfocusPassword() {
                // Open the recorder and take a picture
                uut.forceActiveFocus()
                dummy.forceActiveFocus()
                compare(uut.focusLeft, true)
            }
        }

        onEditFinished: focusLeft = true

        Layout.fillWidth: true
        Layout.fillHeight: true
    }
}
