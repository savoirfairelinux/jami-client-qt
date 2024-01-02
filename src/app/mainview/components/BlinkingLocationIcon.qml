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
import QtQuick.Layouts
import net.jami.Constants 1.1
import "../../commoncomponents"

ResponsiveImage {
    id: root

    property bool isSharing: false
    property bool arrowTimerVisibility
    source: JamiResources.localisation_sharing_send_pin_svg

    ResponsiveImage {
        id: arrowSharePosition

        visible: arrowTimerVisibility
        source: JamiResources.localisation_sharing_send_arrow_svg
        color: root.color
        mirrorHorizontally: isSharing ? false : true
        mirrorVertically: isSharing ? false : true
        anchors.fill: parent
        anchors.bottomMargin: isSharing ? 0 : 4
        anchors.leftMargin: isSharing ? 0 : 3
    }
}
