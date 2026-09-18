/*
 * Copyright (C) 2026 Savoir-faire Linux Inc.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <https://www.gnu.org/licenses/>.
 */

import QtQuick
import QtTest

import "../../../src/app/mainview/components"
import "../../../src/app/commoncomponents"

TestWrapper {
    width: 800
    height: 600

    QuickSwitcher {
        id: uut

        SignalSpy {
            id: conversationSpy
            target: uut
            signalName: "conversationActivated"
        }

        SignalSpy {
            id: settingSpy
            target: uut
            signalName: "settingActivated"
        }
    }

    TestCase {
        name: "QuickSwitcher"
        when: windowShown

        property var conversations: [
            {
                accountId: "account",
                isContact: false,
                searchTerms: ["bob"],
                subtitle: "Bob",
                timestamp: 30,
                title: "Project Alpha",
                uid: "alpha"
            },
            {
                accountId: "account",
                isContact: true,
                searchTerms: ["alice", "alice-id"],
                subtitle: "alice-id",
                timestamp: 20,
                title: "Alice",
                uid: "alice"
            },
            {
                accountId: "account",
                isContact: true,
                searchTerms: ["alicia"],
                subtitle: "alicia-id",
                timestamp: 10,
                title: "Alicia",
                uid: "alicia"
            }
        ]
        property var settings: [
            {
                title: "Media",
                icon: "",
                children: [
                    { id: 14, title: "Audio" },
                    { id: 15, title: "Video" }
                ]
            }
        ]

        function init() {
            uut.close()
            conversationSpy.clear()
            settingSpy.clear()
        }

        function open() {
            uut.openSwitcher(conversations, settings)
            tryCompare(uut, "opened", true)
            return findChild(uut, "quickSwitcherSearch")
        }

        function test_open_focus_and_escape() {
            const input = open()
            tryCompare(input, "activeFocus", true)
            keyClick(Qt.Key_Escape)
            tryCompare(uut, "opened", false)
        }

        function test_prefix_ranking_and_keyboard_activation() {
            const input = open()
            input.text = "ali"
            compare(uut.resultCount, 2)
            compare(uut.resultAt(0).uid, "alice")
            keyClick(Qt.Key_Down)
            compare(uut.selectedIndex, 1)
            keyClick(Qt.Key_Return)
            compare(conversationSpy.count, 1)
            compare(conversationSpy.signalArguments[0][0], "alicia")
        }

        function test_setting_alias_and_activation() {
            open()
            findChild(uut, "quickSwitcherSearch").text = "microphone"
            compare(uut.resultCount, 1)
            compare(uut.resultAt(0).settingIndex, 14)
            keyClick(Qt.Key_Return)
            compare(settingSpy.count, 1)
            compare(settingSpy.signalArguments[0][0], 14)
        }

        function test_result_activation() {
            open()
            const results = findChild(uut, "quickSwitcherResults")
            verify(results)
            tryVerify(() => findChild(results.contentItem, "quickSwitcherResult-0") !== null)
            const result = findChild(results.contentItem, "quickSwitcherResult-0")
            result.clicked()
            compare(conversationSpy.count, 1)
            compare(conversationSpy.signalArguments[0][0], "alpha")
        }
    }
}
