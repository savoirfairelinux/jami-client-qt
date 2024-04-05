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
    property real handleSize: 1

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
            // In the default configuration, the total handle size is 5 (1 + 2 * 2), and the handle is offset
            // to the right by 2 pixels in the case of left-to-right layout, and otherwise to the left by 2 pixels.
            // This is done to make it easier to grab small scroll-view handles. The vertical treatment is independent
            // of the left-to-rightness.
            readonly property real extraOverflow: 2
            readonly property real extraOverflowOffest: 2
            readonly property real handleHoverXPosition: -extraOverflow + (!isRTL ? extraOverflowOffest : -extraOverflowOffest)
            readonly property real handleHoverYPosition: -extraOverflow + extraOverflowOffest
            readonly property real handleHoverSize: handleRoot.defaultSize + (extraOverflow * 2)

            x: control.orientation === Qt.Horizontal ? handleHoverXPosition : 0
            y: control.orientation === Qt.Horizontal ? 0 : handleHoverYPosition
            width: control.orientation === Qt.Horizontal ? handleHoverSize : handleRoot.width
            height: control.orientation === Qt.Horizontal ? handleRoot.height : handleHoverSize
        }
    }
}
