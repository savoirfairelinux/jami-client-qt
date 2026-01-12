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
    ConversationListView {
        id: uut
        headerVisible: false
        headerLabel: ""

        TestCase {
            name: "Check fake conversation list"
            function test_checkFakeConversationList() {
                uut.model = [{"ActiveCallsCount":0,"CallStackViewShouldShow":false,"Draft":"","InCall":false,
                            "IsAudioOnly":false,"IsBanned":false,"IsCoreDialog":false,"IsRequest":false,"IsSwarm":true,
                            "LastInteraction":"Outgoing call - 00:32","LastInteractionTimeStamp":1702479346,"Mode":2,"
                            Monikers":[],"Presence":2,"Title":"Test2 (you)","UID":"48f500d116c0ec9ee16991ee55e9740defbf3601","UnreadMessagesCount":0,
                            "Uris":["5ede716f701ef17fc103a22e6aaea0d91f1b08b0"]},
                            {"ActiveCallsCount":0,"Alias":"Alice","BestId":"581accfc568aeb20c49ed5f1fe7e78806f9c6186",
                            "CallStackViewShouldShow":false,"ContactType":1,"Draft":"","InCall":false,"IsAudioOnly":false,
                            "IsBanned":false,"IsCoreDialog":true,"IsRequest":false,"IsSwarm":true,"LastInteraction":"Incoming call - 26:17",
                            "LastInteractionTimeStamp":1689259642,"Mode":0,"Monikers":["Alice",""],"Presence":0,
                            "RegisteredName":"","Title":"Alice","UID":"68fda54c89c56dc9e92073f0e6a3f36f438eb639","URI":"581accfc568aeb20c49ed5f1fe7e78806f9c6186",
                            "UnreadMessagesCount":4,"Uris":["581accfc568aeb20c49ed5f1fe7e78806f9c6186"]},
                            {"ActiveCallsCount":0,"Alias":"","BestId":"test","CallStackViewShouldShow":false,"ContactType":1,"Draft":"","InCall":false,
                            "IsAudioOnly":false,"IsBanned":false,"IsCoreDialog":true,"IsRequest":false,"IsSwarm":true,"LastInteraction":"3",
                            "LastInteractionTimeStamp":1688407560,"Mode":0,"Monikers":["","test"],"Presence":0,"RegisteredName":"test",
                            "Title":"test","UID":"f25910613c7d9029188231f3b09d6cdb1c90bdf0","URI":"8de0bbe6be0fd5d49dc5648f7a680ada1af68bd7",
                            "UnreadMessagesCount":0,"Uris":["8de0bbe6be0fd5d49dc5648f7a680ada1af68bd7"]}]
                compare(uut.model.length, 3)
            }
        }
    }
}
