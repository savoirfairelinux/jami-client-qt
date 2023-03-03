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

import "../../commoncomponents"
import "../js/pluginhandlerpickercreation.js" as PluginHandlerPickerCreation

Rectangle {
    id: root

    color: JamiTheme.chatviewBgColor

    property var mapPositions: PositionManager.mapStatus
    property var currenctConvId: CurrentConversation.id

    property int lastContentsSplitSize: JamiTheme.detailsPageMinWidth
    property int lastDetailsSplitSize: JamiTheme.detailsPageMinWidth
    property int previousWidth: width
    required property bool inCallView

    signal dismiss

    function focusChatView() {
        chatViewFooter.updateMessageDraft()
        chatViewFooter.textInput.forceActiveFocus()
    }

    function resetPanels() {
        chatViewHeader.showSearch = true
        swarmDetailsPanel.visible = false
        addMemberPanel.visible = false
        chatContents.visible = true
        messagesResearchPanel.visible = false
    }

    function instanceMapObject() {
        if (WITH_WEBENGINE) {
            var component = Qt.createComponent("qrc:/webengine/map/MapPosition.qml");
            var sprite = component.createObject(chatContents, {maxWidth: root.width, maxHeight: root.height});

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
            MessagesAdapter.loadMoreMessages()
        }
    }

    onVisibleChanged: {
        if (visible){
            chatViewHeader.showSearch = !root.parent.showDetails
            addMemberPanel.visible = false
            messagesResearchPanel.visible = false
            if (root.parent.showDetails) {
                chatContents.visible = false
                swarmDetailsPanel.visible = true
            } else {
                chatContents.visible = true
                swarmDetailsPanel.visible = false
            }
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
        onTriggered: {showIconArrow = !showIconArrow}
    }

    Connections {
        target: PositionManager

        function onsharingLocationUrisCountChanged () {
            listUriShared.updateList()
        }

        function onPositionShareConvIdsCountChanged () {
            listUriShared.updateList()
        }
    }

    onCurrenctConvIdChanged: {
        listUriShared.updateList()
    }

    ListModel {
        id: listUriShared

        property var uriList: []
        property var index
        property bool localSharing: false
        property bool sharing: false

        function updateList(){
            listUriShared.clear();
            listUriShare.clear();
            localSharing = false
            sharing = false

            if(PositionManager.isPositionSharedToConv(CurrentAccount.id, CurrentConversation.id)){
                listUriShare.append({"uri":CurrentAccount.uri});
                localSharing = true
            }

            if(PositionManager.isConvSharingPosition(CurrentAccount.id, CurrentConversation.id)){
                sharing = true
            }

            var length = PositionManager.getListSharingUris().length;
            uriList = PositionManager.getListSharingUris();

            for (var i = 0; i < length ; i++){
                listUriShared.append({"uri":uriList[i]});
            }

        }

    }

    ListModel {
        id: listUriShare
    }

    ColumnLayout {
        anchors.fill: root

        spacing: 0

        ChatViewHeader {
            id: chatViewHeader

            property var locationAreaObject

            imSharing: listUriShared.localSharing
            areSharing: listUriShared.sharing

            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: true
            Layout.preferredHeight: JamiTheme.chatViewHeaderPreferredHeight
            Layout.maximumHeight: JamiTheme.chatViewHeaderPreferredHeight
            Layout.minimumWidth: JamiTheme.chatViewHeaderMinimumWidth

            DropArea {
                anchors.fill: parent
                onDropped: chatViewFooter.setFilePathsToSend(drop.urls)
            }

            onBackClicked: root.dismiss()

            signal panelsVisibilityChange()

            onPanelsVisibilityChange: {
                if (!swarmDetailsPanel.visible && !messagesResearchPanel.visible) {
                    chatContents.visible = true
                } else {
                    if (chatViewHeader.width - JamiTheme.detailsPageMinWidth < JamiTheme.chatViewHeaderMinimumWidth)
                        chatContents.visible = false
                }
            }

            onDetailLocationButtonClicked: {
                if (locationAreaContainer2.visible)
                    locationAreaContainer2.visible = false
                locationAreaContainer.visible = true

            }

            onDetailLocationButtonClicked2: {
                if (locationAreaContainer.visible)
                    locationAreaContainer.visible = false
                locationAreaContainer2.visible = true
            }

            onShowDetailsClicked: {
                addMemberPanel.visible = false
                messagesResearchPanel.visible = false
                swarmDetailsPanel.visible = !swarmDetailsPanel.visible
                panelsVisibilityChange()
            }

            onSearchBarOpened: {
                addMemberPanel.visible = false
                swarmDetailsPanel.visible = false
                messagesResearchPanel.visible = true
                panelsVisibilityChange()
            }

            onSearchBarClosed: {
                chatContents.visible = true
                messagesResearchPanel.visible = false
                panelsVisibilityChange()
            }

            onWidthChanged: {
                if (inCallView)
                    return
                const isExpanding = previousWidth < width

                if (!swarmDetailsPanel.visible && !addMemberPanel.visible && !messagesResearchPanel.visible)
                    return
                if (chatViewHeader.width < JamiTheme.detailsPageMinWidth + JamiTheme.chatViewHeaderMinimumWidth
                        && !isExpanding && chatContents.visible) {
                    lastContentsSplitSize = chatContents.width
                    lastDetailsSplitSize = Math.min(JamiTheme.detailsPageMinWidth, (swarmDetailsPanel.visible
                                                                                    ? swarmDetailsPanel.width
                                                                                    : addMemberPanel.visible
                                                                                    ? addMemberPanel.width
                                                                                    : messagesResearchPanel.width))
                    chatContents.visible = false
                } else if (chatViewHeader.width >= JamiTheme.chatViewHeaderMinimumWidth + lastDetailsSplitSize
                           && isExpanding && !layoutManager.isFullScreen && !chatContents.visible) {
                    chatContents.visible = true
                }
                previousWidth = width
            }

            Connections {
                target: CurrentConversation

                function onNeedsHost() {
                    viewCoordinator.presentDialog(
                                appWindow,
                                "mainview/components/HostPopup.qml")
                }
            }

            Connections {
                target: CurrentConversationMembers

                function onCountChanged() {
                    if (CurrentConversationMembers.count >= 8 && addMemberPanel.visible) {
                        swarmDetailsPanel.visible = false
                        addMemberPanel.visible = !addMemberPanel.visible
                    }
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
                implicitHeight: viewCoordinator.splitView.height
                color: JamiTheme.primaryBackgroundColor
                Rectangle {
                    implicitWidth: 1
                    implicitHeight: viewCoordinator.splitView.height
                    color: JamiTheme.tabbarBorderColor
                }
            }

            ColumnLayout {
                id: chatContents
                SplitView.maximumWidth: viewCoordinator.splitView.width
                SplitView.minimumWidth: JamiTheme.chatViewHeaderMinimumWidth
                SplitView.fillWidth: true

                Rectangle {
                    id: locationAreaContainer2
                    visible: false
                    Layout.preferredHeight: Math.min(childrenRect.height,200)
                    Layout.fillWidth: true

                    ListView {
                        width: parent.width
                        height: contentHeight
                        model: listUriShared
                        delegate: LocationArea {}
                    }

                }

                Rectangle {
                    id: locationAreaContainer
                    visible: false
                    Layout.preferredHeight: Math.min(childrenRect.height,200)
                    Layout.fillWidth: true

                    ListView {
                        width: parent.width
                        height: contentHeight
                        model: listUriShare
                        delegate: LocationArea {}
                    }

                }


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

            MessagesResearchPanel {
                id: messagesResearchPanel

                visible: false
                SplitView.maximumWidth: viewCoordinator.splitView.width
                SplitView.minimumWidth: JamiTheme.detailsPageMinWidth
                SplitView.preferredWidth: JamiTheme.detailsPageMinWidth
            }

            SwarmDetailsPanel {
                id: swarmDetailsPanel
                visible: false

                SplitView.maximumWidth: viewCoordinator.splitView.width
                SplitView.preferredWidth: JamiTheme.detailsPageMinWidth
                SplitView.minimumWidth: JamiTheme.detailsPageMinWidth
            }

            AddMemberPanel {
                id: addMemberPanel
                visible: false

                SplitView.maximumWidth: viewCoordinator.splitView.width
                SplitView.preferredWidth: JamiTheme.detailsPageMinWidth
                SplitView.minimumWidth: JamiTheme.detailsPageMinWidth
            }
        }
    }
}
