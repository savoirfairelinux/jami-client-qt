/*
 * Copyright (C) 2020-2023 Savoir-faire Linux Inc.
 * Author: Mingrui Zhang <mingrui.zhang@savoirfairelinux.com>
 * Author: Andreas Traczyk <andreas.traczyk@savoirfairelinux.com>
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

    property string accountId: ""
    property string convId: ""

    highlighted: ListView.isCurrentItem
    property bool interactive: true
    property string lastInteractionDate: LastInteractionTimeStamp === undefined
                                         ? ""
                                         : LastInteractionTimeStamp

    property string lastInteractionFormattedDate: MessagesAdapter.getBestFormattedDate(lastInteractionDate)

    Connections {
        target: UtilsAdapter
        function onChangeLanguage() {
            UtilsAdapter.clearInteractionsCache(root.accountId, root.convId)
        }
    }

    property bool showSharePositionIndicator: PositionManager.isPositionSharedToConv(accountId, UID)
    property bool showSharedPositionIndicator: PositionManager.isConvSharingPosition(accountId, UID)

    Connections {
        target: PositionManager
        function onPositionShareConvIdsCountChanged () {
            root.showSharePositionIndicator = PositionManager.isPositionSharedToConv(accountId, UID)
        }
        function onSharingUrisCountChanged () {
            root.showSharedPositionIndicator = PositionManager.isConvSharingPosition(accountId, UID)
        }
    }

    Connections {
        target: MessagesAdapter
        function onTimestampUpdated() {
            lastInteractionFormattedDate = MessagesAdapter.getBestFormattedDate(lastInteractionDate)
        }
    }

    Component.onCompleted: {
        // Store to avoid undefined at the end
        root.accountId = Qt.binding(() => CurrentAccount.id)
        root.convId = UID
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 15
        anchors.rightMargin: 15
        spacing: 10

        ConversationAvatar {
            id: avatar

            imageId: UID
            showPresenceIndicator: Presence !== undefined ? Presence : false

            Layout.preferredWidth: JamiTheme.smartListAvatarSize
            Layout.preferredHeight: JamiTheme.smartListAvatarSize

            Rectangle {
                id: overlayHighlighted
                visible: highlighted && !interactive

                anchors.fill: parent
                color: Qt.rgba(0, 0, 0, 0.5)
                radius: JamiTheme.smartListAvatarSize / 2

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
                visible: ContactType !== Profile.Type.TEMPORARY
                         && !IsBanned
                         && lastInteractionFormattedDate !== undefined
                         && interactive
                Layout.fillWidth: true
                Layout.minimumHeight: 20
                Layout.alignment: Qt.AlignTop

                // last Interaction date
                Text {
                    Layout.alignment: Qt.AlignVCenter
                    text: lastInteractionFormattedDate === undefined ? "" : lastInteractionFormattedDate
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
                    text: Draft ?
                              Draft :
                              (LastInteraction === undefined ? "" : LastInteraction)
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
                text: JamiStrings.banned
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

                visible : text
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





        Accessible.role: Accessible.Button
        Accessible.name: Title === undefined? "" : Title
        Accessible.description: LastInteraction === undefined? "" : LastInteraction
    }

    background: Rectangle {
        color: {
            if (root.pressed || root.highlighted)
                return JamiTheme.smartListSelectedColor
            else if (root.hovered)
                return JamiTheme.smartListHoveredColor
            else
                return "transparent"
        }
    }

    onClicked: {
        if (!interactive) {
            highlighted = !highlighted
            return;
        }
        ListView.view.model.select(index)
    }
    onDoubleClicked: {
        if (!interactive)
            return;
        ListView.view.model.select(index)
        if (CurrentConversation.isSwarm && !CurrentConversation.isCoreDialog && !UtilsAdapter.getAppValue(Settings.EnableExperimentalSwarm))
            return; // For now disable calls for swarm with multiple participants
        if (LRCInstance.currentAccountType === Profile.Type.SIP || !CurrentAccount.videoEnabled_Video)
            CallAdapter.placeAudioOnlyCall()
        else {
            if (!CurrentConversation.readOnly) {
                CallAdapter.placeCall()
            }
        }
    }
    onPressAndHold: {
        if (!interactive)
            return;
        ListView.view.openContextMenuAt(pressX, pressY, root)
    }

    MouseArea {
        anchors.fill: parent
        enabled: interactive
        acceptedButtons: Qt.RightButton
        onClicked: function (mouse) {
            root.ListView.view.openContextMenuAt(mouse.x, mouse.y, root)
        }
    }
}
