/*
 * Copyright (C) 2021-2026 Savoir-faire Linux Inc.
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

import QtTest

import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import net.jami.Models 1.1

import "../../../src/app/mainview/components"

ColumnLayout {
    id: root

    spacing: 0

    width: 300
    height: uut.implicitHeight

    QtObject {
        id: testConversation

        property string id: "permission-test-conversation"
        property string title: "Permission test"
        property bool isTemporary: false
        property bool isSip: false
        property bool canSendText: true
        property bool canReplyText: true
        property bool canSendFile: true
        property bool canReplyFile: true
        property bool canCreateDocument: true

        function canEditMessage(messageId) {
            return true;
        }
    }

    ChatViewFooter {
        id: uut

        Layout.alignment: Qt.AlignHCenter
        Layout.fillWidth: true
        Layout.preferredHeight: implicitHeight
        Layout.maximumHeight: JamiTheme.chatViewMaximumWidth

        TestCase {
            name: "MessageWebViewFooter Send Message Button Visibility Test"
            when: windowShown

            property bool initialShowTypo: false

            function initTestCase() {
                uut.convContext = testConversation;
                initialShowTypo = uut.messageBar.showTypo;
                MessagesAdapter.replyToId = "";
                MessagesAdapter.editId = "";
            }

            function cleanup() {
                var filesToSendContainer = findChild(uut, "dataTransferSendContainer")
                var messageBarTextArea = findChild(uut, "messageBarTextArea")
                messageBarTextArea.clearText()
                filesToSendContainer.filesToSendListModel.flush()
                MessagesAdapter.replyToId = "";
                MessagesAdapter.editId = "";
                testConversation.canSendText = true;
                testConversation.canReplyText = true;
                testConversation.canSendFile = true;
                testConversation.canReplyFile = true;
                testConversation.canCreateDocument = true;
                uut.messageBar.showTypo = initialShowTypo;
            }

            function test_send_message_button_visibility() {
                var filesToSendContainer = findChild(uut, "dataTransferSendContainer")
                var sendMessageButton = findChild(uut, "sendMessageButton")
                var messageBarTextArea = findChild(uut, "messageBarTextArea")

                compare(sendMessageButton.enabled, false)

                // Text in messageBarTextArea will cause sendMessageButton to show
                messageBarTextArea.insertText("test")
                compare(sendMessageButton.enabled, true)

                // Text cleared in messageBarTextArea will cause sendMessageButton to hide
                messageBarTextArea.clearText()
                compare(sendMessageButton.enabled, false)

                // Both are cleared
                messageBarTextArea.clearText()
                compare(sendMessageButton.enabled, false)
            }

            // Regression: pasting a file with no text left the send button enabled but
            // pressing Enter did nothing because onSendMessagesRequired only checked text.
            function test_enter_sends_when_files_pending_and_no_text() {
                var filesToSendContainer = findChild(uut, "dataTransferSendContainer")
                var sendMessageButton = findChild(uut, "sendMessageButton")
                var messageBarTextArea = findChild(uut, "messageBarTextArea")

                // Add a file — send button should become enabled
                filesToSendContainer.filesToSendListModel.addToPending(":/src/resources/png_test.png")
                compare(filesToSendContainer.filesToSendCount, 1)
                compare(sendMessageButton.enabled, true)

                // Press Enter: should trigger sendMessageButtonClicked
                var spy = Qt.createQmlObject('import QtTest 1.0; SignalSpy {}', uut)
                spy.target = uut.messageBar
                spy.signalName = "sendMessageButtonClicked"

                messageBarTextArea.textAreaObj.forceActiveFocus()
                keyClick(Qt.Key_Return)
                compare(spy.count, 1)

                spy.destroy()
            }

            function test_textPermissionDisablesTextInputAndFormatting() {
                testConversation.canSendText = false;
                testConversation.canSendFile = true;
                uut.messageBar.showTypo = true;

                var messageBarTextArea = findChild(uut, "messageBarTextArea")
                var textArea = messageBarTextArea.textAreaObj
                var formattingRow = findChild(uut, "formattingRow")
                var formatToggle = findChild(uut, "typoButton")

                compare(textArea.enabled, false)
                compare(messageBarTextArea.visible, false)
                compare(formattingRow.visible, false)
                compare(formatToggle.visible, false)
            }

            function test_replyTextPermissionDisablesTextInput() {
                testConversation.canSendText = true;
                testConversation.canReplyText = false;
                MessagesAdapter.replyToId = "permission-test-reply";

                var messageBarTextArea = findChild(uut, "messageBarTextArea")
                compare(messageBarTextArea.textAreaObj.enabled, false)
                compare(messageBarTextArea.visible, false)
            }

            function test_textPasteIsIgnoredWithoutTextPermission() {
                testConversation.canSendText = false;

                uut.pasteText();

                compare(uut.messageBar.text, "")
            }

            function test_unsendableDraftDoesNotEnableSendButton() {
                testConversation.canSendText = false;
                var messageBarTextArea = findChild(uut, "messageBarTextArea")
                messageBarTextArea.insertText("draft")

                var sendMessageButton = findChild(uut, "sendMessageButton")
                compare(sendMessageButton.enabled, false)

                var spy = Qt.createQmlObject('import QtTest 1.0; SignalSpy {}', uut)
                spy.target = uut.messageBar
                spy.signalName = "sendMessageButtonClicked"
                messageBarTextArea.sendMessagesRequired()
                compare(spy.count, 0)

                spy.destroy()
            }

            function test_fileSendingRemainsAvailableWhenTextIsDenied() {
                testConversation.canSendText = false;
                testConversation.canSendFile = true;
                var filesToSendContainer = findChild(uut, "dataTransferSendContainer")
                filesToSendContainer.filesToSendListModel.addToPending(":/src/resources/png_test.png")

                var sendMessageButton = findChild(uut, "sendMessageButton")
                compare(sendMessageButton.enabled, true)
            }

            function test_createDocumentActionFollowsPermission() {
                var shareMenu = findChild(uut, "chatViewShareMenu")
                verify(shareMenu)
                var createDocumentAction = findChild(shareMenu, "newEditableDocumentMenuItem")
                verify(createDocumentAction)
                compare(createDocumentAction.allowed, true)
                var createActionSeparator = shareMenu.generalMenuSeparatorList[0]
                verify(createActionSeparator)
                verify(createActionSeparator.height > 0)

                var formatBar = findChild(uut, "messageFormatBar")
                var openExistingDocumentsAction = findChild(formatBar, "openCollabDocList")
                verify(openExistingDocumentsAction)
                formatBar.hasEditableDocuments = true;
                compare(openExistingDocumentsAction.show, true)

                testConversation.canCreateDocument = false;
                compare(createDocumentAction.allowed, false)
                compare(createDocumentAction.height, 0)
                compare(createActionSeparator.height, 0)
                compare(openExistingDocumentsAction.show, true)

                testConversation.canCreateDocument = true;
                compare(createDocumentAction.allowed, true)
                verify(createDocumentAction.height > 0)
                verify(createActionSeparator.height > 0)
            }

            function test_audioVideoActionsFollowCurrentFilePermission() {
                var shareMenu = findChild(uut, "chatViewShareMenu")
                verify(shareMenu)
                var audioMessage = findChild(shareMenu, "audioMessageMenuItem")
                verify(audioMessage)
                var videoMessage = findChild(shareMenu, "videoMessageMenuItem")
                verify(videoMessage)
                var separators = shareMenu.generalMenuSeparatorList
                compare(separators.length, 3)

                function menuContains(item) {
                    for (var i = 0; i < shareMenu.count; ++i) {
                        if (shareMenu.itemAt(i) === item)
                            return true;
                    }
                    return false;
                }

                MessagesAdapter.replyToId = "";
                testConversation.canSendFile = false;
                shareMenu.open();
                tryCompare(shareMenu, "opened", true);
                compare(audioMessage.allowed, false);
                compare(videoMessage.allowed, false);
                compare(audioMessage.height, 0);
                compare(videoMessage.height, 0);
                verify(separators[0].height > 0);
                compare(separators[1].height, 0);
                compare(separators[2].height, 0);

                testConversation.canSendFile = true;
                compare(audioMessage.allowed, true);
                compare(videoMessage.allowed, true);
                verify(menuContains(audioMessage));
                verify(menuContains(videoMessage));
                verify(audioMessage.height > 0);
                verify(videoMessage.height > 0);
                verify(separators[1].height > 0);
                verify(separators[2].height > 0);

                MessagesAdapter.replyToId = "permission-test-reply";
                testConversation.canReplyFile = false;
                compare(audioMessage.allowed, false);
                compare(videoMessage.allowed, false);
                compare(separators[1].height, 0);
                compare(separators[2].height, 0);

                testConversation.canReplyFile = true;
                compare(audioMessage.allowed, true);
                compare(videoMessage.allowed, true);
                verify(separators[1].height > 0);
                verify(separators[2].height > 0);
                shareMenu.close();
                tryCompare(shareMenu, "opened", false);
            }

            function test_deniedCreateDocumentActionDoesNotLeaveMenuGap() {
                var shareMenu = findChild(uut, "chatViewShareMenu")
                verify(shareMenu)

                // The popup is clamped to the small test window, so compare the
                // menu's natural height rather than its actual height.
                function openMenuHeight() {
                    shareMenu.open();
                    tryCompare(shareMenu, "opened", true);
                    shareMenu.contentItem.forceLayout();
                    var menuHeight = shareMenu.implicitHeight;
                    shareMenu.close();
                    tryCompare(shareMenu, "opened", false);
                    return menuHeight;
                }

                testConversation.canCreateDocument = true;
                var allowedMenuHeight = openMenuHeight();

                testConversation.canCreateDocument = false;
                var deniedMenuHeight = openMenuHeight();
                verify(deniedMenuHeight < allowedMenuHeight,
                       "Denied document creation should not reserve an empty menu row");

                testConversation.canCreateDocument = true;
                compare(openMenuHeight(), allowedMenuHeight,
                        "Allowed document creation should restore its menu row");
            }
        }
    }
}
