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

// A SplitView that supports dynamic RTL and splitView state saving.
SplitView {
    id: control

    property bool isRTL: UtilsAdapter.isRTL
    property bool isSinglePane: false
    property real handleSize: 0
    property bool completed: false

    property string splitViewStateKey: objectName
    property bool autoManageState: !(parent instanceof BaseView)

    property bool handleOnMinor: false

    // Add at top-level in SplitView:
    property bool _reordering: false

    Component.onCompleted: {
        Qt.callLater(reorderPanes)
    }

    onIsRTLChanged: Qt.callLater(reorderPanes)
    onIsSinglePaneChanged: reorderPanes(true)

    function _paneRefs() {
        // Identify panes by role; don't rely on current list order
        let minor = null, major = null
        for (let i = 0; i < contentChildren.length; ++i) {
            const c = contentChildren[i]
            if (c && c.hasOwnProperty && c.hasOwnProperty("isMinorPane")) {
                if (c.isMinorPane) minor = c
                else               major = c
            }
        }
        return { minor, major }
    }

    function _currentOrderPair() {
        // Return [firstPane, secondPane] considering only panes (exclude handle)
        const arr = []
        for (let i = 0; i < contentChildren.length; ++i) {
            const c = contentChildren[i]
            if (c && c.hasOwnProperty && c.hasOwnProperty("isMinorPane"))
                arr.push(c)
        }
        return arr.length >= 2 ? [arr[0], arr[1]] : arr
    }

    function _ordersEqual(a, b) {
        return a && b && a.length === b.length && a[0] === b[0] && a[1] === b[1]
    }

    function reorderPanes(immediate) {
        if (_reordering) return
        const refs = _paneRefs()
        if (!refs.minor || !refs.major) return

        const desired = isRTL ?
                          isSinglePane ? [refs.minor, refs.major] : [refs.major, refs.minor] :
                          [refs.minor, refs.major]
        const current = _currentOrderPair()
        if (_ordersEqual(current, desired)) return

        _reordering = true

        const performReorder = () => {
            const now = _currentOrderPair()
            if (_ordersEqual(now, desired)) {
                _reordering = false
                return
            }

            const children = control.contentChildren
            if (children.length > 1) {
                control.moveItem(children[0], 1)
            }

            _reordering = false
        }

        if (immediate) {
            performReorder()
        } else {
            Qt.callLater(performReorder)
        }
    }

    onVisibleChanged: {
        if (!autoManageState)
            return
        if (visible) {
            Qt.callLater(reorderPanes)
        }
    }

    handle: Rectangle {
        id: handleRoot

        readonly property int defaultSize: control.handleSize
        visible: !control.isSinglePane

        implicitWidth: control.orientation === Qt.Horizontal ? handleRoot.defaultSize : control.width
        implicitHeight: control.orientation === Qt.Horizontal ? control.height : handleRoot.defaultSize

        color: "transparent"

        containmentMask: Item {
            readonly property real extraHandleSize: 4

            // Determine direction based on LTR/RTL and major/minor pane
            readonly property real handleDirection: handleOnMinor ? (UtilsAdapter.isRTL ? -1 : 1) : (UtilsAdapter.isRTL ? 1 : -1)
            readonly property real handleOffset: (handleOnMinor || !viewCoordinator.isInSinglePaneMode) ? JamiTheme.sidePanelIslandRightPadding
                                                                                                        : JamiTheme.sidePanelIslandsSinglePaneModePadding
            readonly property real handleXPosition: handleDirection * handleOffset
            readonly property real handleSize: handleRoot.defaultSize + extraHandleSize

            x: control.orientation === Qt.Horizontal ? handleXPosition : 0
            width: control.orientation === Qt.Horizontal ? handleSize : handleRoot.width
            height: control.orientation === Qt.Horizontal ? handleRoot.height : handleSize
        }
    }
}
