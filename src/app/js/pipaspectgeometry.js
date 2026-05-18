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

// Pure geometry math for CallPipWindow's video-aspect-ratio tracking. Kept
// free of QML Window/Item dependencies so it can be unit tested directly,
// without spinning up the (offscreen-unavailable) QWindowKit stack.

// Given the current window size and the video's inverse aspect ratio
// (height / width), returns the {width, height} the window should take so
// the full video frame is visible without cropping. Clamped to
// [minimumWidth, minimumHeight] and [maxWidth, maxHeight]; whichever clamp
// applies, the paired dimension is re-derived so the result still matches
// videoInvAspect (never leaves the window off-aspect at a boundary).
function computeSize(currentWidth, currentHeight, videoInvAspect, lastVideoInvAspect,
                      minimumWidth, minimumHeight, maxWidth, maxHeight, fromHeight) {
    let newWidth, newHeight;
    if (fromHeight) {
        newWidth = Math.round(currentHeight / videoInvAspect);
        if (newWidth < minimumWidth) {
            newWidth = minimumWidth;
            newHeight = Math.max(minimumHeight, Math.round(newWidth * videoInvAspect));
        } else {
            newHeight = currentHeight;
        }
    } else if (lastVideoInvAspect > 0
               && Math.abs(videoInvAspect - lastVideoInvAspect) / lastVideoInvAspect > 0.01) {
        // The video's own aspect ratio changed (e.g. remote rotated): preserve
        // the window's screen area rather than anchoring either dimension.
        const area = currentWidth * currentHeight;
        newWidth = Math.max(minimumWidth, Math.round(Math.sqrt(area / videoInvAspect)));
        newHeight = Math.round(newWidth * videoInvAspect);
        if (newHeight < minimumHeight) {
            newHeight = minimumHeight;
            newWidth = Math.max(minimumWidth, Math.round(newHeight / videoInvAspect));
        }
    } else {
        newWidth = currentWidth;
        newHeight = Math.round(currentWidth * videoInvAspect);
        if (newHeight < minimumHeight) {
            newHeight = minimumHeight;
            newWidth = Math.max(minimumWidth, Math.round(newHeight / videoInvAspect));
        }
    }

    if (newWidth > maxWidth) {
        newWidth = maxWidth;
        newHeight = Math.round(newWidth * videoInvAspect);
    }
    if (newHeight > maxHeight) {
        newHeight = maxHeight;
        newWidth = Math.round(newHeight / videoInvAspect);
    }

    return { width: newWidth, height: newHeight };
}

// Nudges (x, y) back on-screen when growing to (width, height) would push
// the window past the right/bottom edge of the available screen area.
function clampPosition(x, y, width, height, screenLeft, screenTop, screenWidth, screenHeight) {
    const maxX = screenLeft + screenWidth - width;
    const maxY = screenTop + screenHeight - height;
    return {
        x: x > maxX ? Math.max(screenLeft, maxX) : x,
        y: y > maxY ? Math.max(screenTop, maxY) : y
    };
}
