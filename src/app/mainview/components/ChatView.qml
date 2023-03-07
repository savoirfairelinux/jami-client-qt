/*
 * Copyright (C) 2020-2022 Savoir-faire Linux Inc.
 * Author: Mingrui Zhang <mingrui.zhang@savoirfairelinux.com>
 * Author: Trevor Tabah <trevor.tabah@savoirfairelinux.com>
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
import Qt5Compat.GraphicalEffects

import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import net.jami.Enums 1.1

import "../../commoncomponents"
import "../js/pluginhandlerpickercreation.js" as PluginHandlerPickerCreation

Rectangle {
    id: root

    color: JamiTheme.chatviewBgColor

    // An enum to make the details panels more readable.
    enum Panel {
        MessagesResearchPanel,
        SwarmDetailsPanel,
        AddMemberPanel
    }

    property var mapPositions: PositionManager.mapStatus

    required property bool inCallView

    signal dismiss

    function focusChatView() {
        chatViewFooter.updateMessageDraft()
        chatViewFooter.textInput.forceActiveFocus()
    }

    function resetPanels() {
        chatViewHeader.showSearch = true
    }

    function instanceMapObject() {
        if (WITH_WEBENGINE) {
            var component = Qt.createComponent("qrc:/webengine/map/MapPosition.qml");
            var sprite = component.createObject(root, {maxWidth: root.width, maxHeight: root.height});

            if (sprite === null) {
                // Error Handling
                console.log("Error creating object");
            }
        }
    }

    Connections {
        target: PositionManager
        function onOpenNewMap() {
            instanceMapObject()
        }
    }

    Connections {
        target: CurrentConversation
        function onIdChanged() {
            saveLayout()
            MessagesAdapter.loadMoreMessages()
        }
    }

    Component.onCompleted: restoreLayout()

    function restoreLayout() {
        const detailsIndex = UtilsAdapter.getAppValue(Settings.DetailsIndex)
        if (detailsIndex === -1)
            detailsLayout.closePanel()
        else
            detailsLayout.switchToPanel(detailsIndex)
        print("RESET", detailsIndex)
    }

    function saveLayout() {
        print("SAVE", detailsLayout.currentIndex)
        UtilsAdapter.setAppValue(Settings.DetailsIndex, detailsLayout.currentIndex)
    }

    onVisibleChanged: {
        if (visible) {
            chatViewMainRow.resolvePanes()
            chatViewHeader.showSearch = !root.parent.showDetails
            if (root.parent.showDetails) {
                detailsLayout.switchToPanel(ChatView.SwarmDetailsPanel)
            } else {
                detailsLayout.closePanel()
            }
        } else {
            saveLayout()
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
            onShowDetailsClicked: detailsLayout.switchToPanel(ChatView.SwarmDetailsPanel)
            onSearchClicked: detailsLayout.switchToPanel(ChatView.MessagesResearchPanel)
            onAddToConversationClicked: detailsLayout.switchToPanel(ChatView.AddMemberPanel)

            Connections {
                target: CurrentConversation

                function onNeedsHost() {
                    viewCoordinator.presentDialog(
                                appWindow,
                                "mainview/components/HostPopup.qml")
                }
            }

            onPluginSelector: {
                // Create plugin handler picker - PLUGINS
                PluginHandlerPickerCreation.createPluginHandlerPickerObjects(
                            root, false)
                PluginHandlerPickerCreation.calculateCurrentGeo(root.width / 2,
                                                                root.height / 2)
                PluginHandlerPickerCreation.openPluginHandlerPicker()
            }
        }

        Connections {
            target: CurrentConversation
            enabled: true

            function onActiveCallsChanged() {
                if (CurrentConversation.activeCalls.length > 0) {
                    notificationArea.id = CurrentConversation.activeCalls[0]["id"]
                    notificationArea.uri = CurrentConversation.activeCalls[0]["uri"]
                    notificationArea.device = CurrentConversation.activeCalls[0]["device"]
                }
                notificationArea.visible = CurrentConversation.activeCalls.length > 0 && !root.inCallView
            }

            function onErrorsChanged() {
                if (CurrentConversation.errors.length > 0) {
                    errorRect.errorLabel.text = CurrentConversation.errors[0]
                    errorRect.backendErrorToolTip.text = JamiStrings.backendError.arg(CurrentConversation.backendErrors[0])
                }
                errorRect.visible = CurrentConversation.errors.length > 0 // If too much noise: && LRCInstance.debugMode()
            }
        }

        Connections {
            target: CurrentConversation
            enabled: LRCInstance.debugMode()

            function onErrorsChanged() {
                if (CurrentConversation.errors.length > 0) {
                    errorRect.errorLabel.text = CurrentConversation.errors[0]
                    errorRect.backendErrorToolTip.text = JamiStrings.backendError.arg(CurrentConversation.backendErrors[0])
                }
                errorRect.visible = CurrentConversation.errors.length > 0
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
            id: chatViewMainRow
            Layout.fillWidth: true
            Layout.fillHeight: true

            splitViewStateKey: "Chat"

            property int lastContentsSplitSize: JamiTheme.detailsPageMinWidth
            property int lastDetailsSplitSize: JamiTheme.detailsPageMinWidth
            property int previousWidth: width

            onWidthChanged: resolvePanes()
            function resolvePanes() {
                if (inCallView || !detailsLayout.visible)
                    return
                const isExpanding = previousWidth < width
                if (chatViewHeader.width < JamiTheme.detailsPageMinWidth + JamiTheme.mainViewPaneMinWidth
                        && !isExpanding && chatContents.visible) {
                    lastContentsSplitSize = chatContents.width
                    lastDetailsSplitSize = Math.min(JamiTheme.detailsPageMinWidth, detailsLayout.width)
                    chatContents.visible = false
                } else if (chatViewHeader.width >= JamiTheme.mainViewPaneMinWidth + lastDetailsSplitSize
                           && isExpanding && !layoutManager.isFullScreen && !chatContents.visible) {
                    chatContents.visible = true
                }
                previousWidth = width
            }

            ColumnLayout {
                id: chatContents
                SplitView.maximumWidth: root.width
                SplitView.minimumWidth: JamiTheme.mainViewPaneMinWidth
                SplitView.fillWidth: true

                StackLayout {
                    id: chatViewStack

                    Layout.alignment: Qt.AlignHCenter
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.topMargin: JamiTheme.chatViewHairLineSize
                    Layout.bottomMargin: JamiTheme.chatViewHairLineSize
                    Layout.leftMargin: JamiTheme.chatviewMargin
                    Layout.rightMargin: JamiTheme.chatviewMargin

                    currentIndex: CurrentConversation.isRequest ||
                                  CurrentConversation.needsSyncing

                    Loader {
                        active: CurrentConversation.id !== ""
                        sourceComponent: MessageListView {
                            DropArea {
                                anchors.fill: parent
                                onDropped: function(drop) {
                                    chatViewFooter.setFilePathsToSend(drop.urls)
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
                    visible: !CurrentConversation.isSwarm && !CurrentConversation.isTemporary && CurrentAccount.type  === Profile.Type.JAMI
                    Layout.fillWidth: true
                }

                ChatViewFooter {
                    id: chatViewFooter

                    visible: {
                        if (CurrentAccount.type  === Profile.Type.SIP)
                            return true
                        if (CurrentConversation.isBanned)
                            return false
                        else if (CurrentConversation.needsSyncing)
                            return false
                        else if (CurrentConversation.isSwarm && CurrentConversation.isRequest)
                            return false
                        return CurrentConversation.isSwarm || CurrentConversation.isTemporary
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

            StackLayout {
                id: detailsLayout

                SplitView.maximumWidth: root.width
                SplitView.minimumWidth: JamiTheme.detailsPageMinWidth
                SplitView.preferredWidth: JamiTheme.detailsPageMinWidth

                currentIndex: -1
                visible: false

                function isOpen(panel) {
                    return visible && currentIndex === panel
                }

                Connections {
                    target: CurrentConversationMembers

                    function onCountChanged() {
                        if (CurrentConversationMembers.count >= 8 && addMemberPanel.visible) {
                            detailsLayout.closePanel()
                        }
                    }
                }

                onVisibleChanged: {
                    if (visible) chatViewMainRow.resolvePanes()
                    else chatContents.visible = true
                }

                // This will open the detailsLayout panel if it's not already visible.
                // Additionally, if called while the detailsLayout panel is already visible,
                // it will hide it.
                function switchToPanel(panel) {
                    if (detailsLayout.visible) {
                        if (detailsLayout.currentIndex === panel) {
                            closePanel()
                            return
                        }
                    } else {
                        detailsLayout.visible = true
                    }
                    detailsLayout.currentIndex = panel
                }

                function closePanel() {
                    detailsLayout.currentIndex = -1
                    detailsLayout.visible = false
                }

                MessagesResearchPanel {
                    id: messagesResearchPanel
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }

                SwarmDetailsPanel {
                    id: swarmDetailsPanel
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }

                AddMemberPanel {
                    id: addMemberPanel
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }
            }
        }
    }
}
