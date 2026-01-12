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
import QtQuick.Controls
import QtQuick.Layouts
import net.jami.Models 1.1
import net.jami.Constants 1.1
import "../../commoncomponents"

ItemDelegate {
    id: root

    width: ListView.view.width
    height: JamiTheme.accountListItemHeight

    background: Rectangle {
        anchors {
            left: parent ? parent.left : undefined
            right: parent ? parent.right : undefined
            leftMargin: 5
            rightMargin: 5
        }
        radius: 5

        Rectangle {
            id: separationLine
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                leftMargin: 10
                rightMargin: 10
            }
            height: 1
            color: JamiTheme.hoverColor
            visible: index !== 0
        }

        color: {
            if (root.pressed)
                return JamiTheme.smartListSelectedColor;
            else if (root.hovered)
                return JamiTheme.hoverColor;
            else
                return JamiTheme.accountComboBoxBackgroundColor;
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 15
        anchors.rightMargin: 15
        spacing: 10

        Avatar {
            objectName: "accountComboBoxDelegateAvatar"
            Layout.preferredWidth: JamiTheme.accountListAvatarSize
            Layout.preferredHeight: JamiTheme.accountListAvatarSize
            Layout.alignment: Qt.AlignVCenter

            presenceStatus: Status

            imageId: ID
            mode: Avatar.Mode.Account
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 2

            Text {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter

                text: Alias
                textFormat: TextEdit.PlainText

                font.pointSize: JamiTheme.textFontSize
                color: JamiTheme.textColor
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignLeft
            }

            Text {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter

                visible: text.length && Alias != Username

                text: Username
                textFormat: TextEdit.PlainText

                font.pointSize: JamiTheme.tinyFontSize
                color: JamiTheme.faddedLastInteractionFontColor
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignLeft
            }
        }

        // unread message count
        Item {
            Layout.preferredWidth: childrenRect.width
            Layout.preferredHeight: childrenRect.height
            Layout.alignment: Qt.AlignRight
            BadgeNotifier {
                size: 20
                count: NotificationCount
                animate: index === 0
            }
        }
    }
}
