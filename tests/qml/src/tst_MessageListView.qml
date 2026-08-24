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
}
