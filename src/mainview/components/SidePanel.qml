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

    property bool tabBarVisible: true
    property int pendingRequestCount: 0
    property int totalUnreadMessagesCount: 0

    color: JamiTheme.backgroundColor

    // Intended -> since strange behavior will happen without this for stackview.
    anchors.top: parent.top
    anchors.fill: parent

    // Hack -> force redraw.
    function forceReselectConversationSmartListCurrentIndex() {
        var index = conversationSmartListView.currentIndex
        conversationSmartListView.currentIndex = -1
        conversationSmartListView.currentIndex = index
    }

    // For contact request conv to be focused correctly.
    function setCurrentUidSmartListModelIndex() {
//        conversationSmartListView.currentIndex
//                = conversationSmartListView.model.currentUidSmartListModelIndex()
    }

    function updatePendingRequestCount() {
        pendingRequestCount = UtilsAdapter.getTotalPendingRequest()
    }

    function updateTotalUnreadMessagesCount() {
        totalUnreadMessagesCount = UtilsAdapter.getTotalUnreadMessages()
    }

    function clearContactSearchBar() {
        contactSearchBar.clearText()
    }

    function refreshAccountComboBox(index) {
        accountComboBox.update()
        clearContactSearchBar()
        accountComboBox.resetAccountListModel()
    }

    function deselectConversationSmartList() {
        ConversationsAdapter.deselectConversation()
        conversationSmartListView.currentIndex = -1
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

        anchors.top: contactSearchBar.bottom
        anchors.topMargin: 10
        width: sidePanelRect.width
        height: tabBarVisible ? 42 : 0
    }

//    Rectangle {
//        id: searchStatusRect

//        visible: lblSearchStatus.text !== ""

//        anchors.top: tabBarVisible ? sidePanelTabBar.bottom : contactSearchBar.bottom
//        anchors.topMargin: tabBarVisible ? 0 : 10
//        width: parent.width
//        height: 72

//        color: "transparent"

//        Image {
//            id: searchIcon
//            anchors.left: searchStatusRect.left
//            anchors.leftMargin: 24
//            anchors.verticalCenter: searchStatusRect.verticalCenter
//            width: 24
//            height: 24

//            layer {
//                enabled: true
//                effect: ColorOverlay {
//                    color: JamiTheme.textColor
//                }
//            }

//            fillMode: Image.PreserveAspectFit
//            mipmap: true
//            source: "qrc:/images/icons/ic_baseline-search-24px.svg"
//        }

//        Label {
//            id: lblSearchStatus

//            anchors.verticalCenter: searchStatusRect.verticalCenter
//            anchors.left: searchIcon.right
//            anchors.leftMargin: 24
//            width: searchStatusRect.width - searchIcon.width - 24*2 - 8
//            text: ""
//            color: JamiTheme.textColor
//            wrapMode: Text.WordWrap
//            font.pointSize: JamiTheme.menuFontSize
//        }

//        MouseArea {
//            id: mouseAreaSearchRect

//            anchors.fill: parent
//            hoverEnabled: true

//            onReleased: {
//                searchStatusRect.color = Qt.binding(function(){return JamiTheme.normalButtonColor})
//            }

//            onEntered: {
//                searchStatusRect.color = Qt.binding(function(){return JamiTheme.hoverColor})
//            }

//            onExited: {
//                searchStatusRect.color = Qt.binding(function(){return JamiTheme.backgroundColor})
//            }
//        }
//    }

    Connections {
        target: ConversationsAdapter

        function onShowConversationTabs(visible) {
            tabBarVisible = visible
            updatePendingRequestCount()
            updateTotalUnreadMessagesCount()
        }

        function onShowSearchStatus(status) {
            lblSearchStatus.text = status
        }
    }

    ColumnLayout {
        id: smartListView

        width: parent.width
        anchors.top: sidePanelTabBar.bottom
        anchors.topMargin: 4
        anchors.bottom: parent.bottom

        spacing: 0

        ColumnLayout {
            id: searchResultsSection

            visible: searchResultsListView.count
            Layout.preferredWidth: parent.width
            Layout.preferredHeight: {
                visible ?
                            (searchResultsListView.contentHeight +
                             searchSectionLabel.height) :
                            0
            }
            Layout.maximumHeight: parent.height / 2

            spacing: 4

            Text {
                id: searchSectionLabel

                Layout.topMargin: 8
                Layout.leftMargin: 16
                Layout.fillWidth: true

                text: JamiStrings.searchResults +
                      " (" + searchResultsListView.count + ")"
                font.pointSize: JamiTheme.smartlistItemFontSize
                font.weight: Font.DemiBold
                color: JamiTheme.textColor
            }

            ConversationListView {
                id: searchResultsListView

                model: SearchResultsListModel

                Layout.fillHeight: true
                Layout.fillWidth: true

                Component.onCompleted: {
                    ConversationsAdapter.setQmlObject(this)
                    searchResultsListView.currentIndex = -1
                }
            }
        }

        ColumnLayout {
            Layout.preferredWidth: parent.width
            Layout.fillHeight: true

            Text {
                id: convSectionLabel

                visible: searchResultsSection.visible
                height: visible ? implicitHeight : 0

                Layout.topMargin: 8
                Layout.leftMargin: 16
                Layout.fillWidth: true

                text: JamiStrings.conversations +
                      " (" + conversationSmartListView.count + ")"
                font.pointSize: JamiTheme.smartlistItemFontSize
                font.weight: Font.DemiBold
                color: JamiTheme.textColor
            }

            ConversationListView {
                id: conversationSmartListView

                model: ConversationListProxyModel

                Layout.fillHeight: true
                Layout.fillWidth: true

                Component.onCompleted: {
                    ConversationsAdapter.setQmlObject(this)
                    conversationSmartListView.currentIndex = -1
                }
            }
        }
    }
}
