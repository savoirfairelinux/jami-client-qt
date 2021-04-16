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

    Component.onCompleted: {
        if (ContactType === Profile.Type.TEMPORARY)
            ListView.view.model.updateContactAvatarUid(URI)
        avatar.updateImage(URI, PictureUid)
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 15
        anchors.rightMargin: 15
        spacing: 10
        AvatarImage {
            id: avatar

            Layout.preferredWidth: JamiTheme.smartListAvatarSize
            Layout.preferredHeight: JamiTheme.smartListAvatarSize

            mode: AvatarImage.Mode.FromContactUri
            showPresenceIndicator: Presence === undefined ? false : Presence
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.topMargin: 0
            spacing: 2
            // best name
            Text {
                Layout.fillWidth: true
                Layout.preferredHeight: 20
                Layout.alignment: Qt.AlignVCenter
                elide: Text.ElideRight
                text: DisplayName === undefined ? "" : DisplayName
                font.pointSize: JamiTheme.smartlistItemFontSize
                font.weight: UnreadMessagesCount ? Font.Bold : Font.Normal
                color: JamiTheme.textColor
            }
            RowLayout {
                visible: ContactType !== Profile.Type.TEMPORARY
                Layout.fillWidth: true
                Layout.preferredHeight: 20
                Layout.alignment: Qt.AlignTop
                // last Interaction date
                Text {
                    Layout.alignment: Qt.AlignVCenter
                    visible: text !== ""
                    text: LastInteractionDate === undefined ? "" : LastInteractionDate
                    font.pointSize: JamiTheme.smartlistItemInfoFontSize
                    font.weight: UnreadMessagesCount ? Font.DemiBold : Font.Normal
                    color: JamiTheme.textColor
                }
                // last Interaction
                Text {
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    visible: text !== ""
                    text: Draft ?
                              Draft :
                              (LastInteraction === undefined ? "" : LastInteraction)
                    font.pointSize: JamiTheme.smartlistItemInfoFontSize
                    font.weight: UnreadMessagesCount ? Font.Normal : Font.Light
                    font.hintingPreference: Font.PreferNoHinting
                    maximumLineCount: 1
                    color: Draft ? JamiTheme.draftTextColor : JamiTheme.textColor
                }
            }
        }

        ColumnLayout {
            visible: InCall || UnreadMessagesCount
            Layout.preferredWidth: childrenRect.width
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignVCenter
            // unread message count
            BadgeNotifier {
                size: 20
                count: UnreadMessagesCount
                Layout.alignment: Qt.AlignRight
            }
            // call status
            Text {
                Layout.alignment: Qt.AlignRight
                visible: text !== ""
                text: InCall ? UtilsAdapter.getCallStatusStr(CallState) : ""
                font.pointSize: JamiTheme.smartlistItemInfoFontSize
                font.weight: Font.Medium
                color: JamiTheme.textColor
            }
        }
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

    onClicked: ListView.view.model.select(index)
    onDoubleClicked: {
        ListView.view.model.select(index)
        if (AccountAdapter.currentAccountType === Profile.Type.SIP)
            CallAdapter.placeAudioOnlyCall()
        else
            CallAdapter.placeCall()
        // TODO: factor this out (visible should be observing)
        communicationPageMessageWebView.setSendContactRequestButtonVisible(false)
    }
    onPressAndHold: ListView.view.openContextMenuAt(pressX, pressY, root)

    MouseArea {
        anchors.fill: parent
        propagateComposedEvents: true
        acceptedButtons: Qt.RightButton
        onClicked: {
            root.ListView.view.openContextMenuAt(mouse.x, mouse.y, root)
        }
    }
}
