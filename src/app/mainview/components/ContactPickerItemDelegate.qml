/*
 * Copyright (C) 2020-2025 Savoir-faire Linux Inc.
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

    width: ListView.view.width
    height: Math.max(contactPickerContactName.height + textMetricsContactPickerContactId.height + 10, avatar.height + 10)

    property var showPresenceIndicator: false

    signal contactClicked

    ConversationAvatar {
        id: avatar

        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: 10

        width: 40
        height: 40

        imageId: UID

        showPresenceIndicator: root.showPresenceIndicator && Presence
    }

    Rectangle {
        id: contactPickerContactInfoRect

        anchors.left: avatar.right
        anchors.leftMargin: 10
        anchors.top: parent.top

        width: parent.width - avatar.width - 20
        height: parent.height

        color: "transparent"

        Text {
            id: contactPickerContactName

            anchors.left: contactPickerContactInfoRect.left
            anchors.bottom: contactPickerContactInfoRect.verticalCenter

            TextMetrics {
                id: textMetricsContactPickerContactName
                font: contactPickerContactName.font
                elide: Text.ElideMiddle
                elideWidth: contactPickerContactInfoRect.width
                text: Title
            }

            color: JamiTheme.textColor
            text: textMetricsContactPickerContactName.elidedText
            textFormat: TextEdit.PlainText
            font.pointSize: JamiTheme.textFontSize
        }

        Text {
            id: contactPickerContactId

            anchors.left: contactPickerContactInfoRect.left
            anchors.top: contactPickerContactInfoRect.verticalCenter

            fontSizeMode: Text.Fit
            color: JamiTheme.faddedFontColor

            TextMetrics {
                id: textMetricsContactPickerContactId
                font: contactPickerContactId.font
                elide: Text.ElideMiddle
                elideWidth: contactPickerContactInfoRect.width
                text: !BestId || BestId == Title ? "" : BestId
            }

            text: textMetricsContactPickerContactId.elidedText
            textFormat: TextEdit.PlainText
            font.pointSize: JamiTheme.textFontSize
        }
    }

    background: Rectangle {
        id: itemSmartListBackground

        color: JamiTheme.backgroundColor

        border.width: 0
    }

    MouseArea {
        id: mouseAreaContactPickerItemDelegate

        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton

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

        onEntered: {
            itemSmartListBackground.color = JamiTheme.hoverColor;
        }

        onExited: {
            itemSmartListBackground.color = JamiTheme.backgroundColor;
        }
    }
}
