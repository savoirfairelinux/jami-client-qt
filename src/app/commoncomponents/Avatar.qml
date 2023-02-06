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

    enum Mode { Account, Contact, Conversation }
    property int mode: Avatar.Mode.Account
    property alias sourceSize: image.sourceSize

    property string imageId

    readonly property string divider: '_'
    readonly property string baseProviderPrefix: 'image://avatarImage'
    property string typePrefix: {
        switch (mode) {
        case Avatar.Mode.Account: return 'account'
        case Avatar.Mode.Contact: return 'contact'
        case Avatar.Mode.Conversation: return 'conversation'
        }
    }

    property alias presenceStatus: presenceIndicator.status
    property bool showPresenceIndicator: true
    property bool showSharePositionIndicator: false
    property bool showSharedPositionIndicator: false
    property alias fillMode: image.fillMode

    onImageIdChanged: image.updateSource()

    Connections {
        target: AvatarRegistry

        function onAvatarUidChanged(id) {
            // filter this id only
            if (id !== root.imageId)
                return

            // get the updated uid forcing a new requestImage
            // call to the image provider
            image.updateSource()
        }
    }

    Connections {
        target: CurrentScreenInfo

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
        asynchronous: false

        fillMode: Image.PreserveAspectFit

        function updateSource() {
            if (!imageId)
                return
            source = baseProviderPrefix + '/' +
                    typePrefix + divider +
                    imageId + divider + AvatarRegistry.getUid(imageId)
        }

        opacity: status === Image.Ready
        scale: Math.min(image.opacity + 0.5, 1.0)

        Behavior on opacity {
            NumberAnimation {
                from: 0
                duration: JamiTheme.shortFadeDuration
            }
        }
    }

    PresenceIndicator {
        id: presenceIndicator

        anchors.right: root.right
        anchors.rightMargin: -1
        anchors.bottom: root.bottom
        anchors.bottomMargin: -1

        size: root.width * JamiTheme.avatarPresenceRatio

        visible: showPresenceIndicator
    }
    RowLayout {
        id: positionIndicatorLayout
        anchors.left: root.left
        anchors.leftMargin: -1
        anchors.bottom: root.bottom
        anchors.bottomMargin: -1
        spacing: 0
        property real sizeI: root.width * JamiTheme.avatarPresenceRatio
        Rectangle {
            id: sharePositionIndicator
            visible: showSharePositionIndicator
            Layout.preferredWidth: parent.sizeI
            Layout.preferredHeight: parent.sizeI
            color: JamiTheme.backgroundColor
            radius: parent.sizeI * 0.5
            Image {
                anchors.fill: parent
                ColorOverlay {
                    anchors.fill: parent
                    source: parent
                    color: JamiTheme.sharePositionIndicatorColor
                }
                source: JamiResources.my_location_svg
            }
        }
        Rectangle {
            id: sharedPositionIndicator
            visible: showSharedPositionIndicator
            Layout.preferredWidth: parent.sizeI
            Layout.preferredHeight: parent.sizeI
            color: JamiTheme.backgroundColor
            radius: parent.sizeI * 0.5
            Image {
                anchors.fill: parent
                ColorOverlay {
                    anchors.fill: parent
                    source: parent
                    color: JamiTheme.sharedPositionIndicatorColor
                }
                source: JamiResources.my_location_svg
            }
        }
    }

}
