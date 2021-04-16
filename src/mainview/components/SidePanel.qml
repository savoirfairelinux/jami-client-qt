/*
 * Copyright (C) 2020 by Savoir-faire Linux
 * Author: Mingrui Zhang <mingrui.zhang@savoirfairelinux.com>
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
import QtGraphicalEffects 1.14

import net.jami.Models 1.0
import net.jami.Adapters 1.0
import net.jami.Constants 1.0

import "../../commoncomponents"

Rectangle {
    id: sidePanelRect

    color: JamiTheme.backgroundColor

    // Intended -> since strange behavior will happen without this for stackview.
    anchors.top: parent.top
    anchors.fill: parent

    function clearContactSearchBar() {
        contactSearchBar.clearText()
    }

    function refreshAccountComboBox(index) {
        accountComboBox.update()
        clearContactSearchBar()
        accountComboBox.resetAccountListModel()
    }

    // TODO: hm
    function deselectConversationSmartList() {
        print("deselectConversationSmartList")
//        ConversationsAdapter.deselectConversation()
//        conversationSmartListView.currentIndex = -1
    }

    function selectTab(tabIndex) {
        sidePanelTabBar.selectTab(tabIndex)
    }

    // Search bar container to embed search label
    ContactSearchBar {
        id: contactSearchBar

        height: 40
        anchors.top: sidePanelRect.top
        anchors.topMargin: 10
        anchors.left: sidePanelRect.left
        anchors.leftMargin: 15
        anchors.right: sidePanelRect.right
        anchors.rightMargin: 15

        onContactSearchBarTextChanged: {
            ConversationsAdapter.setFilter(text)
        }

        onReturnPressedWhileSearching: {
            var convUid = conversationSmartListView.itemAtIndex(0).convUid()
            var currentAccountId = AccountAdapter.currentAccountId
            ConversationsAdapter.selectConversation(currentAccountId, convUid)
            conversationSmartListView.repositionIndex(convUid)
        }
    }

    SidePanelTabBar {
        id: sidePanelTabBar

        visible: ConversationsAdapter.pendingRequestCount &&
                 !contactSearchBar.textContent
        anchors.top: contactSearchBar.bottom
        anchors.topMargin: visible ? 10 : 0
        width: sidePanelRect.width
        height: visible ? 42 : 0
    }

    Rectangle {
        id: searchStatusRect

        visible: searchStatusText.text !== ""

        anchors.top: sidePanelTabBar.bottom
        anchors.topMargin: visible ? 10 : 0
        width: parent.width
        height: visible ? 42 : 0

        color: JamiTheme.backgroundColor

        Text {
            id: searchStatusText

            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: 32
            anchors.right: parent.right
            anchors.rightMargin: 32
            color: JamiTheme.textColor
            wrapMode: Text.WordWrap
            font.pointSize: JamiTheme.filterItemFontSize
        }
    }

    Connections {
        target: ConversationsAdapter

        function onShowSearchStatus(status) {
            searchStatusText.text = status
        }
    }

    ColumnLayout {
        id: smartListLayout

        width: parent.width
        anchors.top: searchStatusRect.bottom
        anchors.topMargin: (sidePanelTabBar.visible ||
                            searchStatusRect.visible) ? 0 : 8
        anchors.bottom: parent.bottom

        spacing: 4

        ConversationListView {
            id: searchResultsListView

            visible: count
            opacity: visible ? 1 :0

            Layout.topMargin: 10
            Layout.alignment: Qt.AlignTop
            Layout.fillWidth: true
            Layout.preferredHeight: visible ? contentHeight : 0
            Layout.maximumHeight: parent.height / 2

            model: SearchResultsListModel
            delegate: SmartListItemDelegate {
                onUpdateContactAvatarUidRequested: root.model.updateContactAvatarUid(uid)
            }
            headerLabel: JamiStrings.searchResults
            headerVisible: visible
        }

        ConversationListView {
            id: conversationSmartListView

            visible: count

            Layout.preferredWidth: parent.width
            Layout.fillHeight: true

            highlight: Rectangle {
                width: ListView.view ? ListView.view.width : 0
                color: JamiTheme.selectedColor
            }
            highlightMoveDuration: 60

            currentIndex: ConversationListProxyModel.currentFilteredRow
            model: ConversationListProxyModel
            delegate: SmartListItemDelegate {
                onUpdateContactAvatarUidRequested: root.model.updateContactAvatarUid(uid)
            }
            headerLabel: JamiStrings.conversations
            headerVisible: searchResultsListView.visible

            Connections {
                target: ConversationListProxyModel

                // actually select the conversation
                // TODO: make this generic to the model
                function onValidSelectionChanged() {
                    var row = ConversationListProxyModel.currentFilteredRow
                    var uid = ConversationListProxyModel.dataForRow(row, ConversationListModel.UID)
                    ConversationsAdapter.selectConversation(AccountAdapter.currentAccountId,
                                                            uid,
                                                            false)
                }
            }
        }
    }
}
