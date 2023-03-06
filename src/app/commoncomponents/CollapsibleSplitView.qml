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

SplitView {
    id: splitView

    required property Item leftPaneItem
    required property Item rightPaneItem

    property alias sv1: sv1
    property alias sv2: sv2

    property string splitViewStateKey: objectName

    function saveSplitViewState() {
        UtilsAdapter.setAppValue("sv_" + splitViewStateKey, splitView.saveState())
    }

    function restoreSplitViewState() {
        splitView.restoreState(UtilsAdapter.getAppValue("sv_" + splitViewStateKey))
    }

    onResizingChanged: if (!resizing) saveSplitViewState()

    onVisibleChanged: {
        if (visible) {
            restoreSplitViewState()
        } else {
            saveSplitViewState()
        }
    }

    Component.onCompleted: {
        print(this, "Component.onCompleted")

        leftPaneItem.parent = sv1
        rightPaneItem.parent = sv2

        // Avoid double triggering this handler during instantiation.
        onIsCollapsedChanged.connect(isCollapsedChangedHandler)

        restoreSplitViewState()

        resolvePanes()
    }

    property bool isCollapsed
    property bool isUserCollapsed: false
    property bool collapseToLeft: false

    property real minimumRightPaneWidth: JamiTheme.chatViewHeaderMinimumWidth
    property real previousWidth: splitView.width
    property real mainViewSidePanelRectWidth: sv1.width
    property real previousSidePanelWidth: sv1.width

    onWidthChanged: resolvePanes()

    function resolvePanes() {
        const isExpanding = previousWidth < splitView.width
        if (!isCollapsed) {
            if (splitView.width < minimumRightPaneWidth + sv1.width
                    && sv2.visible && !isExpanding) {
                // Save the side panel width and go into single pane mode.
                previousSidePanelWidth = sv1.width
                isCollapsed = true
            } else if (splitView.width >= previousSidePanelWidth + minimumRightPaneWidth
                       && !sv2.visible && isExpanding && !layoutManager.isFullScreen) {
                // Restore dual pane mode.
                isCollapsed = false
            }
        }
        previousWidth = splitView.width
    }

    // Override this if needed.
    property var isCollapsedChangedHandler: function() {
        print(this, "isCollapsedChangedHandler", collapseToLeft)
        if (collapseToLeft) {
            //sv2.visible = !isCollapsed
            print(this, "isCollapsedChangedHandler2", collapseToLeft)
            return
        }
        rightPaneItem.parent = isCollapsed ? sv1 : sv2
    }

    Component {
        id: handleComp
        Rectangle {
            implicitWidth: JamiTheme.splitViewHandlePreferredWidth
            implicitHeight: splitView.height
            color: JamiTheme.primaryBackgroundColor
            Rectangle {
                implicitWidth: 1
                implicitHeight: splitView.height
                color: JamiTheme.tabbarBorderColor
            }
        }
    }

    handle: !isCollapsed ? handleComp : null

    StackView {
        id: sv1
        SplitView.minimumWidth: 300
        SplitView.maximumWidth: isCollapsed ?
                                    undefined :
                                    splitView.width - minimumRightPaneWidth
        SplitView.preferredWidth: 300
        clip: true
    }
    StackView {
        id: sv2
        clip: true
    }
}
