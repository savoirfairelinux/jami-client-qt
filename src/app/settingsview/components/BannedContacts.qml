/*
 * Copyright (C) 2020-2024 Savoir-faire Linux Inc.
 * Author: Aline Gondim Santos <aline.gondimsantos@savoirfairelinux.com>
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
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
import QtQuick
import QtQuick.Layouts
import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import "../../commoncomponents"

ColumnLayout {
    id: root

    JamiListView {
        id: bannedListWidget

        property int bannedContactsSize: 0

        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(bannedContactsSize, 5) * (74 + spacing)
        spacing: JamiTheme.settingsListViewsSpacing

        model: BannedListModel {
            lrcInstance: LRCInstance

            onCountChanged: bannedListWidget.bannedContactsSize = count
        }

        delegate: ContactItemDelegate {
            id: bannedListDelegate

            width: bannedListWidget.width
            height: 74

            contactName: ContactName
            contactID: ContactID

            btnImgSource: JamiStrings.optionUnban
            btnToolTip: JamiStrings.reinstateContact

            onClicked: bannedListWidget.currentIndex = index
            onBtnContactClicked: MessagesAdapter.unbanContact(index)
        }
    }
}
