/*
 * Copyright (C) 2021-2026 Savoir-faire Linux Inc.
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
import net.jami.Constants 1.1
import net.jami.Models 1.1
import "../../commoncomponents"

JamiListView {
    id: root

    required property string headerLabel
    required property bool headerVisible

    delegate: SmartListItemDelegate {}
    currentIndex: model.currentFilteredRow

    // Allows scrolling to follow currently focused item
    onCurrentIndexChanged: {
        if (currentIndex >= 0 && currentIndex < count) {
            positionViewAtIndex(currentIndex, ListView.Contain);
        }
    }

    // Disable highlight on current item; we do this ourselves with the
    // SmartListItemDelegate.
    highlightFollowsCurrentItem: false

    headerPositioning: ListView.OverlayHeader
    header: Rectangle {
        z: 2
        color: JamiTheme.globalIslandColor
        visible: root.headerVisible
        width: root.width
        height: root.headerVisible ? 20 : 0
        Text {
            anchors {
                left: parent.left
                leftMargin: 16
                verticalCenter: parent.verticalCenter
            }
            text: headerLabel + " (" + root.count + ")"
            font.pointSize: JamiTheme.mediumFontSize
            font.weight: Font.DemiBold
            color: JamiTheme.textColor
        }
    }

    Connections {
        target: model

        // actually select the conversation
        function onValidSelectionChanged() {
            var row = model.currentFilteredRow;
            var convId = model.dataForRow(row, ConversationList.UID);
            LRCInstance.selectConversation(convId);
        }
    }

    onCountChanged: positionViewAtBeginning()

    Behavior on opacity {
        NumberAnimation {
            easing.type: Easing.OutCubic
            duration: 2 * JamiTheme.smartListTransitionDuration
        }
    }

    function openContextMenuAt(x, y, delegate) {
        var mappedCoord = root.mapFromItem(delegate, x, y);
        contextMenu.openMenuAt(mappedCoord.x, mappedCoord.y);
    }

    ConversationSmartListContextMenu {
        id: contextMenu

        property int index: -1

        function openMenuAt(x, y) {
            contextMenu.x = x;
            contextMenu.y = y;
            index = root.indexAt(x, y + root.contentY);

            // TODO: use accountId and convId only
            responsibleAccountId = LRCInstance.currentAccountId;
            responsibleConvUid = model.dataForRow(index, ConversationList.UID);
            isBanned = model.dataForRow(index, ConversationList.IsBanned);
            mode = model.dataForRow(index, ConversationList.Mode);
            isCoreDialog = model.dataForRow(index, ConversationList.IsCoreDialog);
            contactType = LRCInstance.currentAccountType;
            readOnly = mode === Conversation.Mode.NON_SWARM && (model.dataForRow(index, ConversationList.ContactType) !== Profile.Type.TEMPORARY) && CurrentAccount.type !== Profile.Type.SIP;

            isInCall = UtilsAdapter.getCallId(responsibleAccountId, responsibleConvUid) !== "";
            nbActiveCalls = CurrentConversation.activeCalls.length;

            // For UserProfile dialog.
            if (isCoreDialog) {
                aliasText = model.dataForRow(index, ConversationList.Title);
                registeredNameText = model.dataForRow(index, ConversationList.BestId);
                idText = model.dataForRow(index, ConversationList.URI);
            }
            openMenu();
        }

        onShowSwarmDetails: {
            model.select(index);
            CurrentConversation.showSwarmDetails();
        }
    }

    Shortcut {
        sequence: "Ctrl+Shift+X"
        context: Qt.ApplicationShortcut
        enabled: CurrentAccount.videoEnabled_Video && root.visible
        onActivated: {
            if (CurrentAccount.videoEnabled_Video)
                CallAdapter.startCall();
        }
    }

    Shortcut {
        sequence: "Ctrl+Shift+C"
        context: Qt.ApplicationShortcut
        enabled: root.visible
        onActivated: CallAdapter.startAudioOnlyCall()
    }

    Shortcut {
        sequence: "Ctrl+Shift+L"
        context: Qt.ApplicationShortcut
        enabled: root.visible
        onActivated: MessagesAdapter.clearConversationHistory(CurrentAccount.id, CurrentConversation.id)
    }

    Shortcut {
        sequence: "Ctrl+Shift+B"
        context: Qt.ApplicationShortcut
        enabled: root.visible
        onActivated: MessagesAdapter.blockConversation(CurrentConversation.id)
    }

    Shortcut {
        sequence: "Ctrl+Down"
        context: Qt.ApplicationShortcut
        enabled: root.visible
        onActivated: {
            if (currentIndex + 1 >= count)
                return;
            model.select(currentIndex + 1);
        }
    }

    Shortcut {
        sequence: "Ctrl+Up"
        context: Qt.ApplicationShortcut
        enabled: root.visible
        onActivated: {
            if (currentIndex <= 0)
                return;
            model.select(currentIndex - 1);
        }
    }
}
