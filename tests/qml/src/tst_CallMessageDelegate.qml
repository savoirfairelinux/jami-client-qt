/*
 * Copyright (C) 2024-2025 Savoir-faire Linux Inc.
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
    CallMessageDelegate {
        id: uut

        type: Interaction.Type.CALL

        TestCase {
            name: "Check basic visibility for option buttons"
            function test_checkOptionButtonsVisibility() {
                var moreButton = findChild(uut, "more")
                var replyButton = findChild(uut, "reply")
                compare(moreButton.visible, false)
                compare(replyButton.visible, false)
            }
        }

        TestCase {
            name: "Check button visibility for swarm call"
            function test_checkOptionButtonsVisibility() {
                uut.isActive = true
                uut.currentCallId = "foo"
                uut.confId = "foo"
                var callLabel = findChild(uut, "callLabel")
                var joinCallWithAudio = findChild(uut, "joinCallWithAudio")
                var joinCallWithVideo = findChild(uut, "joinCallWithVideo")
                compare(callLabel.visible, true)
                compare(joinCallWithAudio.visible, false)
                compare(joinCallWithVideo.visible, false)
                uut.confId = "bar"
                compare(callLabel.visible, true)
                compare(joinCallWithAudio.visible, true)
                compare(joinCallWithVideo.visible, true)
            }
        }
    }
}
