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

    color: JamiTheme.chatviewBgColor

    RowLayout {
        id: messagingHeaderRectRowLayout

        anchors.fill: parent
        // QWK: spacing
        anchors.leftMargin: layoutManager.qwkSystemButtonSpacing.left
        anchors.rightMargin: 10 + layoutManager.qwkSystemButtonSpacing.right
        spacing: 16

        JamiPushButton {
            id: backToWelcomeViewButton
            QWKSetParentHitTestVisible {
            }

            Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
            Layout.leftMargin: 8

            mirror: UtilsAdapter.isRTL

            source: JamiResources.back_24dp_svg
            toolTipText: CurrentConversation.inCall ? JamiStrings.returnToCall : JamiStrings.hideChat

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

            ColumnLayout {
                id: userNameOrIdColumnLayout
                QWKSetParentHitTestVisible {
                }
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


        CallsButton {
            QWKSetParentHitTestVisible {
            }
            Layout.preferredHeight: 35
            Layout.preferredWidth: 80
            Layout.alignment: Qt.AlignVCenter
            visible: interactionButtonsVisibility && (!addMemberVisibility || UtilsAdapter.getAppValue(Settings.EnableExperimentalSwarm))
        }
       

        JamiPushButton {
            id: inviteMembersButton
            QWKSetParentHitTestVisible {
            }

            checkable: true
            checked: extrasPanel.isOpen(ChatView.AddMemberPanel)
            visible: interactionButtonsVisibility && addMemberVisibility
            source: JamiResources.add_people_24dp_svg
            toolTipText: JamiStrings.inviteMembers

            onClicked: extrasPanel.switchToPanel(ChatView.AddMemberPanel)
        }

        JamiPushButton {
            id: selectExtensionsButton
            QWKSetParentHitTestVisible {
            }

            visible: PluginAdapter.chatHandlersListCount && interactionButtonsVisibility
            source: JamiResources.plugins_24dp_svg
            toolTipText: JamiStrings.showExtensions

            onClicked: pluginSelector()
        }

        JamiPushButton {
            id: searchMessagesButton
            QWKSetParentHitTestVisible {
            }
            objectName: "searchMessagesButton"

            checkable: true
            checked: extrasPanel.isOpen(ChatView.MessagesResearchPanel)
            visible: root.swarmDetailsVisibility
            source: JamiResources.ic_baseline_search_24dp_svg
            toolTipText: JamiStrings.search

            onClicked: extrasPanel.switchToPanel(ChatView.MessagesResearchPanel)

            Shortcut {
                sequence: "Ctrl+Shift+F"
                context: Qt.ApplicationShortcut
                enabled: parent.visible
                onActivated: extrasPanel.switchToPanel(ChatView.MessagesResearchPanel)
            }
        }

        JamiPushButton {
            id: detailsButton
            QWKSetParentHitTestVisible {
            }
            objectName: "detailsButton"

            checkable: true
            checked: extrasPanel.isOpen(ChatView.SwarmDetailsPanel)
            visible: (swarmDetailsVisibility || LRCInstance.currentAccountType === Profile.Type.SIP)
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
