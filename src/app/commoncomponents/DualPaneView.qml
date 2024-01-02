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

    property real minorPaneMinWidth: JamiTheme.mainViewLeftPaneMinWidth
    property real majorPaneMinWidth: JamiTheme.mainViewPaneMinWidth

    property real previousMinorPaneWidth: isRTL ? leftPane.width : rightPane.width
    property real previousMajorPaneWidth: isRTL ? rightPane.width : leftPane.width

    property bool isSinglePane

    onPresented: {
        if (leftPaneItem)
            leftPaneItem.parent = leftPane
        if (rightPaneItem)
            rightPaneItem.parent = rightPane
        splitView.restoreSplitViewState()
        resolvePanes()
    }
    onDismissed: splitView.saveSplitViewState()

    Component.onCompleted: {
        // Avoid double triggering this handler during instantiation.
        onIsSinglePaneChanged.connect(isSinglePaneChangedHandler)
    }

    onWidthChanged: resolvePanes()
    function resolvePanes() {
        isSinglePane = width < majorPaneMinWidth + previousMinorPaneWidth
    }

    // Override this if needed.
    property var isSinglePaneChangedHandler: function () {
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
            if (!isSinglePane && isMinorPane)
                previousMinorPaneWidth = width
            if (!isSinglePane && !isMinorPane)
                previousMajorPaneWidth = width
            if (isMinorPane)
                JamiTheme.currentLeftPaneWidth = width
        }

        Connections {
            target: UtilsAdapter

            function onIsRTLChanged() {
                var bck = previousMinorPaneWidth
                previousMinorPaneWidth = previousMajorPaneWidth
                previousMajorPaneWidth = bck
            }
        }

        SplitView.minimumWidth: isSinglePane ? undefined : (isMinorPane ? minorPaneMinWidth : majorPaneMinWidth)
        SplitView.maximumWidth: isSinglePane || !isMinorPane ? undefined : Math.abs(viewNode.width - majorPaneMinWidth)
        SplitView.preferredWidth: isSinglePane || !isMinorPane ? undefined : JamiTheme.currentLeftPaneWidth
        SplitView.fillWidth: !isMinorPane || isSinglePane
    }
}
