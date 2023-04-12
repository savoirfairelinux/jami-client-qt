/*
 * Copyright (C) 2020-2023 Savoir-faire Linux Inc.
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
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import net.jami.Helpers 1.1

Item {
    id: root
    enum Mode {
        Account,
        Contact,
        Conversation
    }

    readonly property string baseProviderPrefix: 'image://avatarImage'
    readonly property string divider: '_'
    property alias fillMode: image.fillMode
    property string imageId
    property int mode: Avatar.Mode.Account
    property alias presenceStatus: presenceIndicator.status
    property bool showPresenceIndicator: true
    property alias sourceSize: image.sourceSize
    property string typePrefix: {
        switch (mode) {
        case Avatar.Mode.Account:
            return 'account';
        case Avatar.Mode.Contact:
            return 'contact';
        case Avatar.Mode.Conversation:
            return 'conversation';
        }
    }

    onImageIdChanged: image.updateSource()

    Connections {
        target: AvatarRegistry

        function onAvatarUidChanged(id) {
            // filter this id only
            if (id !== root.imageId)
                return;

            // get the updated uid forcing a new requestImage
            // call to the image provider
            image.updateSource();
        }
    }
    Connections {
        target: CurrentScreenInfo

        function onDevicePixelRatioChanged() {
            image.updateSource();
        }
    }
    Image {
        id: image
        anchors.fill: root
        antialiasing: true
        asynchronous: false
        fillMode: Image.PreserveAspectFit
        opacity: status === Image.Ready
        scale: Math.min(image.opacity + 0.5, 1.0)
        smooth: true
        sourceSize.height: Math.max(24, height)
        sourceSize.width: Math.max(24, width)

        function updateSource() {
            if (!imageId)
                return;
            source = baseProviderPrefix + '/' + typePrefix + divider + imageId + divider + AvatarRegistry.getUid(imageId);
        }

        Behavior on opacity  {
            NumberAnimation {
                duration: JamiTheme.shortFadeDuration
                from: 0
            }
        }
    }
    PresenceIndicator {
        id: presenceIndicator
        anchors.bottom: root.bottom
        anchors.bottomMargin: -1
        anchors.right: root.right
        anchors.rightMargin: -1
        size: root.width * JamiTheme.avatarPresenceRatio
        visible: showPresenceIndicator
    }
}
