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
import net.jami.Constants 1.0

ListView {
    id: root

    required model
    required property string headerLabel
    required property bool headerVisible

    delegate: SmartListItemDelegate {}
    currentIndex: model.currentFilteredRow

    // scroll related
    clip: true
    maximumFlickVelocity: 1024
    ScrollIndicator.vertical: ScrollIndicator {}

    // highlight selection
    // down and hover states are done within the delegate
    highlight: Rectangle {
        width: ListView.view ? ListView.view.width : 0
        color: JamiTheme.selectedColor
    }
    highlightMoveDuration: 60

    headerPositioning: ListView.OverlayHeader
    header: Rectangle {
        z: 2
        color: JamiTheme.backgroundColor
        visible: root.headerVisible
        width: root.width
        height: root.headerVisible ? 24 : 0
        Text {
            anchors {
                left: parent.left
                leftMargin: 16
                verticalCenter: parent.verticalCenter
            }
            text: headerLabel + " (" + root.count + ")"
            font.pointSize: JamiTheme.smartlistItemFontSize
            font.weight: Font.DemiBold
            color: JamiTheme.textColor
        }
    }

    Connections {
        target: model

        // actually select the conversation
        function onValidSelectionChanged() {
            var row = model.currentFilteredRow
            var uid = model.dataForRow(row, Conversation.UID)
            ConversationsAdapter.selectConversation(AccountAdapter.currentAccountId,
                                                    uid,
                                                    false)
        }
    }

    onCountChanged: positionViewAtBeginning()

    Component.onCompleted: {
        // TODO: remove this
        ConversationsAdapter.setQmlObject(this)
    }

    add: Transition {
        NumberAnimation { property: "opacity"; from: 0; to: 1.0; duration: 250 }
    }

    displaced: Transition {
        NumberAnimation { properties: "x,y"; duration: 250; easing.type: Easing.OutCubic }
        NumberAnimation { property: "opacity"; to: 1.0; duration: 250 * (1 - from)}
    }

    move: Transition {
        NumberAnimation { properties: "x,y"; duration: 250; easing.type: Easing.OutCubic }
    }

    Behavior on opacity {
        NumberAnimation { duration: 500; easing.type: Easing.OutCubic }
    }

    function openContextMenuAt(x, y, delegate) {
        var mappedCoord = root.mapFromItem(delegate, x, y)
        contextMenu.openMenuAt(mappedCoord.x, mappedCoord.y)
    }

    ConversationSmartListContextMenu {
        id: contextMenu

        function openMenuAt(x, y) {
            contextMenu.x = x
            contextMenu.y = y

            // TODO: change this asap
            // - accountId, convId only
            // - userProfile dialog should use a loader/popup

            var row = root.indexAt(x, y)
            var item = {
                "convId": model.dataForRow(row, Conversation.UID),
                "displayId": model.dataForRow(row, Conversation.DisplayID),
                "displayName": model.dataForRow(row, Conversation.DisplayName),
                "uri": model.dataForRow(row, Conversation.URI),
                "contactType": model.dataForRow(row, Conversation.ContactType),
            }

            responsibleAccountId = AccountAdapter.currentAccountId
            responsibleConvUid = item.convId
            contactType = item.contactType
            userProfile.responsibleConvUid = item.convId
            userProfile.aliasText = item.displayName
            userProfile.registeredNameText = item.displayId
            userProfile.idText = item.uri
            userProfile.contactImageUid = item.convId

            openMenu()
        }
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
            model.select(currentIndex + 1)
        }
    }

    Shortcut {
        sequence: "Ctrl+Up"
        context: Qt.ApplicationShortcut
        enabled: root.visible
        onActivated: {
            if (currentIndex <= 0)
                return
            model.select(currentIndex - 1)
        }
    }
}
