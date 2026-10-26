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
                readonly property var threadModel: MessagesAdapter.threadMessageListModel
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

                function threadPanel() {
                    return findChild(uut, "threadPanel");
                }

                function threadList() {
                    return threadPanel() ? findChild(threadPanel(), "threadMessageList") : null;
                }

                function openThreadFromList(id) {
                    const list = messageList();
                    const row = rootsModel.getDisplayIndex(id);
                    verify(row >= 0, "thread root is not in the main message list");
                    list.positionViewAtIndex(row, ListView.Center);
                    let button = null;
                    tryVerify(() => {
                        const item = list.itemAtIndex(rootsModel.getDisplayIndex(id));
                        button = item ? findChild(item, "threadRepliesButton") : null;
                        return button !== null && button.visible;
                    }, 5000, "no visible open-thread button on the root message");
                    mouseClick(button);
                    tryCompare(threadModel, "threadId", id);
                    tryVerify(() => threadPanel() !== null && threadPanel().visible, 5000, "thread panel did not open");
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
                    threadModel.threadId = "";
                    MessagesAdapter.replyToId = "";
                    MessagesAdapter.threadedView = false;
                }

                function test_shrinkingWindowKeepsThreadInsideChatView() {
                    openThreadFromList(rootId);
                    const originalWidth = uut.width;
                    try {
                        uut.width = JamiTheme.mainViewMajorPaneMinWidth
                                    + (JamiTheme.extrasPanelMinWidth + JamiTheme.threadPanelMinWidth) / 2;
                        const extras = findChild(uut, "conversationExtrasPanel");
                        waitForPolish(findChild(uut, "ChatViewSplitView"));
                        wait(JamiTheme.longFadeDuration);
                        tryVerify(() => extras.mapToItem(uut, extras.width, 0).x <= uut.width,
                                  2000, "thread panel extends outside the chat view");
                        uut.width += 10;
                        waitForPolish(findChild(uut, "ChatViewSplitView"));
                        wait(JamiTheme.longFadeDuration);
                        verify(extras.mapToItem(uut, extras.width, 0).x <= uut.width,
                               "chat restored before both panes could fit");
                    } finally {
                        uut.width = originalWidth;
                    }
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

                function test_openThreadShowsItInSidePanel() {
                    openThreadFromList(rootId);
                    const list = findChild(threadPanel(), "threadMessageList");
                    compare(list.model, threadModel);
                    verify(threadModel.getDisplayIndex(replyId) >= 0);
                    verify(threadModel.getDisplayIndex(nestedReplyId) >= 0);
                    compare(threadModel.count, 1 + threadModel.replyCountOf(rootId));
                    verify(!list.autoLoadHistory);
                    // The conversation stays next to the thread.
                    compare(messageList().model, rootsModel);
                    compare(rootsModel.getDisplayIndex(replyId), -1);
                }

                function test_openThreadButtonStaysVisibleWithNormalColors() {
                    openThreadFromList(rootId);
                    const row = rootsModel.getDisplayIndex(rootId);
                    const item = messageList().itemAtIndex(row);
                    const button = findChild(item, "threadRepliesButton");
                    verify(button !== null);
                    verify(button.visible);
                }

                function test_threadPanelHidesRepliesButtons() {
                    openThreadFromList(rootId);
                    const list = findChild(threadPanel(), "threadMessageList");
                    for (const id of [rootId, replyId, nestedReplyId]) {
                        const row = threadModel.getDisplayIndex(id);
                        list.positionViewAtIndex(row, ListView.Center);
                        tryVerify(() => list.itemAtIndex(row) !== null);
                        const button = findChild(list.itemAtIndex(row), "threadRepliesButton");
                        verify(button !== null);
                        verify(!button.visible);
                    }
                }

                function test_threadPanelTitleShowsConversation() {
                    openThreadFromList(rootId);
                    const title = findChild(threadPanel(), "threadPanelTitle");
                    verify(title.visible);
                    compare(title.eText, CurrentConversation.title);
                    tryVerify(() => title.text.length > 0, 5000, "thread panel title is empty");
                }

                function test_closeButtonClosesThread() {
                    openThreadFromList(rootId);
                    mouseClick(findChild(threadPanel(), "threadPanelCloseButton"));
                    compare(threadModel.threadId, "");
                    tryVerify(() => threadPanel() === null || !threadPanel().visible, 5000, "thread panel is still open");
                }

                function test_disablingThreadedViewClosesThread() {
                    openThreadFromList(rootId);
                    MessagesAdapter.threadedView = false;
                    compare(threadModel.threadId, "");
                    tryVerify(() => threadPanel() === null || !threadPanel().visible, 5000, "thread panel is still open");
                    compare(messageList().model, MessagesAdapter.messageListModel);
                }

                function test_disablingThreadedViewWhileHiddenClosesThreadPanel() {
                    openThreadFromList(rootId);
                    // Opening the settings hides the chat view.
                    uut.visible = false;
                    MessagesAdapter.threadedView = false;
                    uut.visible = true;
                    tryVerify(() => threadPanel() === null || !threadPanel().visible, 5000, "thread panel is still open");
                    verify(!findChild(uut, "conversationExtrasPanel").visible);
                }
            }
        }
    }
}
