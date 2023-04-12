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
    height: JamiTheme.accountListItemHeight
    width: ListView.view.width

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 15
        anchors.rightMargin: 15
        spacing: 10

        Avatar {
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredHeight: JamiTheme.accountListAvatarSize
            Layout.preferredWidth: JamiTheme.accountListAvatarSize
            imageId: ID
            mode: Avatar.Mode.Account
            presenceStatus: Status
        }
        ColumnLayout {
            Layout.fillHeight: true
            Layout.fillWidth: true
            spacing: 2

            Text {
                Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                Layout.fillWidth: true
                color: JamiTheme.textColor
                elide: Text.ElideRight
                font.pointSize: JamiTheme.textFontSize
                text: Alias
                textFormat: TextEdit.PlainText
            }
            Text {
                Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                Layout.fillWidth: true
                color: JamiTheme.faddedLastInteractionFontColor
                elide: Text.ElideRight
                font.pointSize: JamiTheme.textFontSize
                text: Username
                textFormat: TextEdit.PlainText
                visible: text.length && Alias != Username
            }
        }

        // unread message count
        Item {
            Layout.alignment: Qt.AlignRight
            Layout.preferredHeight: childrenRect.height
            Layout.preferredWidth: childrenRect.width

            BadgeNotifier {
                animate: index === 0
                count: NotificationCount
                size: 20
            }
        }
    }

    background: Rectangle {
        color: {
            if (root.pressed)
                return JamiTheme.smartListSelectedColor;
            else if (root.hovered)
                return JamiTheme.smartListHoveredColor;
            else
                return JamiTheme.backgroundColor;
        }
    }
}
