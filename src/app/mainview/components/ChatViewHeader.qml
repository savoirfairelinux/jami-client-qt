/*
 * Copyright (C) 2020-2022 Savoir-faire Linux Inc.
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

import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import net.jami.Enums 1.1
import net.jami.Models 1.1

import "../../commoncomponents"

Rectangle {
    id: root

    signal backClicked
    signal needToHideConversationInCall
    signal addToConversationClicked
    signal pluginSelector
    signal showDetailsClicked

    Connections {
        target: CurrentConversation
        enabled: true
        function onTitleChanged() { title.eText = CurrentConversation.title }
        function onDescriptionChanged() { description.eText = CurrentConversation.description }
        function onShowDetails() { root.showDetailsClicked() }
    }

    property bool interactionButtonsVisibility: {
        if (CurrentConversation.inCall)
            return false
        if (LRCInstance.currentAccountType === Profile.Type.SIP)
            return true
        if (!CurrentConversation.isTemporary && !CurrentConversation.isSwarm)
            return false
        if (CurrentConversation.isRequest || CurrentConversation.needsSyncing)
            return false
        return true
    }

    property bool addMemberVisibility: {
        return swarmDetailsVisibility && !CurrentConversation.isCoreDialog && !CurrentConversation.isRequest
    }

    property bool swarmDetailsVisibility: {
        return CurrentConversation.isSwarm && !CurrentConversation.isRequest
    }

    color: JamiTheme.chatviewBgColor

    RowLayout {
        id: messagingHeaderRectRowLayout

        anchors.fill: parent

        PushButton {
            id: backToWelcomeViewButton

            Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
            Layout.leftMargin: 8

            preferredSize: 24

            source: CurrentConversation.inCall ?
                        JamiResources.round_close_24dp_svg :
                        JamiResources.back_24dp_svg
            toolTipText: JamiStrings.hideChat

            normalColor: JamiTheme.chatviewBgColor
            imageColor: JamiTheme.chatviewButtonColor

            onClicked: CurrentConversation.inCall ?
                           root.needToHideConversationInCall() :
                           root.backClicked()
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

            ColumnLayout {
                id: userNameOrIdColumnLayout

                anchors.fill: parent

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

                    visible: text.length &&
                             CurrentConversation.title != CurrentConversation.description
                    font.pointSize: JamiTheme.textFontSize
                    color: JamiTheme.faddedLastInteractionFontColor

                    horizontalAlignment: Text.AlignLeft
                    verticalAlignment: Text.AlignVCenter
                    eText: CurrentConversation.description
                    maxWidth: userNameOrIdRect.width
                }
            }
        }

        RowLayout {
            id: buttonGroup

            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
            Layout.fillWidth: true
            Layout.rightMargin: 8
            spacing: 16

            PushButton {
                id: startAAudioCallButton

                visible: interactionButtonsVisibility && (!addMemberVisibility || UtilsAdapter.getAppValue(Settings.EnableExperimentalSwarm))

                source: JamiResources.place_audiocall_24dp_svg
                toolTipText: JamiStrings.placeAudioCall

                normalColor: JamiTheme.chatviewBgColor
                imageColor: JamiTheme.chatviewButtonColor

                onClicked: CallAdapter.placeAudioOnlyCall()
            }

            PushButton {
                id: startAVideoCallButton

                visible: CurrentAccount.videoEnabled_Video && interactionButtonsVisibility && (!addMemberVisibility || UtilsAdapter.getAppValue(Settings.EnableExperimentalSwarm))
                source: JamiResources.videocam_24dp_svg
                toolTipText: JamiStrings.placeVideoCall

                normalColor: JamiTheme.chatviewBgColor
                imageColor: JamiTheme.chatviewButtonColor

                onClicked: {
                    CallAdapter.placeCall()
                }
            }

            PushButton {
                id: addParticipantsButton

                source: JamiResources.add_people_24dp_svg
                toolTipText: JamiStrings.addParticipants

                normalColor: JamiTheme.chatviewBgColor
                imageColor: JamiTheme.chatviewButtonColor

                visible: CurrentConversation.uris.length < 8 && addMemberVisibility

                onClicked: addToConversationClicked()
            }

            PushButton {
                id: selectPluginButton

                visible: PluginAdapter.isEnabled && PluginAdapter.chatHandlersListCount &&
                         interactionButtonsVisibility

                source: JamiResources.plugins_24dp_svg
                toolTipText: JamiStrings.showPlugins

                normalColor: JamiTheme.chatviewBgColor
                imageColor: JamiTheme.chatviewButtonColor

                onClicked: pluginSelector()
            }

            PushButton {
                id: sendContactRequestButton

                visible: CurrentConversation.isTemporary || CurrentConversation.isBanned

                source: JamiResources.add_people_24dp_svg
                toolTipText: JamiStrings.addToConversations

                normalColor: JamiTheme.chatviewBgColor
                imageColor: JamiTheme.chatviewButtonColor

                onClicked: CurrentConversation.isBanned ?
                                MessagesAdapter.unbanConversation(CurrentConversation.id)
                                : MessagesAdapter.sendConversationRequest()
            }

            PushButton {
                id: detailsButton

                visible: swarmDetailsVisibility

                source: JamiResources.swarm_details_panel_svg
                toolTipText: JamiStrings.details

                normalColor: JamiTheme.chatviewBgColor
                imageColor: JamiTheme.chatviewButtonColor

                onClicked: showDetailsClicked()
            }
        }
        Component.onCompleted: JamiQmlUtils.messagingHeaderRectRowLayout = messagingHeaderRectRowLayout
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
