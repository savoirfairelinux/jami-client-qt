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
import QtQuick.Controls
import net.jami.Adapters 1.1
import net.jami.Constants 1.1

BaseView {
    id: viewNode

    required property Item leftPaneItem
    required property Item rightPaneItem

    property bool isRTL: UtilsAdapter.isRTL

    property alias leftPane: leftPane
    property alias rightPane: rightPane
    property alias splitViewStateKey: splitView.splitViewStateKey

    readonly property real minorPaneMinWidth: JamiTheme.mainViewMinorPaneMinWidth
    readonly property real majorPaneMinWidth: JamiTheme.mainViewMajorPaneMinWidth

    property real previousMinorPaneWidth: 0
    property bool isSinglePane: false

    onPresented: {
        if (leftPaneItem)
            leftPaneItem.parent = leftPane
        if (rightPaneItem)
            rightPaneItem.parent = rightPane
        // Sync the minor pane width with the global value when the view is presented.
        // This ensures width consistency when switching between views that share the
        // same splitViewStateKey (e.g., SidePanel and SettingsSidePanel).
        if (!isSinglePane && JamiQmlUtils.currentMinorPaneWidth > 0) {
            leftPane.SplitView.preferredWidth = JamiQmlUtils.currentMinorPaneWidth
        }
    }

    Component.onCompleted: {
        onIsSinglePaneChanged.connect(isSinglePaneChangedHandler)
        resolvePanes()
        // Sync local previousMinorPaneWidth with the global value (which is loaded
        // from storage in JamiQmlUtils singleton initialization).
        if (JamiQmlUtils.currentMinorPaneWidth > 0) {
            previousMinorPaneWidth = JamiQmlUtils.currentMinorPaneWidth
        }
    }

    onWidthChanged: resolvePanes()
    function resolvePanes() {
        const threshold = majorPaneMinWidth + (previousMinorPaneWidth || minorPaneMinWidth)
        isSinglePane = width < threshold
    }

    property var isSinglePaneChangedHandler: function () {
        // Move right pane into left when collapsing
        rightPaneItem.parent = isSinglePane ? leftPane : rightPane
    }

    JamiSplitView {
        id: splitView
        anchors.fill: parent
        splitViewStateKey: viewNode.objectName
        isSinglePane: viewNode.isSinglePane

        SplitPane {
            id: leftPane
            isMinorPane: true
        }

        SplitPane {
            id: rightPane
            isMinorPane: false
        }
    }

    component SplitPane: Item {
        clip: true
        required property bool isMinorPane

        // Track the last width we've saved to prevent recursive updates
        property real _lastTrackedWidth: 0
        // Flag to prevent onWidthChanged from firing during initialization
        property bool _initialized: false

        Component.onCompleted: {
            // Set initial preferred width for minor pane only (not in single pane mode)
            // This restores the saved width from previous sessions without creating a binding loop
            if (!isSinglePane && isMinorPane) {
                const initialWidth = JamiQmlUtils.currentMinorPaneWidth || previousMinorPaneWidth || minorPaneMinWidth
                if (initialWidth > 0) {
                    SplitView.preferredWidth = initialWidth
                    _lastTrackedWidth = initialWidth
                }
            }
            _initialized = true
        }

        onWidthChanged: {
            // Only track width changes after initialization, for minor pane, and when width actually changed
            // The _lastTrackedWidth check prevents recursive updates that would cause binding loops
            if (_initialized && !isSinglePane && isMinorPane && width !== _lastTrackedWidth) {
                _lastTrackedWidth = width
                JamiQmlUtils.currentMinorPaneWidth = width
                previousMinorPaneWidth = width
            }
        }

        SplitView.minimumWidth: isSinglePane ? undefined
                                             : (isMinorPane ? minorPaneMinWidth : majorPaneMinWidth)
        SplitView.maximumWidth: isSinglePane || !isMinorPane ? undefined : Math.abs(viewNode.width - majorPaneMinWidth)
        SplitView.fillWidth: !isMinorPane || isSinglePane
    }
}
