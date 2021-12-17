/*
 * Copyright (C) 2021 by Savoir-faire Linux
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

import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1

import "../../commoncomponents"
import "../../commoncomponents/contextmenu"

ContextMenuAutoLoader {
    id: root
    property var conversationId: ""
    property var participantUri: ""

    // TODO get authorization

    property list<GeneralMenuItem> menuItems: [
        GeneralMenuItem {
            id: startVideoCallItem
            itemName: JamiStrings.startVideoCall
            onClicked: {
            }
        },
        GeneralMenuItem {
            id: startAudioCall
            itemName: JamiStrings.startAudioCall
            onClicked: {
            }
        },
        GeneralMenuItem {
            id: goToConversation

            itemName: JamiStrings.goToConversation
            onClicked: {
            }
        },
        GeneralMenuItem {
            id: promoteAdministrator
            itemName: JamiStrings.promoteAdministrator
        },
        GeneralMenuItem {
            id: blockContact
            itemName: JamiStrings.blockContact
            iconSource: JamiResources.block_black_24dp_svg
        },
        GeneralMenuItem {
            id: kickMember
            itemName: JamiStrings.kickMember

            // TODO can trigger (enough permission for self and member accepted)
            onClicked: {
                MessagesAdapter.removeConversationMember(conversationId, participantUri)
            }
        }
    ]

    Component.onCompleted: menuItemsToLoad = menuItems
}
