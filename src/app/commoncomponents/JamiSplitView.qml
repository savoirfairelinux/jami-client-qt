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

// A SplitView that supports dynamic RTL and splitView state saving.
SplitView {
    id: control

    property bool isRTL: UtilsAdapter.isRTL
    property bool isSinglePane: false
    property bool isSwapped: false
    property real handleSize: 0

    onIsRTLChanged: {
        if (isRTL && isSinglePane && !isSwapped)
            return
        if ((isRTL && !isSwapped) || (!isRTL && isSwapped))
            swapItems()
    }
    onIsSinglePaneChanged: {
        if (isSwapped || isRTL)
            swapItems()
    }

    property string splitViewStateKey: objectName
    property bool autoManageState: !(parent instanceof BaseView)

    function saveSplitViewState() {
        UtilsAdapter.setAppValue("sv_" + splitViewStateKey, control.saveState());
    }

    function restoreSplitViewState() {
        control.restoreState(UtilsAdapter.getAppValue("sv_" + splitViewStateKey));
    }

    onResizingChanged: if (!resizing)
        saveSplitViewState()
    onVisibleChanged: {
        if (!autoManageState)
            return;
        visible ? restoreSplitViewState() : saveSplitViewState();
    }

    function swapItems() {
        isSwapped = !isSwapped
        var qqci = children[0];
        if (qqci.children.length > 1) {
            // swap the children
            var tempPane = qqci.children[0];
            qqci.children[0] = qqci.children[1];
            qqci.children.push(tempPane);
        }
    }

    handle: Rectangle {
        id: handleRoot

        readonly property int defaultSize: control.handleSize

        implicitWidth: control.orientation === Qt.Horizontal ? handleRoot.defaultSize : control.width
        implicitHeight: control.orientation === Qt.Horizontal ? control.height : handleRoot.defaultSize

        // Perhaps the color should get lighter in dark theme
        readonly property color baseColor: JamiTheme.tabbarBorderColor
        color: SplitHandle.pressed ? Qt.darker(baseColor, 1.1)
            : (SplitHandle.hovered ? Qt.darker(baseColor, 1.05) : baseColor)

        containmentMask: Item {
            readonly property real extraOverflow: 6

            // We need to shift the containment mask to the left or up (LTR will reverse this) to make sure that
            // a scrollview handle is not obstructed by the splitview handle hover zone.
            readonly property real scrollHandleOffsetSize: JamiTheme.scrollBarHandleSize / 2
            readonly property real scrollHandleOffset: isRTL ? -scrollHandleOffsetSize : scrollHandleOffsetSize
            readonly property real handleHoverPosition: -extraOverflow + scrollHandleOffset
            readonly property real handleHoverSize: handleRoot.defaultSize + (extraOverflow * 2) + scrollHandleOffset

            x: control.orientation === Qt.Horizontal ? handleHoverPosition : 0
            y: control.orientation === Qt.Horizontal ? 0 : handleHoverPosition
            width: control.orientation === Qt.Horizontal ? handleHoverSize : handleRoot.width
            height: control.orientation === Qt.Horizontal ? handleRoot.height : handleHoverSize
        }
    }
}
