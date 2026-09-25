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
                    ThreadReplyCount: 1,
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

            function test_threadRepliesButtonIsTabFocusableOnlyForCurrentRow() {
                tryVerify(function () {
                    return uut.itemAtIndex(0) !== null;
                }, 2000);
                const button = findChild(uut.itemAtIndex(0), "threadRepliesButton");
                verify(button !== null);

                compare(button.activeFocusOnTab, false);
                uut.currentIndex = 0;
                tryCompare(button, "activeFocusOnTab", true);

                uut.currentIndex = 1;
                tryCompare(button, "activeFocusOnTab", false);
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
}
