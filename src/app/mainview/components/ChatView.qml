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
import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import net.jami.Enums 1.1
import "../../commoncomponents"
import "../js/pluginhandlerpickercreation.js" as PluginHandlerPickerCreation

Rectangle {
    id: root

    // HACK: Added to capture the mouse when the layouts start stacking.
    // The header and footer we're unable to be interacted with otherwise.
    MouseArea {
        anchors.fill: parent
        propagateComposedEvents: false
        enabled: viewCoordinator.isInSinglePaneMode
    }

    // An enum to make the details panels more readable.
    enum ExtrasPanel {
        SwarmDetailsPanel,
        MessagesResearchPanel,
        AddMemberPanel
    }

    color: JamiTheme.globalBackgroundColor

    property var mapPositions: PositionManager.mapStatus
    property bool isConversationEndedFlag: false

    // The purpose of this alias is to make the message bar
    // accessible to the EmojiPicker
    property alias messageBar: chatViewFooter.messageBar

    required property bool inCallView

    // Hide the extrasPanel when going into a call view, but save the previous
    // state to restore it when leaving the call view.
    property int chatExtrasPanelIndex: extrasPanel.currentIndex
    onInCallViewChanged: {
        if (inCallView) {
            chatExtrasPanelIndex = extrasPanel.currentIndex;
            extrasPanel.closePanel();
        } else if (chatExtrasPanelIndex >= 0) {
            extrasPanel.openPanel(chatExtrasPanelIndex);
        }
    }

    signal dismiss

    function focusChatView() {
        chatViewFooter.updateMessageDraft();
        chatViewFooter.textInput.forceActiveFocus();
    }

    function instanceMapObject() {
        if (WITH_WEBENGINE) {
            var component = Qt.createComponent("qrc:/webengine/map/MapPosition.qml");
            var sprite = component.createObject(root, {
                    "maxWidth": root.width,
                    "maxHeight": root.height
                });
            if (sprite === null) {
                // Error Handling
                console.log("Error creating object");
            }
        }
    }

    function isConversationEnded() {
        if (!CurrentConversation.isSwarm)
            return false;
        var myRole = UtilsAdapter.getParticipantRole(CurrentAccount.id, CurrentConversation.id, CurrentAccount.uri);
        var info = ConversationsAdapter.getConvInfoMap(CurrentConversation.id);
        var peers = info && info.uris ? info.uris : [];
        peers = peers.filter(function(u) { return u !== CurrentAccount.uri; });
        for (var i = 0; i < peers.length; i++) {
            var role = UtilsAdapter.getParticipantRole(CurrentAccount.id, CurrentConversation.id, peers[i]);
            if (!(role === Member.Role.LEFT || role === Member.Role.BANNED)) {
                return false;
            }
        }
        if (CurrentConversation.isCoreDialog) {
            // Check if a conversation with oneself has been removed
            const peerRole = UtilsAdapter.getParticipantRole(CurrentAccount.id, CurrentConversation.id, peers[0]);
            return peerRole === Member.Role.LEFT;
        }
        return myRole !== Member.Role.ADMIN;
    }

    function updateConversationEndedFlag() {
        var newVal = isConversationEnded();
        if (isConversationEndedFlag !== newVal) {
            isConversationEndedFlag = newVal;
        }
    }

    // Used externally to switch to a extras panel.
    function switchToPanel(panel, toggle = true) {
        extrasPanel.switchToPanel(panel, toggle);
    }

    // Used externally to close the extras panel.
    function closePanel() {
        extrasPanel.closePanel();
    }

    Connections {
        target: PositionManager
        function onOpenNewMap() {
            instanceMapObject();
        }
    }

    Connections {
        target: LRCInstance
        function onConversationUpdated(convId, accountId) {
            if (convId === CurrentConversation.id) {
                updateConversationEndedFlag();
            }
        }
    }
    Connections {
        target: CurrentConversation.members
        function onCountChanged() {
            updateConversationEndedFlag();
        }
    }

    Connections {
        target: CurrentConversation
        function onIdChanged() {
            MessagesAdapter.loadMoreMessages();
            updateConversationEndedFlag();
        }
    }

    onVisibleChanged: {
        if (visible) {
            chatViewSplitView.resolvePanes(true);
            Qt.callLater(updateConversationEndedFlag);
        }
    }

    ColumnLayout {
        anchors.fill: root

        spacing: 0

        Connections {
            target: CallAdapter

            property CallEndedWithErrorPopup popup: CallEndedWithErrorPopup {
                id: callEndedWithErrorPopup
            }

            function onCallEndedWithError(errorCode) {
                popup.showSIPCallStatusError(errorCode);
            }
        }

        ChatViewHeader {
            id: chatViewHeader
            objectName: "chatViewHeader"
            z: 3

            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: true
            Layout.preferredHeight: JamiTheme.qwkTitleBarHeight
            Layout.maximumHeight: JamiTheme.qwkTitleBarHeight
            Layout.minimumWidth: JamiTheme.mainViewMajorPaneMinWidth

            DropArea {
                anchors.fill: parent
                onDropped: chatViewFooter.setFilePathsToSend(drop.urls)
            }

            onBackClicked: root.dismiss()

            Connections {
                target: CurrentConversation

                function onIdChanged() {
                    if (!chatViewHeader.detailsButtonVisibility) {
                        extrasPanel.closePanel();
                    } else if (width < JamiTheme.mainViewMinWidth + extrasPanel.width) {
                        extrasPanel.closePanel();
                    } else if (!chatViewHeader.interactionButtonsVisibility) {
                        extrasPanel.closePanel();
                    }
                }

                function onNeedsHost() {
                    viewCoordinator.presentDialog(appWindow, "mainview/components/HostPopup.qml");
                }
            }

            onPluginSelector: {
                // Create plugin handler picker - PLUGINS
                PluginHandlerPickerCreation.createPluginHandlerPickerObjects(root, false);
                PluginHandlerPickerCreation.calculateCurrentGeo(root.width / 2, root.height / 2);
                PluginHandlerPickerCreation.openPluginHandlerPicker();
            }
        }

        Connections {
            target: CurrentConversation
            enabled: true

            function onActiveCallsChanged() {
                if (CurrentConversation.activeCalls.length > 0)
                // temp update calldropdownmenu
                {
                }
            }

            function onErrorsChanged() {
                if (CurrentConversation.errors.length > 0) {
                    errorRect.errorLabel.text = CurrentConversation.errors[0];
                    errorRect.backendErrorToolTip.text = JamiStrings.backendError.arg(CurrentConversation.backendErrors[0]);
                }
                errorRect.visible = CurrentConversation.errors.length > 0; // If too much noise: && LRCInstance.debugMode()
            }
        }

        Connections {
            target: CurrentConversation
            enabled: LRCInstance.debugMode()

            function onErrorsChanged() {
                if (CurrentConversation.errors.length > 0) {
                    errorRect.errorLabel.text = CurrentConversation.errors[0];
                    errorRect.backendErrorToolTip.text = JamiStrings.backendError.arg(CurrentConversation.backendErrors[0]);
                }
                errorRect.visible = CurrentConversation.errors.length > 0;
            }
        }

        ConversationErrorsRow {
            id: errorRect
            Layout.fillWidth: true
            Layout.preferredHeight: JamiTheme.qwkTitleBarHeight
            visible: false
        }

        Control {
            id: conversationEndedBanner
            Layout.fillWidth: true
            visible: isConversationEndedFlag

            padding: 10
            background: Rectangle {
                color: JamiTheme.infoRectangleColor
                radius: 5
            }
            contentItem: RowLayout {
                spacing: 8
                Label {
                    text: JamiStrings.conversationEnded
                    color: JamiTheme.textColor
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                    Layout.alignment: Qt.AlignHCenter
                    Layout.fillWidth: true
                }
            }
        }

        JamiSplitView {
            id: chatViewSplitView
            objectName: "ChatViewSplitView"

            Layout.fillWidth: true
            Layout.fillHeight: true

            handleOnMinor: true

            property real previousWidth: width
            onWidthChanged: {
                resolvePanes();
                // Track the previous width of the split view.
                previousWidth = width;
            }

            // Track the previous width of the split view.
            property real extrasPanelWidth: extrasPanel.width
            // The previousExtrasPanelWidth is initialized to the minimum width
            // of the extras panel. The value is updated within the "open"-state
            // range of the panel (e.g. not 0 or maximized).
            property real previousExtrasPanelWidth: JamiTheme.extrasPanelMinWidth
            onExtrasPanelWidthChanged: {
                resolvePanes();
                // This range should ensure that the panel won't restore to maximized.
                if (extrasPanelWidth !== 0 && extrasPanelWidth !== this.width) {
                    console.debug("Saving previous extras panel width: %1".arg(extrasPanelWidth));
                    previousExtrasPanelWidth = extrasPanelWidth;
                }
            }

            // Respond to visibility changes for the extras panel in order to
            // determine the structure of the split view.
            property bool extrasPanelVisible: extrasPanel.visible
            onExtrasPanelVisibleChanged: {
                if (extrasPanelVisible) {
                    extrasPanelWidth = previousExtrasPanelWidth;
                } else {
                    previousExtrasPanelWidth = extrasPanelWidth;
                }
                resolvePanes();
            }

            function resolvePanes(force = false) {
                if (!viewNode.visible) {
                    return;
                }

                // If the details panel is not visible, then show the chatContents.
                if (!extrasPanel.visible) {
                    chatContents.visible = true;
                    return;
                }
                const isExpanding = width > previousWidth;

                // Provide a detailed log here, as this function seems problematic.
                const maximizePredicate = (!isExpanding || force) && chatContents.visible;
                const minimizePredicate = (isExpanding || force) && !chatContents.visible;
                const mainViewMinWidth = JamiTheme.mainViewMajorPaneMinWidth;

                // If the SplitView is not wide enough to show both the chatContents
                // and the details panel, then hide the chatContents.
                if (maximizePredicate && width < mainViewMinWidth + extrasPanelWidth) {
                    chatContents.visible = false;
                } else if (minimizePredicate && width >= mainViewMinWidth + previousExtrasPanelWidth) {
                    chatContents.visible = true;
                }
            }

            ColumnLayout {
                id: chatContents
                property bool isMinorPane: true
                SplitView.maximumWidth: root.width
                SplitView.minimumWidth: JamiTheme.mainViewMajorPaneMinWidth
                SplitView.fillWidth: true
                spacing: 0

                StackLayout {
                    id: chatViewStack

                    LayoutMirroring.enabled: false
                    LayoutMirroring.childrenInherit: true

                    Layout.alignment: Qt.AlignHCenter
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.topMargin: JamiTheme.chatViewHairLineSize
                    Layout.bottomMargin: JamiTheme.chatViewHairLineSize
                    Layout.leftMargin: JamiTheme.chatviewMargin
                    Layout.rightMargin: JamiTheme.chatviewMargin

                    currentIndex: CurrentConversation.isRequest || CurrentConversation.needsSyncing

                    Loader {
                        id: loader
                        active: CurrentConversation.id !== ""
                        sourceComponent: MessageListView {
                            DropArea {
                                anchors.fill: parent
                                onDropped: function (drop) {
                                    chatViewFooter.setFilePathsToSend(drop.urls);
                                }
                            }
                        }
                    }

                    InvitationView {
                        id: invitationView

                        Layout.fillWidth: true
                        Layout.fillHeight: true
                    }
                }

                UpdateToSwarm {
                    visible: !CurrentConversation.isSwarm && !CurrentConversation.isTemporary && CurrentAccount.type === Profile.Type.JAMI
                    Layout.fillWidth: true
                }

                ChatViewFooter {
                    id: chatViewFooter
                    objectName: "chatViewFooter"

                    visible: {
                        if (CurrentAccount.type === Profile.Type.SIP)
                            return true;
                        if (CurrentConversation.isBanned)
                            return false;
                        else if (CurrentConversation.needsSyncing)
                            return false;
                        else if (CurrentConversation.isRequest)
                            return false;
                        else if (isConversationEndedFlag)
                            return false;
                        return CurrentConversation.isSwarm || CurrentConversation.isTemporary;
                    }

                    onHeightChanged: {
                        if (loader.item)
                            Qt.callLater(loader.item.scrollToBottom);
                    }

                    Layout.alignment: Qt.AlignHCenter
                    Layout.fillWidth: true
                    Layout.preferredHeight: implicitHeight
                    Layout.maximumHeight: JamiTheme.chatViewFooterMaximumHeight

                    DropArea {
                        anchors.fill: parent
                        onDropped: chatViewFooter.setFilePathsToSend(drop.urls)
                    }
                }
            }

            ConversationExtrasPanel {
                id: extrasPanel
                property bool isMinorPane: false

                SplitView.maximumWidth: root.width
                SplitView.minimumWidth: JamiTheme.extrasPanelMinWidth
                SplitView.preferredWidth: JamiTheme.extrasPanelMinWidth
            }
        }
    }
}
