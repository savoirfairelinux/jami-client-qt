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
import QtQuick.Controls
import QtTest

import net.jami.Models 1.1
import net.jami.Constants 1.1
import net.jami.Adapters 1.1

import "../../../src/app/"

// Tests the CallPipWindowContent item — the visual body of the PiP window —
// with a real active call. The ApplicationWindow / QWindowKit layer (which is
// unavailable offscreen) is intentionally omitted; CallPipWindowContent is a
// plain Item that can be embedded directly in the test wrapper.
TestWrapper {
    id: root

    CallPipWindowContent {
        id: uut

        width: 400
        height: 300

        // Mimic the defaults that CallPipWindow would compute.
        scaleVal: 1.0
        iconButtonSize: JamiTheme.iconButtonSmall
        // Keep useFrameless false so we don't need the QWK close button.
        useFrameless: false
    }

    TestCase {
        name: "CallPipWindowContent"
        when: windowShown

        property string aliceId: ""
        property string aliceConvId: ""

        function initTestCase() {
            aliceId = CurrentAccount.id
            aliceConvId = CurrentConversation.id
            verify(aliceId.length > 0, "Alice account ID must be set by test harness")
            verify(aliceConvId.length > 0, "Alice conversation ID must be set by test harness")
        }

        function cleanup() {
            // Move the mouse out of uut so hover state does not bleed into the next test.
            mouseMove(uut, -10, -10)
            CallPipWindowManager.closeAll()
            CallAdapter.endCall(aliceId, aliceConvId)
            tryVerify(() => !CallPipWindowManager.convHasActiveCall(aliceConvId, aliceId),
                      5000,
                      "Call should be gone by end of cleanup")
            // Give daemon background threads time to settle before the next test.
            wait(300)
            AccountAdapter.changeAccount(0)
        }

        function cleanupTestCase() {
            wait(300)
        }

        // Helpers

        function startCallAndWait() {
            LRCInstance.selectConversation(aliceConvId, aliceId)
            tryVerify(() => CurrentConversation.id === aliceConvId, 5000,
                      "Alice's conversation must be selected before placing a call")
            CallAdapter.startAudioOnlyCall()
            tryVerify(() => CallPipWindowManager.convHasActiveCall(aliceConvId, aliceId),
                      15000,
                      "A call should become active for Alice's conversation")
        }

        function activatePip() {
            // Window creation goes through QWindowKit which is unavailable offscreen.
            // Use the test backdoor to set PiP state directly on the singleton.
            verify(waitForSignalAndCheck(CallPipWindowManager,
                                         "isPipActiveChanged",
                                         () => CallPipWindowManager.setTestPipState(aliceConvId, aliceId, ""),
                                         () => CallPipWindowManager.isPipActive),
                   "isPipActive should become true after setTestPipState()")
        }

        function endCurrentCall() {
            CallAdapter.endCall(aliceId, aliceConvId)
            tryVerify(() => !CallPipWindowManager.convHasActiveCall(aliceConvId, aliceId),
                      10000,
                      "Call should be gone after endCall()")
        }

        // Tests

        // All expected named children must be findable by objectName.
        function test_0_expectedChildrenExist() {
            verify(findChild(uut, "remoteVideo"), "remoteVideo must exist")
            verify(findChild(uut, "popOutButton"), "popOutButton must exist")
            verify(findChild(uut, "controlRow"), "controlRow must exist")
            verify(findChild(uut, "muteAudioButton"), "muteAudioButton must exist")
            verify(findChild(uut, "endCallButton"), "endCallButton must exist")
            verify(findChild(uut, "muteCameraButton"), "muteCameraButton must exist")
            verify(findChild(uut, "durationLabel"), "durationLabel must exist")
        }

        // Before a call is active the control overlay should stay hidden.
        function test_overlayHiddenBeforeCall() {
            compare(CallPipWindowManager.isPipActive, false)

            const controlRow = findChild(uut, "controlRow")
            mouseMove(uut, -10, -10)
            compare(uut.isHovered, false)

            // With no active call the bottomMargin should be negative (off-screen).
            verify(controlRow.anchors.bottomMargin < 0,
                   "controlRow should be off-screen when not hovered")
        }

        // After activating PiP the content should reflect the call's identity.
        function test_pipStateReflectedInContent() {
            startCallAndWait()
            activatePip()

            compare(CallPipWindowManager.pipConvId, aliceConvId)
            compare(CallPipWindowManager.pipAccountId, aliceId)

            // Duration label text binding points at the active conv/account.
            const durationLabel = findChild(uut, "durationLabel")
            verify(durationLabel !== null)

            endCurrentCall()
        }

        // Moving the mouse over the content should reveal the overlay buttons.
        function test_hoverRevealsOverlay() {
            startCallAndWait()
            activatePip()

            const controlRow = findChild(uut, "controlRow")

            mouseMove(uut, -10, -10)
            wait(JamiTheme.shortFadeDuration + 100)
            compare(uut.isHovered, false)
            verify(controlRow.anchors.bottomMargin < 0,
                   "controlRow should be off-screen before hover")

            mouseMove(uut, uut.width / 2, uut.height / 2)

            // We need to wait for the fade-in animation to complete.
            const waitTime = JamiTheme.shortFadeDuration + 100
            wait(waitTime)

            compare(uut.isHovered, true)
            verify(controlRow.anchors.bottomMargin >= 0,
                   "controlRow should be on-screen after hover")

            endCurrentCall()
        }

        // Clicking the end-call button should terminate the active call.
        function test_endCallButtonEndsCall() {
            startCallAndWait()
            activatePip()

            const endCallButton = findChild(uut, "endCallButton")
            verify(endCallButton !== null)

            // Make the overlay visible so the button is interactable.
            mouseMove(uut, uut.width / 2, uut.height / 2)
            wait(JamiTheme.shortFadeDuration + 100)

            mouseClick(endCallButton)

            tryVerify(() => !CallPipWindowManager.convHasActiveCall(aliceConvId, aliceId),
                      10000,
                      "Call should be terminated after clicking the end-call button")
        }

        // Clicking the pop-in button should call reabsorb() and deactivate PiP.
        function test_popInButtonDeactivatesPip() {
            startCallAndWait()
            activatePip()

            verify(CallPipWindowManager.isPipActive,
                   "PiP must be active before clicking pop-in")

            const popOutButton = findChild(uut, "popOutButton")
            verify(popOutButton !== null)

            mouseMove(uut, uut.width / 2, uut.height / 2)
            wait(JamiTheme.shortFadeDuration + 100)

            verify(waitForSignalAndCheck(CallPipWindowManager,
                                         "isPipActiveChanged",
                                         () => mouseClick(popOutButton),
                                         () => !CallPipWindowManager.isPipActive),
                   "isPipActive should become false after clicking pop-in")

            endCurrentCall()
        }
    }
}
