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

        model: ListModel {
            id: messageModel
            Component.onCompleted: {
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
            function test_checkFakeConversation() {
                compare(uut.model.count, 3)
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
