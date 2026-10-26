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

                // Sends through a composer's own send action, as the send button does.
                function sendFrom(footer, body) {
                    footer.messageBar.text = body;
                    footer.messageBar.sendMessageButtonClicked();
                    tryVerify(() => messageId(body) !== "", 10000, "message was not added: " + body);
                    return messageId(body);
                }

                function messageList() {
                    return findChild(uut, "mainMessageList");
                }

                function mainFooter() {
                    return findChild(uut, "chatViewFooter");
                }

                function threadPanel() {
                    return findChild(uut, "threadPanel");
                }

                function threadFooter() {
                    return findChild(threadPanel(), "threadFooter");
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
                    MessagesAdapter.cancelNavigation();
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
                    verify(mainFooter().visible);
                    verify(threadFooter().visible);
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

                function threadItem(id) {
                    const list = threadList();
                    list.positionViewAtIndex(threadModel.getDisplayIndex(id), ListView.Center);
                    let item = null;
                    tryVerify(() => (item = list.itemAtIndex(threadModel.getDisplayIndex(id))) !== null, 5000, "message is not shown in the thread");
                    return item;
                }

                function test_directRepliesInThreadShowNoReplyPreview() {
                    openThreadFromList(rootId);
                    // The root is written by the user, as are its replies.
                    verify(threadItem(rootId).isOutgoing);
                    const direct = threadItem(replyId);
                    verify(!direct.isReply);
                    verify(!findChild(direct, "messageReplyPreview").visible);
                    const nested = threadItem(nestedReplyId);
                    verify(nested.isReply);
                    verify(findChild(nested, "messageReplyPreview").visible);
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

                function test_threadComposerSendsToRoot() {
                    openThreadFromList(rootId);
                    const id = sendFrom(threadFooter(), "thread composer send " + Date.now());
                    compare(MessagesAdapter.dataForInteraction(id, MessageList.ReplyTo), rootId);
                    const next = sendFrom(threadFooter(), "second thread composer send " + Date.now());
                    compare(MessagesAdapter.dataForInteraction(next, MessageList.ReplyTo), rootId);
                    compare(threadModel.threadId, rootId);
                }

                function test_mainComposerIgnoresOpenThread() {
                    openThreadFromList(rootId);
                    const id = sendFrom(mainFooter(), "main composer send " + Date.now());
                    compare(MessagesAdapter.dataForInteraction(id, MessageList.ReplyTo), "");
                }

                function test_explicitReplyBelongsToThreadComposer() {
                    openThreadFromList(rootId);
                    MessagesAdapter.replyToId = replyId;
                    compare(threadFooter().messageBar.replyToId, replyId);
                    compare(mainFooter().messageBar.replyToId, "");
                    const id = sendFrom(threadFooter(), "explicit nested reply " + Date.now());
                    compare(MessagesAdapter.dataForInteraction(id, MessageList.ReplyTo), replyId);
                }

                function test_mainReplyIsNotTakenByThreadComposer() {
                    openThreadFromList(rootId);
                    MessagesAdapter.replyToId = otherRootId;
                    compare(mainFooter().messageBar.replyToId, otherRootId);
                    compare(threadFooter().messageBar.replyToId, "");
                    const id = sendFrom(threadFooter(), "thread send beside main reply " + Date.now());
                    compare(MessagesAdapter.dataForInteraction(id, MessageList.ReplyTo), rootId);
                    compare(MessagesAdapter.replyToId, otherRootId);
                }

                function test_replyInFlatViewDoesNotOpenThread() {
                    MessagesAdapter.threadedView = false;
                    MessagesAdapter.replyToId = rootId;
                    compare(threadModel.threadId, "");
                    compare(mainFooter().messageBar.replyToId, rootId);
                    sendFrom(mainFooter(), "flat reply " + Date.now());
                    compare(threadModel.threadId, "");
                }

                function test_replyToExistingThreadOpensPanel_data() {
                    return [
                        {tag: "root", target: rootId, root: rootId},
                        {tag: "nested reply", target: nestedReplyId, root: rootId}
                    ];
                }

                function test_replyToExistingThreadOpensPanel(data) {
                    MessagesAdapter.replyToId = data.target;
                    tryCompare(threadModel, "threadId", data.root);
                    tryVerify(() => threadPanel() !== null && threadPanel().visible);
                    compare(mainFooter().messageBar.replyToId, "");
                    compare(threadFooter().messageBar.replyToId, data.target);
                }

                function test_sendingFirstReplyOpensThread() {
                    const target = send("new thread root " + Date.now());
                    MessagesAdapter.replyToId = target;
                    compare(threadModel.threadId, "");
                    compare(mainFooter().messageBar.replyToId, target);
                    const id = sendFrom(mainFooter(), "sent reply opens thread " + Date.now());
                    compare(MessagesAdapter.dataForInteraction(id, MessageList.ReplyTo), target);
                    tryCompare(threadModel, "threadId", target);
                    tryVerify(() => threadPanel() !== null && threadPanel().visible);
                }

                function test_threadTargetDoesNotLeakToAnotherConversation() {
                    openThreadFromList(rootId);
                    compare(MessagesAdapter.replyTargetFor(CurrentConversation.id, true), rootId);
                    compare(MessagesAdapter.replyTargetFor(CurrentConversation.id, false), "");
                    compare(MessagesAdapter.replyTargetFor("another-conversation", true), "");
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

                function messageIsShown(list, id) {
                    const row = list ? list.model.getDisplayIndex(id) : -1;
                    return row >= 0 && list.itemAtIndex(row) !== null;
                }

                function test_flatJumpStillScrollsWithoutThreads() {
                    MessagesAdapter.threadedView = false;
                    messageList().positionViewAtEnd();
                    CurrentConversation.scrollToMsg(replyId);
                    tryVerify(() => messageIsShown(messageList(), replyId), 5000, "flat jump target is not shown");
                    compare(threadModel.threadId, "");
                    compare(MessagesAdapter.navigationTarget, "");
                }

                function test_jumpToLoadedReplyOpensItsThreadPanel() {
                    CurrentConversation.scrollToMsg(nestedReplyId);
                    tryCompare(threadModel, "threadId", rootId);
                    tryVerify(() => threadPanel() !== null && threadPanel().visible, 5000, "thread panel did not open");
                    tryVerify(() => messageIsShown(threadList(), nestedReplyId), 5000, "jump target is not shown in its thread");
                }

                function test_jumpToRootKeepsOpenThread() {
                    openThreadFromList(rootId);
                    CurrentConversation.scrollToMsg(otherRootId);
                    tryVerify(() => messageIsShown(messageList(), otherRootId), 5000, "root jump target is not shown in the main list");
                    compare(threadModel.threadId, rootId);
                }

                function test_jumpWithinOpenThreadKeepsIt() {
                    openThreadFromList(rootId);
                    CurrentConversation.scrollToMsg(replyId);
                    compare(threadModel.threadId, rootId);
                    tryVerify(() => messageIsShown(threadList(), replyId), 5000, "jump target is not shown in the open thread");
                }

                function test_jumpToUnknownMessageEndsUnavailable() {
                    CurrentConversation.scrollToMsg("missing-thread-target-" + Date.now());
                    tryVerify(() => MessagesAdapter.navigationFailed, 60000, "unknown jump target never ended");
                    compare(MessagesAdapter.navigationTarget, "");
                    compare(threadModel.threadId, "");
                    const status = findChild(uut, "threadNavigationStatus");
                    tryVerify(() => status.visible, 5000, "unavailable status is not shown");
                    // The row is placed by its layout's next polish.
                    verify(waitForPolish(status.parent));
                    mouseClick(findChild(status, "threadNavigationDismissButton"));
                    verify(!MessagesAdapter.navigationFailed);
                    tryVerify(() => !status.visible, 5000, "unavailable status is still shown");
                }

                function test_cancelledJumpIsNotResumed() {
                    CurrentConversation.scrollToMsg("missing-thread-target-" + Date.now());
                    verify(MessagesAdapter.navigationTarget !== "" || MessagesAdapter.navigationFailed);
                    MessagesAdapter.cancelNavigation();
                    compare(MessagesAdapter.navigationTarget, "");
                    // Give an already-issued history request time to complete.
                    wait(1000);
                    compare(MessagesAdapter.navigationTarget, "");
                    verify(!MessagesAdapter.navigationFailed);
                }

                function test_disablingThreadedViewCancelsJump() {
                    CurrentConversation.scrollToMsg("missing-thread-target-" + Date.now());
                    verify(MessagesAdapter.navigationTarget !== "" || MessagesAdapter.navigationFailed);
                    MessagesAdapter.threadedView = false;
                    compare(MessagesAdapter.navigationTarget, "");
                    verify(!MessagesAdapter.navigationFailed);
                }
            }
        }
    }
}
