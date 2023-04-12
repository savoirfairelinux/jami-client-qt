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
import QtQuick.Controls
import net.jami.Adapters 1.1
import net.jami.Models 1.1
import net.jami.Constants 1.1
import "../../commoncomponents"

ItemDelegate {
    id: root
    property var showPresenceIndicator: false

    height: Math.max(contactPickerContactName.height + textMetricsContactPickerContactId.height + 10, avatar.height + 10)
    width: ListView.view.width

    signal contactClicked

    ConversationAvatar {
        id: avatar
        anchors.left: parent.left
        anchors.leftMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        height: 40
        imageId: UID
        showPresenceIndicator: root.showPresenceIndicator && Presence
        width: 40
    }
    Rectangle {
        id: contactPickerContactInfoRect
        anchors.left: avatar.right
        anchors.leftMargin: 10
        anchors.top: parent.top
        color: "transparent"
        height: parent.height
        width: parent.width - avatar.width - 20

        Text {
            id: contactPickerContactName
            anchors.bottom: contactPickerContactInfoRect.verticalCenter
            anchors.left: contactPickerContactInfoRect.left
            color: JamiTheme.textColor
            font.pointSize: JamiTheme.textFontSize
            text: textMetricsContactPickerContactName.elidedText
            textFormat: TextEdit.PlainText

            TextMetrics {
                id: textMetricsContactPickerContactName
                elide: Text.ElideMiddle
                elideWidth: contactPickerContactInfoRect.width
                font: contactPickerContactName.font
                text: Title
            }
        }
        Text {
            id: contactPickerContactId
            anchors.left: contactPickerContactInfoRect.left
            anchors.top: contactPickerContactInfoRect.verticalCenter
            color: JamiTheme.faddedFontColor
            font.pointSize: JamiTheme.textFontSize
            fontSizeMode: Text.Fit
            text: textMetricsContactPickerContactId.elidedText
            textFormat: TextEdit.PlainText

            TextMetrics {
                id: textMetricsContactPickerContactId
                elide: Text.ElideMiddle
                elideWidth: contactPickerContactInfoRect.width
                font: contactPickerContactId.font
                text: !BestId || BestId == Title ? "" : BestId
            }
        }
    }
    MouseArea {
        id: mouseAreaContactPickerItemDelegate
        acceptedButtons: Qt.LeftButton
        anchors.fill: parent
        hoverEnabled: true

        onEntered: {
            itemSmartListBackground.color = JamiTheme.hoverColor;
        }
        onExited: {
            itemSmartListBackground.color = JamiTheme.backgroundColor;
        }
        onPressed: {
            itemSmartListBackground.color = JamiTheme.pressColor;
        }
        onReleased: {
            itemSmartListBackground.color = JamiTheme.normalButtonColor;
            ContactAdapter.contactSelected(index);
            root.contactClicked();
            // TODO remove from there
            if (contactPickerPopup)
                contactPickerPopup.close();
        }
    }

    background: Rectangle {
        id: itemSmartListBackground
        border.width: 0
        color: JamiTheme.backgroundColor
    }
}
