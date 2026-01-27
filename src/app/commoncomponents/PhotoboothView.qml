/*
 * Copyright (C) 2020-2026 Savoir-faire Linux Inc.
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
import QtQuick.Effects
import QtQuick.Controls
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

    property alias editButton: editImage

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

        Button {
            id: editImage

            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: doubleEditAvatar ? height / 4 : avatar.width / 22

            icon.width: JamiTheme.iconButtonMedium
            icon.height: JamiTheme.iconButtonMedium
            icon.color: enabled ? hovered ? JamiTheme.textColor : JamiTheme.buttonTintedGreyHovered :
                                            JamiTheme.buttonTintedGreyHovered
            icon.source: JamiResources.round_edit_24dp_svg

            Behavior on icon.color {
                enabled: root.enabled
                ColorAnimation {
                    duration: 200
                }
            }

            background: Rectangle {
                visible: editImage.enabled

                width: parent.icon.width + (parent.icon.width / 2)
                height: parent.icon.height + (parent.icon.height / 2)

                radius: width / 2
                anchors.centerIn: parent.contentItem

                color: parent.hovered ? JamiTheme.hoveredButtonColor :
                                        JamiTheme.primaryBackgroundColor
            }

            MaterialToolTip {
                x: editImage.x + editImage.width / 2 - width / 2
                y: editImage.y - editImage.height - 5

                parent: imageLayer
                text: JamiStrings.editProfilePicture
                delay: Qt.styleHints.mousePressAndHoldInterval

                visible: editImage.hovered
            }

            onClicked: viewCoordinator.presentDialog(parent, "commoncomponents/PhotoboothPopup.qml",
                                                     {
                                                         "imageId": root.imageId,
                                                         "newItem": root.newItem
                                                     })
        }
    }
}
