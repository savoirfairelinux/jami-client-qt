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

// A SplitView that supports dynamic RTL and splitView state saving.
SplitView {
    id: control

    property bool isRTL: AppSettingsManager.isRTL
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
        AppSettingsManager.settingsMap["sv_" + splitViewStateKey] = control.saveState();
    }

    function restoreSplitViewState() {
        control.restoreState(AppSettingsManager.settingsMap["sv_" + splitViewStateKey]);
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

        color: JamiTheme.tabbarBorderColor

        containmentMask: Item {
            // In the default configuration, the total handle size is the sum of the default size of the
            // handle and the extra handle size (4). If the layout is not right-to-left (RTL), the handle
            // is positioned at 0 on the X-axis, otherwise it's positioned to the left by the extra handle
            // size (4 pixels). This is done to make it easier to grab small scroll-view handles that are
            // adjacent to the SplitView handle. Note: vertically oriented handles are not offset.
            readonly property real extraHandleSize: 4
            readonly property real handleXPosition: !AppSettingsManager.isRTL ? 0 : -extraHandleSize
            readonly property real handleSize: handleRoot.defaultSize + extraHandleSize

            x: control.orientation === Qt.Horizontal ? handleXPosition : 0
            width: control.orientation === Qt.Horizontal ? handleSize : handleRoot.width
            height: control.orientation === Qt.Horizontal ? handleRoot.height : handleSize
        }
    }
}
