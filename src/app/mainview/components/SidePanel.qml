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

    readonly property var viewCoordinator: appContext ? appContext.viewCoordinator : null
    property bool inNewSwarm: viewCoordinator && viewCoordinator.currentViewName === "NewSwarmPage"
    property int conversationCount: conversationListView.model ? conversationListView.model.count : 0
    property bool isEmptyAccount: inNewSwarm
                                  ? (swarmCurrentConversationList.model && swarmCurrentConversationList.model.count === 0)
                                  : (!ConversationsAdapter.filterRequests && conversationListView.model
                                     && conversationCount === 0)
    // Opened by the Contacts function: the contacts, by date or by name, replace the conversations.
    property bool contactsMode: false
    // The functions panel goes with the conversation list only.
    readonly property bool showFunctions: !inNewSwarm && !contactsMode && !ConversationsAdapter.filterRequests
                                          && !contactSearchBar.textContent && CurrentAccount.type !== Profile.Type.SIP

    property var highlighted: []
    property var highlightedMembers: []

    readonly property real sidePanelIslandsMargin: viewCoordinator && viewCoordinator.isInSinglePaneMode ? JamiTheme.sidePanelIslandsSinglePaneModePadding : JamiTheme.sidePanelIslandsPadding

    color: inNewSwarm ? JamiTheme.globalBackgroundColor : JamiTheme.transparentColor

    Connections {
        target: LRCInstance

        function onCurrentAccountIdChanged() {
            clearContactSearchBar();
            root.contactsMode = false;
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

    Connections {
        target: CurrentAccount

        // New swarm page shouldn't be visible for SIP accounts
        function onTypeChanged() {
            if (CurrentAccount.type === Profile.Type.SIP && inNewSwarm) {
                viewCoordinator.dismiss("NewSwarmPage");
                root.clearHighlighted();
            }
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
                                                        let convuid
                                                        = ConversationsAdapter.createSwarm(title,
                                                                                           description,
                                                                                           avatar, uris);
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

    function openContacts() {
        clearContactSearchBar();
        ConversationsAdapter.contactsListProxyModel.setFilter("");
        contactsMode = true;
    }

    function closeContacts() {
        clearContactSearchBar();
        contactsMode = false;
    }

    // Runs one of the nine functions of the functions panel.
    function runFunction(fn) {
        switch (fn) {
        case FunctionsPanel.Contacts:
            openContacts();
            break;
        case FunctionsPanel.Documents:
            openDocuments();
            break;
        case FunctionsPanel.Groups:
            openGroups();
            break;
        case FunctionsPanel.Board:
            openBoards();
            break;
        case FunctionsPanel.Services:
            openServices();
            break;
        case FunctionsPanel.Circles:
            openCircles();
            break;
        default:
            pickTarget(fn);
        }
    }

    // Calls, Messages, Location and a new document: first, who with.
    function pickTarget(fn) {
        const info = functionsPanel.functionInfo(fn);
        const picker = viewCoordinator.presentDialog(appWindow, "mainview/components/FunctionTargetPicker.qml", {
                                                         "fn": fn,
                                                         "titleText": info.name,
                                                         "accentColor": info.color
                                                     });
        picker.conversationPicked.connect((convId, withVideo) => useConversation(fn, convId, withVideo));
        picker.circlePicked.connect(circleId => manageCircle(circleId));
        picker.boardPicked.connect(feedId => FeedAdapter.open(feedId));
    }

    function useConversation(fn, convId, withVideo) {
        LRCInstance.selectConversation(convId);
        switch (fn) {
        case FunctionsPanel.Calls:
            if (withVideo)
                CallAdapter.startCall();
            else
                CallAdapter.startAudioOnlyCall();
            break;
        case FunctionsPanel.Documents: {
            // A new document, written right away.
            const creation = viewCoordinator.presentDialog(appWindow, "commoncomponents/CollabNewDocPopup.qml", {
                                                               "conversationId": convId
                                                           });
            creation.created.connect((documentId, name) => {
                                         appWindow.openCollabEditor(convId, documentId, name,
                                                                    ConversationsAdapter.getConvInfoMap(convId).title,
                                                                    CurrentAccount.uri);
                                     });
            break;
        }
        case FunctionsPanel.Location:
            // The chat view of the conversation opens the map.
            Qt.callLater(PositionManager.setMapActive, CurrentAccount.id);
            break;
        }
    }

    // The documents of every conversation, each opening in the editor.
    function openDocuments() {
        const dialog = viewCoordinator.presentDialog(appWindow, "mainview/components/DocumentsDialog.qml");
        dialog.editRequested.connect(document => {
                                         appWindow.openCollabEditor(document.convId, document.documentId, document.name,
                                                                    document.conversationTitle, document.author);
                                     });
        dialog.newDocumentRequested.connect(() => pickTarget(FunctionsPanel.Documents));
    }

    // The services the contacts offer, each opened from the list.
    function openServices() {
        const dialog = viewCoordinator.presentDialog(appWindow, "mainview/components/ServicesDialog.qml");
        // The "Shared services" page of the account settings
        dialog.ownServicesRequested.connect(() => JamiQmlUtils.requestSettingsPage(6));
        dialog.openUrlRequested.connect(url => {
                                            const confirmation = viewCoordinator.presentDialog(appWindow, "commoncomponents/ConfirmDialog.qml", {
                                                                                                   "titleText": JamiStrings.openExternalLink,
                                                                                                   "textLabel": JamiStrings.confirmNavigationDescription,
                                                                                                   "confirmLabel": JamiStrings.open
                                                                                               });
                                            confirmation.accepted.connect(() => Qt.openUrlExternally(url));
                                        });
    }

    function openGroups() {
        const dialog = viewCoordinator.presentDialog(appWindow, "mainview/components/GroupsDialog.qml");
        dialog.groupPicked.connect(convId => LRCInstance.selectConversation(convId));
        dialog.createGroupRequested.connect(() => {
                                                if (!inNewSwarm)
                                                    toggleCreateSwarmView();
                                            });
        dialog.leaveGroupRequested.connect(convId => {
                                               const confirmation = viewCoordinator.presentDialog(appWindow, "commoncomponents/ConfirmDialog.qml", {
                                                                                                      "titleText": JamiStrings.confirmAction,
                                                                                                      "textLabel": JamiStrings.confirmLeaveGroup,
                                                                                                      "confirmLabel": JamiStrings.optionLeave
                                                                                                  });
                                               confirmation.accepted.connect(() => MessagesAdapter.removeConversation(convId, true));
                                           });
    }

    function openBoards() {
        const dialog = viewCoordinator.presentDialog(appWindow, "mainview/components/BoardsDialog.qml");
        dialog.boardPicked.connect(feedId => FeedAdapter.open(feedId));
        dialog.createRequested.connect(() => viewCoordinator.presentDialog(appWindow, "commoncomponents/FeedSettingsDialog.qml", {
                                                                                "accountId": CurrentAccount.id
                                                                            }));
        dialog.manageRequested.connect(feedId => viewCoordinator.presentDialog(appWindow, "commoncomponents/FeedSettingsDialog.qml", {
                                                                                    "accountId": CurrentAccount.id,
                                                                                    "feedId": feedId
                                                                                }));
        dialog.catalogueRequested.connect(() => viewCoordinator.presentDialog(appWindow, "commoncomponents/FeedCatalogueDialog.qml", {
                                                                                   "accountId": CurrentAccount.id
                                                                               }));
    }

    function openCircles() {
        const dialog = viewCoordinator.presentDialog(appWindow, "mainview/components/CirclesDialog.qml");
        dialog.createRequested.connect(() => manageCircle(""));
        dialog.manageRequested.connect(circleId => manageCircle(circleId));
    }

    function manageCircle(circleId) {
        viewCoordinator.presentDialog(appWindow, "commoncomponents/CircleDialog.qml", {
                                          "accountId": CurrentAccount.id,
                                          "circleId": circleId
                                      });
    }

    function selectTab(tabIndex) {
        sidePanelTabBar.selectTab(tabIndex);
    }

    function refreshHighlighted(convId, highlightedStatus) {
        var newH = Array.from(root.highlighted);
        var newHm = Array.from(root.highlightedMembers);
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

    // Selects, for the new group, every member of a Circle: its contacts and the
    // members of its groups. refreshHighlighted() keeps each member only once.
    function addCircleMembers(circle) {
        const convIds = (circle.members || []).map(uri => ConversationsAdapter.dialogId(uri.replace(/^(jami|ring):/, "")))
                            .concat((circle.groups || []).map(uri => uri.replace(/^swarm:/, "")));
        for (const convId of convIds) {
            if (convId === "" || Array.from(root.highlighted).includes(convId))
                continue;
            const delegate = Array.from(swarmCurrentConversationList.contentItem.children).find(d => d.convId === convId);
            if (delegate)
                delegate.highlighted = true;
            else
                root.refreshHighlighted(convId, true);
        }
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

    onHighlightedMembersChanged: {
        if (inNewSwarm) {
            const newSwarmPage = viewCoordinator.getView("NewSwarmPage");
            newSwarmPage.members = highlightedMembers;
        }
    }

    Item {
        anchors.fill: parent

        BackgroundGradient {
            id: chatViewGradientExtension

            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right

            height: JamiTheme.qwkTitleBarHeight + JamiTheme.sidePanelIslandsPadding * 2
        }

        ColumnLayout {
            anchors.fill: parent
            // Creates The floating rectangle itself
            anchors.margins: root.sidePanelIslandsMargin
            anchors.topMargin: JamiQmlUtils.isMacOS26OrLater ? JamiTheme.sidePanelIslandPaddingMac : root.sidePanelIslandsMargin
            anchors.leftMargin: JamiQmlUtils.isMacOS26OrLater ? JamiTheme.sidePanelIslandPaddingMac : root.sidePanelIslandsMargin
            anchors.rightMargin: {
                if (viewCoordinator && viewCoordinator.isInSinglePaneMode) {
                    return JamiTheme.sidePanelIslandsSinglePaneModePadding;
                }
                // This manual override for the right margin is necessary,
                // otherwise the shadow appears cut-off.
                return JamiTheme.sidePanelIslandRightPadding;
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                Rectangle {
                    id: conversationListRect

                    anchors.fill: parent
                    color: JamiTheme.globalIslandColor
                    radius: JamiTheme.avatarBasedRadius
                    topLeftRadius: JamiQmlUtils.isMacOS26OrLater ? JamiTheme.macOSTopRadius : JamiTheme.avatarBasedRadius
                    layer.enabled: true
                    layer.effect: MultiEffect {
                        id: conversationListRectMultiEffect
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
                                radius: JamiTheme.avatarBasedRadius
                            }
                        }
                    }

                    RowLayout {
                        id: header

                        QWKSetParentHitTestVisible {}

                        width: parent.width
                        height: 40

                        Layout.topMargin: {
                            const basePadding = JamiTheme.sidePanelConversationsIslandTopPadding;
                            const macPadding = JamiTheme.sidePanelTopPaddingMac;
                            return JamiQmlUtils.isMacOS26OrLater ? basePadding + macPadding : basePadding;
                        }
                        Layout.leftMargin: conversationListRect.radius - contactSearchBar.radius
                        Layout.rightMargin: 15
                        Layout.alignment: Qt.AlignTop

                        NewIconButton {
                            objectName: "closeContactsButton"

                            visible: root.contactsMode
                            iconSource: JamiResources.bidirectional_arrow_back_24dp_svg
                            iconSize: JamiTheme.iconButtonMedium
                            toolTipText: JamiStrings.back
                            onClicked: root.closeContacts()
                        }

                        Searchbar {
                            id: contactSearchBar

                            height: parent.height
                            Layout.fillWidth: true

                            placeHolderText: root.contactsMode ? JamiStrings.search : JamiStrings.searchOrAdd

                            Behavior on width {
                                NumberAnimation {
                                    duration: 1000
                                    easing.type: Easing.InOutQuad
                                }
                            }

                            onSearchBarTextChanged: function (text) {
                                if (root.contactsMode) {
                                    ConversationsAdapter.contactsListProxyModel.setFilter(text);
                                    return;
                                }
                                // not calling positionViewAtBeginning will cause
                                // sort animation visual bugs
                                conversationListView.positionViewAtBeginning();
                                ConversationsAdapter.ignoreFiltering(root.highlighted);
                                ConversationsAdapter.setFilter(text);
                            }

                            onAccepted: {
                                var listView = root.contactsMode ? contactsListView :
                                               searchResultsListView.count ? searchResultsListView :
                                                                             conversationListView;
                                if (listView.count)
                                    listView.model.select(0);
                            }
                        }

                        PushButton {
                            id: actionButton

                            radius: JamiTheme.primaryRadius

                            imageColor: JamiTheme.textColor
                            imagePadding: 8
                            normalColor: JamiTheme.newSwarmButtonColor

                            preferredSize: 40

                            source: {
                                if (root.contactsMode) {
                                    return JamiResources.qr_code_24dp_svg;
                                } else if (CurrentAccount.type === Profile.Type.SIP) {
                                    if (sipInputPanelPopUp.shown) {
                                        return JamiResources.round_close_24dp_svg;
                                    } else {
                                        return JamiResources.keypad_24dp_svg;
                                    }
                                } else if (inNewSwarm) {
                                    return JamiResources.round_close_24dp_svg;
                                } else {
                                    return JamiResources.create_swarm_24dp_svg;
                                }
                            }
                            toolTipText: {
                                if (root.contactsMode) {
                                    return JamiStrings.shareAccount;
                                } else if (CurrentAccount.type === Profile.Type.SIP) {
                                    if (sipInputPanelPopUp.shown) {
                                        return JamiStrings.close;
                                    } else {
                                        return JamiStrings.sipInputPanel;
                                    }
                                } else if (inNewSwarm) {
                                    return JamiStrings.close;
                                } else {
                                    return JamiStrings.newGroup;
                                }
                            }

                            onClicked: {
                                if (root.contactsMode) {
                                    viewCoordinator.presentDialog(appWindow, "mainview/components/WelcomePageQrDialog.qml");
                                } else if (CurrentAccount.type === Profile.Type.SIP) {
                                    sipInputPanelPopUp.shown = !sipInputPanelPopUp.shown;
                                } else {
                                    toggleCreateSwarmView();
                                    contactSearchBar.forceActiveFocus();
                                }
                            }
                        }
                    }

                    SidePanelTabBar {
                        id: sidePanelTabBar

                        Layout.fillWidth: true
                        Layout.preferredHeight: JamiTheme.tabBarHeight
                        Layout.leftMargin: 15
                        Layout.rightMargin: 15
                        // Hack: spacing between convList and TabBars is too large otherwise
                        Layout.bottomMargin: -10
                        Layout.alignment: Qt.AlignTop

                        contentHeight: childrenRect.height
                        width: parent.width

                        visible: ConversationsAdapter.pendingRequestCount &&
                                 !contactSearchBar.textContent && !inNewSwarm && !root.contactsMode
                    }

                    ContactsSortBar {
                        id: contactsSortBar

                        Layout.fillWidth: true
                        Layout.leftMargin: 15
                        Layout.rightMargin: 15

                        visible: root.contactsMode
                    }

                    Binding {
                        target: ConversationsAdapter.contactsListProxyModel
                        property: "sortByTitle"
                        value: contactsSortBar.sortByTitle
                    }

                    Label {
                        Layout.fillWidth: true
                        // Consistent height to avoid choppy movements during visibility changes
                        Layout.preferredHeight: sidePanelTabBar.height
                        Layout.leftMargin: 15
                        Layout.rightMargin: 15
                        // Hack: spacing between convList and TabBars is too large otherwise
                        Layout.bottomMargin: -10
                        Layout.alignment: Qt.AlignVCenter

                        color: JamiTheme.textColor

                        font.bold: true
                        font.pointSize: JamiTheme.contactEventPointSize

                        text: JamiStrings.newGroup
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter

                        visible: inNewSwarm
                    }

                    ColumnLayout {
                        objectName: "newGroupCircles"

                        Layout.fillWidth: true
                        Layout.leftMargin: 15
                        Layout.rightMargin: 15
                        spacing: 6

                        visible: inNewSwarm && newGroupCircles.count > 0

                        Text {
                            Layout.fillWidth: true
                            text: JamiStrings.chooseFromCircles
                            color: JamiTheme.textColor
                            font.pointSize: JamiTheme.textFontSize
                            wrapMode: Text.Wrap
                        }

                        Flow {
                            Layout.fillWidth: true
                            spacing: 6

                            Repeater {
                                id: newGroupCircles

                                model: CircleAdapter.circles.filter(circle => circle.count > 0)

                                delegate: AbstractButton {
                                    id: circleChip

                                    required property var modelData

                                    objectName: "newGroupCircle-" + modelData.id
                                    hoverEnabled: true
                                    focusPolicy: Qt.TabFocus
                                    padding: 6
                                    leftPadding: 12
                                    rightPadding: 12
                                    Accessible.name: modelData.name

                                    contentItem: Text {
                                        text: circleChip.modelData.name + " (" + circleChip.modelData.count + ")"
                                        color: "#6366F1"
                                        font.pointSize: JamiTheme.textFontSize
                                    }
                                    background: Rectangle {
                                        radius: height / 2
                                        color: circleChip.hovered ? "#336366F1" : "#1A6366F1"
                                        border.width: circleChip.visualFocus ? 2 : 1
                                        border.color: "#6366F1"
                                    }
                                    onClicked: root.addCircleMembers(modelData)
                                }
                            }
                        }
                    }

                    DonationBanner {
                        id: donationBanner

                        Layout.fillWidth: true
                        Layout.leftMargin: 15
                        Layout.rightMargin: 15

                        visible: JamiQmlUtils.isDonationBannerVisible && !root.contactsMode
                    }

                    JamiListView {
                        id: swarmCurrentConversationList

                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        activeFocusOnTab: true

                        model: ConversationsAdapter.convListProxyModel

                        delegate: SmartListItemDelegate {
                            interactive: false
                            showLocationIconArrow: locationIconTimer.showIconArrow

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

                        visible: inNewSwarm && !root.isEmptyAccount

                        Timer {
                            id: locationIconTimer

                            property bool showIconArrow: true
                            property bool isSharingPosition:
                                PositionManager.positionShareConvIdsCount !== 0
                            property bool isReceivingPosition: PositionManager.sharingUrisCount
                                                               !== 0

                            interval: 750
                            running: isSharingPosition || isReceivingPosition
                            repeat: true
                            onTriggered: {
                                showIconArrow = !showIconArrow;
                            }
                        }
                    }

                    ConversationListView {
                        id: searchResultsListView

                        Layout.topMargin: 10
                        Layout.alignment: Qt.AlignTop
                        Layout.fillWidth: true
                        Layout.preferredHeight: count * JamiTheme.smartListItemHeight + headerItem.height
                        Layout.maximumHeight: Math.max(0, (conversationLayout.height - header.height + 10 +
                                                           (donationBanner.visible ? donationBanner.height + conversationLayout.spacing : 0)) / 2)

                        visible: !inNewSwarm && !root.contactsMode && contactSearchBar.textContent
                        activeFocusOnTab: true

                        model: ConversationsAdapter.searchListProxyModel

                        delegate: SmartListItemDelegate {
                            showLocationIconArrow: locationIconTimer.showIconArrow

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
                                        MessagesAdapter.unbanConversation(
                                                    CurrentConversation.id);
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

                    Text {
                        id: searchStatusText

                        Layout.fillWidth: true
                        Layout.preferredHeight: sidePanelTabBar.height
                        Layout.leftMargin: 32
                        Layout.rightMargin: 32
                        Layout.alignment: Qt.AlignTop

                        visible: !inNewSwarm && !root.contactsMode && contactSearchBar.textContent
                                 && searchResultsListView.count === 0

                        color: JamiTheme.textColor
                        wrapMode: Text.WordWrap
                        font.pointSize: JamiTheme.filterItemFontSize
                        elide: Text.ElideRight

                        horizontalAlignment: Text.AlignLeft
                        verticalAlignment: Text.AlignVCenter
                    }

                    ConversationListView {
                        id: conversationListView

                        activeFocusOnTab: true

                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        visible: !inNewSwarm && !root.contactsMode && !root.isEmptyAccount

                        model: ConversationsAdapter.convListProxyModel
                        headerLabel: JamiStrings.conversations
                        headerVisible: contactSearchBar.textContent && model.count
                        delegate: SmartListItemDelegate {
                            showLocationIconArrow: locationIconTimer.showIconArrow
                        }
                    }

                    ConversationListView {
                        id: contactsListView
                        objectName: "contactsListView"

                        activeFocusOnTab: true

                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        visible: root.contactsMode

                        model: ConversationsAdapter.contactsListProxyModel
                        headerLabel: JamiStrings.functionContacts
                        headerVisible: false
                        delegate: SmartListItemDelegate {
                            showLocationIconArrow: locationIconTimer.showIconArrow
                        }
                    }

                    Item {
                        objectName: "emptyAccountPlaceholder"
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        visible: root.isEmptyAccount && !root.contactsMode

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 16

                            // For empty accounts, we need the parent (Item) to act as spacer,
                            // Setting the visibiltiy will allow the search results to be forced at the top
                            visible: contactSearchBar.textContent === ""

                            NewIconButton {
                                Layout.alignment: Qt.AlignHCenter

                                iconSource: inNewSwarm ? JamiResources.emotion_sad_line_24dp_svg :
                                                         JamiResources.ghost_line_24dp_svg
                                iconSize: JamiTheme.iconButtonExtraLarge

                                enabled: false
                            }

                            Text {
                                Layout.alignment: Qt.AlignHCenter

                                text: inNewSwarm ? JamiStrings.noContactsToChooseFrom :
                                                   JamiStrings.noConversations
                                color: JamiTheme.textColor
                                elide: Text.ElideRight

                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }

                            NewMaterialButton {
                                id: findAContactButton

                                Layout.alignment: Qt.AlignHCenter

                                filledButton: true
                                color: JamiTheme.buttonTintedBlue
                                iconSource: JamiResources.add_24dp_svg
                                text: JamiStrings.addAContact

                                onClicked: {
                                    if (inNewSwarm)
                                        toggleCreateSwarmView();
                                    contactSearchBar.forceActiveFocus();
                                }
                            }
                        }
                    }

                    FunctionsPanel {
                        id: functionsPanel

                        Layout.fillWidth: true
                        Layout.preferredHeight: implicitHeight

                        visible: root.showFunctions
                        // At most a third of the window
                        maximumHeight: root.height / 3
                        // Location pulses while a contact sends its position
                        pulsingFunctions: PositionManager.sharingUrisCount > 0
                                          && PositionManager.isReceivingPositions(CurrentAccount.id)
                                          ? [FunctionsPanel.Location] : []

                        onFunctionTriggered: function (fn) {
                            root.runFunction(fn);
                        }
                    }
                }

                Rectangle {
                    id: gradientRectTop

                    readonly property color baseColor: JamiTheme.globalIslandColor
                    readonly property bool shouldShow: (!inNewSwarm && !root.contactsMode && !conversationListView.atYBeginning)
                                                       || (root.contactsMode && !contactsListView.atYBeginning)
                                                       || (inNewSwarm && !swarmCurrentConversationList.atYBeginning)

                    anchors.top: conversationLayout.top
                    anchors.topMargin: header.height + JamiTheme.sidePanelConversationsIslandTopPadding + 10 + (sidePanelTabBar.visible ? sidePanelTabBar.height : 0) + (contactsSortBar.visible ? contactsSortBar.height : 0) + (JamiQmlUtils.isMacOS26OrLater ? JamiTheme.sidePanelTopPaddingMac : 0)

                    width: conversationLayout.width
                    height: JamiTheme.smartListItemHeight

                    z: conversationLayout.z + 1

                    gradient: Gradient {
                        orientation: Gradient.Vertical
                        GradientStop {
                            position: 0.0
                            color: Qt.rgba(gradientRect.baseColor.r, gradientRect.baseColor.g,
                                           gradientRect.baseColor.b, 1.0)
                        }
                        GradientStop {
                            position: 0.25
                            color: Qt.rgba(gradientRect.baseColor.r, gradientRect.baseColor.g,
                                           gradientRect.baseColor.b, 0.75)
                        }
                        GradientStop {
                            position: 1.0
                            color: Qt.rgba(gradientRect.baseColor.r, gradientRect.baseColor.g,
                                           gradientRect.baseColor.b, 0.0)
                        }
                    }

                    visible: opacity > 0
                    opacity: shouldShow ? 1.0 : 0.0

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 200
                            easing.type: Easing.InOutQuad
                        }
                    }
                }

                Rectangle {
                    id: gradientRect

                    readonly property color baseColor: JamiTheme.globalIslandColor
                    readonly property bool shouldShow: (!inNewSwarm && !root.contactsMode && !conversationListView.atYEnd)
                                                       || (root.contactsMode && !contactsListView.atYEnd)
                                                       || (inNewSwarm && !swarmCurrentConversationList.atYEnd)

                    // Fades the end of the list, above the functions panel when it is there.
                    anchors.bottom: conversationLayout.bottom
                    anchors.bottomMargin: functionsPanel.visible ? functionsPanel.height + conversationLayout.spacing : -1

                    width: conversationLayout.width
                    height: JamiTheme.smartListItemHeight

                    bottomRightRadius: functionsPanel.visible ? 0 : JamiTheme.avatarBasedRadius
                    bottomLeftRadius: functionsPanel.visible ? 0 : JamiTheme.avatarBasedRadius

                    z: conversationLayout.z + 1

                    gradient: Gradient {
                        orientation: Gradient.Vertical
                        GradientStop {
                            position: 0.0
                            color: Qt.rgba(gradientRect.baseColor.r, gradientRect.baseColor.g,
                                           gradientRect.baseColor.b, 0.0)
                        }
                        GradientStop {
                            position: 0.75
                            color: Qt.rgba(gradientRect.baseColor.r, gradientRect.baseColor.g,
                                           gradientRect.baseColor.b, 0.75)
                        }
                        GradientStop {
                            position: 1.0
                            color: Qt.rgba(gradientRect.baseColor.r, gradientRect.baseColor.g,
                                           gradientRect.baseColor.b, 1.0)
                        }
                    }

                    visible: opacity > 0
                    opacity: shouldShow ? 1.0 : 0.0

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 200
                            easing.type: Easing.InOutQuad
                        }
                    }
                }
            }

            AccountComboBox {
                id: accountComboBox

                appContext: root.appContext

                Layout.fillWidth: true
                Layout.minimumHeight: accountComboBox.height
                Layout.alignment: Qt.AlignBottom
                Layout.topMargin: 8
                Layout.leftMargin: 0

                Shortcut {
                    sequence: "Ctrl+J"
                    context: Qt.ApplicationShortcut
                    onActivated: accountComboBox.openAccountComboBox()
                }
            }
        }

        SipInputPanel {
            id: sipInputPanelPopUp

            popupX: actionButton.x - sipInputPanelPopUp.width / 2 - 10
            popupY: actionButton.y + actionButton.height + 24
            shown: false

            onDigitPressed: {
                contactSearchBar.textContent += digit;
            }
        }
    }
}
