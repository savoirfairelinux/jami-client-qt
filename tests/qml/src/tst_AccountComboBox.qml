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
import QtTest

import net.jami.Adapters 1.1
import net.jami.Models 1.1
import net.jami.Constants 1.1
import net.jami.Enums 1.1

import "../../../src/app/"
import "../../../src/app/mainview"
import "../../../src/app/mainview/components"
import "../../../src/app/commoncomponents"

TestWrapper {
    AccountComboBox {
        id: uut

        TestCase {
            name: "Check model size"
            when: windowShown

            function test_checkModelSize() {
                var accountComboBox = findChild(uut, "accountComboBox")
                verify(accountComboBox !== null, "AccountComboBox should have a ComboBox")

                accountComboBox.popup.open()
                var accountList = accountComboBox.popup.contentItem
                verify(accountList !== null, "Account list ListView should exist when popup is open")

                // Test harness creates 2 accounts (Alice, Bob); dropdown shows other accounts (excludes current), so count is 1
                compare(accountList.count, 1, "Account list should show the other account")
            }
        }
    }
}
