/*
 * Copyright (C) 2024-2026 Savoir-faire Linux Inc.
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
import QtTest

import net.jami.Adapters 1.1
import net.jami.Models 1.1
import net.jami.Constants 1.1
import net.jami.Enums 1.1

import "../../../src/app/"
import "../../../src/app/mainview"
import "../../../src/app/mainview/components"
import "../../../src/app/commoncomponents"

ColumnLayout {
    id: root

    spacing: 0

    width: 300
    height: 300
    MessageListView {
        id: uut

        Layout.fillWidth: true
        Layout.fillHeight: true

        convContext: QtObject {
            property bool allMessagesLoaded: true
            property string id: ""
            property color color: "#00b0d0"
            signal scrollTo(string id)
            signal newInteraction()
            signal moreMessagesLoaded(int loadingRequestId)
            signal fileCopied(string fileName, string downloadDir)
        }

        model: ListModel {
            id: messageModel
            Component.onCompleted: {
                messageModel.append({
                    ActionUri: "",
                    Author: "9cdbe0ec5f1399834f597dbfef6bf7f382000000",
                    Body: "a plain text message",
                    ConfId: "",
                    ContactAction: "",
                    DeviceId: "",
                    Duration: 0,
                    FileExtension: "",
                    Id: "b1946ac92492d2347c6235b4d2611184e1a4f5b2",
                    Index: 3,
                    OriginalBody: "",
                    ParsedOriginalBody: "",
                    IsEmojiOnly: false,
                    IsRead: true,
                    LinkPreviewInfo: {},
                    ParsedBody: "a plain text message",
                    PreviousBodies: [],
                    Reactions: {},
                    Readers: [],
                    ReplyTo: "",
                    ReplyToAuthor: "",
                    ReplyToBody: "",
                    Status: 4,
                    Timestamp: 1708025460,
                    TotalSize: 0,
                    TransferName: "",
                    Type: 2
                })
                messageModel.append({
                    ActionUri: "",
                    Author: "9cdbe0ec5f1399834f597dbfef6bf7f382000000",
                    Body: "Missed incoming call",
                    ConfId: "",
                    ContactAction: "",
                    DeviceId: "",
                    Duration: 0,
                    FileExtension: "",
                    Id: "280713b932f0b4f0ce67f31a9708c48f2cbdec31",
                    Index: 2,
                    OriginalBody: "",
                    ParsedOriginalBody: "",
                    IsEmojiOnly: false,
                    IsRead: false,
                    LinkPreviewInfo: {},
                    ParsedBody: "",
                    PreviousBodies: [],
                    Reactions: {},
                    Readers: ["9cdbe0ec5f1399834f597dbfef6bf7f382000000"],
                    ReplyTo: "",
                    ReplyToAuthor: "",
                    ReplyToBody: "",
                    Status: 4,
                    Timestamp: 1708025453,
                    TotalSize: 0,
                    TransferName: "",
                    Type: 3
                })
                messageModel.append({
                    ActionUri: "5387a0669154964f649b4069c2fce55e76c30a97",
                    Author: "",
                    Body: " joined",
                    ConfId: "",
                    ContactAction: "join",
                    DeviceId: "",
                    Duration: 0,
                    FileExtension: "",
                    Id: "79d091d8bd9fc2dbdb3053e61939c488db06e2bd",
                    Index: 1,
                    OriginalBody: "",
                    ParsedOriginalBody: "",
                    IsEmojiOnly: false,
                    IsRead: false,
                    LinkPreviewInfo: {},
                    ParsedBody: "",
                    PreviousBodies: [],
                    Reactions: {},
                    Readers: [],
                    ReplyTo: "",
                    ReplyToAuthor: "",
                    ReplyToBody: "",
                    Status: 4,
                    Timestamp: 1708025440,
                    TotalSize: 0,
                    TransferName: "",
                    Type: 4
                })
                messageModel.append({
                    ActionUri: "",
                    Author: "9cdbe0ec5f1399834f597dbfef6bf7f382000000",
                    Body: "Private conversation created",
                    ConfId: "",
                    ContactAction: "",
                    DeviceId: "",
                    Duration: 0,
                    FileExtension: "",
                    Id: "fe2b91a35cbd1cc11ac868eadf2ed8a9b3dd227b",
                    Index: 0,
                    OriginalBody: "",
                    ParsedOriginalBody: "",
                    IsEmojiOnly: false,
                    IsRead: false,
                    LinkPreviewInfo: {},
                    ParsedBody: "",
                    PreviousBodies: [],
                    Reactions: {},
                    Readers: [],
                    ReplyTo: "",
                    ReplyToAuthor: "",
                    ReplyToBody: "",
                    Status: 4,
                    Timestamp: 1708025382,
                    TotalSize: 0,
                    TransferName: "",
                    Type: 1
                })
            }
        }

        TestCase {
            name: "Check fake conversation"
            when: windowShown

            function test_checkFakeConversation() {
                compare(uut.model.count, 4)
            }

            // Day separators, timestamps and bubble sequencing are derived from each
            // row's older neighbour, which is not instantiated yet when a row is
            // created while scrolling up. Check every computable row against the
            // model after a scroll round trip.
            function test_groupingSurvivesScrolling() {
                for (var i = 0; i < 40; ++i)
                    messageModel.append(makeTextRow(i));
                tryVerify(function () {
                    return uut.count === 44;
                }, 2000);

                uut.positionViewAtBeginning();
                uut.forceLayout();
                wait(200);

                // Round trip far enough to destroy and rebuild the rows we started with.
                uut.positionViewAtIndex(uut.count - 1, ListView.Beginning);
                uut.forceLayout();
                wait(200);
                uut.positionViewAtBeginning();
                uut.forceLayout();
                wait(200);

                var checked = 0;
                var sawSeparator = false;
                for (var j = 0; j < uut.count; ++j) {
                    var item = uut.itemAtIndex(j);
                    // Higher indices are older. The oldest instantiated row has nothing
                    // to compare against and settles once its neighbour is created.
                    if (item === null || item.seq === undefined || uut.itemAtIndex(j + 1) === null)
                        continue;

                    var mine = messageModel.get(j);
                    var older = messageModel.get(j + 1);
                    compare(item.timestamp, mine.Timestamp, "row " + j + " shows the wrong message");
                    compare(item.showTime, mine.Timestamp - older.Timestamp > JamiTheme.timestampIntervalTime, "row " + j + " has the wrong timestamp separator");
                    compare(item.showDay, MessagesAdapter.getFormattedDay(mine.Timestamp) !== MessagesAdapter.getFormattedDay(older.Timestamp), "row " + j + " has the wrong day separator");
                    if (item.showDay || item.showTime)
                        sawSeparator = true;
                    checked++;
                }
                verify(checked > 0);
                // Guard against the data accidentally producing no separators at all,
                // which would make every assertion above pass trivially.
                verify(sawSeparator);
            }

            function makeTextRow(i) {
                // Newest first, matching the real (reversed) proxy: five messages per
                // day, 30s apart, so day and time separators vary from row to row.
                var ts = 1708000000 - (Math.floor(i / 5) * 86400 + (i % 5) * 30);
                return {
                    ActionUri: "",
                    Author: (i % 7 === 0) ? "someoneelse0000000000000000000000000000" : "9cdbe0ec5f1399834f597dbfef6bf7f382000000",
                    Body: "bulk message " + i,
                    ConfId: "",
                    ContactAction: "",
                    DeviceId: "",
                    Duration: 0,
                    FileExtension: "",
                    Id: "bulk" + i,
                    Index: 100 + i,
                    OriginalBody: "",
                    ParsedOriginalBody: "",
                    IsEmojiOnly: false,
                    IsRead: true,
                    LinkPreviewInfo: {},
                    ParsedBody: "bulk message " + i,
                    PreviousBodies: [],
                    Reactions: {},
                    Readers: [],
                    ReplyTo: "",
                    ReplyToAuthor: "",
                    ReplyToBody: "",
                    Status: 4,
                    Timestamp: ts,
                    TotalSize: 0,
                    TransferName: "",
                    Type: 2
                };
            }

            // The text context menu carries half a dozen icon-loading menu items.
            // Building it with the delegate puts that cost on the scroll path, once
            // per message row, so it must not exist until it is asked for.
            function test_textContextMenuIsBuiltOnFirstUseOnly() {
                tryVerify(function () {
                    return uut.itemAtIndex(0) !== null;
                }, 2000);
                const loader = findChild(uut.itemAtIndex(0), "textContextMenuLoader");
                verify(loader !== null);
                compare(loader.active, false);
                compare(loader.item, null);

                // ...and it still builds when the user actually opens it.
                loader.active = true;
                verify(loader.item !== null);
                loader.active = false;
            }
        }
    }
    MessageListView {
        id: settleUut

        width: root.width
        height: 300

        convContext: QtObject {
            property bool allMessagesLoaded: true
            property string id: "settle"
            property color color: "#00b0d0"
            signal scrollTo(string id)
            signal newInteraction()
            signal moreMessagesLoaded(int loadingRequestId)
            signal fileCopied(string dest)
            function loadMoreMessages() {}
        }

        model: ListModel {
            id: settleModel
            property var getDisplayIndex: function (id) {
                for (var i = 0; i < count; ++i) {
                    if (get(i).Id === id)
                        return i;
                }
                return -1;
            }

            Component.onCompleted: {
                for (var i = 0; i < 80; ++i)
                    append({Id: "row-" + i, Type: Interaction.Type.TEXT});
            }
        }

        // Message rows differ wildly in height, so the average the view
        // extrapolates from the handful it has built does not match the block it
        // is positioning into.
        delegate: Rectangle {
            width: settleUut.width
            height: 20 + ((index * 97) % 13) * 30
            color: "transparent"
        }

        TestCase {
            name: "Check a jump holds its row while the view settles"
            when: windowShown

            function rowBox(idx) {
                const item = settleUut.itemAtIndex(idx);
                if (item === null)
                    return null;
                const top = item.mapToItem(settleUut, 0, 0).y;
                return {top: Math.round(top), bottom: Math.round(top + item.height)};
            }

            // A jump positions the row against the delegate heights the view
            // happens to know. Real rows only reach their final height once they
            // are built, so the geometry keeps moving after the jump has already
            // placed the row, which is what left search results off screen until
            // the button was pressed a second time. The jump has to hold its row.
            function test_theJumpHoldsItsRowWhenTheViewMovesUnderneath() {
                settleUut.convContext.scrollTo("row-70");
                tryVerify(function () {
                    return rowBox(70) !== null;
                }, 2000);
                const before = rowBox(70);
                verify(before.top >= 0 && before.bottom <= settleUut.height,
                       "the jump did not put the row on screen at all: " + JSON.stringify(before));

                // Stand in for the geometry settling underneath the jump.
                settleUut.contentY += 600;

                tryVerify(function () {
                    const box = rowBox(70);
                    return box !== null && box.top >= 0 && box.bottom <= settleUut.height;
                }, 2000, "the jumped-to row was left off screen after the view moved underneath it");
            }

            // ...but once it has settled, the view is the user's again.
            function test_theJumpStopsHoldingTheRowOnceItHasSettled() {
                settleUut.convContext.scrollTo("row-70");
                tryVerify(function () {
                    return rowBox(70) !== null;
                }, 2000);
                tryVerify(function () {
                    return !settleUut.jumpSettling;
                }, 3000, "the jump kept repositioning the view indefinitely");

                const parked = settleUut.contentY + 600;
                settleUut.contentY = parked;
                wait(400);
                compare(settleUut.contentY, parked);
            }
        }
    }

    MessageListView {
        id: prefetchUut

        width: root.width
        height: 180
        convContext: QtObject {
            property bool allMessagesLoaded: false
            property string id: "prefetch"
            property color color: "#00b0d0"
            signal scrollTo(string id)
            signal newInteraction()
            signal moreMessagesLoaded(int loadingRequestId)
            signal fileCopied(string dest)
            signal loadMoreRequested()
            function loadMoreMessages() {
                loadMoreRequested();
            }
        }

        model: ListModel {
            id: prefetchModel
            Component.onCompleted: {
                for (var i = 0; i < 200; ++i)
                    append({Id: "message-" + i, Type: Interaction.Type.TEXT});
            }
        }

        delegate: Rectangle {
            width: prefetchUut.width
            height: 40
            color: "transparent"
        }

        SignalSpy {
            id: loadSpy
            target: prefetchUut.convContext
            signalName: "loadMoreRequested"
        }

        TestCase {
            name: "Check offscreen history prefetch"

            function test_fetchesBeforeReachingTheOldestMessage() {
                wait(100);
                // Park the view well away from the oldest loaded message.
                prefetchUut.contentY = prefetchUut.originY + prefetchUut.displayMarginBeginning * 2;
                wait(100);
                loadSpy.clear();
                prefetchUut.countAtLastRequest = -1;
                verify(!prefetchUut.nearBeginning);
                compare(loadSpy.count, 0);

                // Coming within the offscreen buffer must fetch, without the user
                // having to scroll all the way to the top.
                prefetchUut.contentY = prefetchUut.originY + prefetchUut.displayMarginBeginning / 2;
                verify(!prefetchUut.atYBeginning);
                compare(loadSpy.count, 1);

                // Asking again before anything new arrives would be a busy loop.
                prefetchUut.contentY = prefetchUut.originY + prefetchUut.displayMarginBeginning * 2;
                prefetchUut.contentY = prefetchUut.originY;
                compare(loadSpy.count, 1);
            }

            function test_skeletonReservesRoomWhileLoading() {
                wait(100);
                prefetchUut.loadingMore = false;
                wait(200);
                verify(!prefetchUut.footerItem.visible);
                const idleHeight = prefetchUut.footerItem.height;

                // While a batch is in flight the placeholders give the list somewhere
                // to scroll, instead of dead-ending on the oldest loaded message.
                prefetchUut.loadingMore = true;
                tryVerify(function () {
                    return prefetchUut.footerItem.height > idleHeight;
                }, 1000);
                verify(prefetchUut.footerItem.visible);

                // They must sit at the end the loading is triggered from, so the user
                // is looking at them rather than at the opposite end of the history.
                prefetchUut.contentY = prefetchUut.originY;
                verify(prefetchUut.nearBeginning);
                const top = prefetchUut.footerItem.mapToItem(prefetchUut, 0, 0).y;
                verify(top < prefetchUut.height);
                verify(top + prefetchUut.footerItem.height > 0);

                // And they go away once the batch lands.
                prefetchUut.convContext.moreMessagesLoaded(0);
                compare(prefetchUut.loadingMore, false);
                tryVerify(function () {
                    return !prefetchUut.footerItem.visible;
                }, 1000);
            }
        }
    }

    MessageListView {
        id: jumpUut

        width: root.width
        height: 180
        convContext: CurrentConversation

        model: ListModel {
            id: jumpModel
            property var getDisplayIndex: function(id) {
                for (var i = 0; i < count; ++i) {
                    if (get(i).Id === id)
                        return i;
                }
                return -1;
            }

            Component.onCompleted: {
                for (var i = 0; i < 200; ++i)
                    append({Id: "message-" + i, Type: Interaction.Type.TEXT});
            }
        }

        delegate: Rectangle {
            width: jumpUut.width
            height: 20 + (index % 5) * 10
            color: "transparent"
        }

        SignalSpy {
            id: scrollSpy
            target: CurrentConversation
            signalName: "scrollTo"
        }

        TestCase {
            name: "Check jump positioning inside the loaded window"

            function test_jumpToARowOutsideTheViewport() {
                wait(100);
                scrollSpy.clear();
                compare(typeof jumpModel.getDisplayIndex, "function");
                compare(jumpModel.getDisplayIndex("message-150"), 150);
                CurrentConversation.scrollToMsg("message-150");
                compare(scrollSpy.count, 1);
                tryVerify(function() {
                    return jumpUut.itemAtIndex(150) !== null;
                }, 1000);
                const item = jumpUut.itemAtIndex(150);
                const center = item.mapToItem(jumpUut, 0, item.height / 2).y;
                compare(Math.round(center), Math.round(jumpUut.height / 2));
            }

            function test_jumpHighlightsTheRow() {
                wait(100);
                scrollSpy.clear();
                jumpUut.currentIndex = -1;
                jumpUut.jumpHighlightOpacity = 0;
                CurrentConversation.scrollToMsg("message-120");
                // The highlight tracks the current row and fades in on arrival.
                compare(jumpUut.currentIndex, 120);
                tryVerify(function () {
                    return jumpUut.jumpHighlightOpacity > 0;
                }, 1000);
                // ...then fades back out on its own.
                tryVerify(function () {
                    return jumpUut.jumpHighlightOpacity === 0;
                }, 4000);
            }
        }
    }

    // The target of a jump is often older than anything loaded, so the jump has to
    // survive a round trip: request the history, wait, then land.
    MessageListView {
        id: pendingJumpUut

        width: root.width
        height: 200

        convContext: QtObject {
            property bool allMessagesLoaded: false
            property string id: "pending-jump"
            property color color: "#00b0d0"
            property int lastRequestId: -1
            property int nextRequestId: 7000
            signal scrollTo(string id)
            signal newInteraction()
            signal moreMessagesLoaded(int loadingRequestId)
            signal fileCopied(string dest)
            function loadMoreMessages() {}
            function loadMessagesUntil(messageId) {
                lastRequestId = nextRequestId++;
                return lastRequestId;
            }
        }

        model: ListModel {
            id: pendingJumpModel
            property var getDisplayIndex: function (id) {
                for (var i = 0; i < count; ++i) {
                    if (get(i).Id === id)
                        return i;
                }
                return -1;
            }

            function prependOlder(from, to) {
                for (var i = to; i >= from; --i)
                    insert(0, {Id: "message-" + i, Type: Interaction.Type.TEXT});
            }
        }

        delegate: Rectangle {
            width: pendingJumpUut.width
            height: 20 + (index % 5) * 10
            color: "transparent"
        }

        TestCase {
            name: "Check a jump that has to wait for history"

            function init() {
                pendingJumpModel.clear();
                // Only the most recent hundred messages are loaded.
                for (var i = 100; i < 200; ++i)
                    pendingJumpModel.append({Id: "message-" + i, Type: Interaction.Type.TEXT});
                pendingJumpUut.pendingScrollToId = "";
                pendingJumpUut.pendingScrollToRequest = -1;
                pendingJumpUut.currentIndex = -1;
                wait(50);
            }

            function test_theJumpWaitsForItsHistoryThenLands() {
                const ctx = pendingJumpUut.convContext;
                compare(pendingJumpModel.getDisplayIndex("message-10"), -1);
                ctx.scrollTo("message-10");
                // Nothing to jump to yet, so the jump is parked on its request.
                compare(pendingJumpUut.pendingScrollToId, "message-10");
                compare(pendingJumpUut.pendingScrollToRequest, ctx.lastRequestId);
                compare(pendingJumpUut.currentIndex, -1);

                pendingJumpModel.prependOlder(0, 99);
                ctx.moreMessagesLoaded(ctx.lastRequestId);
                compare(pendingJumpUut.pendingScrollToId, "");
                compare(pendingJumpUut.currentIndex, 10);
            }

            function test_anUnrelatedLoadLeavesThePendingJumpAlone() {
                const ctx = pendingJumpUut.convContext;
                ctx.scrollTo("message-10");
                const request = ctx.lastRequestId;

                // A page this jump did not ask for lands first, and happens to
                // carry the target.
                pendingJumpModel.prependOlder(0, 99);
                ctx.moreMessagesLoaded(request + 999);
                compare(pendingJumpUut.pendingScrollToId, "message-10");
                compare(pendingJumpUut.currentIndex, -1);

                ctx.moreMessagesLoaded(request);
                compare(pendingJumpUut.pendingScrollToId, "");
                compare(pendingJumpUut.currentIndex, 10);
            }

            function test_aTargetThatNeverArrivesIsNotHeldForever() {
                const ctx = pendingJumpUut.convContext;
                ctx.scrollTo("message-does-not-exist");
                const request = ctx.lastRequestId;
                compare(pendingJumpUut.pendingScrollToId, "message-does-not-exist");

                // The requested history lands without the target, so it is
                // unreachable. Holding the ID would hijack the next load.
                ctx.moreMessagesLoaded(request);
                compare(pendingJumpUut.pendingScrollToId, "");
                compare(pendingJumpUut.pendingScrollToRequest, -1);
                compare(pendingJumpUut.currentIndex, -1);
            }
        }
    }

    // Bounding the shown rows means rows get removed while the user is looking
    // at history. Removing rows the view has laid out can shift what is on
    // screen, which is the scrollbar jump the window exists to avoid, so trim
    // both ends and check the visible messages do not move.
    MessageListView {
        id: trimUut

        Layout.fillWidth: true
        Layout.fillHeight: true

        convContext: QtObject {
            property bool allMessagesLoaded: true
            property string id: "trim"
            property color color: "#00b0d0"
            signal scrollTo(string id)
            signal newInteraction()
            signal moreMessagesLoaded(int loadingRequestId)
            signal fileCopied(string dest)
            function loadMoreMessages() {}
            function loadMessagesUntil(messageId) {
                return -1;
            }
        }

        model: ListModel {
            id: trimModel

            // Stands in for the proxy, which decides what the list may show. The
            // proxy's own behaviour is covered in the C++ tests; what is checked
            // here is the bounds the view asks for.
            property string lastOldest: ""
            property string lastNewest: ""
            property int windowCalls: 0

            function setWindow(oldestId, newestId) {
                lastOldest = oldestId;
                lastNewest = newestId;
                ++windowCalls;
            }

            function idAt(row) {
                return row >= 0 && row < count ? get(row).Id : "";
            }
        }

        delegate: Rectangle {
            width: trimUut.width
            height: 20
            color: "transparent"
        }

        TestCase {
            name: "Check trimming the shown rows leaves the view put"
            when: windowShown

            function init() {
                trimModel.clear();
                for (var i = 0; i < 400; ++i)
                    trimModel.append({Id: "trim-" + i, Type: Interaction.Type.TEXT});
                wait(50);
            }

            // Row 0 is the newest and BottomToTop draws it at the bottom, so the
            // ends being trimmed sit off both the top and the bottom.
            function visibleIds() {
                var ids = [];
                for (var i = 0; i < trimModel.count; ++i) {
                    var item = trimUut.itemAtIndex(i);
                    if (item && item.y + item.height > trimUut.contentY
                            && item.y < trimUut.contentY + trimUut.height) {
                        ids.push(trimModel.get(i).Id);
                    }
                }
                return ids;
            }

            function rowOf(id) {
                return parseInt(id.substring("trim-".length));
            }

            // The run the view asks for has to stay bounded, cover what is on
            // screen, and keep its ends clear of the viewport.
            function test_theShownRunFollowsTheViewportAndStaysBounded() {
                trimUut.positionViewAtIndex(200, ListView.Center);
                trimUut.forceLayout();
                wait(100);

                trimUut.updateShownRows();
                verify(trimModel.windowCalls > 0);

                var newest = rowOf(trimModel.lastNewest);
                var oldest = rowOf(trimModel.lastOldest);
                verify(oldest > newest);
                verify(oldest - newest + 1 <= trimUut.shownRowCap);

                // Everything visible is inside the run, well away from its ends.
                var ids = visibleIds();
                verify(ids.length > 0);
                for (var i = 0; i < ids.length; ++i) {
                    var row = rowOf(ids[i]);
                    verify(row >= newest + 1);
                    verify(row <= oldest - 1);
                }
                verify(trimUut.rowsAreTrimmed);
            }

            // Scrolling away has to move the run with the viewport, or the user
            // walks off the end of what is shown.
            function test_theShownRunMovesWithTheViewport() {
                trimUut.positionViewAtIndex(350, ListView.Center);
                trimUut.forceLayout();
                wait(100);
                trimUut.updateShownRows();
                var farNewest = rowOf(trimModel.lastNewest);

                trimUut.positionViewAtIndex(50, ListView.Center);
                trimUut.forceLayout();
                wait(100);
                trimUut.updateShownRows();
                var nearNewest = rowOf(trimModel.lastNewest);

                verify(nearNewest < farNewest);
            }

            function test_trimmingTheFarEndsLeavesTheViewPut() {
                trimUut.positionViewAtIndex(200, ListView.Center);
                trimUut.forceLayout();
                wait(100);

                var before = visibleIds();
                verify(before.length > 0);

                // Trim well clear of the viewport at both ends.
                trimModel.remove(300, 100);
                trimUut.forceLayout();
                wait(100);
                trimModel.remove(0, 100);
                trimUut.forceLayout();
                wait(100);

                compare(trimModel.count, 200);
                compare(visibleIds().join(","), before.join(","));
            }

            // A moving view is still building delegates for the rows it is
            // crossing, and some of those build asynchronously. Trimming
            // mid-flick destroys that work, so the run must be left alone
            // until the view settles.
            function test_theRunIsLeftAloneWhileTheViewIsMoving() {
                trimUut.positionViewAtIndex(200, ListView.Center);
                trimUut.forceLayout();
                wait(100);
                trimUut.updateShownRows();

                var before = trimModel.windowCalls;
                verify(before > 0);

                trimUut.flick(0, 600);
                verify(trimUut.moving);

                // Anything asking for a redraw mid-flick has to be turned away.
                while (trimUut.moving) {
                    trimUut.updateShownRows();
                    compare(trimModel.windowCalls, before);
                    wait(16);
                }

                // Settled again, the run is redrawn.
                trimUut.positionViewAtIndex(200, ListView.Center);
                trimUut.forceLayout();
                wait(100);
                trimUut.updateShownRows();
                verify(trimModel.windowCalls > before);
            }
        }
    }
}
