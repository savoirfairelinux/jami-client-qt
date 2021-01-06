/*
 * Copyright (C) 2020 by Savoir-faire Linux
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

import QtQuick 2.14
import QtQuick.Controls 2.14
import QtQuick.Layouts 1.14
import net.jami.Models 1.0
import net.jami.Adapters 1.0
import net.jami.Constants 1.0

import "../../commoncomponents"

ItemDelegate {
    id: smartListItemDelegate
    height: isSelectable? 48 : 72

    property int lastInteractionPreferredWidth: 80
    property bool isSelectable: false
    property bool isSelected: false

    signal updateContactAvatarUidRequested(string uid)

    function convUid() {
        return UID
    }

    Connections {
        target: conversationSmartListView


        // Hack, make sure that smartListItemDelegate does not show extra item
        // when searching new contacts.
        function onForceUpdatePotentialInvalidItem() {
            smartListItemDelegate.visible = conversationSmartListView.model.rowCount(
                        ) <= index ? false : true
        }


        // When currentIndex is -1, deselect items, if not, change select item
        function onCurrentIndexChanged() {
            if (conversationSmartListView.currentIndex === -1
                    || conversationSmartListView.currentIndex !== index) {
                itemSmartListBackground.color = Qt.binding(function () {
                    return InCall ? Qt.lighter(JamiTheme.selectionBlue,
                                               1.8) : JamiTheme.backgroundColor
                })
            } else {
                itemSmartListBackground.color = Qt.binding(function () {
                    return InCall ? Qt.lighter(JamiTheme.selectionBlue,
                                               1.8) : JamiTheme.selectedColor
                })
                ConversationsAdapter.selectConversation(
                            AccountAdapter.currentAccountId, UID)
            }
        }
    }

    Connections {
        target: ConversationsAdapter

        function onShowConversation(accountId, convUid) {
            if (convUid === UID) {
                mainView.setMainView(DisplayID == DisplayName ? "" : DisplayID,
                            DisplayName, UID, CallStackViewShouldShow, IsAudioOnly, CallState)
            }
        }
    }

    AvatarImage {
        id: conversationSmartListUserImage

        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: 16

        width: isSelectable? 36 : 40
        height: isSelectable? 36 : 40

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
                elideWidth: LastInteractionDate ? (smartListItemDelegate.width - lastInteractionPreferredWidth - conversationSmartListUserImage.width-32) :
                                                  smartListItemDelegate.width - lastInteractionPreferredWidth
                text: DisplayName === undefined ? "" : DisplayName
            }
            text: textMetricsConversationSmartListUserName.elidedText
            font.pointSize: isSelectable? JamiTheme.textFontSize : JamiTheme.menuFontSize
            color: JamiTheme.textColor
        }

        Text {
            visible: !isSelectable

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
        visible: !isSelectable

        TextMetrics {
            id: textMetricsConversationSmartListUserLastInteractionMessage
            font: conversationSmartListUserLastInteractionMessage.font
            elide: Text.ElideRight
            elideWidth: LastInteractionDate ? (smartListItemDelegate.width - lastInteractionPreferredWidth - conversationSmartListUserImage.width-32) :
                                              smartListItemDelegate.width - lastInteractionPreferredWidth
            text: InCall ? UtilsAdapter.getCallStatusStr(CallState) : (Draft ? Draft : LastInteraction)
        }

        font.family: Qt.platform.os === "windows" ? "Segoe UI Emoji" : Qt.application.font.family
        font.hintingPreference: Font.PreferNoHinting
        text: textMetricsConversationSmartListUserLastInteractionMessage.elidedText
        maximumLineCount: 1
        font.pointSize: JamiTheme.textFontSize
        color: Draft ? JamiTheme.draftRed : JamiTheme.faddedLastInteractionFontColor
    }

    Rectangle {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.rightMargin: 14

        width: 16
        height: 16
        radius: 8
        visible: isSelectable

        color: "transparent"
        border.width: 1
        border.color: JamiTheme.textColor

        ResponsiveImage {
            id: isSelectedImage

            anchors.centerIn: parent

            width: 12
            height: 12

            visible: isSelected

            color: JamiTheme.textColor

            source: "qrc:/images/icons/check-24px.svg"
        }
    }


    background: Rectangle {
        id: itemSmartListBackground
        color: InCall ? Qt.lighter(JamiTheme.selectionBlue, 1.8) : JamiTheme.backgroundColor
        implicitWidth: conversationSmartListView.width
        implicitHeight: parent.height
        border.width: 0
    }

    MouseArea {
        id: mouseAreaSmartListItemDelegate

        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        onPressed: {
            if (!InCall) {
                itemSmartListBackground.color = JamiTheme.pressColor
            }
        }
        onDoubleClicked: {
            if (!isSelectable && !InCall) {
                ConversationsAdapter.selectConversation(AccountAdapter.currentAccountId,
                                                        UID,
                                                        false)
                CallAdapter.placeCall()
                communicationPageMessageWebView.setSendContactRequestButtonVisible(false)
            }
        }
        onReleased: {
            if (isSelectable) {
                isSelected = !isSelected
            } else {
                if (!InCall) {
                    itemSmartListBackground.color = JamiTheme.selectionBlue
                }
                if (mouse.button === Qt.RightButton) {
                    smartListContextMenu.parent = mouseAreaSmartListItemDelegate

                    // Make menu pos at mouse.
                    var relativeMousePos = mapToItem(itemSmartListBackground,
                                                     mouse.x, mouse.y)
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
                } else if (mouse.button === Qt.LeftButton) {
                    conversationSmartListView.currentIndex = -1
                    conversationSmartListView.currentIndex = index
                }
            }
        }
        onEntered: {
            if (!InCall) {
                itemSmartListBackground.color = JamiTheme.hoverColor
            }
        }
        onExited: {
            if (!InCall) {
                if (conversationSmartListView.currentIndex !== index
                        || conversationSmartListView.currentIndex === -1) {
                    itemSmartListBackground.color = Qt.binding(function () {
                        return InCall ? Qt.lighter(JamiTheme.selectionBlue,
                                                   1.8) : JamiTheme.backgroundColor
                    })
                } else {
                    itemSmartListBackground.color = Qt.binding(function () {
                        return InCall ? Qt.lighter(JamiTheme.selectionBlue,
                                                   1.8) : JamiTheme.selectedColor
                    })
                }
            }
        }
    }
}
