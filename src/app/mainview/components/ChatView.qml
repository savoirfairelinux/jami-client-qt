/*
 * Copyright (C) 2020-2023 Savoir-faire Linux Inc.
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

    // An enum to make the details panels more readable.
    enum Panel {
        SwarmDetailsPanel,
        MessagesResearchPanel,
        AddMemberPanel
    }

    required property bool inCallView
    property var mapPositions: PositionManager.mapStatus

    color: JamiTheme.chatviewBgColor

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
    function resetPanels() {
        chatViewHeader.showSearch = true;
    }

    Component.onCompleted: extrasPanel.restoreState()
    onVisibleChanged: {
        if (visible) {
            chatViewSplitView.resolvePanes(true);
            if (root.parent.objectName === "CallViewChatViewContainer") {
                chatViewHeader.showSearch = !root.parent.showDetails;
                if (root.parent.showDetails) {
                    extrasPanel.switchToPanel(ChatView.SwarmDetailsPanel);
                } else {
                    extrasPanel.closePanel();
                }
            }
        }
    }

    Connections {
        target: PositionManager

        function onOpenNewMap() {
            instanceMapObject();
        }
    }
    Connections {
        target: CurrentConversation

        function onIdChanged() {
            extrasPanel.restoreState();
            MessagesAdapter.loadMoreMessages();
        }
    }
    ColumnLayout {
        anchors.fill: root
        spacing: 0

        ChatViewHeader {
            id: chatViewHeader
            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: true
            Layout.maximumHeight: JamiTheme.chatViewHeaderPreferredHeight
            Layout.minimumWidth: JamiTheme.mainViewPaneMinWidth
            Layout.preferredHeight: JamiTheme.chatViewHeaderPreferredHeight

            onAddToConversationClicked: extrasPanel.switchToPanel(ChatView.AddMemberPanel)
            onBackClicked: root.dismiss()
            onPluginSelector: {
                // Create plugin handler picker - PLUGINS
                PluginHandlerPickerCreation.createPluginHandlerPickerObjects(root, false);
                PluginHandlerPickerCreation.calculateCurrentGeo(root.width / 2, root.height / 2);
                PluginHandlerPickerCreation.openPluginHandlerPicker();
            }
            onSearchClicked: extrasPanel.switchToPanel(ChatView.MessagesResearchPanel)
            onShowDetailsClicked: extrasPanel.switchToPanel(ChatView.SwarmDetailsPanel)

            DropArea {
                anchors.fill: parent

                onDropped: chatViewFooter.setFilePathsToSend(drop.urls)
            }
            Connections {
                target: CurrentConversation

                function onNeedsHost() {
                    viewCoordinator.presentDialog(appWindow, "mainview/components/HostPopup.qml");
                }
            }
        }
        Connections {
            enabled: true
            target: CurrentConversation

            function onActiveCallsChanged() {
                if (CurrentConversation.activeCalls.length > 0) {
                    notificationArea.id = CurrentConversation.activeCalls[0]["id"];
                    notificationArea.uri = CurrentConversation.activeCalls[0]["uri"];
                    notificationArea.device = CurrentConversation.activeCalls[0]["device"];
                }
                notificationArea.visible = CurrentConversation.activeCalls.length > 0 && !root.inCallView;
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
            enabled: LRCInstance.debugMode()
            target: CurrentConversation

            function onErrorsChanged() {
                if (CurrentConversation.errors.length > 0) {
                    errorRect.errorLabel.text = CurrentConversation.errors[0];
                    errorRect.backendErrorToolTip.text = JamiStrings.backendError.arg(CurrentConversation.backendErrors[0]);
                }
                errorRect.visible = CurrentConversation.errors.length > 0;
            }
        }
        GenericErrorsRow {
            id: genericError
            Layout.fillWidth: true
            Layout.preferredHeight: JamiTheme.chatViewHeaderPreferredHeight
        }
        ConversationErrorsRow {
            id: errorRect
            Layout.fillWidth: true
            Layout.preferredHeight: JamiTheme.chatViewHeaderPreferredHeight
            visible: false
        }
        NotificationArea {
            id: notificationArea
            Layout.fillWidth: true
            Layout.preferredHeight: JamiTheme.chatViewHeaderPreferredHeight
            visible: CurrentConversation.activeCalls.length > 0 && !root.inCallView
        }
        JamiSplitView {
            id: chatViewSplitView
            property real previousDetailsWidth: extrasPanel.width
            property real previousWidth: width

            Layout.fillHeight: true
            Layout.fillWidth: true
            objectName: "ChatViewSplitView"
            splitViewStateKey: "Chat"

            // This function governs the visibility of the chatContents and tracks the
            // the width of the SplitView and the details panel. This function should be
            // called when the width of the SplitView changes, when the SplitView is shown,
            // and when the details panel is shown. When called with force=true, it is being
            // called from a visibleChanged event, and we should not update the previous widths.
            function resolvePanes(force = false) {
                // If the details panel is not visible, then show the chatContents.
                if (!extrasPanel.visible) {
                    chatContents.visible = true;
                    return;
                }

                // Next we compute whether the SplitView is expanding or shrinking.
                const isExpanding = width > previousWidth;

                // If the SplitView is not wide enough to show both the chatContents
                // and the details panel, then hide the chatContents.
                if (width < JamiTheme.mainViewPaneMinWidth + extrasPanel.width && (!isExpanding || force) && chatContents.visible) {
                    if (!force)
                        previousDetailsWidth = extrasPanel.width;
                    chatContents.visible = false;
                } else if (width >= JamiTheme.mainViewPaneMinWidth + previousDetailsWidth && (isExpanding || force) && !chatContents.visible) {
                    chatContents.visible = true;
                }
                if (!force)
                    previousWidth = width;
            }

            onResizingChanged: if (chatContents.visible)
                extrasPanel.previousWidth = extrasPanel.width
            onWidthChanged: resolvePanes()

            Connections {
                target: viewNode

                function onDismissed() {
                    chatViewSplitView.saveSplitViewState();
                }
                function onPresented() {
                    chatViewSplitView.restoreSplitViewState();
                }
            }
            ColumnLayout {
                id: chatContents
                SplitView.fillWidth: true
                SplitView.maximumWidth: root.width
                SplitView.minimumWidth: JamiTheme.mainViewPaneMinWidth

                StackLayout {
                    id: chatViewStack
                    Layout.alignment: Qt.AlignHCenter
                    Layout.bottomMargin: JamiTheme.chatViewHairLineSize
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    Layout.leftMargin: JamiTheme.chatviewMargin
                    Layout.rightMargin: JamiTheme.chatviewMargin
                    Layout.topMargin: JamiTheme.chatViewHairLineSize
                    currentIndex: CurrentConversation.isRequest || CurrentConversation.needsSyncing

                    Loader {
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
                        Layout.fillHeight: true
                        Layout.fillWidth: true
                    }
                }
                UpdateToSwarm {
                    Layout.fillWidth: true
                    visible: !CurrentConversation.isSwarm && !CurrentConversation.isTemporary && CurrentAccount.type === Profile.Type.JAMI
                }
                ChatViewFooter {
                    id: chatViewFooter
                    Layout.alignment: Qt.AlignHCenter
                    Layout.fillWidth: true
                    Layout.maximumHeight: JamiTheme.chatViewFooterMaximumHeight
                    Layout.preferredHeight: implicitHeight
                    visible: {
                        if (CurrentAccount.type === Profile.Type.SIP)
                            return true;
                        if (CurrentConversation.isBanned)
                            return false;
                        else if (CurrentConversation.needsSyncing)
                            return false;
                        else if (CurrentConversation.isSwarm && CurrentConversation.isRequest)
                            return false;
                        return CurrentConversation.isSwarm || CurrentConversation.isTemporary;
                    }

                    DropArea {
                        anchors.fill: parent

                        onDropped: chatViewFooter.setFilePathsToSend(drop.urls)
                    }
                }
            }
            ConversationExtrasPanel {
                id: extrasPanel
                property int previousWidth: JamiTheme.extrasPanelMinWidth

                SplitView.maximumWidth: root.width
                SplitView.minimumWidth: JamiTheme.extrasPanelMinWidth
                SplitView.preferredWidth: JamiTheme.extrasPanelMinWidth

                onVisibleChanged: chatViewSplitView.resolvePanes(true)
            }
        }
    }
}
