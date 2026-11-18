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
    property string excludedConversationId: ""
    property var lockedContactUris: []
    property var selectedConversations: []
    readonly property var selectedIds: selectedConversations.map(conversation => conversation.id)

    spacing: 4

    function focusSearch() {
        searchBar.setTextAreaFocus();
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

    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(chipFlow.implicitHeight + 16, root.height * 0.3)
        radius: 24
        color: JamiTheme.transparentColor
        border.width: 2
        border.color: JamiTheme.chatViewFooterRectangleBorderColor
        visible: root.selectedConversations.length > 0

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
                spacing: 6

                Repeater {
                    model: root.selectedConversations

                    delegate: JamiChip {
                        text: modelData.name
                        avatarId: modelData.id
                        maximumWidth: chipFlow.width
                        iconSource: JamiResources.round_close_24dp_svg
                        toolTipText: text
                        iconButtonToolTipText: JamiStrings.removeSelectedConversation.arg(text)
                        onIconClicked: root.removeConversation(modelData.id)
                    }
                }
            }
        }
    }

    RowLayout {
        Layout.alignment: Qt.AlignHCenter
        Layout.fillWidth: false

        Text {
            text: helpButton.toolTipText
            color: JamiTheme.textColor
            font.pointSize: JamiTheme.textFontSize
        }

        NewIconButton {
            id: helpButton
            objectName: "conversationTypeHelpButton"
            iconSource: JamiResources.bidirectional_help_outline_24dp_svg
            iconSize: JamiTheme.iconButtonMedium
            toolTipText: root.isFeed ? qsTr("What is a feed?") : qsTr("What is a group?")
            onClicked: root.viewCoordinator.presentDialog(root, "commoncomponents/ConversationTypeInfoPopup.qml", {
                "titleText": toolTipText,
                "isFeed": root.isFeed
            })
        }
    }

    Searchbar {
        id: searchBar
        objectName: "creationConversationSearch"
        Layout.fillWidth: true
        Layout.preferredHeight: JamiTheme.searchBarPreferredHeight
        placeHolderText: JamiStrings.search
        onSearchBarTextChanged: function (text) {
            conversationModel.searchText = text;
            conversationModel.invalidate();
        }
    }

    JamiListView {
        id: conversationList
        objectName: "creationConversationList"
        Layout.fillWidth: true
        Layout.fillHeight: true
        model: conversationModel
        activeFocusOnTab: true
        Accessible.name: JamiStrings.conversations

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
