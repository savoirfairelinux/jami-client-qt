/*
 * Copyright (C) 2021-2024 Savoir-faire Linux Inc.
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

import "../../../src/app/settingsview"
import "../../../src/app/commoncomponents"

SettingsSidePanel {
    id: uut

    SignalSpy {
        id: spyUpdated

        target: uut
        signalName: "updated"
    }

    SignalSpy {
        id: spyChangeLang

        target: UtilsAdapter
        signalName: "changeLanguage"
    }

    TestCase {
        name: "WelcomePage to different account creation page and return back"
        when: windowShown

        function test_retranslate() {
            spyUpdated.clear()
            UtilsAdapter.setAppValue(Settings.Key.LANG, "en_EN")
            spyChangeLang.wait(1000)
            compare(spyChangeLang.count, 1)
            spyUpdated.wait(1000)
            compare(spyUpdated.count, 1)
            UtilsAdapter.setAppValue(Settings.Key.LANG, "fr")
            spyChangeLang.wait(1000)
            compare(spyChangeLang.count, 2)
            spyUpdated.wait(1000)
            compare(spyUpdated.count, 2)
        }
    }

}
