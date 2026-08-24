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

import "../../../src/app/mainview/components"

Item {
    id: root

    width: 400
    height: 80

    Searchbar {
        id: uut

        anchors.fill: parent
    }

    SignalSpy {
        id: textChangedSpy

        target: uut
        signalName: "searchBarTextChanged"
    }

    SignalSpy {
        id: acceptedSpy

        target: uut
        signalName: "accepted"
    }

    TestCase {
        name: "Searchbar"
        when: windowShown

        function init() {
            uut.requireAccept = false;
            uut.textContent = "";
            textChangedSpy.clear();
            acceptedSpy.clear();
        }

        function type(text) {
            uut.setTextAreaFocus();
            for (var i = 0; i < text.length; ++i)
                keyClick(text.charAt(i));
        }

        // The local lists filter as you type and must keep doing so.
        function test_reportsEveryKeystrokeByDefault() {
            type("abc");
            compare(uut.textContent, "abc");
            compare(textChangedSpy.count, 3);
            compare(acceptedSpy.count, 0);
        }

        // Searching a conversation hits the daemon, so it waits to be submitted.
        function test_requireAcceptDoesNotSearchWhileTyping() {
            uut.requireAccept = true;
            type("abc");
            compare(uut.textContent, "abc");
            compare(textChangedSpy.count, 0);
            compare(acceptedSpy.count, 0);
        }

        function test_requireAcceptSearchesOnEnter() {
            uut.requireAccept = true;
            type("abc");
            keyClick(Qt.Key_Return);
            compare(acceptedSpy.count, 1);
            compare(acceptedSpy.signalArguments[0][0], "abc");
        }

        function test_requireAcceptSearchesOnButtonPress() {
            uut.requireAccept = true;
            type("abc");
            var button = findChild(uut, "searchActionButton");
            verify(button !== null);
            mouseClick(button);
            compare(acceptedSpy.count, 1);
            compare(acceptedSpy.signalArguments[0][0], "abc");
        }

        // Nothing to submit, so the button must not fire a search.
        function test_requireAcceptIgnoresAnEmptyQuery() {
            uut.requireAccept = true;
            uut.setTextAreaFocus();
            keyClick(Qt.Key_Return);
            compare(acceptedSpy.count, 0);
        }

        // Emptying the box has to drop the results it produced, without an accept.
        function test_clearingReportsThroughEvenInAcceptMode() {
            uut.requireAccept = true;
            type("abc");
            compare(textChangedSpy.count, 0);
            uut.clearText();
            compare(textChangedSpy.count, 1);
            compare(textChangedSpy.signalArguments[0][0], "");
        }
    }
}
