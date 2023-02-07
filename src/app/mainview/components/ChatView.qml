/*
 * Copyright (C) 2020-2023 Savoir-faire Linux Inc.
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
import net.jami.Enums 1.1
import net.jami.Constants 1.1

import "../../commoncomponents"
import "../js/pluginhandlerpickercreation.js" as PluginHandlerPickerCreation

Rectangle {
    id: root

    property bool allMessagesLoaded
    property var mapPositions: PositionManager.mapStatus
    property var inCallView: false

    property int lastContentsSplitSize: JamiTheme.detailsPageMinWidth
    property int lastDetailsSplitSize: JamiTheme.detailsPageMinWidth
    property int previousWidth: width

    signal needToHideConversationInCall
    signal messagesCleared
    signal messagesLoaded

    onInCallViewChanged: {
        notificationArea.visible = CurrentConversation.activeCalls.length > 0 && !root.inCallView
    }

    onVisibleChanged: {
        if (visible)
            return
        UtilsAdapter.clearInteractionsCache(CurrentAccount.id, CurrentConversation.id)
    }

    function focusChatView() {
        chatViewFooter.textInput.forceActiveFocus()
        addMemberPanel.visible = false
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

    color: JamiTheme.chatviewBgColor

    property string currentConvId: CurrentConversation.id

    HostPopup {
        id: hostPopup
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
            Layout.minimumWidth: JamiTheme.chatViewHeaderMinimumWidth

            DropArea {
                anchors.fill: parent
                onDropped: chatViewFooter.setFilePathsToSend(drop.urls)
            }

            onBackClicked: {
                mainView.showWelcomeView()
            }

            onNeedToHideConversationInCall: {
                root.needToHideConversationInCall()
            }

            onShowDetailsClicked: {
                addMemberPanel.visible = false
                if (swarmDetailsPanel.visible) {
                    chatContents.visible = true
                } else {
                    if (chatViewHeader.width - JamiTheme.detailsPageMinWidth < JamiTheme.chatViewHeaderMinimumWidth)
                        chatContents.visible = false
                }
                swarmDetailsPanel.visible = !swarmDetailsPanel.visible
            }

            onWidthChanged: {
                var isExpanding = previousWidth < width

                if (!swarmDetailsPanel.visible && !addMemberPanel.visible)
                    return

                if (chatViewHeader.width < JamiTheme.detailsPageMinWidth + JamiTheme.chatViewHeaderMinimumWidth
                    && !isExpanding && chatContents.visible) {
                    lastContentsSplitSize = chatContents.width
                    lastDetailsSplitSize = swarmDetailsPanel.visible ? swarmDetailsPanel.width : addMemberPanel.width
                    chatContents.visible = false
                } else if (chatViewHeader.width >= JamiTheme.chatViewHeaderMinimumWidth + lastDetailsSplitSize
                         && isExpanding && !layoutManager.isFullScreen && !chatContents.visible) {
                    chatContents.visible = true
                }
                previousWidth = width
            }

            Connections {
                target: CurrentConversation

                function onUrisChanged(uris) {
                    if (CurrentConversation.uris.length >= 8 && addMemberPanel.visible) {
                        swarmDetailsPanel.visible = false
                        addMemberPanel.visible = !addMemberPanel.visible
                    }
                }

                function onNeedsHost() {
                    hostPopup.open()
                }
            }

            onAddToConversationClicked: {
                swarmDetailsPanel.visible = false
                if (addMemberPanel.visible) {
                    chatContents.visible = true
                } else {
                    if (chatViewHeader.width - JamiTheme.detailsPageMinWidth < JamiTheme.chatViewHeaderMinimumWidth)
                        chatContents.visible = false
                }
                addMemberPanel.visible = !addMemberPanel.visible
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

        SplitView {
            id: chatViewMainRow
            Layout.fillWidth: true
            Layout.fillHeight: true

            handle: Rectangle {
                implicitWidth: JamiTheme.splitViewHandlePreferredWidth
                implicitHeight: splitView.height
                color: JamiTheme.primaryBackgroundColor
                Rectangle {
                    implicitWidth: 1
                    implicitHeight: splitView.height
                    color: JamiTheme.tabbarBorderColor
                }
            }

            ColumnLayout {
                id: chatContents
                SplitView.maximumWidth: splitView.width
                SplitView.minimumWidth: JamiTheme.chatViewHeaderMinimumWidth

                SplitView.preferredWidth: chatViewHeader.width -
                                          (swarmDetailsPanel.visible ? swarmDetailsPanel.width :
                                            ( addMemberPanel.visible ? addMemberPanel.width : 0))

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

            SwarmDetailsPanel {
                id: swarmDetailsPanel

                property bool isCompleted: false
                Component.onCompleted: {
                    isCompleted = true
                    visible = UtilsAdapter.getAppValue(Settings.SwarmDetailsPanelState)
                }
                onVisibleChanged: {
                    if (isCompleted)
                        UtilsAdapter.setAppValue(Settings.SwarmDetailsPanelState, visible)
                }
                SplitView.maximumWidth: splitView.width
                SplitView.preferredWidth: JamiTheme.detailsPageMinWidth
                SplitView.minimumWidth: JamiTheme.detailsPageMinWidth
            }

            AddMemberPanel {
                id: addMemberPanel
                visible: false

                SplitView.maximumWidth: splitView.width
                SplitView.preferredWidth: JamiTheme.detailsPageMinWidth
                SplitView.minimumWidth: JamiTheme.detailsPageMinWidth
            }
        }
    }
}
