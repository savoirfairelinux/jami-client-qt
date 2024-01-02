/*
 * Copyright (C) 2024 Savoir-faire Linux Inc.
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

DualPaneView {
    id: viewNode

    property bool hideRightPaneInSinglePaneMode : false

    Component.onCompleted: {
        if (hideRightPaneInSinglePaneMode) return
        onIndexChanged.connect(function() {
            if (hasValidSelection) {
                if (selectionFallback && isSinglePane)
                    rightPaneItem.parent = leftPane
                return
            }
            if (!isSinglePane) dismiss()
            else isSinglePaneChangedHandler()
        })
    }

    // True if we should dismiss to the left pane if in single pane mode.
    // Also causes selection of a default index (0) in dual pane mode.
    property bool selectionFallback: false

    // When this property is set, the view updates its display to show the
    // corresponding item if `hasValidSelection` has no override.
    property int index: -1
    function selectIndex(index) { viewNode.index = index }

    // Override this predicate if needed.
    property bool hasValidSelection: viewNode.index >= -1
    onHasValidSelectionChanged: isSinglePaneChangedHandler()

    // Override BaseView.dismiss with some selection logic.
    function dismiss() {
        if (isSinglePane) {
            if (!selectionFallback) viewCoordinator.dismiss(objectName)
            else if (isSinglePane && leftPane.children.length > 1) {
                rightPaneItem.parent = null
                leftPaneItem.deselect()
            }
        } else viewCoordinator.dismiss(objectName)
    }

    onPresented: isSinglePaneChangedHandler()

    onDismissed: {
        if (leftPaneItem) {
            leftPaneItem.indexSelected.disconnect(selectIndex)
            leftPaneItem.deselect()
        }
    }

    onLeftPaneItemChanged: {
        if (leftPaneItem) leftPaneItem.indexSelected.connect(selectIndex)
    }
    isSinglePaneChangedHandler: () => {
        if (hideRightPaneInSinglePaneMode) return
        // When transitioning from split to single pane, we need to move
        // the right pane item to left stack view if it has a valid index.
        if (isSinglePane) {
            if (hasValidSelection) {
                rightPaneItem.parent = leftPane
            }
        } else {
            rightPaneItem.parent = rightPane
            // We may need a default selection of item 0 here.
            if (!hasValidSelection && selectionFallback) leftPaneItem.select(0)
        }
    }
}
