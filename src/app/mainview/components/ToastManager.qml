/*
 * Copyright (C) 2023 Savoir-faire Linux Inc.
 * Author: Vengeon Nicolas <nicolas.vengeon@savoirfairelinux.com>
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

Item {
    id: root

    function instantiate(message, parent, duration = 1000, fadingTime = 400) {
        var component = Qt.createComponent("Toast.qml");
        if (Component.Error === component.status) {
            console.log("Error loading component:", component.errorString());
        } else if (Component.Ready === component.status) {
            var sprite = component.createObject(parent === undefined ? root : parent, {
                    "message": message,
                    "duration": duration,
                    "fadingTime": fadingTime
                });
        }
    }
}
