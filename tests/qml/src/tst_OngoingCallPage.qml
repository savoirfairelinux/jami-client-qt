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
import QtQuick.Controls
import QtTest

import net.jami.Models 1.1
import net.jami.Constants 1.1

import "../../../src/app/"
import "../../../src/app/mainview/components"

OngoingCallPage {
    id: uut

    width: 800
    height: 600

    property QtObject appWindow
    property ViewManager viewManager: ViewManager {
    }
    property ViewCoordinator viewCoordinator: ViewCoordinator {
        viewManager: uut.viewManager
    }

    TestCase {
        name: "Check basic visibility of action bar during a call"
        when: windowShown // Mouse events can only be handled
                          // after the window has been shown.

        property var callOverlay
        property var mainOverlay

        function initTestCase() {
            callOverlay = findChild(uut, "callOverlay")
            mainOverlay = findChild(callOverlay, "mainOverlay")

            // The CallActionBar on the OngoingCallPage starts out invisible and
            // is made visible whenever the user moves their mouse.
            // This is implemented via an event filter in the CallOverlayModel
            // class. The event filter is created when the MainOverlay becomes
            // visible. In the actual Jami application, this happens when a call
            // is started, but we need to toggle the visiblity manually here
            // because the MainOverlay is visible at the beginning of the test.
            appWindow = uut.Window.window
            mainOverlay.visible = false
            mainOverlay.visible = true

            // Calling mouseMove() will generate warnings if we don't call init first.
            viewCoordinator.init(uut)
        }

        function test_checkBasicVisibility() {
            var callActionBar = findChild(mainOverlay, "callActionBar")

            // The primary and secondary actions in the CallActionBar are currently being added
            // one by one (not using a loop) to CallOverlayModel in the Component.onCompleted
            // block of CallActionBar.qml. The two lines below are meant as a sanity check
            // that no action has been forgotten.
            compare(callActionBar.primaryActions.length, CallOverlayModel.primaryModel().rowCount())
            compare(callActionBar.secondaryActions.length, CallOverlayModel.secondaryModel().rowCount())

            compare(callActionBar.visible, false)
            mouseMove(uut)

            // We need to wait for the fade-in animation of the CallActionBar to be completed
            // before we check that it's visible.
            var waitTime = JamiTheme.overlayFadeDuration + 100
            // Make sure we have time to check that the CallActioinBar is visible before it fades out:
            verify(waitTime + 100 < JamiTheme.overlayFadeDelay)
            // Note: The CallActionBar is supposed to stay visible for a few seconds. If the above
            // check fails, then this means that either overlayFadeDuration or overlayFadeDelay
            // got changed to a value that's way too high/low.

            wait(waitTime)
            compare(callActionBar.visible, true)
        }
    }
}