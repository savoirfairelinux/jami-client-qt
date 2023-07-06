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
    background.visible: false

    required property var emojiReactions
    property var emojiReplied: emojiReactions.ownEmojis

    required property string msgId
    required property string msgBody
    required property bool isOutgoing
    required property int type
    required property string transferName
    required property Item msgBubble
    required property ListView listView

    property string transferId: msgId
    property string location: msgBody
    property bool closeWithoutAnimation: false
    property var emojiPicker

    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    function xPositionProvider(width) {
        // Use the width at function scope to retrigger property evaluation.
        const listViewWidth = listView.width
        if (isOutgoing) {
            const leftMargin = msgBubble.mapToItem(listView, 0, 0).x
            return width > leftMargin ? -leftMargin : -width
        } else {
            const rightMargin = listViewWidth - (msgBubble.x + msgBubble.width)
            return width > rightMargin ? msgBubble.width - width : msgBubble.width
        }
    }
    function yPositionProvider(height) {
        const topOffset = msgBubble.mapToItem(listView, 0, 0).y
        if (topOffset < 0) return -topOffset
        const bottomOffset = topOffset + height - listView.height
        if (bottomOffset > 0) return -bottomOffset
        return 0
    }
    x: xPositionProvider(width)
    y: yPositionProvider(height)

    signal addMoreEmoji
    onAddMoreEmoji: {
        JamiQmlUtils.updateMessageBarButtonsPoints()
        openEmojiPicker()
    }

    function openEmojiPicker() {
        var component =  WITH_WEBENGINE ?
                    Qt.createComponent("qrc:/webengine/emojipicker/EmojiPicker.qml") :
                    Qt.createComponent("qrc:/nowebengine/EmojiPicker.qml")
        emojiPicker = component.createObject(root.parent, { listView: listView })
        emojiPicker.emojiIsPicked.connect(function(content) {
            for (var emoji in emojiReplied) {
                if (emoji.body === content) {
                    MessagesAdapter.removeEmojiReaction(CurrentConversation.id, content, emoji.commitId)
                    return
                }
            }
            MessagesAdapter.addEmojiReaction(CurrentConversation.id, content, msgId)
        })
        if (emojiPicker !== null) {
            root.opacity = 0
            emojiPicker.closed.connect(() => close())
            emojiPicker.x = xPositionProvider(JamiTheme.emojiPickerWidth)
            emojiPicker.y = yPositionProvider(JamiTheme.emojiPickerHeight)
            emojiPicker.open()
        } else {
            console.log("Error creating emojiPicker from message options popup");
        }
    }

    // Close the picker when listView vertical properties change.
    property real listViewHeight: listView.height
    onListViewHeightChanged: close()
    property bool isScrolling: listView.verticalScrollBar.active
    onIsScrollingChanged: close()

    onOpened: root.closeWithoutAnimation = false
    onClosed: if (emojiPicker) emojiPicker.closeEmojiPicker()

    function getModel() {
        const defaultModel = ["👍", "👎", "😂"]
        const reactedEmojis = Array.isArray(emojiReplied) ? emojiReplied.slice(0, defaultModel.length) : []
        var remojis = []
        for (const emoji in reactedEmojis) {
            if (emoji && emoji.body)
                remojis += emoji.body
        }
        const uniqueEmojis = Array.from(new Set(remojis))
        const missingEmojis = defaultModel.filter(emoji => !uniqueEmojis.includes(emoji))
        return uniqueEmojis.concat(missingEmojis)
    }

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
                    model: root.getModel()

                    delegate: Button {
                        id: emojiButton

                        height: 50
                        width: 50
                        text: modelData
                        font.pointSize: JamiTheme.emojiBubbleSize

                        Text {
                            visible: emojiButton.hovered
                            anchors.centerIn: parent
                            text: modelData
                            font.pointSize: JamiTheme.emojiBubbleSizeBig
                            z: 1
                        }

                        background: Rectangle {
                            anchors.fill: parent
                            opacity: {
                                if (!root.emojiReplied)
                                    return 0
                                for (var emojiIdx in root.emojiReplied) {
                                    var body = root.emojiReplied[emojiIdx].body
                                    if (body === modelData)
                                        return 1
                                }
                                return 0
                            }
                            color: JamiTheme.emojiReactPushButtonColor
                            radius: 10
                        }

                        onClicked: {
                            for (var emojiIdx in root.emojiReplied) {
                                var emoji = root.emojiReplied[emojiIdx]
                                if (emoji.body === modelData) {
                                    MessagesAdapter.removeEmojiReaction(CurrentConversation.id,text,emoji.commitId)
                                    close()
                                    return
                                }
                            }

                            MessagesAdapter.addEmojiReaction(CurrentConversation.id,text,msgId)
                            close()
                        }
                    }
                }
                PushButton {
                    toolTipText: JamiStrings.moreEmojis
                    source: JamiResources.add_reaction_svg
                    normalColor: JamiTheme.emojiReactBubbleBgColor
                    imageColor: JamiTheme.emojiReactPushButtonColor
                    visible: WITH_WEBENGINE
                    onClicked: {
                        root.closeWithoutAnimation = true
                        root.addMoreEmoji()
                        //close()
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
                    UtilsAdapter.setClipboardText(msgBody)
                    close()
                }
            }

            MessageOptionButton {
                visible: type === Interaction.Type.DATA_TRANSFER
                textButton: JamiStrings.saveFile
                iconSource: JamiResources.save_file_svg
                Layout.fillWidth: true
                Layout.margins: 5
                onClicked: {
                    MessagesAdapter.copyToDownloads(root.transferId, root.transferName)
                    close()
                }
            }

            MessageOptionButton {
                visible: type === Interaction.Type.DATA_TRANSFER
                textButton: JamiStrings.openLocation
                iconSource: JamiResources.round_folder_24dp_svg
                Layout.fillWidth: true
                Layout.margins: 5
                onClicked: {
                    MessagesAdapter.openDirectory(root.location)
                    close()
                }
            }

            MessageOptionButton {
                visible: type === Interaction.Type.DATA_TRANSFER && Status === Interaction.Status.TRANSFER_FINISHED
                textButton: JamiStrings.removeLocally
                iconSource: JamiResources.trash_black_24dp_svg
                Layout.fillWidth: true
                Layout.margins: 5
                onClicked: {
                    MessagesAdapter.removeFile(msgId, root.location)
                    close()
                }
            }

            MessageOptionButton {
                id: buttonEdit

                visible: root.isOutgoing && type === Interaction.Type.TEXT
                textButton: JamiStrings.editMessage
                iconSource: JamiResources.edit_svg
                Layout.fillWidth: true
                Layout.margins: 5

                onClicked: {
                    MessagesAdapter.replyToId = ""
                    MessagesAdapter.editId = root.msgId
                    close()
                }
            }

            MessageOptionButton {
                visible: root.isOutgoing && type === Interaction.Type.TEXT
                textButton: JamiStrings.deleteMessage
                iconSource: JamiResources.delete_svg
                Layout.fillWidth: true
                Layout.margins: 5
                onClicked: {
                    MessagesAdapter.editMessage(CurrentConversation.id, "", root.msgId)
                    close()
                }
            }
        }
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
        samples: radius + 1
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
            duration: root.closeWithoutAnimation ? 0 : JamiTheme.shortFadeDuration
        }
    }
}
