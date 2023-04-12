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
    id: root
    property bool autoManageState: !(parent instanceof BaseView)
    property string splitViewStateKey: objectName

    function restoreSplitViewState() {
        root.restoreState(UtilsAdapter.getAppValue("sv_" + splitViewStateKey));
    }
    function saveSplitViewState() {
        UtilsAdapter.setAppValue("sv_" + splitViewStateKey, root.saveState());
    }

    onResizingChanged: if (!resizing)
        saveSplitViewState()
    onVisibleChanged: {
        if (!autoManageState)
            return;
        visible ? restoreSplitViewState() : saveSplitViewState();
    }

    handle: Rectangle {
        color: JamiTheme.primaryBackgroundColor
        implicitHeight: root.height
        implicitWidth: JamiTheme.splitViewHandlePreferredWidth

        Rectangle {
            color: JamiTheme.tabbarBorderColor
            implicitHeight: root.height
            implicitWidth: 1
        }
    }
}
