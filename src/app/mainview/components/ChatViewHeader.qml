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
import QtQuick.Effects
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
    property bool isAdmin: UtilsAdapter.getParticipantRole(CurrentAccount.id, CurrentConversation.id, CurrentAccount.uri) === Member.Role.ADMIN

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

    color: JamiTheme.transparentColor//JamiTheme.globalBackgroundColor

    RowLayout {
        anchors.fill: parent
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: 4

        spacing: 2

        Control {
            id: conversationTitle

            Layout.fillWidth: true

            padding: 4

            contentItem: RowLayout {
                Layout.fillWidth: true

                RowLayout {
                    spacing: 2

                    NewIconButton {
                        Layout.alignment: Qt.AlignVCenter

                        implicitWidth: background.width
                        implicitHeight: background.height

                        iconSize: JamiTheme.iconButtonMedium
                        iconSource: JamiResources.chevron_left_black_24dp_svg

                        onClicked: root.backClicked()
                    }

                    BadgeNotifier {
                        id: badge

                        Layout.alignment: Qt.AlignVCenter

                        visible: viewCoordinator.isInSinglePaneMode && count > 0

                        count: ConversationsAdapter.totalUnreadMessageCount + ConversationsAdapter.pendingRequestCount
                        size: 20
                    }
                }


                Avatar {
                    id: userAvatar

                    Layout.preferredWidth: width
                    Layout.preferredHeight: height

                    width: JamiTheme.iconButtonLarge
                    height: JamiTheme.iconButtonLarge

                    mode: CurrentConversation.isSwarm ? Avatar.Mode.Conversation : Avatar.Mode.Contact
                    imageId: CurrentConversation.id
                    showPresenceIndicator: false
                }

                ColumnLayout {
                    id: userNameOrIdColumnLayout
                    QWKSetParentHitTestVisible {}
                    objectName: "userNameOrIdColumnLayout"

                    Layout.fillWidth: true
                    Layout.preferredHeight: parent.height

                    spacing: 0

                    ElidedTextLabel {
                        id: title

                        Layout.fillWidth: true
                        Layout.fillHeight: true

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
                        maxWidth: width
                    }

                    ElidedTextLabel {
                        id: description

                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft

                        visible: eText.length && CurrentConversation.title !== CurrentConversation.description
                        font.pointSize: JamiTheme.textFontSize
                        color: JamiTheme.faddedLastInteractionFontColor

                        horizontalAlignment: Text.AlignLeft
                        verticalAlignment: Text.AlignVCenter
                        eText: CurrentConversation.description
                        maxWidth: width
                    }
                }

                NewIconButton {
                    id: startAudioCallButton
                    QWKSetParentHitTestVisible {}

                    visible: CurrentConversation.activeCalls.length === 0 && interactionButtonsVisibility

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
                    toolTipText: JamiStrings.startVideoCall

                    visible: CurrentConversation.activeCalls.length === 0 && interactionButtonsVisibility && CurrentAccount.videoEnabled_Video

                    onClicked: CallAdapter.startCall()
                }
            }

            background: Rectangle {
                color: JamiTheme.globalIslandColor
                radius: height / 2

                layer.enabled: true
                layer.effect: MultiEffect {
                    id: conversationTitleMultiEffect
                    anchors.fill: conversationTitle
                    shadowEnabled: true
                    shadowBlur: JamiTheme.shadowBlur
                    shadowColor: JamiTheme.shadowColor
                    shadowHorizontalOffset: JamiTheme.shadowHorizontalOffset
                    shadowVerticalOffset: JamiTheme.shadowVerticalOffset
                    shadowOpacity: JamiTheme.shadowOpacity
                }
            }
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

            visible: interactionButtonsVisibility && addMemberVisibility && isAdmin

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
}
