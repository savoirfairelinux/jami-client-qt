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

    width: popupContent.width
    height: popupContent.height
    background.visible: false
    parent: Overlay.overlay

    property var reactions
    property string msgId

    // center in parent
    x: Math.round((parent.width - width) / 2)
    y: Math.round((parent.height - height) / 2)

    modal: true
    padding: 0

    visible: false
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    Rectangle {
        id: container

        anchors.fill: parent
        radius: JamiTheme.modalPopupRadius
        color: JamiTheme.secondaryBackgroundColor

        TextMetrics {
            id: textmetric
            text: "😀"
            font.pointSize: JamiTheme.emojiPopupFontsize
        }

        ColumnLayout {
            id: popupContent

            Layout.alignment: Qt.AlignCenter

            PushButton {
                id: btnClose

                Layout.alignment: Qt.AlignRight
                width: 30
                height: 30
                imageContainerWidth: 30
                imageContainerHeight: 30
                Layout.margins: 8
                radius: 5
                imageColor: "grey"
                normalColor: JamiTheme.transparentColor
                source: JamiResources.round_close_24dp_svg
                onClicked: {
                    root.close();
                }
            }

            ListView {
                id: listViewReaction

                Layout.leftMargin: JamiTheme.popupButtonsMargin
                Layout.rightMargin: JamiTheme.popupButtonsMargin
                spacing: 15
                Layout.preferredWidth: 400
                Layout.preferredHeight: childrenRect.height + 30 < 700 ? childrenRect.height + 30 : 700
                model: Object.entries(reactions)
                clip: true
                property int modelCount: Object.entries(reactions).length

                delegate: RowLayout {
                    width: parent.width
                    property string authorUri: modelData[0]
                    property var emojiArray: modelData[1]
                    property bool isMe: authorUri === CurrentAccount.uri

                    Avatar {
                        id: avatar

                        imageId: isMe ? CurrentAccount.id : authorUri
                        showPresenceIndicator: false
                        mode: isMe ? Avatar.Mode.Account : Avatar.Mode.Contact
                        Layout.preferredWidth: JamiTheme.avatarSize
                        Layout.preferredHeight: JamiTheme.avatarSize
                        Layout.alignment: Qt.AlignLeft && Qt.AlignTop
                        Layout.topMargin: (textmetric.height - height) + (height - authorName.height) / 2
                    }

                    Text {
                        id: authorName

                        Layout.fillWidth: true
                        Layout.rightMargin: 10
                        Layout.topMargin: (textmetric.height - height)
                        Layout.alignment: Qt.AlignLeft && Qt.AlignTop
                        elide: Text.ElideRight
                        font.pointSize: JamiTheme.namePopupFontsize
                        color: JamiTheme.chatviewTextColor
                        text: isMe ? " " + CurrentAccount.bestName + "   " : " " + UtilsAdapter.getBestNameForUri(CurrentAccount.id, authorUri) + "   "
                    }

                    GridLayout {
                        columns: 5
                        visible: !isMe
                        layoutDirection: Qt.RightToLeft
                        Repeater {
                            model: emojiArray.length < 15 ? emojiArray.length : 15
                            delegate: Text {
                                text: emojiArray[index].body
                                horizontalAlignment: Text.AlignRight
                                font.pointSize: JamiTheme.emojiPopupFontsize
                            }
                        }
                    }

                    GridLayout {
                        visible: isMe
                        columns: 5
                        layoutDirection: Qt.RightToLeft
                        Repeater {
                            model: emojiArray.length < 15 ? emojiArray.length : 15
                            delegate: Button {
                                id: emojiButton

                                text: emojiArray[index].body
                                font.pointSize: JamiTheme.emojiPopupFontsize
                                background.visible: false
                                padding: 0

                                Text {
                                    visible: emojiButton.hovered
                                    anchors.centerIn: parent
                                    text: emojiArray[index].body
                                    font.pointSize: JamiTheme.emojiPopupFontsizeBig
                                    z: 1
                                }

                                onClicked: {
                                    MessagesAdapter.removeEmojiReaction(CurrentConversation.id, emojiButton.text, emojiArray[index].commitId);
                                    if (emojiArray.length === 1)
                                        close();
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Overlay.modal: Rectangle {
        color: JamiTheme.transparentColor
        // Color animation for overlay when pop up is shown.
        ColorAnimation on color  {
            to: JamiTheme.popupOverlayColor
            duration: 500
        }
    }

    DropShadow {
        z: -1
        width: root.width
        height: root.height
        horizontalOffset: 3.0
        verticalOffset: 3.0
        radius: container.radius * 4
        color: JamiTheme.shadowColor
        source: container
        transparentBorder: true
        samples: radius + 1
    }

    enter: Transition {
        NumberAnimation {
            properties: "opacity"
            from: 0.0
            to: 1.0
            duration: JamiTheme.shortFadeDuration
        }
    }

    exit: Transition {
        NumberAnimation {
            properties: "opacity"
            from: 1.0
            to: 0.0
            duration: JamiTheme.shortFadeDuration
        }
    }
}
