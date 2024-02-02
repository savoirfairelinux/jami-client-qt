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
import net.jami.Adapters 1.1

import "../../../src/app/"
import "../../../src/app/mainview/components"

TestWrapper {
    OngoingCallPage {
        id: uut

        width: 800
        height: 600

        TestCase {
            name: "Check various components within the OngoingCallPage"
            when: windowShown // Mouse events can only be handled
                              // after the window has been shown.

            function initTestCase() {
                // The CallActionBar on the OngoingCallPage starts out invisible and
                // is made visible whenever the user moves their mouse.
                // This is implemented via an event filter in the CallOverlayModel
                // class. The event filter is created when the MainOverlay becomes
                // visible. In the actual Jami application, this happens when a call
                // is started, but we need to toggle the visiblity manually here
                // because the MainOverlay is visible at the beginning of the test.
                const mainOverlay = findChild(uut, "mainOverlay");
                mainOverlay.visible = false;
                mainOverlay.visible = true;
            }

            // The following test is labeled with "0" to make sure it runs first.
            // This prevents having to wait for the CallActionBar to fade out.
            function test_0_checkCallActionBarVisibility() {
                var callActionBar = findChild(uut, "callActionBar")

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

            function test_checkLocalPreviewAnchoring() {
                const localPreview = findChild(uut, "localPreview");
                const container = localPreview.parent;

                // The preview should normally be invisible at first, but there is a bug
                // in the current implementation that makes it visible. This will need to
                // be adjusted once the bug is fixed.
                compare(localPreview.visible, true);

                // Start a preview of a local resource.
                const dummyImgFile = UtilsAdapter.createDummyImage();
                localPreview.startWithId(UtilsAdapter.urlFromLocalPath(dummyImgFile));

                // First check that the preview is anchored.
                verify(localPreview.state.indexOf("unanchored") === -1);

                const previewCenter = Qt.point(localPreview.width / 2, localPreview.height / 2);
                const center = Qt.point(container.width / 2, container.height / 2);
                function moveAndVerifyState(dx, dy, expectedState) {
                    const toCenterX = (center.x - (localPreview.x + previewCenter.x)) / 2;
                    const toCenterY = (center.y - (localPreview.y + previewCenter.y)) / 2;
                    mouseDrag(localPreview, 0, 0, toCenterX + dx, toCenterY + dy);
                    wait(250);
                    compare(localPreview.state, expectedState);
                }

                moveAndVerifyState(-uut.previewMargin, -uut.previewMarginYTop - 1, "anchor_top_left");
                moveAndVerifyState(uut.previewMargin, -uut.previewMarginYTop - 1, "anchor_top_right");
                moveAndVerifyState(-uut.previewMargin, uut.height, "anchor_bottom_left");
                moveAndVerifyState(uut.previewMargin, uut.height, "anchor_bottom_right");

                // Verify that during a drag process, the preview is unanchored.
                mousePress(localPreview);
                mouseMove(localPreview, 100, 100);
                verify(localPreview.state.indexOf("unanchored") !== -1);

                // Stop the preview.
                localPreview.startWithId("");
            }
        }
    }
}
