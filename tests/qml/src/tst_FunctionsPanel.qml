/*
 * Copyright (C) 2026 Savoir-faire Linux Inc.
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
import QtQuick
import QtTest
import "../../../src/app/mainview/components"

TestWrapper {
    width: 400
    height: 700

    FunctionsPanel {
        id: uut
        width: 360

        SignalSpy {
            id: triggeredSpy
            target: uut
            signalName: "functionTriggered"
        }
    }

    TestCase {
        name: "FunctionsPanel"
        when: windowShown

        function init() {
            uut.maximumHeight = 300;
            uut.expanded = true;
            triggeredSpy.clear();
            tryCompare(uut, "reveal", 1);
        }

        function card(fn) {
            return findChild(uut, "functionCard-" + fn);
        }

        function test_nine_functions_in_three_rows_within_the_height() {
            compare(uut.functions.length, 9);
            compare(uut.rows, 3);
            compare(uut.columns, 3);
            verify(uut.showNames);
            verify(uut.implicitHeight <= uut.maximumHeight);
        }

        function test_one_row_without_names_when_three_do_not_fit() {
            // A short window: three rows would be too small to touch.
            uut.maximumHeight = 120;
            compare(uut.rows, 1);
            compare(uut.columns, 9);
            verify(!uut.showNames);
            verify(uut.implicitHeight <= uut.maximumHeight);
        }

        function test_each_card_triggers_its_function() {
            for (const fn of [FunctionsPanel.Calls, FunctionsPanel.Messages, FunctionsPanel.Contacts,
                              FunctionsPanel.Documents, FunctionsPanel.Groups, FunctionsPanel.Board,
                              FunctionsPanel.Services, FunctionsPanel.Location, FunctionsPanel.Circles]) {
                triggeredSpy.clear();
                mouseClick(card(fn));
                compare(triggeredSpy.count, 1);
                compare(triggeredSpy.signalArguments[0][0], fn);
            }
        }

        function test_the_handle_folds_and_unfolds_the_panel() {
            const handle = findChild(uut, "functionsPanelHandle");
            mouseClick(handle);
            verify(!uut.expanded);
            tryCompare(uut, "implicitHeight", uut.handleHeight);
            // Folded, the cards can no longer be reached.
            verify(!card(FunctionsPanel.Calls).enabled);

            mouseClick(handle);
            verify(uut.expanded);
            tryCompare(uut, "reveal", 1);
            verify(card(FunctionsPanel.Calls).enabled);
        }

        function test_dragging_the_handle_folds_and_unfolds_the_panel() {
            const handle = findChild(uut, "functionsPanelHandle");
            mouseDrag(handle, handle.width / 2, handle.height / 2, 0, 150);
            tryCompare(uut, "expanded", false);
            tryCompare(uut, "reveal", 0);

            mouseDrag(handle, handle.width / 2, handle.height / 2, 0, -150);
            tryCompare(uut, "expanded", true);
            tryCompare(uut, "reveal", 1);
        }

        function test_a_short_drag_changes_nothing() {
            const handle = findChild(uut, "functionsPanelHandle");
            mouseDrag(handle, handle.width / 2, handle.height / 2, 0, 30);
            tryCompare(uut, "reveal", 1);
            verify(uut.expanded);
        }
    }
}
