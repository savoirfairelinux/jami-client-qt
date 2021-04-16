/*
 * Copyright (C) 2020-2021 by Savoir-faire Linux
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

import QtQuick 2.14
import QtQuick.Controls 2.14
import QtQuick.Layouts 1.14

import net.jami.Models 1.0
import net.jami.Adapters 1.0
import net.jami.Constants 1.0

import "../../commoncomponents"

ItemDelegate {
    id: root

    property int lastInteractionPreferredWidth: 80
    signal updateContactAvatarUidRequested(string uid)

    width: ListView.view.width
    height: JamiTheme.smartListItemHeight

    function convUid() {
        return UID
    }

    Connections {
        target: ConversationsAdapter

        function onShowConversation(accountId, convUid) {
            if (convUid === UID) {
                mainView.setMainView(DisplayID === DisplayName ? "" : DisplayID,
                                     DisplayName, UID, CallStackViewShouldShow,
                                     IsAudioOnly, CallState)
            }
        }
    }

    AvatarImage {
        id: conversationSmartListUserImage

        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: 16

        width: 40
        height: 40

        mode: AvatarImage.Mode.FromContactUri

        showPresenceIndicator: Presence === undefined ? false : Presence

        unreadMessagesCount: UnreadMessagesCount

        Component.onCompleted: {
            var contactUid = URI
            if (ContactType === Profile.Type.TEMPORARY)
                updateContactAvatarUidRequested(contactUid)
            updateImage(contactUid, PictureUid)
        }
    }

    RowLayout {
        id: rowUsernameAndLastInteractionDate
        anchors.left: conversationSmartListUserImage.right
        anchors.leftMargin: 16
        anchors.top: parent.top
        anchors.topMargin: conversationSmartListUserLastInteractionMessage.text !== "" ?
                               16 : parent.height/2-conversationSmartListUserName.height/2
        anchors.right: parent.right
        anchors.rightMargin: 10

        Text {
            id: conversationSmartListUserName
            Layout.alignment: conversationSmartListUserLastInteractionMessage.text !== "" ?
                                  Qt.AlignLeft : Qt.AlignLeft | Qt.AlignVCenter

            TextMetrics {
                id: textMetricsConversationSmartListUserName
                font: conversationSmartListUserName.font
                elide: Text.ElideRight
                elideWidth: LastInteractionDate ? (root.width - lastInteractionPreferredWidth
                                                   - conversationSmartListUserImage.width-32)
                                                : root.width - lastInteractionPreferredWidth
                text: DisplayName === undefined ? "" : DisplayName
            }
            text: textMetricsConversationSmartListUserName.elidedText
            font.pointSize: JamiTheme.smartlistItemFontSize
            color: JamiTheme.textColor
        }

        Text {
            id: conversationSmartListUserLastInteractionDate
            Layout.alignment: Qt.AlignRight
            TextMetrics {
                id: textMetricsConversationSmartListUserLastInteractionDate
                font: conversationSmartListUserLastInteractionDate.font
                elide: Text.ElideRight
                elideWidth: lastInteractionPreferredWidth
                text: LastInteractionDate === undefined ? "" : LastInteractionDate
            }

            text: textMetricsConversationSmartListUserLastInteractionDate.elidedText
            font.pointSize: JamiTheme.textFontSize
            color: JamiTheme.faddedLastInteractionFontColor
        }
    }

    Text {
        id: conversationSmartListUserLastInteractionMessage

        anchors.left: conversationSmartListUserImage.right
        anchors.leftMargin: 16
        anchors.bottom: rowUsernameAndLastInteractionDate.bottom
        anchors.bottomMargin: -20

        TextMetrics {
            id: textMetricsConversationSmartListUserLastInteractionMessage
            font: conversationSmartListUserLastInteractionMessage.font
            elide: Text.ElideRight
            elideWidth: LastInteractionDate ? (root.width - lastInteractionPreferredWidth
                                               - conversationSmartListUserImage.width-32)
                                            : root.width - lastInteractionPreferredWidth
            text: InCall ? UtilsAdapter.getCallStatusStr(CallState) : (Draft ? Draft : LastInteraction)
        }

        font.family: Qt.platform.os === "windows" ? "Segoe UI Emoji" : Qt.application.font.family
        font.hintingPreference: Font.PreferNoHinting
        text: textMetricsConversationSmartListUserLastInteractionMessage.elidedText
        maximumLineCount: 1
        font.pointSize: JamiTheme.textFontSize
        color: Draft ? JamiTheme.draftRed : JamiTheme.faddedLastInteractionFontColor
    }

    background: Rectangle {
        color: {
            if (root.pressed)
                return Qt.darker(JamiTheme.selectedColor, 1.1)
            else if (root.hovered)
                return Qt.darker(JamiTheme.selectedColor, 1.05)
            else
                return "transparent"
        }
    }

    onClicked: ConversationListProxyModel.select(index)
    onDoubleClicked: {
        // ??? if (!InCall) {
        ConversationListProxyModel.select(index)
        if (AccountAdapter.currentAccountType === Profile.Type.SIP)
            CallAdapter.placeAudioOnlyCall()
        else
            CallAdapter.placeCall()
        // TODO: factor this out
        communicationPageMessageWebView.setSendContactRequestButtonVisible(false)
    }
    onPressAndHold: openContextMenu(mouse)

    function openContextMenu(mouse) {
        openedMenu = true
        smartListContextMenu.parent = mouseAreaSmartListItemDelegate

        // spawn a menu at the current mouse position
        var relativeMousePos = mapToItem(root, mouse.x, mouse.y)
        smartListContextMenu.x = relativeMousePos.x
        smartListContextMenu.y = relativeMousePos.y
        smartListContextMenu.responsibleAccountId = AccountAdapter.currentAccountId
        smartListContextMenu.responsibleConvUid = UID
        smartListContextMenu.contactType = ContactType
        userProfile.responsibleConvUid = UID
        userProfile.aliasText = DisplayName
        userProfile.registeredNameText = DisplayID
        userProfile.idText = URI
        userProfile.contactImageUid = UID
        smartListContextMenu.openMenu()
    }
}
