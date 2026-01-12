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
import QtQuick.Layouts
import QtQuick.Controls
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import net.jami.Enums 1.1
import net.jami.Models 1.1
import "../../commoncomponents"

Rectangle {
    id: root

    signal backClicked
    signal pluginSelector

    Connections {
        target: CurrentConversation
        enabled: true
        function onTitleChanged() {
            title.eText = CurrentConversation.title;
        }
        function onDescriptionChanged() {
            description.eText = CurrentConversation.description;
        }
        function onShowSwarmDetails() {
            extrasPanel.switchToPanel(ChatView.SwarmDetailsPanel);
        }
    }

    property bool detailsButtonVisibility: detailsButton.visible

    readonly property bool interactionButtonsVisibility: {
        if (CurrentConversation.inCall)
            return false;
        if (LRCInstance.currentAccountType === Profile.Type.SIP)
            return true;
        if (!CurrentConversation.isTemporary && !CurrentConversation.isSwarm)
            return false;
        if (CurrentConversation.isRequest || CurrentConversation.needsSyncing)
            return false;
        return true;
    }

    property bool addMemberVisibility: {
        return swarmDetailsVisibility && !CurrentConversation.isCoreDialog && !CurrentConversation.isRequest;
    }

    property bool swarmDetailsVisibility: {
        return CurrentConversation.isSwarm && !CurrentConversation.isRequest;
    }

    color: JamiTheme.globalBackgroundColor

    RowLayout {
        id: messagingHeaderRectRowLayout

        anchors.fill: parent
        // QWK: spacing
        anchors.leftMargin: layoutManager.qwkSystemButtonSpacing.left
        anchors.rightMargin: 10 + layoutManager.qwkSystemButtonSpacing.right
        spacing: 8

        JamiPushButton {
            id: backToWelcomeViewButton
            QWKSetParentHitTestVisible {}

            Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
            Layout.leftMargin: 8

            normalColor: JamiTheme.globalBackgroundColor

            mirror: UtilsAdapter.isRTL

            source: JamiResources.back_24dp_svg
            toolTipText: CurrentConversation.inCall ? JamiStrings.returnToCall : JamiStrings.hideChat

            onClicked: root.backClicked()
        }

        Avatar {
            id: userAvatar

            width: JamiTheme.iconButtonLarge
            height: JamiTheme.iconButtonLarge

            mode: CurrentConversation.isSwarm ? Avatar.Mode.Conversation : Avatar.Mode.Contact
            imageId: CurrentConversation.id
            showPresenceIndicator: false
        }

        Rectangle {
            id: userNameOrIdRect

            Layout.alignment: Qt.AlignLeft | Qt.AlignTop

            // Width + margin.
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.topMargin: 7
            Layout.bottomMargin: 7
            Layout.leftMargin: 4

            color: JamiTheme.transparentColor

            ColumnLayout {
                id: userNameOrIdColumnLayout
                QWKSetParentHitTestVisible {}
                objectName: "userNameOrIdColumnLayout"

                height: parent.height

                spacing: 0

                ElidedTextLabel {
                    id: title

                    LineEditContextMenu {
                        id: displayNameContextMenu
                        lineEditObj: title
                        selectOnly: true
                    }
                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.RightButton
                        cursorShape: Qt.IBeamCursor
                        onClicked: function (mouse) {
                            displayNameContextMenu.openMenuAt(mouse);
                        }
                    }

                    Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft

                    font.pointSize: JamiTheme.textFontSize + 2

                    horizontalAlignment: Text.AlignLeft
                    verticalAlignment: Text.AlignVCenter

                    eText: CurrentConversation.title
                    maxWidth: userNameOrIdRect.width
                }

                ElidedTextLabel {
                    id: description

                    Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft

                    visible: text.length && CurrentConversation.title !== CurrentConversation.description
                    font.pointSize: JamiTheme.textFontSize
                    color: JamiTheme.faddedLastInteractionFontColor

                    horizontalAlignment: Text.AlignLeft
                    verticalAlignment: Text.AlignVCenter
                    eText: CurrentConversation.description
                    maxWidth: userNameOrIdRect.width
                }
            }
        }

        NewIconButton {
            id: startAudioCallButton
            QWKSetParentHitTestVisible {}

            iconSize: JamiTheme.iconButtonMedium
            iconSource: JamiResources.start_audiocall_24dp_svg
            toolTipText: JamiStrings.startAudioCall

            onClicked: CallAdapter.startAudioOnlyCall()
        }

        NewIconButton {
            id: startVideoCallButton
            QWKSetParentHitTestVisible {}

            iconSize: JamiTheme.iconButtonMedium
            iconSource: JamiResources.videocam_24dp_svg
            toolTipText: JamiStrings.startAudioCall

            visible: CurrentConversation.activeCalls.length === 0 && interactionButtonsVisibility && CurrentAccount.videoEnabled_Video

            onClicked: CallAdapter.startCall()
        }

        // Custom component (DNR: DO NOT REPLACE)
        CallsButton {
            QWKSetParentHitTestVisible {}
            Layout.preferredHeight: 36
            Layout.alignment: Qt.AlignVCenter
            visible: CurrentConversation.activeCalls.length > 0 && interactionButtonsVisibility
        }

        NewIconButton {
            id: inviteMembersButton
            QWKSetParentHitTestVisible {}

            iconSize: JamiTheme.iconButtonMedium
            iconSource: JamiResources.add_people_24dp_svg
            toolTipText: JamiStrings.inviteMembers

            checkable: true
            checked: extrasPanel.isOpen(ChatView.AddMemberPanel)

            visible: interactionButtonsVisibility && addMemberVisibility

            onClicked: extrasPanel.switchToPanel(ChatView.AddMemberPanel)
        }

        NewIconButton {
            id: selectExtensionsButton
            QWKSetParentHitTestVisible {}

            iconSize: JamiTheme.iconButtonMedium
            iconSource: JamiResources.plugins_24dp_svg
            toolTipText: JamiStrings.showExtensions

            visible: LRCInstance.chatHandlersListCount && interactionButtonsVisibility

            onClicked: pluginSelector()
        }

        NewIconButton {
            id: searchMessagesButton
            QWKSetParentHitTestVisible {}

            objectName: "searchMessagesButton"

            iconSize: JamiTheme.iconButtonMedium
            iconSource: JamiResources.ic_baseline_search_24dp_svg
            toolTipText: JamiStrings.search

            checkable: true
            checked: extrasPanel.isOpen(ChatView.MessagesResearchPanel)

            visible: root.swarmDetailsVisibility

            onClicked: extrasPanel.switchToPanel(ChatView.MessagesResearchPanel)

            Shortcut {
                sequence: "Ctrl+Shift+F"
                context: Qt.ApplicationShortcut
                enabled: parent.visible
                onActivated: extrasPanel.switchToPanel(ChatView.MessagesResearchPanel)
            }
        }

        NewIconButton {
            id: detailsButton
            QWKSetParentHitTestVisible {}

            objectName: "detailsButton"

            iconSize: JamiTheme.iconButtonMedium
            iconSource: JamiResources.swarm_details_panel_svg
            toolTipText: JamiStrings.details

            checkable: true
            checked: extrasPanel.isOpen(ChatView.SwarmDetailsPanel)

            visible: (swarmDetailsVisibility || LRCInstance.currentAccountType === Profile.Type.SIP)

            onClicked: extrasPanel.switchToPanel(ChatView.SwarmDetailsPanel)
        }
    }

    CustomBorder {
        commonBorder: false
        lBorderwidth: 0
        rBorderwidth: 0
        tBorderwidth: 0
        bBorderwidth: JamiTheme.chatViewHairLineSize
        borderColor: JamiTheme.chatViewFooterRectangleBorderColor
    }
}
