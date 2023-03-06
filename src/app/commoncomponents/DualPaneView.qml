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

    property alias leftPaneItem: splitView.leftPaneItem
    property alias rightPaneItem: splitView.rightPaneItem
    property alias sv1: splitView.sv1
    property alias sv2: splitView.sv2

    property alias collapseToLeft: splitView.collapseToLeft
    property alias isCollapsed: splitView.isCollapsed
    property alias isCollapsedChangedHandler: splitView.isCollapsedChangedHandler
    property alias splitViewStateKey: splitView.objectName
    property alias isUserCollapsed: splitView.isUserCollapsed
    property alias minimumRightPaneWidth: splitView.minimumRightPaneWidth

    CollapsibleSplitView {
        id: splitView
        anchors.fill: parent
    }
}
