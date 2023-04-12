/*
 * Copyright (C) 2021-2023 Savoir-faire Linux Inc.
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
import QtQuick
import QtQuick.Controls
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import net.jami.Models 1.1
import "../../commoncomponents"

JamiListView {
    id: root

    // the following should be marked required (Qtver >= 5.15)
    // along with `required model`
    property string headerLabel
    property bool headerVisible

    currentIndex: model.currentFilteredRow
    headerPositioning: ListView.OverlayHeader

    // highlight selection
    // down and hover states are done within the delegate
    highlightMoveDuration: 60

    function openContextMenuAt(x, y, delegate) {
        var mappedCoord = root.mapFromItem(delegate, x, y);
        contextMenu.openMenuAt(mappedCoord.x, mappedCoord.y);
    }

    onCountChanged: positionViewAtBeginning()

    Connections {
        target: model

        // actually select the conversation
        function onValidSelectionChanged() {
            var row = model.currentFilteredRow;
            var convId = model.dataForRow(row, ConversationList.UID);
            LRCInstance.selectConversation(convId);
        }
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
            hasCall = UtilsAdapter.getCallId(responsibleAccountId, responsibleConvUid) !== "";

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
        context: Qt.ApplicationShortcut
        enabled: CurrentAccount.videoEnabled_Video && root.visible
        sequence: "Ctrl+Shift+X"

        onActivated: {
            if (CurrentAccount.videoEnabled_Video)
                CallAdapter.placeCall();
        }
    }
    Shortcut {
        context: Qt.ApplicationShortcut
        enabled: root.visible
        sequence: "Ctrl+Shift+C"

        onActivated: CallAdapter.placeAudioOnlyCall()
    }
    Shortcut {
        context: Qt.ApplicationShortcut
        enabled: root.visible
        sequence: "Ctrl+Shift+L"

        onActivated: MessagesAdapter.clearConversationHistory(CurrentAccount.id, CurrentConversation.id)
    }
    Shortcut {
        context: Qt.ApplicationShortcut
        enabled: root.visible
        sequence: "Ctrl+Shift+B"

        onActivated: MessagesAdapter.blockConversation(CurrentConversation.id)
    }
    Shortcut {
        context: Qt.ApplicationShortcut
        enabled: root.visible
        sequence: "Ctrl+Down"

        onActivated: {
            if (currentIndex + 1 >= count)
                return;
            model.select(currentIndex + 1);
        }
    }
    Shortcut {
        context: Qt.ApplicationShortcut
        enabled: root.visible
        sequence: "Ctrl+Up"

        onActivated: {
            if (currentIndex <= 0)
                return;
            model.select(currentIndex - 1);
        }
    }

    add: Transition {
        NumberAnimation {
            duration: JamiTheme.smartListTransitionDuration
            from: 0
            property: "opacity"
            to: 1.0
        }
    }
    delegate: SmartListItemDelegate {
    }
    displaced: Transition {
        NumberAnimation {
            duration: JamiTheme.smartListTransitionDuration
            easing.type: Easing.OutCubic
            properties: "x,y"
        }
        NumberAnimation {
            duration: JamiTheme.smartListTransitionDuration * (1 - from)
            property: "opacity"
            to: 1.0
        }
    }
    header: Rectangle {
        color: JamiTheme.backgroundColor
        height: root.headerVisible ? 20 : 0
        visible: root.headerVisible
        width: root.width
        z: 2

        Text {
            color: JamiTheme.textColor
            font.pointSize: JamiTheme.smartlistItemFontSize
            font.weight: Font.DemiBold
            text: headerLabel + " (" + root.count + ")"

            anchors {
                left: parent.left
                leftMargin: 16
                verticalCenter: parent.verticalCenter
            }
        }
    }
    Behavior on opacity  {
        NumberAnimation {
            duration: 2 * JamiTheme.smartListTransitionDuration
            easing.type: Easing.OutCubic
        }
    }
}
