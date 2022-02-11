/*
 * Copyright (C) 2021 by Savoir-faire Linux
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

import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1

import "../../commoncomponents"


Rectangle {
    id: root

    color: JamiTheme.chatviewBgColor

    signal createSwarmClicked(string title, string description, string avatar)

    onVisibleChanged: {
        UtilsAdapter.setSwarmCreationImage()
    }

    property var members: []

    RowLayout {
        id: labelsMember
        anchors.top: root.top
        anchors.topMargin: 16
        anchors.leftMargin: 16
        Layout.preferredWidth: root.width
        spacing: 16

        Label {
            text: qsTr("To:")
            font.bold: true
            color: JamiTheme.textColor
        }
        // TODO flow

        Repeater {
            id: repeater

            delegate: Rectangle {
                id: delegate
                radius: (delegate.height + 12) / 2
                width: childrenRect.width + 12
                height: childrenRect.height + 12

                RowLayout {
                    anchors.centerIn: parent

                    Label {
                        text: UtilsAdapter.getBestNameForUri(CurrentAccount.id, modelData)
                        color: JamiTheme.textColor
                    }
                    // TODO close button
                }

                color: "grey"
            }
            model: root.members
        }
    }

    ColumnLayout {
        id: mainLayout
        anchors.centerIn: root

        PhotoboothView {
            id: currentAccountAvatar

            Layout.alignment: Qt.AlignCenter

            newConversation: true
            imageId: root.visible ? "temp" : ""
            avatarSize: 180
        }

        EditableLineEdit {
            id: title
            Layout.alignment: Qt.AlignCenter
            Layout.topMargin: JamiTheme.preferredMarginSize

            font.pointSize: JamiTheme.titleFontSize

            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter

            placeholderText: JamiStrings.editTitle
            tooltipText: JamiStrings.editTitle
            backgroundColor: root.color
            color: "white"
        }

        EditableLineEdit {
            id: description
            Layout.alignment: Qt.AlignCenter
            Layout.topMargin: JamiTheme.preferredMarginSize

            font.pointSize: JamiTheme.titleFontSize

            placeholderText: JamiStrings.editDescription
            tooltipText: JamiStrings.editDescription
            backgroundColor: root.color
            color: "white"
        }

        MaterialButton {
            id: btnCreateSwarm

            Layout.alignment: Qt.AlignCenter
            Layout.topMargin: JamiTheme.preferredMarginSize

            preferredWidth: JamiTheme.aboutButtonPreferredWidth

            color: JamiTheme.buttonTintedBlue
            hoveredColor: JamiTheme.buttonTintedBlueHovered
            pressedColor: JamiTheme.buttonTintedBluePressed

            text: JamiStrings.createTheSwarm

            onClicked: {
                createSwarmClicked(title.text, description.text, UtilsAdapter.swarmCreationImage())
            }
        }
    }
}
