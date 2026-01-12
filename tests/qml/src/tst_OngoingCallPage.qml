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

            property string dummyImgUrl

            function initTestCase() {
                // Create a dummy image file to use for the local preview.
                dummyImgUrl = UtilsAdapter.urlFromLocalPath(UtilsAdapter.createDummyImage());

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

            // Define a generic local preview test wrapper function that starts and stops
            // the local preview, and calls the provided test function in between.
            function localPreviewTestWrapper(testFunction) {
                const localPreview = findChild(uut, "localPreview");

                // The preview should be invisible at first.
                compare(localPreview.visible, false);

                // Start a preview of a local resource and wait for the preview to become visible.
                verify(waitForSignalAndCheck(localPreview,
                                             "visibleChanged",
                                             () => localPreview.startWithId(dummyImgUrl),
                                             () => localPreview.visible));

                // Call the provided test function.
                testFunction(localPreview);

                // Stop the preview.
                verify(waitForSignalAndCheck(localPreview,
                                             "visibleChanged",
                                             () => localPreview.stop(),
                                             () => !localPreview.visible));

                // Move the mouse to the center of the call screen.
                mouseMove(uut);
            }

            function test_localPreviewAnchoring() {
                localPreviewTestWrapper(function(localPreview) {
                    const container = localPreview.parent;

                    // First check that the preview is anchored.
                    verify(localPreview.anchored);

                    const containerCenter = Qt.point(container.width / 2, container.height / 2);
                    function moveAndVerifyState(dx, dy, expectedState) {
                        const previewCenter = Qt.point(localPreview.x + localPreview.width / 2,
                                                       localPreview.y + localPreview.height / 2);
                        const destination = Qt.point(containerCenter.x + dx,
                                                     containerCenter.y + dy);
                        // Position the mouse at the center of the preview, then drag it until
                        // we reach the destination point.
                        mouseDrag(container, previewCenter.x, previewCenter.y,
                                  destination.x - previewCenter.x, destination.y - previewCenter.y);
                        wait(250);
                        compare(localPreview.state, expectedState);
                    }

                    const dx = 1;
                    const dy = 1;
                    moveAndVerifyState(-dx, -dy, "anchor_top_left");
                    moveAndVerifyState(dx, -dy, "anchor_top_right");
                    moveAndVerifyState(-dx, dy, "anchor_bottom_left");
                    moveAndVerifyState(dx, dy, "anchor_bottom_right");

                    // Verify that during a drag process, the preview is unanchored.
                    mousePress(localPreview);
                    mouseMove(localPreview, 100, 100);
                    verify(!localPreview.anchored);
                    mouseRelease(localPreview);
                });
            }

            function test_localPreviewHiding() {
                localPreviewTestWrapper(function(localPreview) {
                    // Make sure the preview is anchored.
                    verify(localPreview.anchored);

                    // It should also not be hidden.
                    compare(localPreview.hidden, false);

                    // We presume that the preview is anchored and that once we hover over the
                    // local preview, that the hide button will become visible.
                    const hidePreviewButton = findChild(localPreview, "hidePreviewButton");
                    // This is required when the opacity has an animation.
                    if (hidePreviewButton.visible) {
                        verify(waitForSignalAndCheck(hidePreviewButton,
                                                     "visibleChanged",
                                                     undefined,
                                                     () => !hidePreviewButton.visible));
                    }
                    compare(hidePreviewButton.visible, false);
                    verify(waitForSignalAndCheck(hidePreviewButton,
                                                 "visibleChanged",
                                                 () => mouseMove(localPreview),
                                                 () => hidePreviewButton.visible));

                    // Click the hide button to hide the preview.
                    mouseClick(hidePreviewButton);
                    compare(localPreview.hidden, true);

                    // Click the hide button again to show the preview.
                    mouseClick(hidePreviewButton);
                    compare(localPreview.hidden, false);
                });
            }

            function test_localPreviewRemainsVisibleWhenOngoingCallPageIsToggled() {
                localPreviewTestWrapper(function(localPreview) {
                    // The local preview should remain visible when the OngoingCallPage is toggled.
                    compare(localPreview.visible, true);
                    uut.visible = false;
                    compare(localPreview.visible, false);
                    uut.visible = true;
                    compare(localPreview.visible, true);
                });
            }
        }
    }
}
