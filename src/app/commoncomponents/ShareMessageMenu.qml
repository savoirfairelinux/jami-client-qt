/*
 * Copyright (C) 2024-2026 Savoir-faire Linux Inc.
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
import net.jami.Constants 1.1
import net.jami.Adapters 1.1
import "../mainview/components"

BaseModalDialog {
    id: mainMenu

    titleText: JamiStrings.share
    title: titleText
    implicitWidth: parent ? Math.min(400, Math.max(0, parent.width - 32)) : 400
    height: Math.min(parent.height * 0.7, Math.max(0, parent.height - 64))

    required property string msgBody
    required property int type
    required property var viewCoordinator
    property string transferName: ""
    property color messageColor: JamiTheme.messageInBgColor

    onOpened: picker.focusSearch()

    Connections {
        target: LRCInstance

        function onCurrentAccountIdChanged() {
            mainMenu.close();
        }

        function onCurrentAccountRemoved() {
            mainMenu.close();
        }
    }

    Connections {
        target: CurrentConversation

        function onIdChanged() {
            mainMenu.close();
        }
    }

    contentItem: GridLayout {
        id: shareContent
        columns: 2

        ConversationPicker {
            id: picker
            objectName: "conversationPicker"

            Layout.columnSpan: 2
            Layout.fillWidth: true
            Layout.fillHeight: true

            viewCoordinator: mainMenu.viewCoordinator
            forSharing: true
        }

        Rectangle {
            Layout.columnSpan: 2
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: JamiTheme.menuSeparatorColor
        }

        Label {
            objectName: "sharedMessagePreview"

            Layout.columnSpan: 2
            Layout.alignment: Qt.AlignLeft
            Layout.maximumWidth: shareContent.width

            leftPadding: 12
            rightPadding: 12
            topPadding: 8
            bottomPadding: 8
            font.pointSize: JamiTheme.mediumFontSize
            text: mainMenu.type === 2 ? mainMenu.msgBody
                                      : (mainMenu.transferName || UtilsAdapter.fileName(mainMenu.msgBody))
            textFormat: Text.PlainText
            maximumLineCount: 1
            elide: Text.ElideRight
            color: UtilsAdapter.luma(mainMenu.messageColor) ? JamiTheme.chatviewTextColorLight
                                                           : JamiTheme.chatviewTextColorDark

            background: MessageBubble {
                color: mainMenu.messageColor
                radius: JamiTheme.messageBubbleRadius
            }
        }

        Flickable {
            id: commentField
            objectName: "shareMessageCommentField"

            Layout.fillWidth: true
            Layout.minimumHeight: JamiTheme.chatViewFooterButtonSize
            Layout.preferredHeight: Math.ceil(messageInput.contentHeight) + messageInput.topPadding + messageInput.bottomPadding
            Layout.maximumHeight: Math.max(JamiTheme.chatViewFooterButtonSize,
                                           Math.ceil(commentFont.lineSpacing * 4) + messageInput.topPadding + messageInput.bottomPadding)

            flickableDirection: Flickable.VerticalFlick
            boundsBehavior: Flickable.StopAtBounds
            clip: true

            ScrollBar.vertical: JamiScrollBar {
                attachedFlickableMoving: commentField.moving
                topPadding: 14
                bottomPadding: topPadding
                rightPadding: 12
            }

            FontMetrics {
                id: commentFont
                font: messageInput.font
            }

            TextArea.flickable: TextArea {
                id: messageInput
                objectName: "shareMessageComment"

                leftPadding: 20
                rightPadding: leftPadding
                topPadding: 6
                bottomPadding: 6
                verticalAlignment: Text.AlignVCenter

                placeholderText: JamiStrings.addAComment
                placeholderTextColor: JamiTheme.messageBarPlaceholderTextColor
                Accessible.name: placeholderText

                font.pointSize: JamiTheme.textFontSize + 2
                color: JamiTheme.textColor
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere

                background: Rectangle {
                    color: JamiTheme.globalBackgroundColor
                    radius: 18
                    border.color: messageInput.activeFocus ? JamiTheme.tintedBlue : JamiTheme.chatViewFooterRectangleBorderColor
                }
            }
        }

        PushButton {
            objectName: "shareMessageButton"

            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
            Layout.preferredWidth: JamiTheme.chatViewFooterButtonSize
            Layout.preferredHeight: JamiTheme.chatViewFooterButtonSize

            enabled: picker.selectedIds.length > 0
            hoverEnabled: enabled
            radius: JamiTheme.chatViewFooterButtonRadius
            preferredSize: JamiTheme.chatViewFooterButtonIconSize - 6
            imageContainerWidth: 25
            imageContainerHeight: 25
            source: JamiResources.bidirectional_send_black_24dp_svg
            mirror: UtilsAdapter.isRTL
            toolTipText: JamiStrings.share
            Accessible.name: toolTipText

            normalColor: enabled ? JamiTheme.chatViewFooterSendButtonColor :
                                   JamiTheme.chatViewFooterSendButtonDisableColor
            imageColor: enabled ? JamiTheme.chatViewFooterSendButtonImgColor :
                                  JamiTheme.chatViewFooterSendButtonImgColorDisable
            hoveredColor: JamiTheme.buttonTintedBlueHovered
            pressedColor: hoveredColor

            onClicked: {
                for (const uid of picker.selectedIds) {
                    if (mainMenu.type === 2)
                        MessagesAdapter.sendMessageToUid(mainMenu.msgBody, uid);
                    else
                        MessagesAdapter.sendFileToUid(mainMenu.msgBody, uid);
                    if (messageInput.text)
                        MessagesAdapter.sendMessageToUid(messageInput.text, uid);
                }
                mainMenu.close();
            }
        }
    }
}
