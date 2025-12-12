/*
 * Copyright (C) 2020-2025 Savoir-faire Linux Inc.
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
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import net.jami.Enums 1.1
import net.jami.Models 1.1
import "../../commoncomponents"

ItemDelegate {
    id: root

    width: ListView.view.width
    height: JamiTheme.smartListItemHeight

    property alias extraButtons: extraButtons

    property string accountId: ""
    property string convId: ""

    highlighted: ListView.isCurrentItem
    property bool interactive: true
    property bool isTemporary: false
    property bool isBanned: false

    property int lastInteractionTimeStamp: LastInteractionTimeStamp
    property string lastInteractionFormattedDate: MessagesAdapter.getBestFormattedDate(lastInteractionTimeStamp)

    property bool showSharePositionIndicator: PositionManager.isPositionSharedToConv(accountId, UID)
    property bool showSharedPositionIndicator: PositionManager.isConvSharingPosition(accountId, UID)

    Connections {
        target: PositionManager
        function onPositionShareConvIdsCountChanged() {
            root.showSharePositionIndicator = PositionManager.isPositionSharedToConv(accountId, UID);
        }
        function onSharingUrisCountChanged() {
            root.showSharedPositionIndicator = PositionManager.isConvSharingPosition(accountId, UID);
        }
    }

    Connections {
        target: MessagesAdapter
        function onTimestampUpdated() {
            lastInteractionFormattedDate = MessagesAdapter.getBestFormattedDate(lastInteractionTimeStamp);
        }
    }

    Component.onCompleted: {
        // Store to avoid undefined at the end
        root.accountId = Qt.binding(() => CurrentAccount.id);
        root.convId = UID;
        root.isTemporary = ContactType === Profile.Type.TEMPORARY;
        root.isBanned = isBanned;
    }

    RowLayout {
        id: rowLayout

        anchors.fill: contentRect
        anchors.margins: JamiTheme.itemPadding

        spacing: 16

        ConversationAvatar {
            id: avatar
            objectName: "smartlistItemDelegateAvatar"

            imageId: UID
            presenceStatus: Presence
            showPresenceIndicator: Presence !== undefined ? Presence : false

            Layout.preferredWidth: JamiTheme.smartListAvatarSize
            Layout.preferredHeight: JamiTheme.smartListAvatarSize

            Rectangle {
                id: overlayHighlighted
                visible: highlighted && !interactive

                anchors.fill: parent
                color: Qt.rgba(0, 0, 0, 0.5)
                radius: JamiTheme.avatarRadius

                Image {
                    id: highlightedImage

                    width: JamiTheme.smartListAvatarSize / 2
                    height: JamiTheme.smartListAvatarSize / 2
                    anchors.centerIn: parent

                    layer {
                        enabled: true
                        effect: ColorOverlay {
                            color: "white"
                        }
                    }
                    source: JamiResources.check_black_24dp_svg
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            // best name
            Text {
                Layout.fillWidth: true
                Layout.minimumHeight: 20
                Layout.alignment: Qt.AlignVCenter
                horizontalAlignment: Text.AlignLeft
                elide: Text.ElideMiddle
                text: Title === undefined ? "" : Title
                textFormat: TextEdit.PlainText
                font.pointSize: JamiTheme.mediumFontSize
                font.weight: UnreadMessagesCount ? Font.Bold : Font.Normal
                color: JamiTheme.textColor
            }
            RowLayout {
                visible: ContactType !== Profile.Type.TEMPORARY && !IsBanned && lastInteractionTimeStamp > 0 && interactive
                Layout.fillWidth: true
                Layout.minimumHeight: 20
                Layout.alignment: Qt.AlignTop

                // last Interaction date
                Text {
                    Layout.alignment: Qt.AlignVCenter
                    text: lastInteractionFormattedDate
                    textFormat: TextEdit.PlainText
                    font.pointSize: JamiTheme.smallFontSize
                    font.weight: UnreadMessagesCount ? Font.DemiBold : Font.Normal
                    color: JamiTheme.textColor
                }

                // last Interaction
                Text {
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    horizontalAlignment: Text.AlignLeft
                    text: Draft ? Draft : (LastInteraction === undefined ? "" : LastInteraction)
                    textFormat: TextEdit.PlainText
                    font.pointSize: JamiTheme.smallFontSize
                    font.weight: UnreadMessagesCount ? Font.Normal : Font.Light
                    font.hintingPreference: Font.PreferNoHinting
                    maximumLineCount: 1
                    color: JamiTheme.textColor
                }
            }
            Text {
                Layout.fillWidth: true
                Layout.minimumHeight: 20
                Layout.alignment: Qt.AlignVCenter
                text: JamiStrings.blocked
                textFormat: TextEdit.PlainText
                visible: IsBanned
                font.pointSize: JamiTheme.mediumFontSize
                font.weight: Font.Bold
                color: JamiTheme.textColor
            }
        }

        BlinkingLocationIcon {
            isSharing: true
            visible: showSharePositionIndicator
            arrowTimerVisibility: locationIconTimer.showIconArrow
            color: JamiTheme.draftIconColor
            containerWidth: 25
        }

        BlinkingLocationIcon {
            isSharing: false
            visible: showSharedPositionIndicator
            arrowTimerVisibility: locationIconTimer.showIconArrow
            color: JamiTheme.draftIconColor
            containerWidth: 25
        }

        // Draft indicator
        ResponsiveImage {
            visible: Draft && !root.highlighted
            containerWidth: 20

            source: JamiResources.round_edit_24dp_svg
            color: JamiTheme.draftIconColor
        }

        // Show that a call is ongoing for groups indicator
        ResponsiveImage {
            visible: ActiveCallsCount && !root.highlighted
            source: JamiResources.phone_in_talk_24dp_svg
            containerWidth: 16
            color: JamiTheme.primaryForegroundColor
        }

        ColumnLayout {
            Layout.fillHeight: true
            spacing: 2

            // call status
            Text {
                id: callStatusText

                visible: text
                Layout.minimumHeight: 20
                Layout.alignment: Qt.AlignRight
                text: InCall ? UtilsAdapter.getCallStatusStr(CallState) : ""
                textFormat: TextEdit.PlainText
                font.pointSize: JamiTheme.smallFontSize
                font.weight: Font.Medium
                color: JamiTheme.textColor
            }

            // unread message count
            Item {

                Layout.preferredWidth: childrenRect.width
                Layout.preferredHeight: childrenRect.height
                Layout.alignment: Qt.AlignTop | Qt.AlignRight
                BadgeNotifier {
                    size: 16
                    count: UnreadMessagesCount
                    animate: index === 0
                    radius: 3
                }
            }
        }

        Control {
            id: extraButtons
        }

        Accessible.role: Accessible.Button
        Accessible.name: Title === undefined ? "" : Title
        Accessible.description: LastInteraction === undefined ? "" : LastInteraction

        states: [
            State {
                name: "normal"
                when: !hovered || highlighted
                PropertyChanges {
                    target: rowLayout
                    scale: 1.0
                }
            },
            State {
                name: "hovered"
                when: hovered && !highlighted
                PropertyChanges {
                    target: rowLayout
                    scale: 1.05
                }
            }
        ]

        transitions: [
            Transition {
                NumberAnimation {
                    target: rowLayout
                    property: "scale"
                    duration: 400
                    easing.type: Easing.OutCubic
                }
            },
            Transition {
                from: "normal"
                to: "hovered"
                reversible: true
                ColorAnimation {
                    duration: JamiTheme.shortFadeDuration
                }
            },
            Transition {
                from: "hovered"
                to: "normal"
                reversible: true
                ColorAnimation {
                    duration: 150
                }
            }
        ]
    }

    background: Rectangle {
        id: contentRect

        anchors.fill: root
        anchors.topMargin: JamiTheme.itemMarginVertical
        anchors.bottomMargin: JamiTheme.itemMarginVertical
        anchors.leftMargin: JamiTheme.itemMarginHorizontal
        anchors.rightMargin: JamiTheme.itemMarginHorizontal

        radius: JamiTheme.avatarRadius + JamiTheme.itemPadding

        color: JamiTheme.backgroundColor

        scale: 1.0
        states: [
            State {
                name: "normal"
                when: !hovered && !highlighted
                PropertyChanges {
                    target: contentRect
                    color: JamiTheme.backgroundColor
                }
            },
            State {
                name: "hovered"
                when: hovered
                PropertyChanges {
                    target: contentRect
                    color: JamiTheme.smartListHoveredColor
                }
            },
            State {
                name: "highlighted"
                when: highlighted
                PropertyChanges {
                    target: contentRect
                    color: JamiTheme.smartListSelectedColor
                }
            }
        ]

        transitions: [
            Transition {
                to: "normal"
                reversible: true
                ColorAnimation {
                    duration: JamiTheme.shortFadeDuration
                }
            },
            Transition {
                to: "hovered"
                reversible: true
                ColorAnimation {
                    duration: JamiTheme.shortFadeDuration
                }
            },
            Transition {
                to: "highlighted"
                reversible: true
                ColorAnimation {
                    duration: JamiTheme.shortFadeDuration * 0.5
                }
            }
        ]
    }

    onClicked: {
        if (!interactive) {
            highlighted = !highlighted;
            return;
        }
        ListView.view.model.select(index);
    }
    onDoubleClicked: {
        if (!interactive)
            return;
        ListView.view.model.select(index);
        if (CurrentConversation.isSwarm && !CurrentConversation.isCoreDialog)
            return; // For now disable calls for swarm with multiple participants
        if (LRCInstance.currentAccountType === Profile.Type.SIP || !CurrentAccount.videoEnabled_Video)
            CallAdapter.startAudioOnlyCall();
        else {
            if (!CurrentConversation.readOnly) {
                CallAdapter.startCall();
            }
        }
    }
    onPressAndHold: {
        if (!interactive)
            return;
        ListView.view.openContextMenuAt(pressX, pressY, root);
    }

    MouseArea {
        anchors.fill: parent
        enabled: interactive
        acceptedButtons: Qt.RightButton
        onClicked: function (mouse) {
            root.ListView.view.openContextMenuAt(mouse.x, mouse.y, root);
        }
        // onHoveredChanged: {
        //     if (hovered) {
        //         contentRect.scale = 1.1
        //     } else {
        //         contentRect.scale = 1.0
        //     }
        // }
    }
}
