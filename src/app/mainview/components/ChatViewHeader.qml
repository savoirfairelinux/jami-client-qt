/*
 * Copyright (C) 2020-2023 Savoir-faire Linux Inc.
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
    property bool addMemberVisibility: {
        return swarmDetailsVisibility && !CurrentConversation.isCoreDialog && !CurrentConversation.isRequest;
    }
    property bool interactionButtonsVisibility: {
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
    property bool showSearch: true
    property bool swarmDetailsVisibility: {
        return CurrentConversation.isSwarm && !CurrentConversation.isRequest;
    }

    color: JamiTheme.chatviewBgColor

    signal addToConversationClicked
    signal backClicked
    signal pluginSelector
    signal searchClicked
    signal showDetailsClicked

    Connections {
        enabled: true
        target: CurrentConversation

        function onDescriptionChanged() {
            description.eText = CurrentConversation.description;
        }
        function onShowSwarmDetails() {
            root.showDetailsClicked();
        }
        function onTitleChanged() {
            title.eText = CurrentConversation.title;
        }
    }
    RowLayout {
        id: messagingHeaderRectRowLayout
        anchors.fill: parent

        PushButton {
            id: backToWelcomeViewButton
            Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
            Layout.leftMargin: 8
            imageColor: JamiTheme.chatviewButtonColor
            normalColor: JamiTheme.chatviewBgColor
            preferredSize: 24
            source: JamiResources.back_24dp_svg
            toolTipText: CurrentConversation.inCall ? JamiStrings.backCall : JamiStrings.hideChat

            onClicked: root.backClicked()
        }
        Rectangle {
            id: userNameOrIdRect
            Layout.alignment: Qt.AlignLeft | Qt.AlignTop
            Layout.bottomMargin: 7

            // Width + margin.
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.leftMargin: 8
            Layout.topMargin: 7
            color: JamiTheme.transparentColor

            ColumnLayout {
                id: userNameOrIdColumnLayout
                anchors.fill: parent
                spacing: 0

                ElidedTextLabel {
                    id: title
                    Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
                    eText: CurrentConversation.title
                    font.pointSize: JamiTheme.textFontSize + 2
                    horizontalAlignment: Text.AlignLeft
                    maxWidth: userNameOrIdRect.width
                    verticalAlignment: Text.AlignVCenter
                }
                ElidedTextLabel {
                    id: description
                    Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
                    color: JamiTheme.faddedLastInteractionFontColor
                    eText: CurrentConversation.description
                    font.pointSize: JamiTheme.textFontSize
                    horizontalAlignment: Text.AlignLeft
                    maxWidth: userNameOrIdRect.width
                    verticalAlignment: Text.AlignVCenter
                    visible: text.length && CurrentConversation.title !== CurrentConversation.description
                }
            }
        }
        RowLayout {
            id: headerButtons
            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
            Layout.fillWidth: true
            Layout.rightMargin: 8
            spacing: 16

            Searchbar {
                id: rowSearchBar
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                spacing: headerButtons.spacing
                visible: root.showSearch && CurrentConversation.isSwarm

                Shortcut {
                    context: Qt.ApplicationShortcut
                    enabled: rowSearchBar.visible
                    sequence: "Ctrl+Shift+F"

                    onActivated: {
                        rowSearchBar.openSearchBar();
                    }
                }
            }
            PushButton {
                id: startAAudioCallButton
                imageColor: JamiTheme.chatviewButtonColor
                normalColor: JamiTheme.chatviewBgColor
                source: JamiResources.place_audiocall_24dp_svg
                toolTipText: JamiStrings.placeAudioCall
                visible: interactionButtonsVisibility && (!addMemberVisibility || UtilsAdapter.getAppValue(Settings.EnableExperimentalSwarm))

                onClicked: CallAdapter.placeAudioOnlyCall()
            }
            PushButton {
                id: startAVideoCallButton
                imageColor: JamiTheme.chatviewButtonColor
                normalColor: JamiTheme.chatviewBgColor
                source: JamiResources.videocam_24dp_svg
                toolTipText: JamiStrings.placeVideoCall
                visible: CurrentAccount.videoEnabled_Video && interactionButtonsVisibility && (!addMemberVisibility || UtilsAdapter.getAppValue(Settings.EnableExperimentalSwarm))

                onClicked: {
                    CallAdapter.placeCall();
                }
            }
            PushButton {
                id: addParticipantsButton
                imageColor: JamiTheme.chatviewButtonColor
                normalColor: JamiTheme.chatviewBgColor
                source: JamiResources.add_people_24dp_svg
                toolTipText: JamiStrings.addParticipants
                visible: interactionButtonsVisibility && CurrentConversationMembers.count < 8 && addMemberVisibility

                onClicked: addToConversationClicked()
            }
            PushButton {
                id: selectPluginButton
                imageColor: JamiTheme.chatviewButtonColor
                normalColor: JamiTheme.chatviewBgColor
                source: JamiResources.plugins_24dp_svg
                toolTipText: JamiStrings.showPlugins
                visible: PluginAdapter.isEnabled && PluginAdapter.chatHandlersListCount && interactionButtonsVisibility

                onClicked: pluginSelector()
            }
            PushButton {
                id: sendContactRequestButton
                imageColor: JamiTheme.chatviewButtonColor
                normalColor: JamiTheme.chatviewBgColor
                source: JamiResources.add_people_24dp_svg
                toolTipText: JamiStrings.addToConversations
                visible: CurrentConversation.isTemporary || CurrentConversation.isBanned

                onClicked: CurrentConversation.isBanned ? MessagesAdapter.unbanConversation(CurrentConversation.id) : MessagesAdapter.sendConversationRequest()
            }
            PushButton {
                id: detailsButton
                imageColor: JamiTheme.chatviewButtonColor
                normalColor: JamiTheme.chatviewBgColor
                source: JamiResources.swarm_details_panel_svg
                toolTipText: JamiStrings.details
                visible: interactionButtonsVisibility && (swarmDetailsVisibility || LRCInstance.currentAccountType === Profile.Type.SIP) // TODO if SIP not a request

                onClicked: showDetailsClicked()
            }
        }
    }
    CustomBorder {
        bBorderwidth: JamiTheme.chatViewHairLineSize
        borderColor: JamiTheme.tabbarBorderColor
        commonBorder: false
        lBorderwidth: 0
        rBorderwidth: 0
        tBorderwidth: 0
    }
}
