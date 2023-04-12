/*
 * Copyright (C) 2023 Savoir-faire Linux Inc.
 * Author: Nicolas Vengeon <nicolas.vengeon@savoirfairelinux.com>
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
import Qt.labs.platform
import Qt5Compat.GraphicalEffects
import SortFilterProxyModel
import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import "../../commoncomponents"
import "../../settingsview/components"

ListView {
    id: root
    property var prompt: MessagesAdapter.searchbarPrompt

    spacing: 10

    onPromptChanged: {
        MessagesAdapter.startSearch(prompt);
    }

    Connections {
        target: researchTabBar

        function onFilterTabChange() {
            MessagesAdapter.startSearch(prompt);
        }
    }

    delegate: Item {
        height: msgLayout.height
        width: root.width

        HoverHandler {
            id: msgHover
            target: parent
        }
        ColumnLayout {
            id: msgLayout
            width: root.width

            TimestampInfo {
                id: timestampItem
                formattedDay: MessagesAdapter.getFormattedDay(Timestamp)
                formattedTime: MessagesAdapter.getFormattedTime(Timestamp)
                showDay: true
                showTime: true
            }
            RowLayout {
                id: contentRow
                property bool isMe: Author === CurrentAccount.uri

                Avatar {
                    id: avatar
                    Layout.leftMargin: 10
                    height: 30
                    imageId: contentRow.isMe ? CurrentAccount.id : Author
                    mode: contentRow.isMe ? Avatar.Mode.Account : Avatar.Mode.Contact
                    showPresenceIndicator: false
                    width: 30
                }
                ColumnLayout {
                    Text {
                        Layout.leftMargin: 10
                        Layout.preferredWidth: myText.width
                        Layout.rightMargin: 10
                        color: JamiTheme.chatviewUsernameColor
                        font.bold: true
                        font.pixelSize: 0
                        text: contentRow.isMe ? CurrentAccount.bestName : UtilsAdapter.getBestNameForUri(CurrentAccount.id, Author) + " :"
                    }
                    Text {
                        id: myText
                        Layout.alignment: Qt.AlignHCenter
                        Layout.leftMargin: 10
                        Layout.preferredWidth: msgLayout.width - avatar.width - 30 - 10
                        Layout.rightMargin: 10
                        color: JamiTheme.textColor
                        elide: Text.ElideRight
                        font.pixelSize: IsEmojiOnly ? JamiTheme.chatviewEmojiSize : JamiTheme.chatviewFontSize
                        text: Body
                    }
                }
            }
        }
        Button {
            id: buttonJumpTo
            anchors.right: msgLayout.right
            anchors.rightMargin: 20
            anchors.top: msgLayout.top
            anchors.topMargin: timestampItem.height - 20
            background.visible: false
            height: buttonJumpText.height + 10
            visible: msgHover.hovered || hovered
            width: buttonJumpText.width + 10

            onClicked: {
                CurrentConversation.scrollToMsg(Id);
            }

            Text {
                id: buttonJumpText
                anchors.centerIn: parent
                color: buttonJumpTo.hovered ? JamiTheme.blueLinkColor : JamiTheme.chatviewUsernameColor
                font.pointSize: JamiTheme.jumpToFontSize
                font.underline: buttonJumpTo.hovered
                text: JamiStrings.jumpTo
            }
        }
    }
    model: SortFilterProxyModel {
        id: proxyModel
        property var messageListModel: MessagesAdapter.mediaMessageListModel
        readonly property int textType: Interaction.Type.TEXT

        onMessageListModelChanged: sourceModel = root.visible && messageListModel ? messageListModel : null

        filters: ExpressionFilter {
            expression: Type === proxyModel.textType
        }
    }
}
