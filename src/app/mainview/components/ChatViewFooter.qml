/*
 * Copyright (C) 2020-2025 Savoir-faire Linux Inc.
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
    property alias messageBar: messageBar
    property string previousConvId
    property string previousAccountId
    property bool showTypo: messageBar.showTypo

    function setFilePathsToSend(filePaths) {
        for (var index = 0; index < filePaths.length; ++index) {
            var path = UtilsAdapter.getAbsPath(decodeURIComponent(filePaths[index]));
            messageBar.fileContainer.filesToSendListModel.addToPending(path);
        }
    }

    implicitHeight: footerColumnLayout.implicitHeight

    color: JamiTheme.primaryBackgroundColor

    function updateMessageDraft() {
        // Store the current files that have not been sent, if any. Do the same for the message draft.
        var filePathDraft = [];
        while (messageBar.fileContainer.filesToSendCount > 0) {
            var currentIndex = messageBar.fileContainer.filesToSendListModel.index(0, 0);
            var filePath = messageBar.fileContainer.filesToSendListModel.data(currentIndex, FilesToSend.FilePath);
            filePathDraft.push(filePath);
            messageBar.fileContainer.filesToSendListModel.removeFromPending(0);
        }
        LRCInstance.setContentDraft(previousConvId, previousAccountId, messageBar.text, filePathDraft);
        previousConvId = CurrentConversation.id;
        previousAccountId = CurrentAccount.id;

        // turn off the button animations when switching convs
        messageBar.animate = false;
        messageBar.textAreaObj.clearText();

        // restore the draft state of contents for a specific conversation
        var restoredContent = LRCInstance.getContentDraft(CurrentConversation.id, CurrentAccount.id);
        if (restoredContent) {
            messageBar.textAreaObj.insertText(restoredContent["text"]);
            for (var i = 0; i < restoredContent["files"].length; ++i) {
                messageBar.fileContainer.filesToSendListModel.addToPending(restoredContent["files"][i]);
            }
        }
    }

    Connections {
        target: CurrentConversation

        function onIdChanged() {
            messageBar.animate = true;
        }
    }

    Connections {
        target: MessagesAdapter

        function onNewFilePasted(filePath) {
            messageBar.fileContainer.filesToSendListModel.addToPending(filePath);
        }

        function onNewTextPasted() {
            messageBar.textAreaObj.pasteText();
        }

        function onEditIdChanged() {
            if (MessagesAdapter.editId.length > 0) {
                var editedMessageBody = MessagesAdapter.dataForInteraction(MessagesAdapter.editId, MessageList.Body);
                messageBar.textAreaObj.insertText(editedMessageBody);
                messageBar.textAreaObj.forceActiveFocus();
            } else {
                messageBar.textAreaObj.clearText();
            }
        }

        function onReplyToIdChanged() {
            if (MessagesAdapter.replyToId.length > 0)
                messageBar.textAreaObj.forceActiveFocus();
        }
    }

    RecordBox {
        id: recordBox

        visible: false
        parent: root
        x: messageBar.x + 140
        y: isVideo ? -165 : -65
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
            Layout.leftMargin: marginSize
            Layout.rightMargin: marginSize
            Layout.bottomMargin: marginSize
            Layout.preferredHeight: height

            property var emojiPicker

            Connections {
                target: messageBar.emojiPicker ? messageBar.emojiPicker : null
                function onEmojiIsPicked(content) {
                    messageBar.textAreaObj.insertText(content);
                }
            }

            function openEmojiPicker() {
                var component = WITH_WEBENGINE ? Qt.createComponent("qrc:/webengine/emojipicker/EmojiPicker.qml") : Qt.createComponent("qrc:/nowebengine/EmojiPicker.qml");
                messageBar.emojiPicker = component.createObject(messageBar, {
                        "x": setXposition(),
                        "y": setYposition(),
                        "listView": null
                    });
                if (messageBar.emojiPicker === null) {
                    console.log("Error creating emojiPicker in chatViewFooter");
                }
            }
            onWidthChanged: {
                if (emojiPicker)
                    emojiPicker.x = setXposition();
            }

            function setXposition() {
                return messageBar.width - JamiTheme.emojiPickerWidth;
            }

            function setYposition() {
                return -JamiTheme.emojiPickerHeight;
            }

            sendButtonVisibility: text || messageBar.fileContainer.filesToSendCount

            onEmojiButtonClicked: {
                if (emojiPicker && emojiPicker.opened) {
                    emojiPicker.closeEmojiPicker();
                } else {
                    openEmojiPicker();
                }
            }

            onShowMapClicked: {
                PositionManager.setMapActive(CurrentAccount.id);
            }

            onSendFileButtonClicked: {
                var dlg = viewCoordinator.presentDialog(appWindow, "commoncomponents/JamiFileDialog.qml", {
                        "fileMode": JamiFileDialog.OpenFiles,
                        "nameFilters": [JamiStrings.allFiles]
                    }, true); // is a single instance
                dlg.filesAccepted.connect(function (files) {
                        setFilePathsToSend(files);
                    });
            }

            onVideoRecordMessageButtonClicked: {
                recordBox.openRecorder(true);
            }

            onAudioRecordMessageButtonClicked: {
                recordBox.openRecorder(false);
            }

            onSendMessageButtonClicked: {
                // Send file messages
                var fileCounts = messageBar.fileContainer.filesToSendListModel.rowCount();
                for (var i = 0; i < fileCounts; i++) {
                    var currentIndex = messageBar.fileContainer.filesToSendListModel.index(i, 0);
                    var filePath = messageBar.fileContainer.filesToSendListModel.data(currentIndex, FilesToSend.FilePath);
                    MessagesAdapter.sendFile(filePath);
                }
                messageBar.fileContainer.filesToSendListModel.flush();
                // Send text message
                if (messageBar.text) {
                    if (MessagesAdapter.editId !== "") {
                        MessagesAdapter.editMessage(CurrentConversation.id, messageBar.text);
                    } else {
                        MessagesAdapter.sendMessage(messageBar.text);
                    }
                }
                messageBar.textAreaObj.clearText();
                MessagesAdapter.replyToId = "";
            }

            Keys.onShortcutOverride: function (keyEvent) {
                if (keyEvent.key === Qt.Key_Escape) {
                    if (recordBox != null && recordBox.opened) {
                        recordBox.closeRecorder();
                    } else if (PositionManager.isMapActive(CurrentAccount.id)) {
                        PositionManager.setMapInactive(CurrentAccount.id);
                    }
                }
            }
        }
    }
}
