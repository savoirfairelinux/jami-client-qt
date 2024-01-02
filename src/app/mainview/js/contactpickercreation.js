/*
 * Copyright (C) 2020-2024 Savoir-faire Linux Inc.
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

function presentContactPickerPopup(type, parent) {
    var comp = Qt.createComponent(
                "../components/ContactPicker.qml")
    if (comp.status === Component.Ready) {
        var obj = comp.createObject(parent, { type: type, parent: parent })
        if (obj === null) {
            console.log("Error creating object for contact picker")
        } else {
            obj.x = Qt.binding(() => parent.width / 2 - obj.width / 2)
            obj.y = Qt.binding(() => parent.height / 2 - obj.height / 2)
            obj.closed.connect(() => obj.destroy())
            obj.open()
        }
    } else if (comp.status === Component.Error) {
        console.log("Error loading component:", comp.errorString())
    }
}
