/*
 * Copyright (C) 2022 Savoir-faire Linux Inc.
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
import Qt5Compat.GraphicalEffects
import QtQuick.Layouts

import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1

Popup {
    id: root

    width: emojiColumn.width + JamiTheme.emojiMargins
    height: emojiColumn.height + JamiTheme.emojiMargins
    padding: 0

    property string msgId
    property string msg
    property string emojiReplied
    property bool out

    Rectangle {
        id: bubble

        color: JamiTheme.chatviewBgColor
        anchors.fill: parent
        radius: JamiTheme.modalPopupRadius

        ColumnLayout {
            id: emojiColumn

            anchors.centerIn: parent

            RowLayout {
                id: emojiRow
                Layout.alignment: Qt.AlignCenter

                Repeater {
                    // thumbsUp,face-with-tears-of-joy, angry-face
                    model: ["👍", "😂", "😠" ]

                    delegate:Button {
                        id: curButton

                        height: 50
                        width: 50
                        text: modelData
                        font.pointSize: JamiTheme.emojiBubbleSize

                        Text {
                            visible: curButton.hovered
                            anchors.centerIn: parent
                            text: modelData
                            font.pointSize: JamiTheme.emojiBubbleSizeBig
                            z: 1
                        }

                        background: Rectangle {
                            anchors.fill: parent
                            opacity: emojiReplied.includes(modelData) ? 1 : 0
                            color: JamiTheme.emojiReactPushButtonColor
                            radius: 10
                        }

                        onClicked: {
                            MessagesAdapter.reactMessage(CurrentConversation.id,text,msgId)
                        }
                    }
                }
            }

            Rectangle {
                Layout.margins: 5
                color: JamiTheme.timestampColor
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                radius: width * 0.5
                opacity: 0.6
            }

            MessageOptionButton {
                textButton: JamiStrings.copy
                iconSource: JamiResources.copy_svg
                Layout.fillWidth: true
                Layout.margins: 5
                onClicked: {
                    UtilsAdapter.setClipboardText(msg)
                    root.close()
                }
            }

            MessageOptionButton {
                id: buttonEdit

                visible: out
                textButton: JamiStrings.editMessage
                iconSource: JamiResources.edit_svg
                Layout.fillWidth: true
                Layout.margins: 5
                onClicked: {
                    MessagesAdapter.replyToId = ""
                    MessagesAdapter.editId = root.msgId
                    root.close()
                }
            }

            MessageOptionButton {
                visible: out
                textButton: JamiStrings.deleteMessage
                iconSource: JamiResources.delete_svg
                Layout.fillWidth: true
                Layout.margins: 5
                onClicked: {
                    MessagesAdapter.editMessage(CurrentConversation.id, "", root.msgId)
                    root.close()
                }
            }

        }
    }

    background: Rectangle {
        color: JamiTheme.transparentColor
    }

    Overlay.modal: Rectangle {
        color: JamiTheme.transparentColor
        // Color animation for overlay when pop up is shown.
        ColorAnimation on color {
            to: JamiTheme.popupOverlayColor
            duration: 500
        }
    }

    DropShadow {
        z: -1

        width: bubble.width
        height: bubble.height
        horizontalOffset: 3.0
        verticalOffset: 3.0
        radius: bubble.radius * 4
        color: JamiTheme.shadowColor
        source: bubble
        transparentBorder: true
    }

    enter: Transition {
        NumberAnimation {
            properties: "opacity"; from: 0.0; to: 1.0
            duration: JamiTheme.shortFadeDuration
        }
    }

    exit: Transition {
        NumberAnimation {
            properties: "opacity"; from: 1.0; to: 0.0
            duration: JamiTheme.shortFadeDuration
        }
    }
}





