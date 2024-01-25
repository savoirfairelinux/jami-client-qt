/*
 * Copyright (C) 2021-2024 Savoir-faire Linux Inc.
 * Author: Mingrui Zhang <mingrui.zhang@savoirfairelinux.com>
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

import "../../../src/app/mainview"
import "../../../src/app/commoncomponents"

MainView {
    id: uut

    width: 400
    height: 600

    SignalSpy {
        id: settingsPageRequestedSpy

        target: JamiQmlUtils
        signalName: "onSettingsPageRequested"
    }

    TestCase {
        name: "Test shortcuts"
        when: windowShown

        function test_shortcuts() {
            keyClick(Qt.Key_M, Qt.ControlModifier)
            settingsPageRequestedSpy.wait(1000)
            compare(settingsPageRequestedSpy.count, 1)
            keyClick(Qt.Key_G, Qt.ControlModifier)
            settingsPageRequestedSpy.wait(1000)
            compare(settingsPageRequestedSpy.count, 2)
        }
    }

}
