/*
 * Copyright (C) 2021 by Savoir-faire Linux
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

import QtQuick 2.14
import QtQuick.Controls 2.14

import net.jami.Adapters 1.0
import net.jami.Constants 1.0
import net.jami.Models 1.0

Item {
    id: root

    property string avatarId
    property alias presenceStatus: presenceIndicator.status
    property bool showPresenceIndicator: true

    readonly property string providerPrefix: "image://avatarImage/"

    onAvatarIdChanged: img.updateSource()

    Connections {
        target: AvatarRegistry

        function avatarUidChanged(id) {
            // filter this id only
            if (id !== root.avatarId)
                return

            // get the updated uid forcing a new requestImage
            // call to the image provider
            img.updateSource()
        }
    }

    Image {
        id: img

        anchors.fill: root

        sourceSize.width: Math.max(24, width)
        sourceSize.height: Math.max(24, height)

        smooth: true
        antialiasing: true
        asynchronous: true

        fillMode: Image.PreserveAspectFit

        function updateSource() {
            source = providerPrefix +
                    avatarId + '_' + AvatarRegistry.getUid(avatarId)
        }

        Component.onCompleted: updateSource()
    }

    PresenceIndicator {
        id: presenceIndicator

        anchors.right: img.right
        anchors.rightMargin: -1
        anchors.bottom: img.bottom
        anchors.bottomMargin: -1

        size: img.width * 0.26

        visible: showPresenceIndicator
    }
}
