/*
 * Copyright (C) 2020-2022 Savoir-faire Linux Inc.
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

import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1

import "../../commoncomponents"

ItemDelegate {
    id: root

    width: ListView.view.width
    height: JamiTheme.smartListItemHeight

    property string accountId: ""
    property string convId: ""

    highlighted: ListView.isCurrentItem
    property bool interactive: true

    onVisibleChanged: {
        if (visible)
            return
        UtilsAdapter.clearInteractionsCache(root.accountId, root.convId)
    }

    Component.onCompleted: {
        // Store to avoid undefined at the end
        root.accountId = CurrentAccount.id
        root.convId = UID
    }

    Component.onDestruction: {
        UtilsAdapter.clearInteractionsCache(root.accountId, root.convId)
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
            showSharePositionIndicator: MessagesAdapter.isPositionSharedToConv(UID)
            showSharedPositionIndicator: MessagesAdapter.isConvSharingPosition(UID)

            Layout.preferredWidth: JamiTheme.smartListAvatarSize
            Layout.preferredHeight: JamiTheme.smartListAvatarSize

            Connections {
                target: MessagesAdapter
                function onPositionShareConvIdsChanged () {
                    avatar.showSharePositionIndicator = MessagesAdapter.isPositionSharedToConv(UID)

                }
                function onSharingUrisChanged () {
                    avatar.showSharedPositionIndicator = MessagesAdapter.isConvSharingPosition(UID)
                }
            }

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
                elide: Text.ElideMiddle
                text: Title === undefined ? "" : Title
                textFormat: TextEdit.PlainText
                font.pointSize: JamiTheme.smartlistItemFontSize
                font.weight: UnreadMessagesCount ? Font.Bold : Font.Normal
                color: JamiTheme.textColor
            }
            RowLayout {
                visible: ContactType !== Profile.Type.TEMPORARY
                         && !IsBanned
                         && LastInteractionDate !== undefined
                         && interactive
                Layout.fillWidth: true
                Layout.minimumHeight: 20
                Layout.alignment: Qt.AlignTop

                // last Interaction date
                Text {
                    Layout.alignment: Qt.AlignVCenter
                    text: LastInteractionDate === undefined ? "" : LastInteractionDate
                    textFormat: TextEdit.PlainText
                    font.pointSize: JamiTheme.smartlistItemInfoFontSize
                    font.weight: UnreadMessagesCount ? Font.DemiBold : Font.Normal
                    color: JamiTheme.textColor
                }

                // last Interaction
                Text {
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    text: Draft ?
                              Draft :
                              (LastInteraction === undefined ? "" : LastInteraction)
                    textFormat: TextEdit.PlainText
                    font.pointSize: JamiTheme.smartlistItemInfoFontSize
                    font.weight: UnreadMessagesCount ? Font.Normal : Font.Light
                    font.hintingPreference: Font.PreferNoHinting
                    maximumLineCount: 1
                    color: JamiTheme.textColor
                    // deal with poor rendering of the pencil emoji on Windows
                    font.family: Qt.platform.os === "windows" && Draft ?
                                     "Segoe UI Emoji" :
                                     Qt.application.font.family
                    lineHeight: font.family === "Segoe UI Emoji" ? 1.25 : 1
                }
            }
            Text {
                Layout.fillWidth: true
                Layout.minimumHeight: 20
                Layout.alignment: Qt.AlignVCenter
                text: JamiStrings.banned
                textFormat: TextEdit.PlainText
                visible: IsBanned
                font.pointSize: JamiTheme.smartlistItemFontSize
                font.weight: Font.Bold
                color: JamiTheme.textColor
            }
        }

        // Draft indicator
        ResponsiveImage {
            visible: Draft && !root.highlighted
            source: JamiResources.round_edit_24dp_svg
            color: JamiTheme.primaryForegroundColor
        }

        ColumnLayout {
            Layout.fillHeight: true
            spacing: 2

            // call status
            Text {
                id: callStatusText

                Layout.minimumHeight: 20
                Layout.alignment: Qt.AlignRight
                text: InCall ? UtilsAdapter.getCallStatusStr(CallState) : ""
                textFormat: TextEdit.PlainText
                font.pointSize: JamiTheme.smartlistItemInfoFontSize
                font.weight: Font.Medium
                color: JamiTheme.textColor
            }

            // unread message count
            Item {
                Layout.preferredWidth: childrenRect.width
                Layout.preferredHeight: childrenRect.height
                Layout.alignment: Qt.AlignTop | Qt.AlignRight
                BadgeNotifier {
                    size: 20
                    count: UnreadMessagesCount
                    animate: index === 0
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
                return Qt.darker(JamiTheme.selectedColor, 1.1)
            else if (root.hovered)
                return Qt.darker(JamiTheme.selectedColor, 1.05)
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
