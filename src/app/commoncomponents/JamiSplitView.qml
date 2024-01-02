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
    id: root

    property bool isRTL: UtilsAdapter.isRTL
    property bool isSinglePane: false
    property bool isSwapped: false

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
        UtilsAdapter.setAppValue("sv_" + splitViewStateKey, root.saveState());
    }

    function restoreSplitViewState() {
        root.restoreState(UtilsAdapter.getAppValue("sv_" + splitViewStateKey));
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
        visible: !isSinglePane
        implicitWidth: JamiTheme.splitViewHandlePreferredWidth
        implicitHeight: root.height
        color: JamiTheme.primaryBackgroundColor
        Rectangle {
            anchors.left: parent.left
            implicitWidth: 1
            implicitHeight: root.height
            color: JamiTheme.tabbarBorderColor
        }
    }
}
