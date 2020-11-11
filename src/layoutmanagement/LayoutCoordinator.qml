/*
 * Copyright (C) 2020 by Savoir-faire Linux
 * Author: Mingrui Zhang <mingrui.zhang@savoirfairelinux.com>
 * Author: Andreas Traczyk <andreas.traczyk@savoirfairelinux.com>
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

// LayoutCoordinator as a singleton is to provide global ui presentation management
pragma Singleton

import QtQuick 2.14

import "../constant"

QtObject {
    id: root

    objectName: "LayoutCoordinator"

    // map<name, obj>
    property var views: new Map()

    property var mainApplicationWindow: ""

    // MainView
    property var mainStackLayout: ""
    property var leftStackView: ""
    property var rightStackView: ""

    function registerView(view, name) {
        if (JamiQmlUtils.isEmpty(view) || JamiQmlUtils.isEmpty(name)) {
            console.log("View registered failed")
            return
        }

        views.set(name, view)
        console.log(name)
    }
}
