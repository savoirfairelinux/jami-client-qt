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

    property alias imageId: avatar.imageId

    property bool newItem: false
    property bool readOnly: false
    property real avatarSize
    property bool doubleEditAvatar: false

    height: avatarSize

    Rectangle {
        id: imageLayer

        anchors.centerIn: parent
        anchors.fill: parent
        color: "transparent"

        Avatar {
            id: avatar

            width: avatarSize
            height: avatarSize
            anchors.centerIn: parent
            anchors.margins: 1

            mode: newItem ? Avatar.Mode.Conversation : Avatar.Mode.Account

            fillMode: Image.PreserveAspectCrop
            showPresenceIndicator: false
        }

        JamiPushButton {
            id: editImage

            width: doubleEditAvatar ? avatar.width / 2 : avatar.width / 4
            height: doubleEditAvatar ? avatar.height / 2 : avatar.height / 4
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: doubleEditAvatar ? height / 4 : avatar.width / 22

            source: JamiResources.round_edit_24dp_svg

            preferredSize: doubleEditAvatar ? avatar.width / 3 : avatar.width / 6

            normalColor: JamiTheme.secondaryBackgroundColor
            hoveredColor: JamiTheme.hoveredButtonColorWizard
            border.color: JamiTheme.editButtonBorderColor
            border.width: 2
            imageColor: hovered ? JamiTheme.textColor : JamiTheme.buttonTintedGreyHovered

            enabled: avatar.visible && !root.readOnly
            visible: enabled

            onClicked: viewCoordinator.presentDialog(parent, "commoncomponents/PhotoboothPopup.qml", {
                    "parent": editImage,
                    "imageId": root.imageId,
                    "newItem": root.newItem
                })
        }
    }
}
