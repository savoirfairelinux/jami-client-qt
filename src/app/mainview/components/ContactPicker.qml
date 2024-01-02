/*
 * Copyright (C) 2020-2024 Savoir-faire Linux Inc.
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

BaseModalDialog {
    id: contactPickerPopup

    property int type: ContactList.CONFERENCE

    title: {
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

    popupContent: ColumnLayout {
        id: contactPickerPopupRectColumnLayout
        anchors.centerIn: parent
        width: 400

        Searchbar {
            id: contactPickerContactSearchBar

            Layout.alignment: Qt.AlignCenter
            Layout.margins: 5
            Layout.fillWidth: true
            Layout.preferredHeight: 35

            placeHolderText: type === ContactList.TRANSFER ? JamiStrings.transferTo : JamiStrings.addParticipant

            onSearchBarTextChanged: function(text){
                ContactAdapter.setSearchFilter(text);
            }
        }

        JamiListView {
            id: contactPickerListView

            Layout.alignment: Qt.AlignCenter
            Layout.fillWidth: true
            Layout.preferredHeight: 180
            Layout.bottomMargin: JamiTheme.preferredMarginSize

            model: ContactAdapter.getContactSelectableModel(type)

            delegate: ContactPickerItemDelegate {
                id: contactPickerItemDelegate

                showPresenceIndicator: type !== ContactList.TRANSFER
            }
        }
    }
}
