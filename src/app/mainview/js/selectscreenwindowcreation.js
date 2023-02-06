/*
 * Copyright (C) 2020-2023 Savoir-faire Linux Inc.
 * Author: Mingrui Zhang <mingrui.zhang@savoirfairelinux.com>
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

function presentSelectScreenWindow(parent, selectWindows) {
    var comp = Qt.createComponent(
                "../components/SelectScreen.qml")
    if (comp.status === Component.Ready) {
        var obj = comp.createObject(parent, {showWindows: selectWindows})
        if (obj === null) {
            // Error Handling.
            console.log("Error creating select screen object")
        } else {
            var centerX = appWindow.x + appWindow.width / 2
            var centerY = appWindow.y + appWindow.height / 2
            obj.width = 0.75 * appWindow.width
            obj.height = 0.75 * appWindow.height
            obj.x = centerX - obj.width / 2
            obj.y = centerY - obj.height / 2
            obj.show()
        }
    } else if (comp.status === Component.Error) {
        console.log("Error loading component:", comp.errorString())
    }
}
