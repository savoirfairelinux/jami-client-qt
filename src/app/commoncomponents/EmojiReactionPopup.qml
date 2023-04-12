/*
 * Copyright (C) 2022-2023 Savoir-faire Linux Inc.
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
import QtQuick.Layouts
import QtQuick.Controls
import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import Qt5Compat.GraphicalEffects

Popup {
    id: root
    property var emojiReaction
    property string msgId

    background.visible: false
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    height: popupContent.height
    modal: true
    padding: 0
    parent: Overlay.overlay
    visible: false
    width: popupContent.width

    // center in parent
    x: Math.round((parent.width - width) / 2)
    y: Math.round((parent.height - height) / 2)

    Rectangle {
        id: container
        anchors.fill: parent
        color: JamiTheme.secondaryBackgroundColor
        radius: JamiTheme.modalPopupRadius

        TextMetrics {
            id: textmetric
            font.pointSize: JamiTheme.emojiPopupFontsize
            text: "😀"
        }
        ColumnLayout {
            id: popupContent
            Layout.alignment: Qt.AlignCenter

            PushButton {
                id: btnClose
                Layout.alignment: Qt.AlignRight
                Layout.margins: 8
                height: 30
                imageColor: "grey"
                imageContainerHeight: 30
                imageContainerWidth: 30
                normalColor: JamiTheme.transparentColor
                radius: 5
                source: JamiResources.round_close_24dp_svg
                width: 30

                onClicked: {
                    root.close();
                }
            }
            ListView {
                id: listViewReaction
                property int modelCount: Object.entries(emojiReaction).length

                Layout.leftMargin: JamiTheme.popupButtonsMargin
                Layout.preferredHeight: childrenRect.height + 30 < 700 ? childrenRect.height + 30 : 700
                Layout.preferredWidth: 400
                Layout.rightMargin: JamiTheme.popupButtonsMargin
                clip: true
                model: Object.entries(emojiReaction)
                spacing: 15

                delegate: RowLayout {
                    property string authorUri: modelData[0]
                    property var emojiArray: modelData[1]
                    property bool isMe: authorUri === CurrentAccount.uri

                    width: parent.width

                    Avatar {
                        id: avatar
                        Layout.alignment: Qt.AlignLeft && Qt.AlignTop
                        Layout.preferredHeight: JamiTheme.avatarSize
                        Layout.preferredWidth: JamiTheme.avatarSize
                        Layout.topMargin: (textmetric.height - height) + (height - authorName.height) / 2
                        imageId: isMe ? CurrentAccount.id : authorUri
                        mode: isMe ? Avatar.Mode.Account : Avatar.Mode.Contact
                        showPresenceIndicator: false
                    }
                    Text {
                        id: authorName
                        Layout.alignment: Qt.AlignLeft && Qt.AlignTop
                        Layout.fillWidth: true
                        Layout.rightMargin: 10
                        Layout.topMargin: (textmetric.height - height)
                        color: JamiTheme.chatviewTextColor
                        elide: Text.ElideRight
                        font.pointSize: JamiTheme.namePopupFontsize
                        text: isMe ? " " + CurrentAccount.bestName + "   " : " " + UtilsAdapter.getBestNameForUri(CurrentAccount.id, authorUri) + "   "
                    }
                    GridLayout {
                        columns: 5
                        layoutDirection: Qt.RightToLeft
                        visible: !isMe

                        Repeater {
                            model: emojiArray.length < 15 ? emojiArray.length : 15

                            delegate: Text {
                                font.pointSize: JamiTheme.emojiPopupFontsize
                                horizontalAlignment: Text.AlignRight
                                text: emojiArray[index]
                            }
                        }
                    }
                    GridLayout {
                        columns: 5
                        layoutDirection: Qt.RightToLeft
                        visible: isMe

                        Repeater {
                            model: emojiArray.length < 15 ? emojiArray.length : 15

                            delegate: Button {
                                id: emojiButton
                                background.visible: false
                                font.pointSize: JamiTheme.emojiPopupFontsize
                                padding: 0
                                text: emojiArray[index]

                                onClicked: {
                                    MessagesAdapter.removeEmojiReaction(CurrentConversation.id, emojiButton.text, msgId);
                                    if (emojiArray.length === 1)
                                        close();
                                }

                                Text {
                                    anchors.centerIn: parent
                                    font.pointSize: JamiTheme.emojiPopupFontsizeBig
                                    text: emojiArray[index]
                                    visible: emojiButton.hovered
                                    z: 1
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    DropShadow {
        color: JamiTheme.shadowColor
        height: root.height
        horizontalOffset: 3.0
        radius: container.radius * 4
        source: container
        transparentBorder: true
        verticalOffset: 3.0
        width: root.width
        z: -1
    }

    Overlay.modal: Rectangle {
        color: JamiTheme.transparentColor

        // Color animation for overlay when pop up is shown.
        ColorAnimation on color  {
            duration: 500
            to: JamiTheme.popupOverlayColor
        }
    }
    enter: Transition {
        NumberAnimation {
            duration: JamiTheme.shortFadeDuration
            from: 0.0
            properties: "opacity"
            to: 1.0
        }
    }
    exit: Transition {
        NumberAnimation {
            duration: JamiTheme.shortFadeDuration
            from: 1.0
            properties: "opacity"
            to: 0.0
        }
    }
}
