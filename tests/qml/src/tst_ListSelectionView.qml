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
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

import QtQuick
import QtTest

import "../../../src/app/commoncomponents"

TestWrapper {
    id: root

    width: 400
    height: 600

    Item {
        id: sharedSidePanel
        objectName: "SharedSidePanel"
    }

    ListSelectionView {
        id: activeView
        objectName: "ActiveListSelectionView"
        managed: false
        visible: true
        width: 400
        height: 600

        leftPaneItem: sharedSidePanel
        rightPaneItem: Item {}

        Component.onCompleted: {
            isSinglePane = true;
            index = -1;
            isSinglePaneChangedHandler();
        }
    }

    ListSelectionView {
        id: hiddenView
        objectName: "HiddenListSelectionView"
        managed: false
        visible: false
        width: 400
        height: 600

        property int handlerCalls: 0
        property bool fakeSelection: false
        hasValidSelection: fakeSelection

        leftPaneItem: sharedSidePanel
        rightPaneItem: Item {}

        // If this function runs while hidden, it would steal the shared side panel.
        isSinglePaneChangedHandler: () => {
            handlerCalls++;
            leftPaneItem.parent = leftPane;
        }
    }

    TestCase {
        name: "ListSelectionView hidden view cannot steal side panel"
        when: windowShown

        function test_hiddenViewSelectionChangeDoesNotReparentSidePanel() {
            // Prepare visible view with no selection => side panel should be shown in active view.
            activeView.isSinglePane = true;
            activeView.index = -1;
            activeView.isSinglePaneChangedHandler();
            compare(sharedSidePanel.parent, activeView.leftPane);

            hiddenView.handlerCalls = 0;
            hiddenView.isSinglePane = true;
            hiddenView.fakeSelection = false;

            // Trigger hasValidSelection transitions on the hidden view without
            // going through index-driven selection logic.
            hiddenView.fakeSelection = true;
            hiddenView.fakeSelection = false;

            compare(hiddenView.visible, false);
            compare(hiddenView.handlerCalls, 0);
            compare(sharedSidePanel.parent, activeView.leftPane);
        }
    }
}
