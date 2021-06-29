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

    enum Mode { Account, Conversation }
    property int mode: Avatar.Mode.Account

    property string imageId
    readonly property string divider: '_'
    readonly property string baseProviderPrefix: 'image://avatarImage'
    property string typePrefix: mode === Avatar.Mode.Account ? 'a' : 'c'

    property alias presenceStatus: presenceIndicator.status
    property bool showPresenceIndicator: true

    onImageIdChanged: image.updateSource()

    Connections {
        target: AvatarRegistry

        function avatarUidChanged(id) {
            // filter this id only
            if (id !== root.imageId)
                return

            // get the updated uid forcing a new requestImage
            // call to the image provider
            image.updateSource()
        }
    }

    Connections {
        target: ScreenInfo

        function onDevicePixelRatioChanged() {
            image.updateSource()
        }
    }

    Image {
        id: image

        anchors.fill: root

        sourceSize.width: Math.max(24, width)
        sourceSize.height: Math.max(24, height)

        smooth: true
        antialiasing: true
        asynchronous: true

        fillMode: Image.PreserveAspectFit

        function updateSource() {
            if (!imageId)
                return
            source = baseProviderPrefix + '/' +
                    typePrefix + divider +
                    imageId + divider + AvatarRegistry.getUid(imageId)
        }
    }

    PresenceIndicator {
        id: presenceIndicator

        anchors.right: image.right
        anchors.rightMargin: -1
        anchors.bottom: image.bottom
        anchors.bottomMargin: -1

        size: image.width * 0.26

        visible: showPresenceIndicator
    }
}
