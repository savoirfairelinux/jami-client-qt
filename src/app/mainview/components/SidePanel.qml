/*
 * Copyright (C) 2020-2026 Savoir-faire Linux Inc.
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
import QtQuick.Effects
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import net.jami.Enums 1.1
import net.jami.Models 1.1
import "../../commoncomponents"
import "../../settingsview/components"

SidePanelBase {
    id: root

    objectName: "SidePanel"

    color: JamiTheme.globalBackgroundColor

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

    Item {
        anchors.fill: parent

        Rectangle {
            id: chatViewHairLineExtension
            anchors.top: parent.top
            anchors.topMargin: JamiTheme.qwkTitleBarHeight
            anchors.left: parent.left
            anchors.leftMargin: JamiTheme.sidePanelIslandsPadding
            width: parent.width
            height: JamiTheme.chatViewHairLineSize
            color: JamiTheme.chatViewFooterRectangleBorderColor
            visible: CurrentConversation.id !== "" && !CurrentConversation.hasCall
        }

        ColumnLayout {
            anchors.fill: parent
            // Creates The floating rectangle itself
            anchors.leftMargin: JamiTheme.sidePanelIslandsPadding
            anchors.topMargin: JamiTheme.sidePanelIslandsPadding
            anchors.bottomMargin: JamiTheme.sidePanelIslandsPadding
            anchors.rightMargin: JamiTheme.sidePanelIslandsPadding * 2

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                Rectangle {
                    id: conversationListRect

                    anchors.fill: parent

                    color: JamiTheme.globalIslandColor
                    radius: JamiTheme.commonRadius
                    layer.enabled: true
                    layer.effect: MultiEffect {
                        id: searchBarMultiEffect
                        anchors.fill: conversationListRect
                        shadowEnabled: true
                        shadowBlur: JamiTheme.shadowBlur
                        shadowColor: JamiTheme.shadowColor
                        shadowHorizontalOffset: JamiTheme.shadowHorizontalOffset
                        shadowVerticalOffset: JamiTheme.shadowVerticalOffset
                        shadowOpacity: JamiTheme.shadowOpacity
                    }
                }

                ColumnLayout {
                    id: conversationLayout

                    anchors.fill: conversationListRect
                    spacing: 10

                    // We use this to update the donation banner visibility, instead of a timer.
                    onVisibleChanged: JamiQmlUtils.updateIsDonationBannerVisible()

                    layer.enabled: true
                    layer.effect: MultiEffect {
                        anchors.fill: conversationListRect
                        maskEnabled: true
                        maskSource: ShaderEffectSource {
                            sourceItem: Rectangle {
                                width: conversationLayout.width
                                height: conversationLayout.height
                                radius: JamiTheme.commonRadius
                            }
                        }
                    }

                    // Label/button to create a new swarm.
                    RowLayout {
                        id: createSwarmToggle

                        QWKSetParentHitTestVisible {}

                        visible: swarmMemberSearchList.visible

                        width: parent.width
                        height: 40

                        Layout.topMargin: JamiTheme.sidePanelConversationsIslandTopPadding
                        Layout.leftMargin: 15
                        Layout.rightMargin: 15
                        Layout.alignment: Qt.AlignTop

                        Label {
                            height: parent.height
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter

                            color: JamiTheme.textColor

                            font.bold: true
                            font.pointSize: JamiTheme.contactEventPointSize

                            text: JamiStrings.newGroup
                        }

                        PushButton {
                            radius: JamiTheme.primaryRadius

                            imageColor: JamiTheme.textColor
                            imagePadding: 8
                            normalColor: JamiTheme.newSwarmButtonColor

                            preferredSize: createSwarmToggle.height

                            source: JamiResources.round_close_24dp_svg
                            toolTipText: JamiStrings.cancel

                            onClicked: toggleCreateSwarmView()
                        }
                    }

                    // Search conversations, start new conversations, etc.
                    RowLayout {
                        id: startBar

                        QWKSetParentHitTestVisible {}

                        width: parent.width
                        height: 40

                        Layout.topMargin: JamiTheme.sidePanelConversationsIslandTopPadding
                        Layout.leftMargin: 15
                        Layout.rightMargin: 15
                        Layout.alignment: Qt.AlignTop

                        Shortcut {
                            sequence: "Ctrl+F"
                            context: Qt.ApplicationShortcut
                            onActivated: {
                                contactSearchBar.forceActiveFocus();
                            }
                        }

                        Searchbar {
                            id: contactSearchBar

                            height: parent.height
                            Layout.fillWidth: true

                            Behavior on width {
                                NumberAnimation {
                                    duration: 1000
                                    easing.type: Easing.InOutQuad
                                }
                            }

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
                            normalColor: JamiTheme.newSwarmButtonColor

                            preferredSize: startBar.height

                            visible: !swarmMemberSearchList.visible && (!contactSearchBar.textContent || CurrentAccount.type === Profile.Type.SIP)

                            source: smartListLayout.visible ? (CurrentAccount.type !== Profile.Type.SIP ? JamiResources.create_swarm_svg : JamiResources.ic_keypad_svg) : JamiResources.round_close_24dp_svg
                            toolTipText: smartListLayout.visible ? ((CurrentAccount.type !== Profile.Type.SIP) ? JamiStrings.newGroup : JamiStrings.openKeypad) : JamiStrings.cancel

                            onClicked: {
                                if (CurrentAccount.type === Profile.Type.SIP) {
                                    sipInputPanelPopUp.shown = !sipInputPanelPopUp.shown;
                                } else {
                                    toggleCreateSwarmView();
                                }
                            }
                        }
                    }

                    SidePanelTabBar {
                        id: sidePanelTabBar

                        visible: ConversationsAdapter.pendingRequestCount && !contactSearchBar.textContent && smartListLayout.visible

                        contentHeight: childrenRect.height
                        width: parent.width
                        Layout.preferredHeight: 42

                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignTop

                        Layout.bottomMargin: -10

                        // We need to propogate the active to the smartListLayout
                        onCurrentIndexChanged: smartListLayout.forceActiveFocus()
                    }

                    Rectangle {
                        id: searchStatusRect

                        visible: searchStatusText.text !== "" && smartListLayout.visible

                        width: parent.width
                        height: 42

                        Layout.bottomMargin: -10
                        Layout.alignment: Qt.AlignTop

                        color: JamiTheme.globalIslandColor
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

                    DonationBanner {
                        Layout.fillWidth: true
                        Layout.leftMargin: 15
                        Layout.rightMargin: 15
                        Layout.topMargin: sidePanelTabBar.visible ? 10 : 0

                        visible: JamiQmlUtils.isDonationBannerVisible
                    }

                    ColumnLayout {
                        id: smartListLayout

                        width: parent.width
                        Layout.fillHeight: true

                        spacing: 4

                        visible: !swarmMemberSearchList.visible

                        onActiveFocusChanged: {
                            // We need to defer to the focus to the appropriate list
                            if (smartListLayout.activeFocus) {
                                if (searchResultsListView.visible)
                                    conversationListView.forceActiveFocus();
                                if (conversationListView.visible)
                                    conversationListView.forceActiveFocus();
                            }
                        }

                        ConversationListView {
                            id: searchResultsListView

                            enabled: !sipInputPanelPopUp.visible

                            activeFocusOnTab: true

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

                            model: ConversationsAdapter.searchListProxyModel

                            delegate: SmartListItemDelegate {
                                extraButtons.contentItem: NewIconButton {
                                    id: sendContactRequestButton
                                    QWKSetParentHitTestVisible {}

                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter

                                    iconSize: JamiTheme.iconButtonMedium
                                    iconSource: JamiResources.add_people_24dp_svg
                                    toolTipText: JamiStrings.addToConversations

                                    // Disalbe due to fading issues
                                    background.visible: false

                                    visible: isTemporary || isBanned

                                    onClicked: {
                                        console.log(isBanned);
                                        if (isBanned) {
                                            LRCInstance.selectConversation(UID);
                                            MessagesAdapter.unbanConversation(CurrentConversation.id);
                                        } else {
                                            LRCInstance.selectConversation(UID);
                                            MessagesAdapter.sendConversationRequest();
                                        }
                                    }
                                }

                                extraButtons.height: sendContactRequestButton.height
                                extraButtons.width: sendContactRequestButton.width
                            }
                            headerLabel: JamiStrings.searchResults
                            headerVisible: true
                        }

                        ConversationListView {
                            id: conversationListView

                            enabled: !sipInputPanelPopUp.visible

                            activeFocusOnTab: true

                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            model: ConversationsAdapter.convListProxyModel
                            headerLabel: JamiStrings.conversations
                            headerVisible: count && searchResultsListView.visible
                        }
                    }

                    ColumnLayout {
                        id: swarmMemberSearchList

                        visible: inNewSwarm

                        width: parent.width
                        Layout.fillHeight: true

                        spacing: 4

                        JamiListView {
                            id: swarmCurrentConversationList

                            Layout.preferredWidth: parent.width
                            Layout.fillHeight: true

                            model: ConversationsAdapter.convListProxyModel
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

            AccountComboBox {
                id: accountComboBox

                Layout.fillWidth: true
                Layout.minimumHeight: accountComboBox.height
                Layout.alignment: Qt.AlignBottom
                Layout.topMargin: 8

                Shortcut {
                    sequence: "Ctrl+J"
                    context: Qt.ApplicationShortcut
                    onActivated: accountComboBox.togglePopup()
                }
            }
        }

        SipInputPanel {
            id: sipInputPanelPopUp
            onDigitPressed: {
                contactSearchBar.textContent += digit;
            }
            x: startConversation.x - sipInputPanelPopUp.width / 2 - 10
            y: startConversation.y + startConversation.height + 24
            z: parent.z + 1
            width: sipInputPanelPopUp.implicitWidth
            height: sipInputPanelPopUp.implicitHeight
            opacity: 0
            transform: Translate {
                id: sipTranslate
                y: -10
            }
            property bool shown: false
            visible: false
            states: [
                State {
                    name: "visible"
                    when: sipInputPanelPopUp.shown
                    PropertyChanges {
                        target: sipInputPanelPopUp
                        opacity: 1.0
                        visible: true
                    }
                    PropertyChanges {
                        target: sipTranslate
                        y: 0
                    }
                },
                State {
                    name: "hidden"
                    when: !sipInputPanelPopUp.shown
                    PropertyChanges {
                        target: sipInputPanelPopUp
                        opacity: 0.0
                        // Do not set visible: false here; let the transition handle it
                    }
                    PropertyChanges {
                        target: sipTranslate
                        y: -10
                    }
                }
            ]
            transitions: [
                Transition {
                    from: "hidden"
                    to: "visible"
                    SequentialAnimation {
                        PropertyAction {
                            target: sipInputPanelPopUp
                            property: "visible"
                            value: true
                        }
                        ParallelAnimation {
                            NumberAnimation {
                                target: sipInputPanelPopUp
                                property: "opacity"
                                duration: 250
                                easing.type: Easing.OutCubic
                            }
                            NumberAnimation {
                                target: sipTranslate
                                property: "y"
                                duration: 250
                                easing.type: Easing.OutCubic
                            }
                        }
                    }
                },
                Transition {
                    from: "visible"
                    to: "hidden"
                    SequentialAnimation {
                        ParallelAnimation {
                            NumberAnimation {
                                target: sipInputPanelPopUp
                                property: "opacity"
                                duration: 250
                                easing.type: Easing.InCubic
                            }
                            NumberAnimation {
                                target: sipTranslate
                                property: "y"
                                duration: 250
                                easing.type: Easing.InCubic
                            }
                        }
                        PropertyAction {
                            target: sipInputPanelPopUp
                            property: "visible"
                            value: false
                        }
                    }
                }
            ]
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: sipInputPanelPopUp.visible || sipInputPanelPopUp.shown
        hoverEnabled: true
        onClicked: {
            if ((mouseX < sipInputPanelPopUp.x || mouseX > sipInputPanelPopUp.x + sipInputPanelPopUp.width) || (mouseY < sipInputPanelPopUp.y || mouseY > sipInputPanelPopUp.y + sipInputPanelPopUp.height)) {
                sipInputPanelPopUp.shown = false;
            }
        }
    }
}
