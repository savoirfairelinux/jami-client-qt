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

Control {
    id: root

    property alias contentItemRowLayout: messagingHeaderRectRowLayout

    signal backClicked
    signal pluginSelector

    Connections {
        target: CurrentConversation
        enabled: true

        function onIdChanged() {
            if (title.eText === undefined || description.eText === undefined || userAvatar.imageId === undefined) {
                title.eText = CurrentConversation.title
                description.eText = CurrentConversation.description
                userAvatar.imageId = CurrentConversation.id
            } else {
                titleFadeAnimation.start();
            }
        }

        function onShowSwarmDetails() {
            extrasPanel.switchToPanel(ChatView.SwarmDetailsPanel);
        }
    }

    leftPadding: 8
    rightPadding: 8

    SequentialAnimation {
        id: titleFadeAnimation

        ParallelAnimation {
            NumberAnimation {
                target: userNameOrIdColumnLayout
                property: "opacity"
                to: 0
                duration: JamiTheme.longFadeDuration
            }
            NumberAnimation {
                target: userAvatar
                property: "opacity"
                to: 0
                duration: JamiTheme.longFadeDuration
            }
        }
        ScriptAction {
            script: {
                title.eText = CurrentConversation.title
                description.eText = CurrentConversation.description
                userAvatar.imageId = CurrentConversation.id
            }
        }
        ParallelAnimation {
            NumberAnimation {
                target: userNameOrIdColumnLayout
                property: "opacity"
                to: 1
                duration: JamiTheme.longFadeDuration
            }
            NumberAnimation {
                target: userAvatar
                property: "opacity"
                to: 1
                duration: JamiTheme.longFadeDuration
            }
        }
    }

    contentItem: RowLayout {
        id: messagingHeaderRectRowLayout

        spacing: 8

        JamiPushButton {
            id: backToWelcomeViewArrowButton
            QWKSetParentHitTestVisible {}

            Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft

            normalColor: JamiTheme.globalIslandColor

            mirror: UtilsAdapter.isRTL

            source: JamiResources.back_24dp_svg
            toolTipText: CurrentConversation.inCall ? JamiStrings.returnToCall : JamiStrings.hideChat

            visible: !viewCoordinator.isInSinglePaneMode

            onClicked: root.backClicked()
        }

        JamiPushButton {
            id: backToWelcomeViewChevronButton
            QWKSetParentHitTestVisible {}

            Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft

            normalColor: JamiTheme.globalIslandColor

            mirror: UtilsAdapter.isRTL

            source: JamiResources.chevron_left_black_24dp_svg
            toolTipText: CurrentConversation.inCall ? JamiStrings.returnToCall : JamiStrings.hideChat

            visible: viewCoordinator.isInSinglePaneMode

            onClicked: root.backClicked()
        }

        BadgeNotifier {
            size: 20
            count: ConversationsAdapter.totalUnreadMessageCount + ConversationsAdapter.pendingRequestCount
            visible: viewCoordinator.isInSinglePaneMode
        }


        Avatar {
            id: userAvatar

            width: JamiTheme.iconButtonLarge
            height: JamiTheme.iconButtonLarge

            mode: CurrentConversation.isSwarm ? Avatar.Mode.Conversation : Avatar.Mode.Contact
            //imageId: CurrentConversation.id
            showPresenceIndicator: false
        }

        ColumnLayout {
            id: userNameOrIdColumnLayout
            QWKSetParentHitTestVisible {}
            objectName: "userNameOrIdColumnLayout"

            Layout.preferredWidth: 352
            Layout.preferredHeight: parent.height
            Layout.topMargin: 7
            Layout.bottomMargin: 7
            Layout.leftMargin: 4

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

                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft

                font.pointSize: JamiTheme.textFontSize + 2

                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter

                //eText: CurrentConversation.title
                maxWidth: userNameOrIdColumnLayout.width
            }

            ElidedTextLabel {
                id: description

                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft

                visible: text.length && CurrentConversation.title !== CurrentConversation.description
                font.pointSize: JamiTheme.textFontSize
                color: JamiTheme.faddedLastInteractionFontColor

                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
                //eText: CurrentConversation.description
                maxWidth: userNameOrIdColumnLayout.width
            }
        }

        // Custom component (DNR: DO NOT REPLACE)
        CallsButton {
            QWKSetParentHitTestVisible {}
            Layout.alignment: Qt.AlignVCenter
            visible: CurrentConversation.activeCalls.length > 0 && interactionButtonsVisibility
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
            anchors.fill: parent
            shadowEnabled: true
            shadowBlur: JamiTheme.shadowBlur
            shadowColor: JamiTheme.shadowColor
            shadowHorizontalOffset: JamiTheme.shadowHorizontalOffset
            shadowVerticalOffset: JamiTheme.shadowVerticalOffset
            shadowOpacity: JamiTheme.shadowOpacity
        }
    }
}
