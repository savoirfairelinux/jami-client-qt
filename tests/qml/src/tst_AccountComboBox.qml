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
    AccountComboBoxPopup {
        id: uut

        function loadMockData() {
            return JSON.parse('[\
                {"Alias":"Foo","ID":"a2d724d18a943e6c","NotificationCount":0,"Status":5,"Type":1,"Username":"foo"}, \
                {"Alias":"Bar","ID":"8a22b7d0176327db","NotificationCount":0,"Status":5,"Type":1,"Username":"bar"}, \
                {"Alias":"TEST JAMI","ID":"3b7d2b9e2af83a47","NotificationCount":0,"Status":5,"Type":2,"Username":"696"}, \
                {"Alias":"Whatever","ID":"131ad59045a9a146","NotificationCount":0,"Status":5,"Type":1,"Username":"whatever"}]')
        }

        TestCase {
            name: "Check model size"
            function test_checkModelSize() {
                var accountList = findChild(uut, "accountList")
                accountList.model = uut.loadMockData()
                compare(accountList.model.length, 4)
            }
        }
    }
}
