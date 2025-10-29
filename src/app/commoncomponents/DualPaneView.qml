/*
 * Copyright (C) 2024-2025 Savoir-faire Linux Inc.
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
    }

    Component.onCompleted: {
        onIsSinglePaneChanged.connect(isSinglePaneChangedHandler)
        resolvePanes()
        // Restore minor pane width from persistent storage on app start
        const savedWidth = UtilsAdapter.getAppValue("minorPaneWidth")
        if (!JamiQmlUtils.currentMinorPaneWidth && savedWidth && savedWidth > 0) {
            JamiQmlUtils.currentMinorPaneWidth = savedWidth
            previousMinorPaneWidth = savedWidth
        } else if (JamiQmlUtils.currentMinorPaneWidth) {
            previousMinorPaneWidth = JamiQmlUtils.currentMinorPaneWidth
        }
        console.warn("************ Loaded minor pane width:", previousMinorPaneWidth)
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

        onWidthChanged: {
            if (!isSinglePane && isMinorPane) {
                console.warn("!!!!!!!!!!!! Restoring minor pane width:", width)
                JamiQmlUtils.currentMinorPaneWidth = width
                previousMinorPaneWidth = width
            }
        }

        SplitView.minimumWidth: isSinglePane ? undefined
                                             : (isMinorPane ? minorPaneMinWidth : majorPaneMinWidth)
        SplitView.maximumWidth: {
            const mw = isSinglePane || !isMinorPane ? undefined : Math.abs(viewNode.width - majorPaneMinWidth)
            console.warn("++++++++++", mw)
            return mw
        }
        width: {
            if (isSinglePane || !isMinorPane) return undefined
            // Use cached minor pane width from JamiQmlUtils, or fall back to previousMinorPaneWidth or minimum
            const w = JamiQmlUtils.currentMinorPaneWidth || previousMinorPaneWidth || minorPaneMinWidth
            console.warn("____________________", w)
            return w
        }
        SplitView.fillWidth: !isMinorPane || isSinglePane
    }
}
