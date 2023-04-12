/*
 * Copyright (C) 2023 Savoir-faire Linux Inc.
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
    property bool isSinglePane

    // Override this if needed.
    property var isSinglePaneChangedHandler: function () {
        rightPaneItem.parent = isSinglePane ? leftPane : rightPane;
    }
    property alias leftPane: leftPane
    required property Item leftPaneItem
    property real leftPaneMinWidth: JamiTheme.mainViewLeftPaneMinWidth
    property real previousLeftPaneWidth: leftPane.width
    property alias rightPane: rightPane
    required property Item rightPaneItem
    property real rightPaneMinWidth: JamiTheme.mainViewPaneMinWidth
    property alias splitViewStateKey: splitView.splitViewStateKey

    function resolvePanes() {
        isSinglePane = width < rightPaneMinWidth + previousLeftPaneWidth;
    }

    Component.onCompleted: {
        // Avoid double triggering this handler during instantiation.
        onIsSinglePaneChanged.connect(isSinglePaneChangedHandler);
    }
    onDismissed: splitView.saveSplitViewState()
    onPresented: {
        if (leftPaneItem)
            leftPaneItem.parent = leftPane;
        if (rightPaneItem)
            rightPaneItem.parent = rightPane;
        splitView.restoreSplitViewState();
        resolvePanes();
    }
    onWidthChanged: resolvePanes()

    JamiSplitView {
        id: splitView
        anchors.fill: parent
        splitViewStateKey: viewNode.objectName

        Item {
            id: leftPane
            SplitView.maximumWidth: isSinglePane ? viewNode.width : viewNode.width - rightPaneMinWidth
            SplitView.minimumWidth: isSinglePane ? viewNode.width : viewNode.leftPaneMinWidth
            SplitView.preferredWidth: viewNode.leftPaneMinWidth
            clip: true

            onWidthChanged: if (!isSinglePane)
                previousLeftPaneWidth = width
        }
        Item {
            id: rightPane
            clip: true
        }
    }
}
