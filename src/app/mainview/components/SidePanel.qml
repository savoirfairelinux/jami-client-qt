/*
 * Copyright (C) 2020-2023 Savoir-faire Linux Inc.
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
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import net.jami.Enums 1.1
import net.jami.Models 1.1
import "../../commoncomponents"
import "../../settingsview/components"

SidePanelBase {
    id: root

    property var donateDate: UtilsAdapter.getAppValue(Settings.Key.DonateDateBis)

    objectName: "SidePanel"

    property bool donationVisible: new Date() > new Date(Date.parse(root.donateDate))

    color: JamiTheme.backgroundColor

    Connections {
        target: LRCInstance

        function onCurrentAccountIdChanged() {
            clearContactSearchBar();
        }
    }

    Connections {
        target: ConversationsAdapter

        function onConversationReady() {
            selectTab(SidePanelTabBar.Conversations);
            clearContactSearchBar();
        }
    }

    Connections {
        target: ConversationsAdapter

        function onShowSearchStatus(status) {
            searchStatusText.text = status;
        }

        function onTextFilterChanged(text) {
            // In the swarm details, "Go to conversation" can
            // change the search bar. Be sure to be synced
            contactSearchBar.textContent = text;
        }
    }

    function toggleCreateSwarmView() {
        if (!inNewSwarm) {
            viewCoordinator.present("NewSwarmPage");
            const newSwarmPage = viewCoordinator.getView("NewSwarmPage");
            newSwarmPage.removeMember.connect((convId, member) => {
                    removeMember(convId, member);
                });
            newSwarmPage.createSwarmClicked.connect((title, description, avatar) => {
                    var uris = [];
                    for (var idx in newSwarmPage.members) {
                        var uri = newSwarmPage.members[idx].uri;
                        if (uris.indexOf(uri) === -1) {
                            uris.push(uri);
                        }
                    }
                    let convuid = ConversationsAdapter.createSwarm(title, description, avatar, uris);
                    viewCoordinator.dismiss("NewSwarmPage");
                    LRCInstance.selectConversation(convuid);
                });
        } else {
            viewCoordinator.dismiss("NewSwarmPage");
        }
    }

    function clearContactSearchBar() {
        contactSearchBar.clearText();
    }

    function selectTab(tabIndex) {
        sidePanelTabBar.selectTab(tabIndex);
    }

    property bool inNewSwarm: viewCoordinator.currentViewName === "NewSwarmPage"

    property var highlighted: []
    property var highlightedMembers: []
    onHighlightedMembersChanged: {
        if (inNewSwarm) {
            const newSwarmPage = viewCoordinator.getView("NewSwarmPage");
            newSwarmPage.members = highlightedMembers;
        }
    }

    function refreshHighlighted(convId, highlightedStatus) {
        var newH = root.highlighted;
        var newHm = root.highlightedMembers;
        if (highlightedStatus) {
            var item = ConversationsAdapter.getConvInfoMap(convId);
            var added = false;
            for (var idx in item.uris) {
                var uri = item.uris[idx];
                if (!Array.from(newHm).find(r => r.uri === uri) && uri !== CurrentAccount.uri) {
                    newHm.push({
                            "uri": uri,
                            "convId": convId
                        });
                    added = true;
                }
            }
            if (!added)
                return false;
        } else {
            newH = Array.from(newH).filter(r => r !== convId);
            newHm = Array.from(newHm).filter(r => r.convId !== convId);
        }
        newH.push(convId);
        root.highlighted = newH;
        root.highlightedMembers = newHm;
        ConversationsAdapter.ignoreFiltering(root.highlighted);
        return true;
    }

    function clearHighlighted() {
        root.highlighted = [];
        root.highlightedMembers = [];
    }

    function removeMember(convId, member) {
        var refreshHighlighted = true;
        var newHm = [];
        for (var hm in root.highlightedMembers) {
            var m = root.highlightedMembers[hm];
            if (m.convId === convId && m.uri === member) {
                continue;
            } else if (m.convId === convId) {
                refreshHighlighted = false;
            }
            newHm.push(m);
        }
        root.highlightedMembers = newHm;
        if (refreshHighlighted) {
            // Remove highlighted status if necessary
            for (var d in swarmCurrentConversationList.contentItem.children) {
                var delegate = swarmCurrentConversationList.contentItem.children[d];
                if (delegate.convId === convId)
                    delegate.highlighted = false;
            }
        }
    }

    Page {
        id: page

        anchors.fill: parent

        background: Rectangle {
            color: JamiTheme.backgroundColor
        }

        header: AccountComboBox {
        }

        Item {
            anchors.fill: parent

            onVisibleChanged: {
                root.donateDate = UtilsAdapter.getAppValue(Settings.Key.DonateDateBis);
                donationVisible = Qt.binding(() => new Date() > new Date(Date.parse(root.donateDate)));
            }

            RowLayout {
                id: titleBar

                visible: swarmMemberSearchList.visible

                height: 40
                anchors.top: parent.top
                anchors.topMargin: 10
                anchors.left: parent.left
                anchors.leftMargin: 15
                anchors.right: parent.right
                anchors.rightMargin: 15

                Label {
                    id: title

                    height: parent.height
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter

                    color: JamiTheme.textColor

                    font.bold: true
                    font.pointSize: JamiTheme.contactEventPointSize

                    text: JamiStrings.createSwarm
                }

                PushButton {
                    radius: JamiTheme.primaryRadius

                    imageColor: JamiTheme.textColor
                    imagePadding: 8
                    normalColor: JamiTheme.secondaryBackgroundColor

                    preferredSize: titleBar.height

                    source: JamiResources.round_close_24dp_svg
                    toolTipText: JamiStrings.cancel

                    onClicked: toggleCreateSwarmView()
                }
            }

            RowLayout {
                id: startBar

                height: 40
                anchors.top: titleBar.visible ? titleBar.bottom : parent.top
                anchors.topMargin: 10
                anchors.left: parent.left
                anchors.leftMargin: 15
                anchors.right: parent.right
                anchors.rightMargin: 15

                Shortcut {
                    sequence: "Ctrl+F"
                    context: Qt.ApplicationShortcut
                    onActivated: {
                        contactSearchBar.forceActiveFocus();
                    }
                }

                Searchbar {
                    id: contactSearchBar

                    Layout.fillHeight: true
                    Layout.fillWidth: true

                    onSearchBarTextChanged: function (text) {
                        // not calling positionViewAtBeginning will cause
                        // sort animation visual bugs
                        conversationListView.positionViewAtBeginning();
                        ConversationsAdapter.ignoreFiltering(root.highlighted);
                        ConversationsAdapter.setFilter(text);
                    }

                    onReturnPressedWhileSearching: {
                        var listView = searchResultsListView.count ? searchResultsListView : conversationListView;
                        if (listView.count)
                            listView.model.select(0);
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

                    visible: !swarmMemberSearchList.visible && CurrentAccount.type !== Profile.Type.SIP

                    source: smartListLayout.visible ? JamiResources.create_swarm_svg : JamiResources.round_close_24dp_svg
                    toolTipText: root.donateDate//smartListLayout.visible ? JamiStrings.startSwarm : JamiStrings.cancel

                    onClicked: toggleCreateSwarmView()
                }
            }

            SidePanelTabBar {
                id: sidePanelTabBar

                visible: ConversationsAdapter.pendingRequestCount && !contactSearchBar.textContent && smartListLayout.visible
                anchors.top: startBar.bottom
                anchors.topMargin: visible ? 10 : 0
                width: page.width
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

                color: "red"
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

            Rectangle {
                id: donation

                visible: root.donationVisible

                anchors.top: sidePanelTabBar.bottom
                anchors.topMargin: 10
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width - 20
                height: donationTextRect.height + 45
                radius: 5

                color: "#D5E4EF"

                GridLayout {
                    id: donationLayout

                    anchors.fill: parent
                    columns: 3
                    rows: 2
                    rowSpacing: 0
                    columnSpacing: 10

                    Rectangle {
                        //Scaffold{}
                        id: donationIcon

                        Layout.row: 0
                        Layout.column: 0
                        Layout.rowSpan: 2
                        Layout.fillHeight: true
                        Layout.preferredWidth: 50
                        Layout.leftMargin: 10
                        Layout.topMargin: 10
                        Layout.bottomMargin: 15

                        color: JamiTheme.transparentColor

                        Image {
                            id: donationImage
                            height: parent.height
                            width: 50
                            anchors.centerIn: parent
                            source: JamiResources.icon_donate_svg
                        }
                    }

                    Rectangle {
                        //Scaffold{}
                        id: donationTextRect

                        Layout.topMargin: 10
                        Layout.row: 0
                        Layout.column: 1
                        Layout.columnSpan: 2
                        Layout.preferredHeight: donationText.height
                        Layout.preferredWidth: parent.width - 74
                        color: JamiTheme.transparentColor

                        Text {
                            id: donationText
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            width: parent.width
                            height: contentHeight
                            text: "If you enjoy using Jami and believe in our mission, would you make a donation ?"
                            wrapMode: Text.WordWrap

                            font.pointSize: JamiTheme.textFontSize
                        }
                    }

                    Rectangle {
                        id: notNowRect

                        Layout.row: 1
                        Layout.column: 1
                        Layout.preferredHeight: 30
                        Layout.preferredWidth: (parent.width - 55) / 2

                        color: JamiTheme.transparentColor

                        Text {
                            id: notNowText
                            MouseArea {
                                cursorShape: Qt.PointingHandCursor
                                anchors.fill: parent
                                onClicked: {
                                    UtilsAdapter.setAppValue(Settings.Key.DonateDateBis, new Date(new Date().getTime() + 7 * 24 * 60 * 60 * 1000).toISOString().slice(0, 16).replace("T", " "));
                                    root.donateDate = UtilsAdapter.getAppValue(Settings.Key.DonateDateBis);
                                    root.donationVisible = Qt.binding(() => new Date() > new Date(Date.parse(root.donateDate)));
                                }
                            }
                            text: "Not now"
                            color: "#005699"
                            anchors.top: parent.top
                            anchors.left: parent.left
                            font.pointSize: JamiTheme.textFontSize
                        }
                    }

                    Rectangle {
                        id: donateRect
                        Layout.row: 1
                        Layout.column: 2
                        Layout.preferredHeight: 30
                        Layout.preferredWidth: (parent.width - 50) / 2
                        color: JamiTheme.transparentColor

                        Text {
                            id: donateText
                            MouseArea {
                                cursorShape: Qt.PointingHandCursor
                                anchors.fill: parent
                                onClicked: {
                                    Qt.openUrlExternally("https://jami.net/donate/");
                                }
                            }
                            text: "Donate"
                            font.pointSize: JamiTheme.textFontSize
                            color: "#005699"
                            anchors.top: parent.top
                            anchors.left: parent.left
                        }
                    }
                }
            }

            ColumnLayout {
                id: smartListLayout

                width: parent.width
                anchors.top: root.donationVisible ? donation.bottom : sidePanelTabBar.bottom
                anchors.topMargin: (sidePanelTabBar.visible || searchStatusRect.visible) ? 0 : 12
                anchors.bottom: parent.bottom

                spacing: 4

                visible: !swarmMemberSearchList.visible

                ConversationListView {
                    id: searchResultsListView

                    visible: count
                    opacity: visible ? 1 : 0

                    Layout.topMargin: 10
                    Layout.alignment: Qt.AlignTop
                    Layout.fillWidth: true
                    Layout.preferredHeight: visible ? contentHeight : 0
                    Layout.maximumHeight: {
                        var otherContentHeight = conversationListView.contentHeight + 16;
                        if (conversationListView.visible)
                            if (otherContentHeight < parent.height / 2)
                                return parent.height - otherContentHeight;
                            else
                                return parent.height / 2;
                        else
                            return parent.height;
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

                visible: inNewSwarm

                width: parent.width
                anchors.top: root.donationVisible ? donation.bottom : sidePanelTabBar.bottom
                anchors.topMargin: (sidePanelTabBar.visible || searchStatusRect.visible) ? 0 : 12
                anchors.bottom: parent.bottom

                spacing: 4

                JamiListView {
                    id: swarmCurrentConversationList

                    Layout.preferredWidth: parent.width
                    Layout.fillHeight: true

                    model: ConversationListModel
                    delegate: SmartListItemDelegate {
                        interactive: false

                        onVisibleChanged: {
                            if (!swarmCurrentConversationList.visible) {
                                highlighted = false;
                                root.clearHighlighted();
                            }
                        }

                        Component.onCompleted: {
                            // Note: when scrolled down, this delegate will be
                            // destroyed from the memory. So, re-add the highlighted
                            // status if necessary
                            if (Array.from(root.highlighted).find(r => r === UID)) {
                                highlighted = true;
                            }
                        }

                        onHighlightedChanged: function onHighlightedChanged() {
                            if (highlighted && Array.from(root.highlighted).find(r => r === UID)) {
                                // Due to scrolling destruction/reconstruction
                                return;
                            }
                            var currentHighlighted = root.highlighted;
                            if (!root.refreshHighlighted(UID, highlighted)) {
                                highlighted = false;
                                return;
                            }
                            if (highlighted) {
                                root.highlighted.push(UID);
                            } else {
                                root.highlighted = Array.from(root.highlighted).filter(r => r !== UID);
                            }
                            root.clearContactSearchBar();
                        }
                    }
                    currentIndex: model.currentFilteredRow

                    Timer {
                        id: locationIconTimer

                        property bool showIconArrow: true
                        property bool isSharingPosition: PositionManager.positionShareConvIdsCount !== 0
                        property bool isReceivingPosition: PositionManager.sharingUrisCount !== 0

                        interval: 750
                        running: isSharingPosition || isReceivingPosition
                        repeat: true
                        onTriggered: {
                            showIconArrow = !showIconArrow;
                        }
                    }
                }
            }
        }
    }
}
