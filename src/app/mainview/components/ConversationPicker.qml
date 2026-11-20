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
import QtQuick.Controls
import QtQuick.Layouts
import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import "../../commoncomponents"

ColumnLayout {
    id: root

    required property var viewCoordinator
    property bool isFeed: false
    property bool allContactsAvailable: false
    readonly property bool allContacts: allContactsAvailable && audienceComboBox.currentIndex === 0
    readonly property bool pickingContacts: !allContacts
    property string excludedConversationId: ""
    property var lockedContactUris: []
    property var selectedConversations: []
    readonly property var selectedIds: selectedConversations.map(conversation => conversation.id)
    property var contactLists: ContactAdapter.getAllContactTags()

    readonly property Component helpButton: NewIconButton {
        QWKSetParentHitTestVisible {}

        objectName: "conversationTypeHelpButton"
        iconSource: JamiResources.bidirectional_help_outline_24dp_svg
        iconSize: JamiTheme.iconButtonMedium
        toolTipText: root.isFeed ? qsTr("What is a feed?") : qsTr("What is a group?")
        onClicked: root.viewCoordinator.presentDialog(root, "commoncomponents/ConversationTypeInfoPopup.qml", {
            "titleText": toolTipText,
            "isFeed": root.isFeed
        })
    }

    spacing: 4

    function focusSearch() {
        if (pickingContacts)
            searchBar.setTextAreaFocus();
        else
            audienceComboBox.forceActiveFocus();
    }

    function removeConversation(id) {
        selectedConversations = selectedConversations.filter(conversation => conversation.id !== id);
        focusSearch();
    }

    function toggleConversation(id, name) {
        if (selectedIds.includes(id)) {
            removeConversation(id);
        } else {
            selectedConversations = selectedConversations.concat({ "id": id, "name": name });
            searchBar.clearText();
        }
    }

    // Conversations of a list's members that can be picked here.
    function listConversations(list) {
        return ContactAdapter.getContactTagConversations(list).filter(conversation => conversation.id !== excludedConversationId && !lockedContactUris.includes(conversation.uri));
    }

    function isListSelected(conversations, ids) {
        return conversations.length > 0 && conversations.every(conversation => ids.includes(conversation.id));
    }

    // Selects every member of the list, or deselects them all if they already are.
    function toggleList(conversations) {
        if (isListSelected(conversations, selectedIds)) {
            const ids = conversations.map(conversation => conversation.id);
            selectedConversations = selectedConversations.filter(conversation => !ids.includes(conversation.id));
        } else {
            selectedConversations = selectedConversations.concat(conversations.filter(conversation => !selectedIds.includes(conversation.id)).map(conversation => ({
                            "id": conversation.id,
                            "name": conversation.name
                        })));
        }
    }

    ListModel {
        id: emptyConversations
    }

    SortFilterProxyModel {
        id: conversationModel

        sourceModel: ConversationsAdapter.convListProxyModel.sourceModel || emptyConversations
        property string searchText: ""

        sorters: RoleSorter {
            roleName: "LastInteractionTimeStamp"
            sortOrder: Qt.DescendingOrder
        }

        filters: [
            ValueFilter { roleName: "IsRequest"; value: false },
            ValueFilter { roleName: "IsBanned"; value: false },
            ValueFilter { roleName: "Mode"; value: Conversation.Mode.FEED; inverted: true },
            ValueFilter { roleName: "UID"; value: root.excludedConversationId; inverted: true },
            FunctionFilter {
                column: 0
                function filter(Title: string, Monikers: list<string>, Uris: list<string>, IsCoreDialog: bool): bool {
                    if (!Uris || Uris.length === 0)
                        return false;
                    if (IsCoreDialog && !Array.from(Uris).some(uri => uri !== CurrentAccount.uri))
                        return false;
                    const query = conversationModel.searchText.trim().toLowerCase();
                    return !query || [Title || ""].concat(Array.from(Monikers || []), Array.from(Uris))
                        .some(value => value.toLowerCase().includes(query));
                }
            }
        ]
    }

    SettingParaCombobox {
        id: audienceComboBox
        objectName: "feedAudienceComboBox"
        Layout.fillWidth: true
        visible: root.allContactsAvailable
        tooltipText: JamiStrings.feedAudience
        model: [JamiStrings.allContacts, JamiStrings.selectContacts]
        onActivated: function (index) {
            if (index === 0) {
                root.selectedConversations = [];
                searchBar.clearText();
            }
            root.focusSearch();
        }
    }

    Label {
        Layout.fillWidth: true
        visible: root.allContacts
        text: JamiStrings.addAllContactsDescription
        color: JamiTheme.faddedLastInteractionFontColor
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(chipFlow.implicitHeight + 16, root.height * 0.3)
        radius: 25
        color: JamiTheme.transparentColor
        border.width: 1
        border.color: JamiTheme.chatViewFooterRectangleBorderColor
        visible: root.selectedConversations.length > 0 && root.pickingContacts

        JamiFlickable {
            anchors.fill: parent
            anchors.margins: 8
            contentWidth: width
            contentHeight: chipFlow.implicitHeight
            flickableDirection: Flickable.VerticalFlick
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
            Accessible.role: Accessible.Grouping
            Accessible.name: JamiStrings.selectedConversations

            Flow {
                id: chipFlow
                width: Math.max(0, parent.width - 8)
                spacing: 4

                Repeater {
                    model: root.selectedConversations

                    delegate: JamiChip {
                        text: modelData.name
                        avatarId: modelData.id
                        variant: JamiChip.Variant.Neutral
                        width: Math.min(implicitWidth, chipFlow.width)
                        iconSource: JamiResources.cancel_24dp_svg
                        toolTipText: text
                        iconButtonToolTipText: JamiStrings.removeSelectedConversation.arg(text)
                        onIconClicked: root.removeConversation(modelData.id)
                    }
                }
            }
        }
    }

    Searchbar {
        id: searchBar
        objectName: "creationConversationSearch"
        Layout.fillWidth: true
        Layout.preferredHeight: JamiTheme.searchBarPreferredHeight
        placeHolderText: JamiStrings.search
        visible: root.pickingContacts
        onSearchBarTextChanged: function (text) {
            conversationModel.searchText = text;
            conversationModel.invalidate();
        }
    }

    ListView {
        id: contactListChips
        objectName: "conversationPickerLists"
        Layout.fillWidth: true
        // Room for chips to grow when hovered without being clipped.
        Layout.preferredHeight: contentItem.childrenRect.height + 4
        leftMargin: 2
        rightMargin: 2
        visible: root.pickingContacts && count > 0
        orientation: ListView.Horizontal
        spacing: 6
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        model: root.contactLists
        Accessible.role: Accessible.List
        Accessible.name: JamiStrings.lists

        // Let a vertical mouse wheel scroll the row; touchpads already scroll it natively.
        WheelHandler {
            acceptedDevices: PointerDevice.Mouse
            onWheel: function (event) {
                const delta = event.angleDelta.y !== 0 ? event.angleDelta.y : event.angleDelta.x;
                const minX = contactListChips.originX - contactListChips.leftMargin;
                const maxX = Math.max(minX, contactListChips.originX + contactListChips.contentWidth + contactListChips.rightMargin - contactListChips.width);
                contactListChips.contentX = Math.max(minX, Math.min(maxX, contactListChips.contentX - delta));
            }
        }

        delegate: JamiChip {
            // Resolved once per chip so selection changes do not rescan all contacts.
            readonly property var conversations: root.listConversations(modelData)
            readonly property bool selected: root.isListSelected(conversations, root.selectedIds)
            objectName: "conversationPickerList_" + modelData
            y: 2
            text: modelData
            toolTipText: text
            clickable: true
            variant: selected ? JamiChip.Variant.Filled : JamiChip.Variant.Outlined
            Accessible.checkable: true
            Accessible.checked: selected
            onClicked: root.toggleList(conversations)
        }
    }

    JamiListView {
        id: conversationList
        objectName: "creationConversationList"
        Layout.fillWidth: true
        Layout.fillHeight: true
        model: conversationModel
        visible: root.pickingContacts
        activeFocusOnTab: true
        Accessible.name: JamiStrings.conversations

        ScrollFadeGradient {
            parent: conversationList
            flickable: conversationList
            atTop: true
        }

        ScrollFadeGradient {
            parent: conversationList
            flickable: conversationList
        }

        delegate: SmartListItemDelegate {
            readonly property bool locked: IsCoreDialog && Array.from(Uris).some(uri => root.lockedContactUris.includes(uri))
            interactive: false
            enabled: !locked
            highlighted: locked || root.selectedIds.includes(UID)
            onSelectionToggled: {
                if (!locked)
                    root.toggleConversation(UID, Title);
            }

            Accessible.role: Accessible.CheckBox
            Accessible.checkable: true
            Accessible.checked: highlighted
            Accessible.onToggleAction: {
                if (!locked)
                    selectionToggled();
            }
        }

        Label {
            anchors.centerIn: parent
            width: parent.width
            visible: conversationList.count === 0
            text: JamiStrings.noContactsToChooseFrom
            color: JamiTheme.textColor
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
        }
    }
}
