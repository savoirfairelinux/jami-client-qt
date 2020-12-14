/*
 * Copyright (C) 2020 by Savoir-faire Linux
 * Author: Albert Babí Oller <albert.babi@savoirfairelinux.com>
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

import QtQuick 2.14
import QtQuick.Layouts 1.14
import net.jami.Models 1.0
import net.jami.Constants 1.0

import "../../commoncomponents"

ColumnLayout {
    id:root

    property bool isSIP

    visible: moderatorListWidget.model.rowCount() > 0

    function updateAndShowModeratorsSlot() {
        moderatorListWidget.model.reset()
        moderatorListWidget.visible =
                moderatorListWidget.model.rowCount() > 0
    }

    function removeModerator(index) {
        console.error("Remove moderator", index)
        // TODO: Implement SettingsAdapter.removeModerator(index)
    }

    ElidedTextLabel {
        Layout.fillWidth: true

        eText: JamiStrings.moderators
        fontSize: JamiTheme.headerFontSize
        maxWidth: root.width - JamiTheme.preferredFieldHeight
                    - JamiTheme.preferredMarginSize * 4
    }

    ListViewJami {
        id: moderatorListWidget

        Layout.fillWidth: true
        Layout.preferredHeight: 160

        model: ModeratorListModel {}

        delegate: ModeratorItemDelegate {
            id: moderatorListDelegate

            width: moderatorListWidget.width
            height: 74

            contactName : ContactName
            contactID: ContactID

            onClicked: moderatorListWidget.currentIndex = index

            onBtnRemoveModeratorClicked: removeModerator(index)
        }
    }
}
