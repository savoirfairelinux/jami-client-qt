/*
 * Copyright (C) 2024 Savoir-faire Linux Inc.
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
import "../../../src/app/commoncomponents"

Item {
    id: uut

    // Mock reactions
    EmojiReactions {
        id: emojiReactions
    }

    // Mock bubble item
    Item {
        id: bubble
    }

    // Mock listview
    JamiListView {
        id: listView
    }

    property int id
    function getId() {
        id += 1;
        return "test" + id;
    }

    function getOptionsPopup(isOutgoing, id, body, type, transferName) {
        var component = Qt.createComponent("qrc:/commoncomponents/ShowMoreMenu.qml");
        var obj = component.createObject(bubble, {
                "emojiReactions": emojiReactions,
                "isOutgoing": isOutgoing,
                "msgId": id,
                "msgBody": body,
                "type": type,
                "transferName": transferName,
                "msgBubble": bubble,
                "listView": listView
            });
        return obj;
    }

    SignalSpy {
        id: accountAdded

        target: AccountAdapter
        signalName: "accountAdded"
    }

    TestCase {
        name: "Test message options popup instantiation"
        when: windowShown

        function test_createMessageOptionsPopup() {
            // Create an account and set it as current account
            AccountAdapter.createSIPAccount({
                "username": "currentAccountUsername"
            });
            // Block on account creation
            accountAdded.wait(1000);

            // Add some emoji reactions (one from current account uri, one from another uri)
            emojiReactions.reactions = {
                "currentAccountUsername": [{"commitId":"hotdog", "body":"🌭"}],
                "notCurrentAccountUri": [{"commitId":"tacos", "body":"🌮"}]
            };

            var optionsPopup = getOptionsPopup(true, getId(), "test", 0, "test");
            verify(optionsPopup !== null, "Message options popup should be created");

            // Check if the popup is visible once opened.
            optionsPopup.open();
            verify(optionsPopup.visible, "Message options popup should be visible");

            // Check that emojiReplied has our emoji.
            verify(JSON.stringify(optionsPopup.emojiReplied) === JSON.stringify(["🌭"]),
                "Message options popup should have emoji replied");
        }
    }
}
