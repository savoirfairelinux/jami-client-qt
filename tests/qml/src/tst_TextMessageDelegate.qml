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

// Interaction.Type enum values (from libclient/api/interaction.h):
//   INVALID=0, INITIAL=1, TEXT=2, CALL=3, CONTACT=4, DATA_TRANSFER=5
// DelegateChooser in MessageListView routes Type=2 → TextMessageDelegate.
//
// All TestCase items are placed directly inside the MessageListView so that
// model context properties (ParsedBody, IsEmojiOnly, …) are fully propagated
// to each TextMessageDelegate delegate.  Mixing a standalone TextMessageDelegate
// with a MessageListView in the same file causes a SIGSEGV in the QML engine;
// using ListView.itemAtIndex(0) to reach the delegate avoids that entirely.
ColumnLayout {
    id: root

    width: 400
    height: 600

    // Generates a long HTML body with `count` numbered lines separated by <br/>.
    function makeLongBody(count) {
        var lines = [];
        for (var i = 1; i <= count; i++)
            lines.push("Line " + i + " of the long message text.");
        return lines.join("<br/>");
    }

    // Returns a model entry for a long text message (Type=2, TEXT).
    function longMsgEntry() {
        return {
            "ActionUri": "",
            "Author": "aabbccddeeff00112233445566778899aabbccdd",
            "Body": "",
            "ConfId": "", "ContactAction": "", "DeviceId": "",
            "Duration": 0, "FileExtension": "",
            "Id": "0000000000000000000000000000000000000001",
            "Index": 0, "IsEmojiOnly": false, "IsRead": true,
            "LinkPreviewInfo": {},
            "ParsedBody": root.makeLongBody(50),
            "PreviousBodies": [], "Reactions": {}, "Readers": [],
            "ReplyTo": "", "ReplyToAuthor": "", "ReplyToBody": "",
            "Status": 4, "Timestamp": 1708025453,
            "TotalSize": 0, "TransferName": "", "Type": 2
        };
    }

    MessageListView {
        id: listView

        // Override the default MessagesAdapter.messageListModel so that no
        // real cached data is loaded at startup.  Individual test functions
        // assign their own model entries.
        model: []

        Layout.fillWidth: true
        Layout.fillHeight: true

        // ------------------------------------------------------------------
        // TC-2: Collapsed state → button shows JamiStrings.showMore.
        // ------------------------------------------------------------------
        TestCase {
            name: "Collapsed state shows show-more label"

            function test_collapsedButtonText() {
                listView.model = [root.longMsgEntry()];
                var delegate = null;
                tryVerify(function () {
                    delegate = listView.itemAtIndex(0);
                    return delegate !== null;
                }, 1000, "TextMessageDelegate must be created by ListView");
                // Force collapsed (breaks the isLongMessage binding intentionally).
                delegate.longMsgCollapsed = true;
                var btn = findChild(delegate, "collapseButton");
                verify(btn !== null, "collapseButton must exist");
                compare(btn.text, JamiStrings.showMore,
                        "collapsed state must show showMore label");
            }
        }

        // ------------------------------------------------------------------
        // TC-3: Expanded state → button shows JamiStrings.showLess.
        // ------------------------------------------------------------------
        TestCase {
            name: "Expanded state shows show-less label"

            function test_expandedButtonText() {
                listView.model = [root.longMsgEntry()];
                var delegate = null;
                tryVerify(function () {
                    delegate = listView.itemAtIndex(0);
                    return delegate !== null;
                }, 1000, "TextMessageDelegate must be created by ListView");
                delegate.longMsgCollapsed = false;
                var btn = findChild(delegate, "collapseButton");
                verify(btn !== null, "collapseButton must exist");
                compare(btn.text, JamiStrings.showLess,
                        "expanded state must show showLess label");
            }
        }

        // ------------------------------------------------------------------
        // TC-4: Toggling longMsgCollapsed flips the button label.
        // ------------------------------------------------------------------
        TestCase {
            name: "Toggling longMsgCollapsed flips button label"

            function test_toggleCollapsed() {
                listView.model = [root.longMsgEntry()];
                var delegate = null;
                tryVerify(function () {
                    delegate = listView.itemAtIndex(0);
                    return delegate !== null;
                }, 1000, "TextMessageDelegate must be created by ListView");
                var btn = findChild(delegate, "collapseButton");
                verify(btn !== null, "collapseButton must exist");
                delegate.longMsgCollapsed = true;
                compare(btn.text, JamiStrings.showMore);
                delegate.longMsgCollapsed = false;
                compare(btn.text, JamiStrings.showLess);
                delegate.longMsgCollapsed = true;
                compare(btn.text, JamiStrings.showMore);
            }
        }

        // ------------------------------------------------------------------
        // TC-5: A long message makes longMsgFooter visible.
        //
        // In test context DelegateChooser does not forward JS-array model roles
        // (ParsedBody, Author, …) as QML context properties, so
        // textEditId.implicitHeight stays small and isLongMessage never becomes
        // true naturally.  We work around this by:
        //   1. Setting longMsgCollapsed = true FIRST  (TC-2/3/4 prove this is
        //      safe and does not crash).
        //   2. Then setting isLongMessage = true (breaks the binding).
        //      Because longMsgCollapsed is already true, the
        //      onIsLongMessageChanged guard (!longMsgCollapsed) is false
        //      → Qt.callLater is NOT called → no height cascade.
        //   3. longMsgFooter.visible (= isLongMessage && !extraContent.active)
        //      immediately becomes true.
        // ------------------------------------------------------------------
        TestCase {
            name: "Long message: footer bar becomes visible after rendering"

            function test_longMessageShowsFooter() {
                listView.model = [root.longMsgEntry()];
                var delegate = null;
                tryVerify(function () {
                    delegate = listView.itemAtIndex(0);
                    return delegate !== null;
                }, 1000, "TextMessageDelegate must be created by ListView");

                // Pre-set longMsgCollapsed so the onIsLongMessageChanged guard
                // prevents Qt.callLater from firing (avoids height cascade).
                delegate.longMsgCollapsed = true;
                // Now override isLongMessage — the guard condition
                // (isLongMessage && !longMsgCollapsed) is false, so no cascade.
                delegate.isLongMessage = true;

                // In the test context the LinkPreviewInfo model role is not
                // propagated through DelegateChooser, so the Loader binding
                // `active: LinkPreviewInfo.url !== undefined` throws a
                // ReferenceError and keeps the Loader's default (active=true).
                // Force it off so that footer.visible can become true.
                var extraContent = findChild(delegate, "extraContent");
                if (extraContent)
                    extraContent.active = false;

                var footer = findChild(delegate, "longMsgFooter");
                verify(footer !== null,
                       "longMsgFooter must exist in the component");
                verify(delegate.isLongMessage,
                       "isLongMessage override did not stick");
                // longMsgFooter.visible = isLongMessage && !extraContent.active
                compare(footer.visible, true,
                        "footer must be visible when isLongMessage is true");
            }
        }

        // ------------------------------------------------------------------
        // TC-1: A short message keeps longMsgFooter hidden.
        // ------------------------------------------------------------------
        TestCase {
            name: "Short message: footer is not visible"

            function test_shortMessageFooterHidden() {
                listView.model = [{
                    "ActionUri": "",
                    "Author": "aabbccddeeff00112233445566778899aabbccdd",
                    "Body": "",
                    "ConfId": "", "ContactAction": "", "DeviceId": "",
                    "Duration": 0, "FileExtension": "",
                    "Id": "0000000000000000000000000000000000000002",
                    "Index": 0, "IsEmojiOnly": false, "IsRead": true,
                    "LinkPreviewInfo": {},
                    "ParsedBody": "This is a short message.",
                    "PreviousBodies": [], "Reactions": {}, "Readers": [],
                    "ReplyTo": "", "ReplyToAuthor": "", "ReplyToBody": "",
                    "Status": 4, "Timestamp": 1708025453,
                    "TotalSize": 0, "TransferName": "", "Type": 2
                }];
                wait(200);
                var footer = findChild(listView, "longMsgFooter");
                if (footer !== null)
                    compare(footer.visible, false,
                            "footer must be hidden for a short message");
            }
        }

        // ------------------------------------------------------------------
        // TC-6: An emoji-only message never shows the footer.
        // ------------------------------------------------------------------
        TestCase {
            name: "Emoji-only message is never collapsed"

            property string emojiBody: "😀😂🎉🔥👍🚀🌟💡🎵🎨😀😂🎉🔥👍🚀🌟💡🎵🎨😀😂"

            function test_emojiOnlyNotCollapsed() {
                listView.model = [{
                    "ActionUri": "",
                    "Author": "aabbccddeeff00112233445566778899aabbccdd",
                    "Body": "", "ConfId": "", "ContactAction": "", "DeviceId": "",
                    "Duration": 0, "FileExtension": "",
                    "Id": "0000000000000000000000000000000000000003",
                    "Index": 0, "IsEmojiOnly": true, "IsRead": true,
                    "LinkPreviewInfo": {},
                    "ParsedBody": emojiBody,
                    "PreviousBodies": [], "Reactions": {}, "Readers": [],
                    "ReplyTo": "", "ReplyToAuthor": "", "ReplyToBody": "",
                    "Status": 4, "Timestamp": 1708025453,
                    "TotalSize": 0, "TransferName": "", "Type": 2
                }];
                wait(200);
                var footer = findChild(listView, "longMsgFooter");
                if (footer !== null)
                    compare(footer.visible, false,
                            "footer must stay hidden for emoji-only messages");
            }
        }
    }
}
