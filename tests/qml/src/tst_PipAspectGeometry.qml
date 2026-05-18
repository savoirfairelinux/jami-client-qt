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

import QtTest

import "../../../src/app/js/pipaspectgeometry.js" as PipAspectGeometry

// Tests the pure aspect-ratio geometry math used by CallPipWindow.qml.
// This deliberately avoids instantiating CallPipWindow itself: it is a
// top-level Window backed by QWindowKit, which is unavailable offscreen
// (see tst_CallPipWindow.qml, which tests CallPipWindowContent instead).
TestCase {
    name: "PipAspectGeometry"

    // Below-minimum height forces newWidth up to minimumWidth; the paired
    // height must be re-derived so the result still matches videoInvAspect.
    function test_computeSize_fromHeight_clampsWidthAndRederivesHeight() {
        const size = PipAspectGeometry.computeSize(
            400, 50,    // currentWidth, currentHeight
            2.0, 0,     // videoInvAspect, lastVideoInvAspect
            260, 180,   // minimumWidth, minimumHeight
            4000, 3000, // maxWidth, maxHeight
            true)       // fromHeight

        compare(size.width, 260, "width should clamp to minimumWidth")
        verify(Math.abs(size.height / size.width - 2.0) < 0.02,
               "height should be re-derived to honour videoInvAspect")
        verify(size.height >= 180, "height must not end up below minimumHeight")
    }

    // Below-minimum height on the width-driven branch forces newHeight up to
    // minimumHeight; the paired width must be re-derived symmetrically.
    function test_computeSize_widthDriven_clampsHeightAndRederivesWidth() {
        const size = PipAspectGeometry.computeSize(
            200, 300,
            0.5, 0.5,   // no aspect change -> width-driven branch, wide video
            260, 180,
            4000, 3000,
            false)

        compare(size.height, 180, "height should clamp to minimumHeight")
        verify(Math.abs(size.height / size.width - 0.5) < 0.02,
               "width should be re-derived to honour videoInvAspect")
        verify(size.width >= 260, "width must not end up below minimumWidth")
    }

    // A genuine aspect-ratio change takes the area-preserving branch, which
    // already re-derives symmetrically; sanity-check it still holds.
    function test_computeSize_areaPreserving_honoursAspectRatio() {
        const size = PipAspectGeometry.computeSize(
            400, 300,
            0.3, 0.75,
            260, 180,
            4000, 3000,
            false)

        verify(Math.abs(size.height / size.width - 0.3) < 0.02,
               "aspect ratio should be honoured after area-preserving resize")
        verify(size.width >= 260 && size.height >= 180,
               "result must not fall below the minimum size")
    }

    // A portrait video can compute a height taller than the screen; it must
    // clamp to maxHeight and re-derive width rather than overflow off-screen.
    function test_computeSize_clampsToMaxHeight() {
        const size = PipAspectGeometry.computeSize(
            400, 300,
            1.78, 0, // portrait: height > width
            260, 180,
            4000, 500, // small available height
            false)

        compare(size.height, 500, "height should clamp to maxHeight")
        verify(Math.abs(size.height / size.width - 1.78) < 0.02,
               "width should be re-derived to honour videoInvAspect")
    }

    // clampPosition should leave an on-screen window untouched...
    function test_clampPosition_leavesOnScreenWindowUntouched() {
        const pos = PipAspectGeometry.clampPosition(100, 100, 400, 300, 0, 0, 1920, 1080)
        compare(pos.x, 100)
        compare(pos.y, 100)
    }

    // ...but nudges a window back on-screen when growth would push it past
    // the right/bottom edge (e.g. PiP parked near a corner).
    function test_clampPosition_nudgesBackOnScreenWhenGrown() {
        const pos = PipAspectGeometry.clampPosition(1800, 1000, 400, 300, 0, 0, 1920, 1080)
        compare(pos.x, 1920 - 400)
        compare(pos.y, 1080 - 300)
    }
}
