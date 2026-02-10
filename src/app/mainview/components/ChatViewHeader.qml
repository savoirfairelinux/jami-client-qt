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

    leftPadding: 8
    rightPadding: 8

    signal backClicked
    signal pluginSelector

    Connections {
        target: CurrentConversation
        enabled: true

        function onIdChanged() {
            if (title.eText === "" || userAvatar.imageId === "") {
                title.eText = CurrentConversation.title
                description.eText = CurrentConversation.description
                userAvatar.imageId = CurrentConversation.id
            } else {
                // When switching between conversations
                if (titleFadeAnimation.running)
                    titleFadeAnimation.stop();
                titleFadeAnimation.start();
            }
        }

        function onShowSwarmDetails() {
            extrasPanel.switchToPanel(ChatView.SwarmDetailsPanel);
        }
    }

    // We must assign the title, desc., and avatar id on the initial
    // creation of the component
    Component.onCompleted: {
        title.eText = CurrentConversation.title
        description.eText = CurrentConversation.description
        userAvatar.imageId = CurrentConversation.id
    }


    SequentialAnimation {
        id: titleFadeAnimation
        NumberAnimation {
            targets: [title, description, userAvatar]
            property: "opacity"
            to: 0
            duration: JamiTheme.chatViewFadeDuration / 2
        }
        ScriptAction {
            script: {
                console.warn("ASSIGNMENT STARTED")
                title.eText = CurrentConversation.title;
                description.eText = CurrentConversation.description;
                userAvatar.imageId = CurrentConversation.id;
                if (CurrentConversation.description === "" || CurrentConversation.title === CurrentConversation.description) {
                    description.visible = false;
                } else {
                    description.visible = true;
                }
            }
        }
        NumberAnimation {
            targets: [title, description, userAvatar]
            property: "opacity"
            to: 1
            duration: JamiTheme.chatViewFadeDuration / 2
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
            toolTipText: JamiStrings.hideChat

            visible: !viewCoordinator.isInSinglePaneMode && !CurrentConversation.inCall

            onClicked: root.backClicked()
        }

        JamiPushButton {
            id: backToWelcomeViewChevronButton
            QWKSetParentHitTestVisible {}

            Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft

            normalColor: JamiTheme.globalIslandColor

            mirror: UtilsAdapter.isRTL

            source: JamiResources.chevron_left_black_24dp_svg
            toolTipText: JamiStrings.hideChat

            visible: viewCoordinator.isInSinglePaneMode && !CurrentConversation.inCall

            onClicked: root.backClicked()
        }

        // NOTE: this a very customized component and should be generalized at some point
        Button {
            id: backToActiveCallButton
            QWKSetParentHitTestVisible {}

            Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
            
            implicitWidth: background.width
            implicitHeight: background.height

            icon.width: JamiTheme.iconButtonMedium
            icon.height: JamiTheme.iconButtonMedium
            icon.source: JamiResources.return_to_call_24dp_svg
            icon.color: hovered ? JamiTheme.buttonCallLightGreen : JamiTheme.blackColor

            visible: CurrentConversation.inCall

            Behavior on icon.color {
                ColorAnimation {
                    duration: 200
                }
            }

            background: Rectangle {
                id: backToActiveCallButtonBackground

                width: backToActiveCallButton.icon.width + (backToActiveCallButton.icon.width / 2)
                height: backToActiveCallButton.icon.height + (backToActiveCallButton.icon.height / 2)

                radius: height / 2
                color: backToActiveCallButton.hovered ? JamiTheme.buttonCallDarkGreen : JamiTheme.buttonCallLightGreen

                Behavior on color {
                    ColorAnimation {
                        duration: 200
                    }
                }
            }

            MaterialToolTip {
                parent: backToActiveCallButton

                text: JamiStrings.returnToCall
                visible: (root.hovered || root.activeFocus) && (text.length > 0)
                delay: Qt.styleHints.mousePressAndHoldInterval
            }

            onClicked: root.backClicked()
        }

        BadgeNotifier {
            size: 20
            count: ConversationsAdapter.totalUnreadMessageCount + ConversationsAdapter.pendingRequestCount
            visible: viewCoordinator.isInSinglePaneMode
        }


        RowLayout {
            id: userInfoRowLayout

            Layout.preferredWidth: 352
            Layout.preferredHeight: parent.height

            Avatar {
                id: userAvatar

                width: JamiTheme.iconButtonLarge
                height: JamiTheme.iconButtonLarge

                mode: CurrentConversation.isSwarm ? Avatar.Mode.Conversation : Avatar.Mode.Contact
                showPresenceIndicator: false
            }

            ColumnLayout {
                id: userNameOrIdColumnLayout
                QWKSetParentHitTestVisible {}
                objectName: "userNameOrIdColumnLayout"

                Layout.fillWidth: true
                Layout.fillHeight: true
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

                    maxWidth: userNameOrIdColumnLayout.width
                }
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
