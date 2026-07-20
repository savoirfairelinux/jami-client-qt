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
import QtQuick.Controls
import QtTest

import net.jami.Models 1.1
import net.jami.Constants 1.1
import net.jami.Adapters 1.1

import "../../../src/app/mainview/components"

// Exercises the "one big + small" (inLine) side-strip scroll math introduced in
// the "keep thumbnail ratio, fix side scroll" change: the ^/v buttons drive a
// Flickable, the scroll step is viewport-based (never skips content) and scroll
// positions are clamped. The actual video tiles are not populated here (that
// needs a live conference); we drive the Flickable geometry directly, which is
// exactly what the scroll functions operate on.
TestWrapper {
    ParticipantsLayoutHorizontal {
        id: uut

        width: 400
        height: 600
        inLine: true

        TestCase {
            name: "ParticipantsLayoutHorizontal side-strip scroll"
            when: windowShown

            property var strip

            // A tall content strip inside a short viewport: 3x taller than the
            // visible area, so scrolling is required to reach the bottom.
            readonly property real viewportH: 200
            readonly property real contentH: 600
            readonly property real maxY: contentH - viewportH // 400

            function setupStrip() {
                strip = findChild(uut, "centerItem");
                verify(strip !== null);
                // Break the layout/content bindings and pin a known geometry so
                // the scroll math is tested against deterministic values.
                strip.height = viewportH;
                strip.contentHeight = contentH;
                strip.contentY = 0;
            }

            function test_1_scrollStepIsViewportBasedAndNeverSkips() {
                setupStrip();
                // Step is a fraction of the viewport, so consecutive pages
                // overlap and no content is skipped between clicks.
                compare(strip.scrollStep(), Math.max(1, viewportH * 0.85));
                verify(strip.scrollStep() < strip.height);
            }

            function test_2_scrollDownClampsAtBottom() {
                setupStrip();
                // Click v enough times to certainly pass the bottom.
                for (var i = 0; i < 20; ++i)
                    strip.scrollDown();
                compare(strip.contentY, maxY); // never overshoots
                verify(!strip.canScrollDown);
                verify(strip.canScrollUp);
            }

            function test_3_scrollUpClampsAtTop() {
                setupStrip();
                strip.contentY = maxY;
                for (var i = 0; i < 20; ++i)
                    strip.scrollUp();
                compare(strip.contentY, 0); // never goes negative
                verify(!strip.canScrollUp);
                verify(strip.canScrollDown);
            }

            function test_4_buttonEnableStateTracksPosition() {
                setupStrip();
                // Top: only down is available.
                verify(!strip.canScrollUp);
                verify(strip.canScrollDown);
                // Middle: both available.
                strip.contentY = maxY / 2;
                verify(strip.canScrollUp);
                verify(strip.canScrollDown);
                // Bottom: only up is available.
                strip.contentY = maxY;
                verify(strip.canScrollUp);
                verify(!strip.canScrollDown);
            }

            function test_5_scrollDownReachesEveryPage() {
                setupStrip();
                // Walk down one step at a time; because the step is smaller than
                // the viewport, every part of the content is shown at some point
                // (this is the regression: old paging could hide bottom tiles).
                var covered = 0;
                var guard = 0;
                while (strip.canScrollDown && guard++ < 100) {
                    // The next page's top must be within the current viewport
                    // (overlap), guaranteeing no gap is skipped.
                    var nextTop = Math.min(maxY, strip.contentY + strip.scrollStep());
                    verify(nextTop <= strip.contentY + strip.height);
                    strip.scrollDown();
                    covered = strip.contentY + strip.height;
                }
                // The last visible pixel reaches the end of the content.
                compare(covered, contentH);
            }

            function test_6_notScrollableWhenNotInLine() {
                setupStrip();
                uut.inLine = false;
                verify(!strip.canScrollUp);
                verify(!strip.canScrollDown);
                uut.inLine = true; // restore for any later runs
            }
        }
    }
}
