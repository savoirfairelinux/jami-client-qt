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
import QtQuick
import QtQuick.Layouts
import Qt.labs.platform
import Qt5Compat.GraphicalEffects
import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import "../mainview/components"

Item {
    id: root
    property real avatarSize
    property bool doubleEditAvatar: false
    property alias imageId: avatar.imageId
    property bool newItem: false
    property bool readOnly: false

    height: Math.max(avatarSize, buttonSize)

    Rectangle {
        id: imageLayer
        anchors.centerIn: parent
        anchors.fill: parent
        color: "transparent"

        Avatar {
            id: avatar
            anchors.centerIn: parent
            anchors.margins: 1
            fillMode: Image.PreserveAspectCrop
            height: avatarSize
            mode: newItem ? Avatar.Mode.Conversation : Avatar.Mode.Account
            showPresenceIndicator: false
            width: avatarSize
        }
        PushButton {
            id: editImage
            anchors.margins: doubleEditAvatar ? height / 4 : avatar.width / 22
            anchors.right: parent.right
            anchors.top: parent.top
            border.color: JamiTheme.buttonTintedBlue
            enabled: avatar.visible && !root.readOnly
            height: doubleEditAvatar ? avatar.height / 2 : avatar.height / 4
            hoveredColor: JamiTheme.hoveredButtonColorWizard
            imageColor: JamiTheme.buttonTintedBlue
            normalColor: JamiTheme.secondaryBackgroundColor
            preferredSize: doubleEditAvatar ? avatar.width / 3 : avatar.width / 6
            source: JamiResources.round_edit_24dp_svg
            visible: enabled
            width: doubleEditAvatar ? avatar.width / 2 : avatar.width / 4

            onClicked: viewCoordinator.presentDialog(parent, "commoncomponents/PhotoboothPopup.qml", {
                    "parent": editImage,
                    "imageId": root.imageId,
                    "newItem": root.newItem
                })
        }
    }
}
