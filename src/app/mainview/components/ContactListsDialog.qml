/*
 * Copyright (C) 2026 Savoir-faire Linux Inc.
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
import net.jami.Adapters 1.1
import net.jami.Constants 1.1

// Adds the contact of a one-to-one conversation to lists (contact tags).
AddToListDialog {
    id: root
    objectName: "ContactListsDialog"

    required property string conversationId

    Component.onCompleted: {
        availableLists = ContactAdapter.getAllContactTags();
        initialSelection = ContactAdapter.getContactTags(conversationId);
    }

    onSubmitted: function (lists) {
        if (ContactAdapter.setContactTags(conversationId, lists))
            close();
        else
            errorText = JamiStrings.listsSaveFailed;
    }

    Connections {
        target: LRCInstance

        function onCurrentAccountIdChanged() {
            root.close();
        }
        function onCurrentAccountRemoved() {
            root.close();
        }
    }
}
