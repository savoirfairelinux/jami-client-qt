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
    enum ExtrasPanel {
        SwarmDetailsPanel,
        MessagesResearchPanel,
        AddMemberPanel
    }

    color: JamiTheme.chatviewBgColor

    property var mapPositions: PositionManager.mapStatus

    required property bool inCallView

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

    // Used externally to determine the current state of the chat view.
    property bool extrasPanelVisible: extrasPanel.visible

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
        target: CurrentConversation
        function onIdChanged() {
            MessagesAdapter.loadMoreMessages();
        }
    }

    onVisibleChanged: {
        if (visible) {
            print("ChatView: visibleChanged: " + visible);
            chatViewSplitView.resolvePanes(true);
        }
    }

    ColumnLayout {
        anchors.fill: root

        spacing: 0

        ChatViewHeader {
            id: chatViewHeader

            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: true
            Layout.preferredHeight: JamiTheme.chatViewHeaderPreferredHeight
            Layout.maximumHeight: JamiTheme.chatViewHeaderPreferredHeight
            Layout.minimumWidth: JamiTheme.mainViewPaneMinWidth

            DropArea {
                anchors.fill: parent
                onDropped: chatViewFooter.setFilePathsToSend(drop.urls)
            }

            onBackClicked: root.dismiss()

            Connections {
                target: CurrentConversation

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
            objectName: "ChatViewSplitView"

            Layout.fillWidth: true
            Layout.fillHeight: true

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
                if (extrasPanelWidth != 0 && extrasPanelWidth != width) {
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
                console.debug("ChatViewSplitView.resolvePanes: f: %1 w: %2 pw: %3 epw: %4 pepw: %5 ie: %6"
                              .arg(force).arg(width).arg(previousWidth)
                              .arg(extrasPanelWidth).arg(previousExtrasPanelWidth).arg(isExpanding));

                const maximizePredicate = (!isExpanding || force) && chatContents.visible;
                const minimizePredicate = (isExpanding || force) && !chatContents.visible;
                const mainViewMinWidth = JamiTheme.mainViewPaneMinWidth;

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
                SplitView.maximumWidth: root.width
                SplitView.minimumWidth: JamiTheme.mainViewPaneMinWidth
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

                    onHeightChanged: {
                        if (loader.item != null) {
                            Qt.callLater(loader.item.scrollToBottom);
                        }
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

                SplitView.maximumWidth: root.width
                SplitView.minimumWidth: JamiTheme.extrasPanelMinWidth
                SplitView.preferredWidth: JamiTheme.extrasPanelMinWidth
            }
        }
    }
}
