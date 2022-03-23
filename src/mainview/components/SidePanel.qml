/*
 * Copyright (C) 2020-2022 Savoir-faire Linux Inc.
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
import QtQuick.Layouts

import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1

import "../../commoncomponents"

Rectangle {
    id: root

    color: JamiTheme.backgroundColor

    signal createSwarmClicked

    Connections {
        target: LRCInstance

        function onCurrentAccountIdChanged() {
            clearContactSearchBar()
        }
    }

    Connections {
        target: ConversationsAdapter

        function onConversationReady() {
            selectTab(SidePanelTabBar.Conversations)
            clearContactSearchBar()
        }
    }

    function clearContactSearchBar() {
        contactSearchBar.clearText()
    }

    function selectTab(tabIndex) {
        sidePanelTabBar.selectTab(tabIndex)
    }

    property var highlighted: []
    property var highlightedMembers: []

    function refreshHighlighted(convId, highlightedStatus) {
        var newH = root.highlighted
        var newHm = root.highlightedMembers

        if (highlightedStatus) {
            var item = ConversationsAdapter.getConvInfoMap(convId)
            var added = false
            for (var idx in item.uris) {
                var uri = item.uris[idx]
                if (!Array.from(newHm).find(r => r.uri === uri) && uri != CurrentAccount.uri) {
                    newHm.push({"uri": uri, "convId": convId})
                    added = true
                }
            }
            if (!added)
                return false
        } else {
            newH = Array.from(newH).filter(r => r !== convId)
            newHm = Array.from(newHm).filter(r => r.convId !== convId)
        }

        // We can't have more than 8 participants yet. (7 + self)
        if (newHm.length > 7) {
            return false
        }

        newH.push(convId)
        root.highlighted = newH
        root.highlightedMembers = newHm
        ConversationsAdapter.ignoreFiltering(root.highlighted)
        return true
    }

    function clearHighlighted() {
        root.highlighted = []
        root.highlightedMembers = []
    }

    function removeMember(convId, member) {
        var refreshHighlighted = true
        var newHm = []
        for (var hm in root.highlightedMembers) {
            var m = root.highlightedMembers[hm]
            if (m.convId == convId && m.uri == member) {
                continue;
            } else if (m.convId == convId) {
                refreshHighlighted = false
            }
            newHm.push(m)
        }
        root.highlightedMembers = newHm

        if (refreshHighlighted) {
            // Remove highlighted status if necessary
            for (var d in swarmCurrentConversationList.contentItem.children) {
                var delegate = swarmCurrentConversationList.contentItem.children[d]
                if (delegate.convId == convId)
                    delegate.highlighted = false
            }
        }
    }

    function showSwarmListView(v) {
        smartListLayout.visible = !v
        swarmMemberSearchList.visible = v
    }

    RowLayout {
        id: startBar

        height: 40
        anchors.top: root.top
        anchors.topMargin: 10
        anchors.left: root.left
        anchors.leftMargin: 15
        anchors.right: root.right
        anchors.rightMargin: 15

        ContactSearchBar {
            id: contactSearchBar

            Layout.fillHeight: true
            Layout.fillWidth: true

            onContactSearchBarTextChanged: function (text) {
                // not calling positionViewAtBeginning will cause
                // sort animation visual bugs
                conversationListView.positionViewAtBeginning()
                ConversationsAdapter.ignoreFiltering(root.highlighted)
                ConversationsAdapter.setFilter(text)
            }

            onReturnPressedWhileSearching: {
                var listView = searchResultsListView.count ?
                            searchResultsListView :
                            conversationListView
                if (listView.count)
                    listView.model.select(0)
            }
        }

        PushButton {
            id: startConversation

            Layout.alignment: Qt.AlignLeft
            radius: JamiTheme.primaryRadius

            imageColor: JamiTheme.textColor
            imagePadding: 8
            normalColor: JamiTheme.secondaryBackgroundColor

            preferredSize: startBar.height

            source: smartListLayout.visible ? JamiResources.create_swarm_svg : JamiResources.round_close_24dp_svg
            toolTipText: smartListLayout.visible ? JamiStrings.startASwarm : JamiStrings.cancel

            onClicked: createSwarmClicked()
        }
    }

    SidePanelTabBar {
        id: sidePanelTabBar

        visible: ConversationsAdapter.pendingRequestCount &&
                 !contactSearchBar.textContent && smartListLayout.visible
        anchors.top: startBar.bottom
        anchors.topMargin: visible ? 10 : 0
        width: root.width
        height: visible ? 42 : 0
        contentHeight: visible ? 42 : 0
    }

    Rectangle {
        id: searchStatusRect

        visible: searchStatusText.text !== "" && smartListLayout.visible

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

        function onTextFilterChanged(text) {
            // In the swarm details, "Go to conversation" can
            // change the search bar. Be sure to be synced
            contactSearchBar.textContent = text
        }
    }

    ColumnLayout {
        id: smartListLayout

        width: parent.width
        anchors.top: searchStatusRect.bottom
        anchors.topMargin: (sidePanelTabBar.visible ||
                            searchStatusRect.visible) ? 0 : 12
        anchors.bottom: parent.bottom

        spacing: 4

        ConversationListView {
            id: searchResultsListView

            visible: count
            opacity: visible ? 1 : 0

            Layout.topMargin: 10
            Layout.alignment: Qt.AlignTop
            Layout.fillWidth: true
            Layout.preferredHeight: visible ? contentHeight : 0
            Layout.maximumHeight: {
                var otherContentHeight = conversationListView.contentHeight + 16
                if (conversationListView.visible)
                    if (otherContentHeight < parent.height / 2)
                        return parent.height - otherContentHeight
                    else
                        return parent.height / 2
                else
                    return parent.height
            }

            model: SearchResultsListModel
            headerLabel: JamiStrings.searchResults
            headerVisible: visible
        }

        ConversationListView {
            id: conversationListView

            visible: count

            Layout.preferredWidth: parent.width
            Layout.fillHeight: true

            model: ConversationListModel
            headerLabel: JamiStrings.conversations
            headerVisible: searchResultsListView.visible
        }
    }

    ColumnLayout {
        id: swarmMemberSearchList

        visible: false

        width: parent.width
        anchors.top: searchStatusRect.bottom
        anchors.topMargin: (sidePanelTabBar.visible ||
                            searchStatusRect.visible) ? 0 : 12
        anchors.bottom: parent.bottom

        spacing: 4

        Label {
            font.bold: true
            font.pointSize: JamiTheme.contactEventPointSize

            Layout.margins: 16
            Layout.maximumHeight: 24

            text: {
                if (highlightedMembers.length === 0)
                    return JamiStrings.youCanAdd8
                return JamiStrings.youCanAddMore.arg(7 - Math.min(highlightedMembers.length, 7))
            }
            color: JamiTheme.textColor
        }

        JamiListView {
            id: swarmCurrentConversationList

            Layout.preferredWidth: parent.width
            Layout.fillHeight: true

            model: ConversationListModel
            delegate: SmartListItemDelegate {
                interactive: false

                onVisibleChanged: {
                    if (!swarmCurrentConversationList.visible) {
                        highlighted = false
                        root.clearHighlighted()
                    }
                }

                Component.onCompleted: {
                    // Note: when scrolled down, this delegate will be
                    // destroyed from the memory. So, re-add the highlighted
                    // status if necessary
                    if (Array.from(root.highlighted).find(r => r === UID)) {
                        highlighted = true
                    }
                }

                onHighlightedChanged: function onHighlightedChanged() {
                    if (highlighted && Array.from(root.highlighted).find(r => r === UID)) {
                        // Due to scrolling destruction/reconstruction
                        return
                    }
                    var currentHighlighted = root.highlighted
                    if (!root.refreshHighlighted(UID, highlighted)) {
                        highlighted = false
                        return
                    }
                    if (highlighted) {
                        root.highlighted.push(UID)
                    } else {
                        root.highlighted = Array.from(root.highlighted).filter(r => r !== UID)
                    }
                }
            }
            currentIndex: model.currentFilteredRow
        }
    }
}
