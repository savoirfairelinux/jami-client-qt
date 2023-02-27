/*
 * Copyright (C) 2020-2023 Savoir-faire Linux Inc.
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

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import net.jami.Models 1.1
import net.jami.Constants 1.1
import net.jami.Adapters 1.1

import "../../commoncomponents"

Rectangle {
    id: root

    property alias textInput: messageBar.textAreaObj
    property string previousConvId
    property string previousAccountId

    function setFilePathsToSend(filePaths) {
        for (var index = 0; index < filePaths.length; ++index) {
            var path = UtilsAdapter.getAbsPath(decodeURIComponent(filePaths[index]))
            dataTransferSendContainer.filesToSendListModel.addToPending(path)
        }
    }

    implicitHeight: footerColumnLayout.implicitHeight

    color: JamiTheme.primaryBackgroundColor

    function updateMessageDraft() {
        LRCInstance.setContentDraft(previousConvId,
                                    previousAccountId,
                                    messageBar.text);

        previousConvId = CurrentConversation.id
        previousAccountId = CurrentAccount.id

        // turn off the button animations when switching convs
        messageBar.animate = false
        messageBar.textAreaObj.clearText()

        var restoredContent = LRCInstance.getContentDraft(CurrentConversation.id,
                                                          CurrentAccount.id);
        if (restoredContent) {
            messageBar.textAreaObj.insertText(restoredContent)
        }
    }

    Connections {
        target: CurrentConversation

        function onIdChanged() { messageBar.animate = true }
    }

    Connections {
        target: MessagesAdapter

        function onNewFilePasted(filePath) {
            dataTransferSendContainer.filesToSendListModel.addToPending(filePath)
        }

        function onNewTextPasted() {
            messageBar.textAreaObj.pasteText()
        }

        function onEditIdChanged() {
            if (MessagesAdapter.editId.length > 0) {
                var editedMessageBody = MessagesAdapter.dataForInteraction(MessagesAdapter.editId, MessageList.Body)
                messageBar.textAreaObj.insertText(editedMessageBody)
                messageBar.textAreaObj.forceActiveFocus()

            }
        }

        function onReplyToIdChanged() {
            if (MessagesAdapter.replyToId.length > 0)
                messageBar.textAreaObj.forceActiveFocus()
        }
    }

    RecordBox {
        id: recordBox

        visible: false
    }

    ColumnLayout {
        id: footerColumnLayout

        anchors.centerIn: root

        width: root.width

        spacing: 0

        ReplyingContainer {
            id: replyingContainer

            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: footerColumnLayout.width
            Layout.maximumWidth: JamiTheme.chatViewMaximumWidth
            Layout.minimumHeight: 36
            Layout.preferredHeight: 36 * JamiTheme.baseZoom
            visible: MessagesAdapter.replyToId !== ""
        }

        EditContainer {
            id: editContainer

            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: footerColumnLayout.width
            Layout.maximumWidth: JamiTheme.chatViewMaximumWidth
            Layout.minimumHeight: 36
            Layout.preferredHeight: 36 * JamiTheme.baseZoom
            visible: MessagesAdapter.editId !== ""
        }

        MessageBar {
            id: messageBar

            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: footerColumnLayout.width
            Layout.preferredHeight: implicitHeight
            property var emojiPicker

            Connections {
                target: messageBar.emojiPicker ? messageBar.emojiPicker : null
                function onEmojiIsPicked(content) {
                    messageBar.textAreaObj.insertText(content)
                }
            }

            function openEmojiPicker() {
                var component =  WITH_WEBENGINE
                          ? Qt.createComponent("qrc:/webengine/emojipicker/EmojiPicker.qml")
                          : Qt.createComponent("qrc:/nowebengine/EmojiPicker.qml")
                messageBar.emojiPicker =
                        component.createObject(messageBar, {
                                                   x: setXposition(),
                                                   y: setYposition(),
                                                   listView: null
                                               });
                if (messageBar.emojiPicker === null) {
                    console.log("Error creating emojiPicker in chatViewFooter");
                }
            }
            onWidthChanged: {
                if (emojiPicker)
                    emojiPicker.x = setXposition()
            }

            function setXposition(){
                return messageBar.width - JamiTheme.emojiPickerWidth //- JamiTheme.emojiMargins
            }

            function setYposition() {
                return - JamiTheme.emojiPickerHeight //- JamiTheme.emojiMargins
            }

            sendButtonVisibility: text ||
                                  dataTransferSendContainer.filesToSendCount

            onEmojiButtonClicked: {
                JamiQmlUtils.updateMessageBarButtonsPoints()
                openEmojiPicker()
            }

            onShowMapClicked: {
                PositionManager.setMapActive(CurrentAccount.id)
            }

            onSendFileButtonClicked: {
                var dlg = viewCoordinator.presentDialog(
                            appWindow,
                            "commoncomponents/JamiFileDialog.qml",
                            {
                                fileMode: JamiFileDialog.OpenFiles,
                                nameFilters: [JamiStrings.allFiles]
                            })
                dlg.filesAccepted.connect(function(files) {
                    setFilePathsToSend(files)
                })
            }

            onSendMessageButtonClicked: {
                // Send text message
                if (messageBar.text) {
                    if (MessagesAdapter.editId !== "") {
                        MessagesAdapter.editMessage(CurrentConversation.id, messageBar.text)
                    } else {
                        MessagesAdapter.sendMessage(messageBar.text)
                    }
                }
                messageBar.textAreaObj.clearText()

                // Send file messages
                var fileCounts = dataTransferSendContainer.filesToSendListModel.rowCount()
                for (var i = 0; i < fileCounts; i++) {
                    var currentIndex = dataTransferSendContainer.filesToSendListModel.index(i, 0)
                    var filePath = dataTransferSendContainer.filesToSendListModel.data(
                                currentIndex, FilesToSend.FilePath)
                    MessagesAdapter.sendFile(filePath)
                }
                dataTransferSendContainer.filesToSendListModel.flush()
            }
            onVideoRecordMessageButtonClicked: {
                JamiQmlUtils.updateMessageBarButtonsPoints()

                recordBox.parent = JamiQmlUtils.mainViewRectObj

                recordBox.x = Qt.binding(function() {
                    var buttonCenterX = JamiQmlUtils.videoRecordMessageButtonInMainViewPoint.x +
                            JamiQmlUtils.videoRecordMessageButtonObj.width / 2
                    return buttonCenterX - recordBox.width / 2
                })
                recordBox.y = Qt.binding(function() {
                    var buttonY = JamiQmlUtils.videoRecordMessageButtonInMainViewPoint.y
                    return buttonY - recordBox.height - recordBox.spikeHeight
                })

                recordBox.openRecorder(true)
            }
            onAudioRecordMessageButtonClicked: {
                JamiQmlUtils.updateMessageBarButtonsPoints()

                recordBox.parent = JamiQmlUtils.mainViewRectObj

                recordBox.x = Qt.binding(function() {
                    var buttonCenterX = JamiQmlUtils.audioRecordMessageButtonInMainViewPoint.x +
                            JamiQmlUtils.audioRecordMessageButtonObj.width / 2
                    return buttonCenterX - recordBox.width / 2
                })
                recordBox.y = Qt.binding(function() {
                    var buttonY = JamiQmlUtils.audioRecordMessageButtonInMainViewPoint.y
                    return buttonY - recordBox.height - recordBox.spikeHeight
                })

                recordBox.openRecorder(false)
            }
        }

        FilesToSendContainer {
            id: dataTransferSendContainer

            objectName: "dataTransferSendContainer"

            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: footerColumnLayout.width
            Layout.maximumWidth: JamiTheme.chatViewMaximumWidth
            Layout.preferredHeight: filesToSendCount ?
                                        JamiTheme.filesToSendDelegateHeight : 0
        }
    }
}
