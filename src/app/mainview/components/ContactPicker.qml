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
import QtQuick.Layouts
import net.jami.Adapters 1.1
import net.jami.Models 1.1
import net.jami.Constants 1.1
import "../../commoncomponents"

Popup {
    id: contactPickerPopup
    property int type: ContactList.CONFERENCE

    contentHeight: contactPickerPopupRectColumnLayout.height + 50
    contentWidth: 250
    modal: true
    padding: 0

    onAboutToShow: {
        contactPickerListView.model = ContactAdapter.getContactSelectableModel(type);
    }

    background: Rectangle {
        color: "transparent"
    }
    contentItem: Rectangle {
        id: contactPickerPopupRect
        color: JamiTheme.backgroundColor
        radius: 10
        width: 250

        PushButton {
            id: closeButton
            anchors.right: contactPickerPopupRect.right
            anchors.rightMargin: 5
            anchors.top: contactPickerPopupRect.top
            anchors.topMargin: 5
            imageColor: JamiTheme.textColor
            source: JamiResources.round_close_24dp_svg

            onClicked: {
                contactPickerPopup.close();
            }
        }
        ColumnLayout {
            id: contactPickerPopupRectColumnLayout
            anchors.top: contactPickerPopupRect.top
            anchors.topMargin: 15

            Text {
                id: contactPickerTitle
                Layout.alignment: Qt.AlignCenter
                Layout.preferredHeight: 30
                Layout.preferredWidth: contactPickerPopupRect.width
                color: JamiTheme.textColor
                font.bold: true
                font.pointSize: JamiTheme.textFontSize
                horizontalAlignment: Text.AlignHCenter
                text: {
                    switch (type) {
                    case ContactList.CONFERENCE:
                        return JamiStrings.addToConference;
                    case ContactList.ADDCONVMEMBER:
                        return JamiStrings.addToConversation;
                    case ContactList.TRANSFER:
                        return JamiStrings.transferThisCall;
                    default:
                        return JamiStrings.addDefaultModerator;
                    }
                }
                verticalAlignment: Text.AlignVCenter
            }
            ContactSearchBar {
                id: contactPickerContactSearchBar
                Layout.alignment: Qt.AlignCenter
                Layout.fillWidth: true
                Layout.margins: 5
                Layout.preferredHeight: 35
                placeHolderText: type === ContactList.TRANSFER ? JamiStrings.transferTo : JamiStrings.addParticipant

                onContactSearchBarTextChanged: {
                    ContactAdapter.setSearchFilter(text);
                }
            }
            JamiListView {
                id: contactPickerListView
                Layout.alignment: Qt.AlignCenter
                Layout.preferredHeight: 200
                Layout.preferredWidth: contactPickerPopupRect.width
                model: ContactAdapter.getContactSelectableModel(type)

                delegate: ContactPickerItemDelegate {
                    id: contactPickerItemDelegate
                    showPresenceIndicator: type !== ContactList.TRANSFER
                }
            }
        }
    }
}
