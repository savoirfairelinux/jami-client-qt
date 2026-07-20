/*
 * Copyright (C) 2026 Savoir-faire Linux Inc.
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

import net.jami.Models 1.1
import net.jami.Constants 1.1
import net.jami.Adapters 1.1

import "../../../src/app/mainview/components"

// End-to-end coverage of the "one big + small" (ONE_WITH_SMALL) side strip
// introduced/fixed by "conference: keep thumbnail ratio, fix side scroll".
//
// Unlike tst_ParticipantsLayoutHorizontal (which unit-tests the scroll math on
// bare Flickable geometry), this drives the real chain: a populated
// CallParticipantsModel produces real tiles, and synthetic video frames pushed
// into each tile's QVideoSink give them a known aspect ratio -- no live call.
//
// Both fakes are provided by the test harness (tests/qml/main.cpp):
//   videoTestHelper.setConferenceParticipants(list, layout)
//   videoTestHelper.pushFrame(videoSink, w, h)
TestWrapper {
    ParticipantsLayer {
        id: layer

        // Deliberately small so the strip must scroll (and cull) with 12 tiles.
        width: 240
        height: 220
        participantsSide: true

        TestCase {
            name: "Conference participant side strip"
            when: windowShown

            readonly property real portraitRatio: 1280 / 720  // ~1.7778 (h/w)
            readonly property real landscapeRatio: 720 / 1280 // 0.5625

            function genericTiles() {
                var flow = findChild(layer, "commonParticipantsFlow");
                verify(flow !== null);
                var out = [];
                for (var i = 0; i < flow.children.length; ++i) {
                    if (flow.children[i].objectName === "genericTile")
                        out.push(flow.children[i]);
                }
                return out;
            }

            function populate(n) {
                var parts = [];
                for (var i = 0; i < n; ++i)
                    parts.push({ uri: "p" + i, sinkId: "s" + i, active: false, videoMuted: false });
                videoTestHelper.setConferenceParticipants(parts, CallParticipantsModel.ONE_WITH_SMALL);
                tryVerify(function() { return genericTiles().length === n; }, 3000);
                // Layout drives inLine via the singleton layout.
                compare(CallParticipantsModel.conferenceLayout, CallParticipantsModel.ONE_WITH_SMALL);
            }

            // ponytail: cleanup() alone leaves the last test's participants
            // visible until the next populate() call replaces them; clearing
            // here is what keeps this singleton from leaking into later tests.
            function cleanup() {
                videoTestHelper.setConferenceParticipants([], CallParticipantsModel.GRID);
            }

            // Each tile is sized to the whole incoming video aspect ratio instead
            // of being cropped to a fixed box: portrait feeds are taller, landscape
            // feeds shorter, at the same tile width.
            function test_1_tilesKeepIncomingAspectRatio() {
                populate(12);
                var t = genericTiles();
                // The first two tiles start near the top, so they are loaded.
                tryVerify(function() { return t[0].item && t[1].item; }, 3000);

                videoTestHelper.pushFrame(t[0].item.videoSink, 1280, 720); // landscape
                videoTestHelper.pushFrame(t[1].item.videoSink, 720, 1280); // portrait

                tryVerify(function() { return Math.abs(t[0].invAspectRatio_ - landscapeRatio) < 0.01; }, 2000);
                tryVerify(function() { return Math.abs(t[1].invAspectRatio_ - portraitRatio) < 0.01; }, 2000);

                // Height follows width * ratio (whole video, not a cropped box).
                fuzzyCompare(t[0].height, Math.round(t[0].width * landscapeRatio), 1);
                fuzzyCompare(t[1].height, Math.round(t[1].width * portraitRatio), 1);
                verify(t[1].height > t[0].height);
            }

            // Off-screen tiles are culled (Loader deactivated -> VideoView stops
            // rendering) but keep their layout slot sized from the last known
            // aspect ratio, so contentHeight does not collapse/jump. This is the
            // regression the change fixed.
            function test_2_offscreenTilesAreCulledButKeepTheirSlot() {
                populate(12);
                var t = genericTiles();
                var strip = findChild(layer, "centerItem");
                verify(strip !== null);

                tryVerify(function() { return t[0].item; }, 3000);
                videoTestHelper.pushFrame(t[0].item.videoSink, 720, 1280); // portrait
                tryVerify(function() { return Math.abs(t[0].invAspectRatio_ - portraitRatio) < 0.01; }, 2000);

                var slotHeight = t[0].height;
                verify(slotHeight > 0);
                verify(strip.contentHeight > strip.height); // scrolling is required

                // Scroll the top tile well out of view.
                for (var s = 0; s < 30; ++s)
                    strip.scrollDown();
                tryVerify(function() { return !t[0].inViewport_; }, 2000);

                // Culled: no active Loader and the VideoView item is gone.
                verify(!t[0].active);
                verify(t[0].item === null);

                // ...but the slot keeps its size from the cached ratio.
                fuzzyCompare(t[0].lastInvAspectRatio_, portraitRatio, 0.01);
                fuzzyCompare(t[0].height, slotHeight, 1);
            }

            // The strip scrolls all the way to the bottom (the bottom thumbnails
            // are reachable, not hidden), and the last tile then loads.
            function test_3_bottomTilesAreReachable() {
                populate(12);
                var t = genericTiles();
                var strip = findChild(layer, "centerItem");

                for (var s = 0; s < 30; ++s)
                    strip.scrollDown();
                verify(!strip.canScrollDown);       // reached the end
                verify(strip.canScrollUp);
                var last = t[t.length - 1];
                tryVerify(function() { return last.inViewport_ && last.item; }, 3000);
            }
        }
    }
}
