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
import QtQuick.Controls.impl
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
    property var createConversationDialog: null
    property bool isEmptyAccount: conversationListView.model && conversationListView.model.count === 0

    readonly property real sidePanelIslandsMargin: viewCoordinator && viewCoordinator.isInSinglePaneMode ? JamiTheme.sidePanelIslandsSinglePaneModePadding : JamiTheme.sidePanelIslandsPadding

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

    function openCreateConversationDialog(isFeed) {
        if (createConversationDialog)
            return;
        createConversationDialog = viewCoordinator.presentDialog(appWindow.contentItem, "mainview/components/CreateConversationDialog.qml", {
            "viewCoordinator": viewCoordinator,
            "isFeed": isFeed
        }, true);
        if (!createConversationDialog)
            return;
        createConversationDialog.canceled.connect(() => newConversationTypeButton.forceActiveFocus());
        createConversationDialog.closed.connect(() => root.createConversationDialog = null);
    }

    function clearContactSearchBar() {
        contactSearchBar.clearText();
    }

    function selectCategory(category) {
        sidePanelTabBar.selectCategory(category);
    }

    Shortcut {
        sequence: "Ctrl+L"
        context: Qt.ApplicationShortcut
        enabled: root.visible && !root.createConversationDialog
        onActivated: {
            clearContactSearchBar();
            selectCategory(ConversationListProxyModel.All);
            conversationListView.forceActiveFocus();
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

                        QWKSetParentHitTestVisible {
                            visible: Qt.platform.os !== "osx"
                        }

                        width: parent.width
                        height: 40

                        Layout.topMargin: {
                            const basePadding = JamiTheme.sidePanelConversationsIslandTopPadding;
                            const macPadding = JamiTheme.sidePanelTopPaddingMac;
                            return JamiQmlUtils.isMacOS26OrLater ? basePadding + macPadding : basePadding;
                        }
                        Layout.leftMargin: Qt.platform.os === "osx" ? JamiTheme.itemMarginHorizontal
                                                                   : conversationListRect.radius - contactSearchBar.radius
                        Layout.rightMargin: Qt.platform.os === "osx" ? JamiTheme.itemMarginHorizontal : 15
                        Layout.alignment: Qt.AlignTop

                        Searchbar {
                            id: contactSearchBar

                            objectName: "contactSearchBar"

                            height: parent.height
                            Layout.fillWidth: true

                            placeHolderText: JamiStrings.searchOrAdd

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
                                ConversationsAdapter.setFilter(text);
                            }

                            onAccepted: {
                                var listView = searchResultsListView.count ? searchResultsListView :
                                                                             conversationListView;
                                if (listView.count)
                                    listView.model.select(0);
                            }
                        }

                        PushButton {
                            id: sipPanelButton
                            radius: JamiTheme.primaryRadius

                            imageColor: JamiTheme.textColor
                            imagePadding: 8
                            normalColor: JamiTheme.newSwarmButtonColor

                            preferredSize: 40

                            visible: CurrentAccount.type === Profile.Type.SIP

                            source: sipInputPanelPopUp.shown ? JamiResources.round_close_24dp_svg : JamiResources.keypad_24dp_svg
                            toolTipText: sipInputPanelPopUp.shown ? JamiStrings.close : JamiStrings.sipInputPanel
                            onClicked: sipInputPanelPopUp.shown = !sipInputPanelPopUp.shown;
                        }

                        Button {
                            id: newConversationTypeButton

                            objectName: "newConversationTypeButton"

                            Layout.preferredWidth: 40
                            Layout.preferredHeight: 40
                            padding: 0
                            visible: CurrentAccount.type !== Profile.Type.SIP

                            Accessible.name: JamiStrings.newGroup + " / " + JamiStrings.createNewFeed

                            onClicked: {
                                if (creationPopup.visible) {
                                    creationPopup.close();
                                } else {
                                    creationPopup.open();
                                }
                            }

                            contentItem: IconImage {
                                anchors.centerIn: parent

                                width: 24
                                height: 24

                                source: JamiResources.add_24dp_svg
                                sourceSize.width: 20
                                sourceSize.height: 20

                                color: JamiTheme.textColor
                            }

                            background: Rectangle {
                                radius: height / 2
                                color: newConversationTypeButton.down ? JamiTheme.pressedButtonColor
                                                                 : newConversationTypeButton.hovered ? JamiTheme.hoveredButtonColor
                                                                                                 : JamiTheme.newSwarmButtonColor
                            }

                            Popup {
                                id: creationPopup

                                focus: true
                                closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent

                                x: newConversationTypeButton.width - width
                                y: newConversationTypeButton.height + 4
                                width: Math.max(newConversationTypeButton.width,
                                                options.implicitWidth + leftPadding + rightPadding)
                                padding: 4

                                opacity: opened ? 1.0 : 0.0
                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: JamiTheme.shortFadeDuration
                                    }
                                }

                                contentItem: ColumnLayout {
                                    id: options
                                    spacing: 4

                                    Repeater {
                                        model: [
                                            {
                                                buttonLabel: JamiStrings.newGroup,
                                                buttonIcon: "qrc:/icons/create_swarm_24dp.svg",
                                                isFeed: false
                                            },
                                            {
                                                buttonLabel: JamiStrings.createNewFeed,
                                                buttonIcon: "qrc:/icons/create_feed_24dp.svg",
                                                isFeed: true
                                            }
                                        ]

                                        delegate: NewMaterialButton {
                                            Layout.fillWidth: true

                                            filledButton: true
                                            text: modelData.buttonLabel
                                            iconSource: modelData.buttonIcon

                                            onClicked: {
                                                creationPopup.close();
                                                openCreateConversationDialog(modelData.isFeed);
                                            }
                                        }
                                    }
                                }

                                background: Rectangle {
                                    color: JamiTheme.searchBarColor
                                    radius: 20 + creationPopup.padding

                                    layer.enabled: true
                                    layer.effect: MultiEffect {
                                        anchors.fill: parent
                                        shadowEnabled: true
                                        shadowBlur: JamiTheme.shadowBlur
                                        shadowColor: JamiTheme.shadowColor
                                        shadowHorizontalOffset: JamiTheme.shadowHorizontalOffset
                                        shadowVerticalOffset: JamiTheme.shadowVerticalOffset
                                        shadowOpacity: JamiTheme.shadowOpacity
                                    }
                                }
                            }
                        }
                    }

                    SidePanelTabBar {
                        id: sidePanelTabBar

                        Layout.fillWidth: true
                        Layout.preferredHeight: implicitHeight
                        Layout.leftMargin: 15
                        Layout.rightMargin: 15
                        Layout.alignment: Qt.AlignTop

                        spacing: conversationLayout.spacing
                        visible: CurrentAccount.type !== Profile.Type.SIP &&
                                 !contactSearchBar.textContent
                    }

                    DonationBanner {
                        id: donationBanner

                        Layout.fillWidth: true
                        Layout.leftMargin: 15
                        Layout.rightMargin: 15

                        visible: JamiQmlUtils.isDonationBannerVisible
                    }

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

                    ConversationListView {
                        id: searchResultsListView

                        Layout.topMargin: 10
                        Layout.alignment: Qt.AlignTop
                        Layout.fillWidth: true
                        Layout.preferredHeight: count * JamiTheme.smartListItemHeight + headerItem.height
                        Layout.maximumHeight: Math.max(0, (conversationLayout.height - header.height + 10 +
                                                           (donationBanner.visible ? donationBanner.height + conversationLayout.spacing : 0)) / 2)

                        visible: contactSearchBar.textContent
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

                        visible: contactSearchBar.textContent && searchResultsListView.count === 0

                        color: JamiTheme.textColor
                        wrapMode: Text.WordWrap
                        font.pointSize: JamiTheme.filterItemFontSize
                        elide: Text.ElideRight

                        horizontalAlignment: Text.AlignLeft
                        verticalAlignment: Text.AlignVCenter
                    }

                    ConversationListView {
                        id: conversationListView

                        objectName: "sidebarConversationList"
                        readonly property bool feedSections: !contactSearchBar.textContent &&
                                                             ConversationsAdapter.category === ConversationListProxyModel.Feeds

                        activeFocusOnTab: true

                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        visible: !root.isEmptyAccount

                        model: ConversationsAdapter.convListProxyModel
                        headerLabel: JamiStrings.conversations
                        headerVisible: contactSearchBar.textContent && model.count
                        section.property: feedSections ? "IsRequest" : ""
                        section.delegate: Rectangle {
                            required property string section

                            width: conversationListView.width
                            height: sectionTitle.implicitHeight + sectionTitle.anchors.topMargin + conversationLayout.spacing
                            color: JamiTheme.globalIslandColor

                            Text {
                                id: sectionTitle

                                readonly property rect glyphBounds: titleFontMetrics.tightBoundingRect(text)

                                anchors.left: parent.left
                                anchors.leftMargin: 16
                                anchors.top: parent.top
                                anchors.topMargin: parent.section === "true" ? conversationLayout.spacing : 0

                                text: parent.section === "true" ? JamiStrings.feedInvitations : JamiStrings.feeds
                                font.pointSize: JamiTheme.largeFontSize
                                font.weight: Font.Light
                                color: JamiTheme.textColor
                                Accessible.role: Accessible.Heading

                                FontMetrics {
                                    id: titleFontMetrics

                                    font: sectionTitle.font
                                }

                                transform: Translate {
                                    y: (sectionTitle.height - sectionTitle.glyphBounds.height) / 2 -
                                       sectionTitle.baselineOffset - sectionTitle.glyphBounds.y
                                }
                            }
                        }
                        delegate: SmartListItemDelegate {
                            showLocationIconArrow: locationIconTimer.showIconArrow

                            extraButtons.visible: conversationListView.feedSections && IsRequest
                            extraButtons.contentItem: NewIconButton {
                                id: acceptFeedInvitationButton
                                QWKSetParentHitTestVisible {}

                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter

                                iconSize: JamiTheme.iconButtonMedium
                                iconSource: JamiResources.notification_add_24dp_svg
                                toolTipText: "Subscribe"

                                background.visible: false

                                onClicked: MessagesAdapter.acceptInvitation(UID)
                            }

                            extraButtons.height: acceptFeedInvitationButton.height
                            extraButtons.width: acceptFeedInvitationButton.width
                        }
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

                                iconSource: JamiResources.ghost_line_24dp_svg
                                iconSize: JamiTheme.iconButtonExtraLarge

                                enabled: false
                            }

                            Text {
                                Layout.alignment: Qt.AlignHCenter

                                Layout.maximumWidth: conversationListRect.width - 32
                                text: ConversationsAdapter.category === ConversationListProxyModel.Feeds ? JamiStrings.noFeeds :
                                      ConversationsAdapter.invitationsOnly ? JamiStrings.noInvitations :
                                      ConversationsAdapter.category === ConversationListProxyModel.Groups ? JamiStrings.noGroupConversations :
                                      JamiStrings.noConversations
                                color: JamiTheme.textColor
                                elide: Text.ElideRight
                                wrapMode: Text.WordWrap

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
                                visible: !ConversationsAdapter.invitationsOnly &&
                                         (ConversationsAdapter.category === ConversationListProxyModel.All ||
                                          ConversationsAdapter.category === ConversationListProxyModel.OneToOne)

                                onClicked: {
                                    contactSearchBar.forceActiveFocus();
                                }
                            }
                        }
                    }
                }

                ScrollFadeGradient {
                    id: gradientRectTop

                    flickable: conversationListView
                    atTop: true

                    anchors.top: conversationLayout.top
                    anchors.topMargin: header.height + JamiTheme.sidePanelConversationsIslandTopPadding + 10 + (sidePanelTabBar.visible ? sidePanelTabBar.height : 0) + (JamiQmlUtils.isMacOS26OrLater ? JamiTheme.sidePanelTopPaddingMac : 0)

                    width: conversationLayout.width
                    z: conversationLayout.z + 1
                }

                ScrollFadeGradient {
                    id: gradientRect

                    flickable: conversationListView

                    anchors.bottom: conversationLayout.bottom
                    anchors.bottomMargin: -1

                    width: conversationLayout.width

                    bottomRightRadius: JamiTheme.avatarBasedRadius
                    bottomLeftRadius: JamiTheme.avatarBasedRadius

                    z: conversationLayout.z + 1
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

            popupX: sipPanelButton.x - sipInputPanelPopUp.width / 2 - 10
            popupY: sipPanelButton.y + sipPanelButton.height + 24
            shown: false

            onDigitPressed: {
                contactSearchBar.textContent += digit;
            }
        }
    }
}
