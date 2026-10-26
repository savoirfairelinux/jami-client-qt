/*
 * Copyright (C) 2026 Savoir-faire Linux Inc.
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
import QtTest

import net.jami.Adapters 1.1
import net.jami.Models 1.1
import net.jami.Constants 1.1
import net.jami.Enums 1.1

import "../../../src/app/"
import "../../../src/app/mainview"
import "../../../src/app/mainview/components"
import "../../../src/app/commoncomponents"

TestWrapper {
    ListSelectionView {
        id: viewNode
        objectName: "ConversationView"
        managed: false
        // Sizes the test window so clicks on the ChatView land inside it.
        width: 1800
        height: 700

        leftPaneItem: Rectangle {}

        rightPaneItem: ChatView {
            id: uut

            inCallView: false
            width: 1200
            height: 700

            TestCase {
                name: "ThreadedConversation"
                when: windowShown

                readonly property var rootsModel: MessagesAdapter.threadedMessageListModel
                property string rootId
                property string replyId
                property string nestedReplyId
                property string otherRootId

                function messageId(body) {
                    const flat = MessagesAdapter.messageListModel;
                    for (let row = 0; row < flat.count; ++row) {
                        const message = flat.get(row);
                        if (message.Body === body)
                            return message.Id;
                    }
                    return "";
                }

                function send(body, replyTo) {
                    MessagesAdapter.replyToId = replyTo || "";
                    MessagesAdapter.sendMessage(body);
                    MessagesAdapter.replyToId = "";
                    tryVerify(() => messageId(body) !== "", 10000, "message was not added: " + body);
                    return messageId(body);
                }

                function messageList() {
                    return findChild(uut, "mainMessageList");
                }

                function initTestCase() {
                    // Unmanaged views only parent their right pane once something is selected.
                    viewNode.selectIndex(0);
                    MessagesAdapter.threadedView = false;
                    const stamp = Date.now();
                    rootId = send("thread root " + stamp);
                    replyId = send("thread reply " + stamp, rootId);
                    nestedReplyId = send("nested thread reply " + stamp, replyId);
                    otherRootId = send("other thread root " + stamp);
                }

                function init() {
                    MessagesAdapter.threadedView = true;
                }

                function cleanup() {
                    MessagesAdapter.replyToId = "";
                    MessagesAdapter.threadedView = false;
                }

                function test_flatModeIsTheDefault() {
                    MessagesAdapter.threadedView = false;
                    compare(messageList().model, MessagesAdapter.messageListModel);
                    verify(MessagesAdapter.messageListModel.getDisplayIndex(replyId) >= 0);
                }

                function test_mainListShowsRootsOnly() {
                    compare(messageList().model, rootsModel);
                    verify(rootsModel.getDisplayIndex(rootId) >= 0);
                    compare(rootsModel.getDisplayIndex(replyId), -1);
                }
            }
        }
    }
}
