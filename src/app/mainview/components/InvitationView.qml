/*
 * Copyright (C) 2020-2023 Savoir-faire Linux Inc.
 * Author: Mingrui Zhang <mingrui.zhang@savoirfairelinux.com>
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
import net.jami.Models 1.1
import "../../commoncomponents"

Rectangle {
    id: root
    property real marginSize: 20
    property real textMarginSize: 50

    color: JamiTheme.primaryBackgroundColor

    Text {
        id: invitationViewSentRequestText
        anchors.horizontalCenter: root.horizontalCenter
        anchors.top: root.top
        anchors.topMargin: visible ? marginSize : 0
        color: JamiTheme.textColor
        font.pointSize: JamiTheme.textFontSize
        height: visible ? contentHeight : 0
        horizontalAlignment: Text.AlignHCenter
        text: JamiStrings.invitationViewSentRequest.arg(CurrentConversation.title)
        verticalAlignment: Text.AlignVCenter
        visible: !CurrentConversation.needsSyncing
        width: infoColumnLayout.width - textMarginSize
        wrapMode: Text.Wrap
    }
    ColumnLayout {
        id: infoColumnLayout
        anchors.centerIn: root
        width: root.width

        Avatar {
            id: avatar
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredHeight: JamiTheme.invitationViewAvatarSize
            Layout.preferredWidth: JamiTheme.invitationViewAvatarSize
            Layout.topMargin: invitationViewSentRequestText.visible ? marginSize : 0
            imageId: CurrentConversation.id
            mode: Avatar.Mode.Conversation
            showPresenceIndicator: false
        }
        Text {
            id: invitationViewMiddlePhraseText
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: infoColumnLayout.width - textMarginSize
            Layout.topMargin: marginSize
            color: JamiTheme.textColor
            font.pointSize: JamiTheme.textFontSize + 3
            font.weight: Font.DemiBold
            horizontalAlignment: Text.AlignHCenter
            text: CurrentConversation.needsSyncing ? JamiStrings.invitationViewAcceptedConversation : JamiStrings.invitationViewJoinConversation
            verticalAlignment: Text.AlignVCenter
            wrapMode: Text.Wrap
        }
        Text {
            id: invitationViewWaitingForSyncText
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredHeight: visible ? contentHeight : 0
            Layout.preferredWidth: infoColumnLayout.width - textMarginSize
            Layout.topMargin: marginSize
            color: JamiTheme.textColor
            font.pointSize: JamiTheme.textFontSize
            horizontalAlignment: Text.AlignHCenter
            text: JamiStrings.invitationViewWaitingForSync.arg(CurrentConversation.title)
            verticalAlignment: Text.AlignVCenter
            visible: CurrentConversation.needsSyncing
            wrapMode: Text.Wrap
        }
        RowLayout {
            id: buttonGroupRowLayout
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: marginSize
            spacing: JamiTheme.invitationViewButtonsSpacing
            visible: !CurrentConversation.needsSyncing

            PushButton {
                id: blockButton
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredHeight: JamiTheme.invitationViewButtonSize
                Layout.preferredWidth: JamiTheme.invitationViewButtonSize
                hoveredColor: JamiTheme.blockOrange
                imageColor: JamiTheme.primaryBackgroundColor
                normalColor: JamiTheme.blockOrangeTransparency
                preferredSize: JamiTheme.invitationViewButtonIconSize
                pressedColor: JamiTheme.blockOrange
                radius: JamiTheme.invitationViewButtonRadius
                source: JamiResources.block_black_24dp_svg
                toolTipText: JamiStrings.blockContact

                onClicked: MessagesAdapter.blockConversation()
            }
            PushButton {
                id: refuseButton
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredHeight: JamiTheme.invitationViewButtonSize
                Layout.preferredWidth: JamiTheme.invitationViewButtonSize
                hoveredColor: JamiTheme.refuseRed
                imageColor: JamiTheme.primaryBackgroundColor
                normalColor: JamiTheme.refuseRedTransparent
                preferredSize: JamiTheme.invitationViewButtonSize
                pressedColor: JamiTheme.refuseRed
                radius: JamiTheme.invitationViewButtonRadius
                source: JamiResources.cross_black_24dp_svg
                toolTipText: JamiStrings.declineContactRequest

                onClicked: MessagesAdapter.refuseInvitation()
            }
            PushButton {
                id: acceptButton
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredHeight: JamiTheme.invitationViewButtonSize
                Layout.preferredWidth: JamiTheme.invitationViewButtonSize
                hoveredColor: JamiTheme.acceptGreen
                imageColor: JamiTheme.primaryBackgroundColor
                normalColor: JamiTheme.acceptGreenTransparency
                preferredSize: JamiTheme.invitationViewButtonIconSize
                pressedColor: JamiTheme.acceptGreen
                radius: JamiTheme.invitationViewButtonRadius
                source: JamiResources.check_black_24dp_svg
                toolTipText: JamiStrings.acceptContactRequest

                onClicked: MessagesAdapter.acceptInvitation()
            }
        }
    }
}
