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

    property bool inNewSwarm: viewCoordinator.currentViewName === "NewSwarmPage"
    property bool isEmptyAccount: (!inNewSwarm && conversationListView.model && conversationListView.model.count === 0) || (inNewSwarm && swarmCurrentConversationList.model && swarmCurrentConversationList.model.count === 0)

    property var highlighted: []
    property var highlightedMembers: []

    color: JamiTheme.transparentColor

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

    function selectTab(tabIndex) {
        sidePanelTabBar.selectTab(tabIndex);
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
            anchors.margins: viewCoordinator.isInSinglePaneMode ? JamiTheme.sidePanelIslandsSinglePaneModePadding : JamiTheme.sidePanelIslandsPadding
            anchors.rightMargin: {
                if (viewCoordinator.isInSinglePaneMode) {
                    return JamiTheme.sidePanelIslandsSinglePaneModePadding;
                }
                // This manual override for the right margin is necessary,
                // otherwise the shadow appears cut-off.
                return 16;
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                Rectangle {
                    id: conversationListRect

                    anchors.fill: parent

                    color: JamiTheme.globalIslandColor
                    radius: JamiTheme.avatarBasedRadius
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

                        Layout.topMargin: JamiTheme.sidePanelConversationsIslandTopPadding
                        Layout.leftMargin: 15
                        Layout.rightMargin: 15
                        Layout.alignment: Qt.AlignTop

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
                                var listView = searchResultsListView.count ? searchResultsListView :
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
                                if (CurrentAccount.type === Profile.Type.SIP) {
                                    if (sipInputPanelPopUp.shown) {
                                        return JamiResources.round_close_24dp_svg;
                                    } else {
                                        return JamiResources.ic_keypad_svg;
                                    }
                                } else if (inNewSwarm) {
                                    return JamiResources.round_close_24dp_svg;
                                } else {
                                    return JamiResources.create_swarm_svg;
                                }
                            }
                            toolTipText: {
                                if (CurrentAccount.type === Profile.Type.SIP) {
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
                                if (CurrentAccount.type === Profile.Type.SIP) {
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
                                 !contactSearchBar.textContent && !inNewSwarm
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

                    DonationBanner {
                        Layout.fillWidth: true
                        Layout.leftMargin: 15
                        Layout.rightMargin: 15

                        visible: JamiQmlUtils.isDonationBannerVisible
                    }

                    JamiListView {
                        id: swarmCurrentConversationList

                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        activeFocusOnTab: true

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
                        Layout.preferredHeight: count ? JamiTheme.smartListItemHeight + headerItem.height : headerItem.height

                        visible: !inNewSwarm && contactSearchBar.textContent
                        activeFocusOnTab: true

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

                        visible: !inNewSwarm && contactSearchBar.textContent && searchResultsListView.count === 0

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

                        visible: !inNewSwarm && !root.isEmptyAccount

                        model: ConversationsAdapter.convListProxyModel
                        headerLabel: JamiStrings.conversations
                        headerVisible: contactSearchBar.textContent && model.count
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        visible: root.isEmptyAccount

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 16

                            // For empty accounts, we need the parent (Item) to act as spacer,
                            // Setting the visibiltiy will allow the search results to be forced at the top
                            visible: contactSearchBar.textContent === ""

                            NewIconButton {
                                Layout.alignment: Qt.AlignHCenter

                                iconSource: inNewSwarm ? JamiResources.emotion_sad_line_svg :
                                                         JamiResources.ghost_line_svg
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
                }

                Rectangle {
                    id: gradientRectTop

                    readonly property color baseColor: JamiTheme.globalIslandColor
                    readonly property bool shouldShow: (!inNewSwarm && !conversationListView.atYBeginning) || (inNewSwarm && !swarmCurrentConversationList.atYBeginning)

                    anchors.top: conversationLayout.top
                    anchors.topMargin: header.height + JamiTheme.sidePanelIslandsSinglePaneModePadding * 3

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
                    readonly property bool shouldShow: (!inNewSwarm && !conversationListView.atYEnd) || (inNewSwarm && !swarmCurrentConversationList.atYEnd)

                    anchors.bottom: conversationLayout.bottom
                    anchors.bottomMargin: -1

                    width: conversationLayout.width
                    height: JamiTheme.smartListItemHeight

                    bottomRightRadius: JamiTheme.avatarBasedRadius
                    bottomLeftRadius: JamiTheme.avatarBasedRadius

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

                Layout.fillWidth: true
                Layout.minimumHeight: accountComboBox.height
                Layout.alignment: Qt.AlignBottom
                Layout.topMargin: 8

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
