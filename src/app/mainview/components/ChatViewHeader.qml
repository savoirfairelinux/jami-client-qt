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
import QtQuick.Controls

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
    signal startResearchClicked

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

            RowLayout {
                id: rowSearchBar

                function searchBarInteraction() {
                    startResearchClicked()
                    rectTextArea.isSearch = !rectTextArea.isSearch
                    anim.start()
                    if (rectTextArea.isSearch)
                        textArea.focus = true
                }

                PushButton {
                    id: startMessagesResearch

                    source: JamiResources.search_svg
                    toolTipText: JamiStrings.startMessagesResearch

                    normalColor: JamiTheme.chatviewBgColor
                    imageColor: JamiTheme.chatviewButtonColor

                    onClicked: {
                        rowSearchBar.searchBarInteraction()
                    }
                }

                SequentialAnimation {
                    id: anim

                    PropertyAnimation {
                        target: rectTextArea; properties: "visible"
                        to: true
                        duration: 0
                    }

                    ParallelAnimation {

                        NumberAnimation {
                            target: rectTextArea; properties: "opacity"
                            from: rectTextArea.isSearch ? 0 : 1
                            to: rectTextArea.isSearch ? 1 : 0
                            duration: 150
                        }

                        NumberAnimation {
                            target: rectTextArea; properties: "Layout.preferredWidth"
                            from: rectTextArea.isSearch ? 0 : rectTextArea.textAreaWidth
                            to: rectTextArea.isSearch ? rectTextArea.textAreaWidth : 0
                            duration: 150
                        }
                    }

                    PropertyAnimation {
                        target: rectTextArea; properties: "visible"
                        to: rectTextArea.isSearch
                        duration: 0
                    }

                }
                Rectangle {
                    id: rectTextArea

                    property bool isSearch: false
                    visible: false
                    Layout.preferredHeight: startMessagesResearch.height
                    Layout.alignment: Qt.AlignVCenter
                    property int textAreaWidth: 150

                    color: "transparent"
                    border.color: "grey"
                    radius: 10
                    border.width: 2

                    TextField {
                        id: textArea

                        background.visible: false
                        anchors.right: clearTextButton.left
                        anchors.left: rectTextArea.left
                        onTextChanged: {MessagesAdapter.startMessagesResearch(text)}
                    }

                    PushButton {
                        id: clearTextButton

                        anchors.verticalCenter: rectTextArea.verticalCenter
                        anchors.right: rectTextArea.right
                        anchors.margins: 5
                        preferredSize: 21

                        radius: rectTextArea.radius

                        visible: textArea.text.length
                        opacity: visible ? 1 : 0

                        normalColor: "transparent"
                        imageColor: JamiTheme.chatviewButtonColor

                        source: JamiResources.ic_clear_24dp_svg
                        toolTipText: JamiStrings.clearText

                        onClicked: textArea.clear()

                        Behavior on opacity {
                            NumberAnimation { duration: 500; easing.type: Easing.OutCubic }
                        }
                    }
                }
            }

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
