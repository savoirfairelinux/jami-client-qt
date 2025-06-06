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
import QtTest

import net.jami.Models 1.1
import net.jami.Constants 1.1

import "../../../src/app/commoncomponents"

PresenceIndicator {
    id: uut

    TestCase {
        name: "Presence Indicator Color Test"

        function test_color() {
            compare(uut.color, JamiTheme.presenceGreen)

            uut.status = Account.Status.TRYING

            compare(uut.color, JamiTheme.unPresenceOrange)

            uut.status = Account.Status.UNREGISTERED

            compare(uut.color, JamiTheme.notificationRed)
        }
    }
}
