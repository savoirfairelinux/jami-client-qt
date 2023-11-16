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
import net.jami.Models 1.1
import net.jami.Constants 1.1
import "../../commoncomponents"

ItemDelegate {
    id: root

    width: ListView.view.width
    height: JamiTheme.accountListItemHeight

    background: Rectangle {
        width: root.width - 10
        anchors.horizontalCenter: parent.horizontalCenter
        radius: 5

        Rectangle{
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            height: 1.5
            width: parent.width - 20
            color: JamiTheme.smartListHoveredColor
        }

        color: {
            if (root.pressed)
                return JamiTheme.smartListSelectedColor;
            else if (root.hovered)
                return JamiTheme.smartListHoveredColor;
            else
                return JamiTheme.backgroundColor;
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 15
        anchors.rightMargin: 15
        spacing: 10

        Avatar {
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

                font.pointSize: JamiTheme.textFontSize
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
