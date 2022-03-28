/*
 * Copyright (C) 2022 Savoir-faire Linux Inc.
 * Author: Sébastien Blin <sebastien.blin@savoirfairelinux.com>
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

    color: JamiTheme.backgroundColor
    property int type: ContactList.ADDCONVMEMBER

    width: 250

    ColumnLayout {
        id: contactPickerPopupRectColumnLayout

        anchors.top: root.top
        anchors.bottom: root.bottom
        anchors.margins: 16

        ContactSearchBar {
            id: contactPickerContactSearchBar

            Layout.alignment: Qt.AlignCenter
            Layout.margins: 5
            Layout.fillWidth: true
            Layout.preferredHeight: 35

            placeHolderText: JamiStrings.addParticipant

            onContactSearchBarTextChanged: {
                ContactAdapter.setSearchFilter(text)
            }
        }

        JamiListView {
            id: contactPickerListView

            Layout.alignment: Qt.AlignCenter
            Layout.preferredWidth: root.width - 8
            Layout.preferredHeight: contactPickerPopupRectColumnLayout.height - contactPickerContactSearchBar.height

            model: ContactAdapter.getContactSelectableModel(type)

            Connections {
                enabled: visible
                target: CurrentConversation

                function onUrisChanged(uris) {
                    model = ContactAdapter.getContactSelectableModel(type)
                }
            }

            onVisibleChanged: {
                if (visible)
                    model = ContactAdapter.getContactSelectableModel(type)
            }

            delegate: ContactPickerItemDelegate {
                id: contactPickerItemDelegate

                showPresenceIndicator: true
            }
        }
    }
}
