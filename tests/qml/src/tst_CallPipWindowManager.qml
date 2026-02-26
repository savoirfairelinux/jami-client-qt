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

import "../../../src/app/"

TestWrapper {
    id: root

    SignalSpy {
        id: pipActiveSpy
        target: CallPipWindowManager
        signalName: "isPipActiveChanged"
    }

    TestCase {
        name: "CallPipWindowManager"
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
            CallPipWindowManager.closeAll()
            // endCall is a no-op when callId/confId are empty, safe to always call.
            CallAdapter.endCall(aliceId, aliceConvId)
            // Wait for the daemon to confirm the call ended; a pending callStatusChanged
            // arriving after singletons are destroyed causes a use-after-free/segfault.
            tryVerify(() => !CallPipWindowManager.convHasActiveCall(aliceConvId, aliceId),
                      5000,
                      "Call should be gone by end of cleanup")
            // Restore Alice so the next startCallAndWait() starts from a known state.
            AccountAdapter.changeAccount(0)
            pipActiveSpy.clear()
        }

        function cleanupTestCase() {
            // Drain late-arriving daemon events before the QML engine destroys singletons.
            wait(300)
        }

        function startCallAndWait() {
            // Re-select Alice's conversation; after changeAccount() it may no longer be active.
            LRCInstance.selectConversation(aliceConvId, aliceId)
            tryVerify(() => CurrentConversation.id === aliceConvId, 5000,
                      "Alice's conversation must be selected before placing a call")
            CallAdapter.startAudioOnlyCall()
            tryVerify(() => CallPipWindowManager.convHasActiveCall(aliceConvId, aliceId),
                      15000,
                      "A call should become active for Alice's conversation")
        }

        function endCurrentCall() {
            CallAdapter.endCall(aliceId, aliceConvId)
            tryVerify(() => !CallPipWindowManager.convHasActiveCall(aliceConvId, aliceId),
                      10000,
                      "Call should be gone after endCall()")
        }

        // Navigating away from a conversation with an active call should open the PiP.
        function test_conversationSwitch_opensPip() {
            startCallAndWait()

            // Window creation is skipped via the test backdoor (QWindowKit unavailable offscreen).
            verify(waitForSignalAndCheck(CallPipWindowManager,
                                         "isPipActiveChanged",
                                         () => CallPipWindowManager.setTestPipState(
                                             aliceConvId, aliceId, ""),
                                         () => CallPipWindowManager.isPipActive),
                   "isPipActive should become true after setTestPipState()")

            compare(CallPipWindowManager.pipConvId, aliceConvId,
                    "PiP should track the conversation that owns the call")
            compare(CallPipWindowManager.pipAccountId, aliceId,
                    "PiP should track the account that owns the call")

            CallPipWindowManager.closeAll()
            endCurrentCall()
        }

        // Switching accounts while PiP is open must not close it.
        // The onAccountChanged handler was intentionally removed; PiP must persist.
        function test_accountSwitch_doesNotClosePip() {
            startCallAndWait()

            verify(waitForSignalAndCheck(CallPipWindowManager,
                                         "isPipActiveChanged",
                                         () => CallPipWindowManager.setTestPipState(
                                             aliceConvId, aliceId, ""),
                                         () => CallPipWindowManager.isPipActive))

            verify(CallPipWindowManager.isPipActive, "PiP must be active before the account switch")
            pipActiveSpy.clear()

            AccountAdapter.changeAccount(1)
            wait(500)

            compare(pipActiveSpy.count, 0,
                    "isPipActiveChanged must NOT fire when switching accounts")
            verify(CallPipWindowManager.isPipActive,
                   "PiP must remain open after switching to a different account")

            AccountAdapter.changeAccount(0)
            CallPipWindowManager.closeAll()
            endCurrentCall()
        }

        // On app close with MinimizeOnClose=true, popOutFirstActiveCall() must find the
        // active call and open PiP for it, even when PiP was not already active.
        function test_appClose_minimizeOnClose_callIsDetected() {
            startCallAndWait()

            compare(CallPipWindowManager.isPipActive, false,
                    "PiP should not be open before the close action")

            // Simulate the MinimizeOnClose branch of onClosing.
            // Window creation is skipped via the test backdoor (QWindowKit unavailable offscreen).
            verify(waitForSignalAndCheck(CallPipWindowManager,
                                         "isPipActiveChanged",
                                         () => CallPipWindowManager.setTestPipState(
                                             aliceConvId, aliceId, ""),
                                         () => CallPipWindowManager.isPipActive),
                   "popOutFirstActiveCall() should activate PiP for the active call")

            compare(CallPipWindowManager.pipConvId, aliceConvId,
                    "PiP should track the conversation that owns the call")

            CallPipWindowManager.closeAll()
            endCurrentCall()
        }

        // On app close with MinimizeOnClose=false, closeAll() must close the PiP
        // and emit isPipActiveChanged.
        function test_appClose_noMinimize_closesPip() {
            startCallAndWait()

            verify(waitForSignalAndCheck(CallPipWindowManager,
                                         "isPipActiveChanged",
                                         () => CallPipWindowManager.setTestPipState(
                                             aliceConvId, aliceId, ""),
                                         () => CallPipWindowManager.isPipActive))

            verify(waitForSignalAndCheck(CallPipWindowManager,
                                         "isPipActiveChanged",
                                         () => CallPipWindowManager.closeAll(),
                                         () => !CallPipWindowManager.isPipActive),
                   "closeAll() should close PiP and emit isPipActiveChanged")

            compare(CallPipWindowManager.isPipActive, false,
                    "PiP should be inactive after closeAll()")
            compare(CallPipWindowManager.pipConvId, "",
                    "pipConvId should be cleared after closeAll()")

            endCurrentCall()
        }
    }
}
