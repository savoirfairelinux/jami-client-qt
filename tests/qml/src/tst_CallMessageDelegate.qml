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
    ListView {
        id: uut
        width: 400
        height: 200
        model: ListModel {
            id: mockModel

            ListElement {
                Author: ""
                Duration: 0
                ReplyToAuthor: ""
                ReplyToBody: ""
                ReplyTo: ""
                IsEmojiOnly: false
                IsLastSent: false
                Body: ""
                Id: ""
                ConfId: ""
                ActionUri: ""
                Timestamp: 0
                Readers: ""
                Reactions: ""
                PreviousBodies: ""
                DeviceId: ""
            }
        }

        delegate: CallMessageDelegate {
            type: Interaction.Type.CALL
        }
    }

    TestCase {
        name: "Check basic visibility for option buttons"
        function test_checkOptionButtonsVisibility() {
            uut.currentIndex = 0

            const delegate = uut.currentItem
            const moreButton = findChild(delegate, "more")
            const replyButton = findChild(delegate, "reply")
            compare(moreButton.visible, false)
            compare(replyButton.visible, false)
        }
    }

    TestCase {
        name: "Check button visibility for swarm call"
        function test_checkButtonVisibilityForSwarmCall() {
            uut.currentIndex = 0

            const delegate = uut.currentItem
            delegate.isActive = true
            delegate.currentCallId = "foo"
            delegate.confId = "foo"

            const callLabel = findChild(delegate, "callLabel")
            const joinCallWithAudio = findChild(delegate, "joinCallWithAudio")
            compare(callLabel.visible, true)
            compare(joinCallWithAudio.visible, false)

            delegate.confId = "bar"
            compare(callLabel.visible, true)
            compare(joinCallWithAudio.visible, true)
        }
    }
}
