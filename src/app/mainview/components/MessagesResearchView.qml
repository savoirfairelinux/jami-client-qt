/*
 * Copyright (C) 2024-2025 Savoir-faire Linux Inc.
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
    footer: Item {
        width: root.width
        height: 16
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

    property string prompt: MessagesAdapter.searchbarPrompt

    onPromptChanged: MessagesAdapter.startSearch(prompt, false);
    onVisibleChanged: visible && MessagesAdapter.startSearch(prompt, false);

    Connections {
        target: CurrentConversation
        function onIdChanged() {
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
            spacing: 5
            Layout.fillWidth: true

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
                width: parent.width
                Layout.fillWidth: true
                spacing: 10

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
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        id: nameText
                        text: contentRow.isMe ? CurrentAccount.bestName : UtilsAdapter.getBestNameForUri(CurrentAccount.id, Author) + " :"
                        Layout.fillWidth: true
                        Layout.rightMargin: 10
                        Layout.leftMargin: 10
                        font.pixelSize: 0
                        color: JamiTheme.chatviewSecondaryInformationColor
                        font.bold: true
                        elide: Text.ElideRight
                    }

                    TextEdit {
                        id: myText
                        text: Body
                        color: JamiTheme.textColor
                        Layout.preferredWidth: contentRow.width - avatar.width
                        Layout.fillWidth: true
                        wrapMode: Text.Wrap
                        readOnly: true
                        selectByMouse: true
                        Layout.rightMargin: 10
                        Layout.leftMargin: 10
                        font.pixelSize: IsEmojiOnly ? JamiTheme.chatviewEmojiSize : JamiTheme.chatviewFontSize

                        // Limit height to approximately 4 lines
                        property int lineHeight: font.pixelSize * 1.2
                        Layout.maximumHeight: lineHeight * 4
                        clip: true

                        // Add fade-out effect for text that is too high
                        layer.enabled: contentHeight > Layout.maximumHeight
                        layer.effect: OpacityMask {
                            maskSource: Item {
                                width: myText.width
                                height: myText.height

                                Rectangle {
                                    anchors.fill: parent
                                    gradient: Gradient {
                                        GradientStop { position: 0.0; color: "white" }
                                        GradientStop { position: 0.5; color: "white" }
                                        GradientStop { position: 0.75; color: Qt.rgba(1, 1, 1, 0.5) }
                                        GradientStop { position: 1.0; color: "transparent" }
                                    }
                                }
                            }
                        }
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
