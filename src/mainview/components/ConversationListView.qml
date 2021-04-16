/*
 * Copyright (C) 2021 by Savoir-faire Linux
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

import QtQuick 2.14
import QtQuick.Controls 2.14
import QtQuick.Layouts 1.14

import net.jami.Models 1.0
import net.jami.Adapters 1.0

ListView {
    id: root

    model: ConversationListProxyModel

    clip: true
    maximumFlickVelocity: 1024
    delegate: ConversationSmartListViewItemDelegate {
        id: smartListItemDelegate

        onUpdateContactAvatarUidRequested: root.model.updateContactAvatarUid(uid)
    }

    ScrollIndicator.vertical: ScrollIndicator {}

    ConversationSmartListContextMenu {
        id: smartListContextMenu
    }

    Shortcut {
        sequence: "Ctrl+Shift+X"
        context: Qt.ApplicationShortcut
        enabled: root.visible
        onActivated: {
            CallAdapter.placeCall()
            communicationPageMessageWebView.setSendContactRequestButtonVisible(false)
        }
    }

    Shortcut {
        sequence: "Ctrl+Shift+C"
        context: Qt.ApplicationShortcut
        enabled: root.visible
        onActivated: {
            CallAdapter.placeAudioOnlyCall()
            communicationPageMessageWebView.setSendContactRequestButtonVisible(false)
        }
    }

    Shortcut {
        sequence: "Ctrl+Shift+L"
        context: Qt.ApplicationShortcut
        enabled: root.visible
        onActivated: MessagesAdapter.clearConversationHistory(
                         AccountAdapter.currentAccountId,
                         UtilsAdapter.getCurrConvId())
    }

    Shortcut {
        sequence: "Ctrl+Shift+B"
        context: Qt.ApplicationShortcut
        enabled: root.visible
        onActivated: {
            MessagesAdapter.blockConversation(UtilsAdapter.getCurrConvId())
        }
    }

    Shortcut {
        sequence: "Ctrl+Shift+Delete"
        context: Qt.ApplicationShortcut
        enabled: root.visible
        onActivated: MessagesAdapter.removeConversation(
                         AccountAdapter.currentAccountId,
                         UtilsAdapter.getCurrConvId(),
                         false)
    }

    Shortcut {
        sequence: "Ctrl+Down"
        context: Qt.ApplicationShortcut
        enabled: root.visible
        onActivated: {
            if (currentIndex + 1 >= count)
                return
            root.currentIndex += 1
        }
    }

    Shortcut {
        sequence: "Ctrl+Up"
        context: Qt.ApplicationShortcut
        enabled: root.visible
        onActivated: {
            if (currentIndex <= 0)
                return
            root.currentIndex -= 1
        }
    }
}
