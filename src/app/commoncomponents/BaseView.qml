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

Rectangle {
    id: viewNode

    // The name of the view that this view must be on top of.
    property string rootViewName

    // Whether or not this view functions in a dual-pane context.
    property bool dualPane: true

    Component.onCompleted: print("+", this)
    Component.onDestruction: print("-", this)

//    Button {
//        anchors {
//            top: parent.top
//            left: parent.left
//        }
//        text: "Back"
//        visible: viewNode.parent instanceof StackView ?
//                     viewNode.parent.depth > 1 :
//                     false
//        onClicked: viewCoordinator.dismiss(viewNode)
//    }
}
