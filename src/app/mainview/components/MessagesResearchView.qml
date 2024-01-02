/*
 * Copyright (C) 2024 Savoir-faire Linux Inc.
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

    spacing: 10
    model: SortFilterProxyModel {
        id: proxyModel

        property var messageListModel: MessagesAdapter.mediaMessageListModel
        readonly property int textType: Interaction.Type.TEXT

        onMessageListModelChanged: sourceModel = root.visible && messageListModel ? messageListModel : null

        filters: ExpressionFilter {
            expression: Type === proxyModel.textType
        }
    }

    property var prompt: MessagesAdapter.searchbarPrompt

    onPromptChanged: {
        MessagesAdapter.startSearch(prompt, false);
    }

    Connections {
        target: researchTabBar
        function onFilterTabChange() {
            MessagesAdapter.startSearch(prompt, false);
        }
    }

    delegate: Item {
        width: root.width
        height: msgLayout.height

        HoverHandler {
            id: msgHover

            target: parent
        }

        ColumnLayout {
            id: msgLayout

            width: root.width

            TimestampInfo {
                id: timestampItem

                showDay: true
                showTime: true
                formattedTime: MessagesAdapter.getFormattedTime(Timestamp)
                formattedDay: MessagesAdapter.getFormattedDay(Timestamp)
            }

            RowLayout {
                id: contentRow

                property bool isMe: Author === CurrentAccount.uri

                Avatar {
                    id: avatar

                    width: 30
                    height: 30
                    imageId: contentRow.isMe ? CurrentAccount.id : Author
                    showPresenceIndicator: false
                    mode: contentRow.isMe ? Avatar.Mode.Account : Avatar.Mode.Contact
                    Layout.leftMargin: 10
                }

                ColumnLayout {

                    Text {
                        text: contentRow.isMe ? CurrentAccount.bestName : UtilsAdapter.getBestNameForUri(CurrentAccount.id, Author) + " :"
                        Layout.preferredWidth: myText.width
                        Layout.rightMargin: 10
                        Layout.leftMargin: 10
                        font.pixelSize: 0
                        color: JamiTheme.chatviewSecondaryInformationColor
                        font.bold: true
                    }

                    Text {
                        id: myText

                        text: Body
                        color: JamiTheme.textColor
                        Layout.preferredWidth: msgLayout.width - avatar.width - 30 - 10
                        elide: Text.ElideRight
                        Layout.rightMargin: 10
                        Layout.leftMargin: 10
                        font.pixelSize: IsEmojiOnly ? JamiTheme.chatviewEmojiSize : JamiTheme.chatviewFontSize
                        Layout.alignment: Qt.AlignHCenter
                    }
                }
            }
        }

        Button {
            id: buttonJumpTo

            visible: msgHover.hovered || hovered
            anchors.top: msgLayout.top
            anchors.right: msgLayout.right
            anchors.rightMargin: 20
            anchors.topMargin: timestampItem.height - 20
            width: buttonJumpText.width + 10
            height: buttonJumpText.height + 10
            background.visible: false

            onClicked: {
                CurrentConversation.scrollToMsg(Id);
            }

            Text {
                id: buttonJumpText

                text: JamiStrings.jumpTo
                color: buttonJumpTo.hovered ? JamiTheme.blueLinkColor : JamiTheme.chatviewSecondaryInformationColor
                font.underline: buttonJumpTo.hovered
                anchors.centerIn: parent
                font.pointSize: JamiTheme.jumpToFontSize
            }
        }
    }
}
