/*
 * Copyright (C) 2020-2024 Savoir-faire Linux Inc.
 * Author: Mingrui Zhang <mingrui.zhang@savoirfairelinux.com>
 * Author: Sébastien Blin <sebastien.blin@savoirfairelinux.com>
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
        return swarmDetailsVisibility
                && !CurrentConversation.isCoreDialog
                && !CurrentConversation.isRequest;
    }

    property bool swarmDetailsVisibility: {
        return CurrentConversation.isSwarm && !CurrentConversation.isRequest;
    }

    color: JamiTheme.chatviewBgColor

    RowLayout {
        id: messagingHeaderRectRowLayout

        anchors.fill: parent
        // QWK: spacing
        anchors.rightMargin: 8 + systemButtonGroupLoader.spacing
        anchors.leftMargin: {
            // QWK: Spacing for macOS system buttons.
            if (Qt.platform.os.toString() === "osx" && viewCoordinator.isInSinglePaneMode)
                return 80;
            return 0;
        }
        spacing: 16

        JamiPushButton { QWKSetParentHitTestVisible {}
            id: backToWelcomeViewButton

            Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
            Layout.leftMargin: 8

            mirror: UtilsAdapter.isRTL

            source: JamiResources.back_24dp_svg
            toolTipText: CurrentConversation.inCall ? JamiStrings.backCall : JamiStrings.hideChat

            onClicked: root.backClicked()
        }

        Rectangle {
            id: userNameOrIdRect

            Layout.alignment: Qt.AlignLeft | Qt.AlignTop

            // Width + margin.
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.topMargin: 7
            Layout.bottomMargin: 7
            Layout.leftMargin: 8

            color: JamiTheme.transparentColor

            ColumnLayout { QWKSetParentHitTestVisible {}
                id: userNameOrIdColumnLayout
                objectName: "userNameOrIdColumnLayout"

                height: parent.height

                spacing: 0

                ElidedTextLabel {
                    id: title

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

        JamiPushButton { QWKSetParentHitTestVisible {}
            id: startAAudioCallButton

            visible: interactionButtonsVisibility &&
                     (!addMemberVisibility || UtilsAdapter.getAppValue(Settings.EnableExperimentalSwarm))
            source: JamiResources.place_audiocall_24dp_svg
            toolTipText: JamiStrings.placeAudioCall

            onClicked: CallAdapter.placeAudioOnlyCall()
        }

        JamiPushButton { QWKSetParentHitTestVisible {}
            id: startAVideoCallButton

            visible: interactionButtonsVisibility &&
                     CurrentAccount.videoEnabled_Video &&
                     (!addMemberVisibility || UtilsAdapter.getAppValue(Settings.EnableExperimentalSwarm))
            source: JamiResources.videocam_24dp_svg
            toolTipText: JamiStrings.placeVideoCall

            onClicked: CallAdapter.placeCall()
        }

        JamiPushButton { QWKSetParentHitTestVisible {}
            id: addParticipantsButton

            checkable: true
            checked: extrasPanel.isOpen(ChatView.AddMemberPanel)
            visible: interactionButtonsVisibility && addMemberVisibility
            source: JamiResources.add_people_24dp_svg
            toolTipText: JamiStrings.addParticipants

            onClicked: extrasPanel.switchToPanel(ChatView.AddMemberPanel)
        }

        JamiPushButton { QWKSetParentHitTestVisible {}
            id: selectPluginButton

            visible: PluginAdapter.chatHandlersListCount && interactionButtonsVisibility
            source: JamiResources.plugins_24dp_svg
            toolTipText: JamiStrings.showPlugins

            onClicked: pluginSelector()
        }

        JamiPushButton { QWKSetParentHitTestVisible {}
            id: sendContactRequestButton
            objectName: "sendContactRequestButton"

            visible: CurrentConversation.isTemporary || CurrentConversation.isBanned
            source: JamiResources.add_people_24dp_svg
            toolTipText: JamiStrings.addToConversations

            onClicked: CurrentConversation.isBanned ?
                           MessagesAdapter.unbanConversation(CurrentConversation.id) :
                           MessagesAdapter.sendConversationRequest()
        }

        JamiPushButton { QWKSetParentHitTestVisible {}
            id: searchMessagesButton
            objectName: "searchMessagesButton"

            checkable: true
            checked: extrasPanel.isOpen(ChatView.MessagesResearchPanel)
            visible: root.swarmDetailsVisibility
            source:  JamiResources.ic_baseline_search_24dp_svg
            toolTipText: JamiStrings.search

            onClicked: extrasPanel.switchToPanel(ChatView.MessagesResearchPanel)

            Shortcut {
                sequence: "Ctrl+Shift+F"
                context: Qt.ApplicationShortcut
                enabled: parent.visible
                onActivated: extrasPanel.switchToPanel(ChatView.MessagesResearchPanel)
            }
        }

        JamiPushButton { QWKSetParentHitTestVisible {}
            id: detailsButton
            objectName: "detailsButton"

            checkable: true
            checked: extrasPanel.isOpen(ChatView.SwarmDetailsPanel)
            visible: interactionButtonsVisibility &&
                     (swarmDetailsVisibility || LRCInstance.currentAccountType === Profile.Type.SIP) // TODO if SIP not a request
            source: JamiResources.swarm_details_panel_svg
            toolTipText: JamiStrings.details

            onClicked: extrasPanel.switchToPanel(ChatView.SwarmDetailsPanel)
        }
    }

    CustomBorder {
        commonBorder: false
        lBorderwidth: 0
        rBorderwidth: 0
        tBorderwidth: 0
        bBorderwidth: JamiTheme.chatViewHairLineSize
        borderColor: JamiTheme.tabbarBorderColor
    }
}
