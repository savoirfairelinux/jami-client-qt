/*
 * Copyright (C) 2022-2026 Savoir-faire Linux Inc.
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
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
#include "macutils.h"

#include <MetalKit/MetalKit.h>
#include <QWindow>
#include <Cocoa/Cocoa.h>

bool macutils::isMetalSupported() {
    return ([[MTLCopyAllDevices() autorelease] count] > 0);
}

void macutils::fixMacOSRoundedCorners(QWindow* window) {
    if (!window) {
        return;
    }

    if (@available(macOS 26.0, *)) {
        WId windowId = window->winId();
        if (!windowId) {
            return;
        }

        NSView* view = reinterpret_cast<NSView*>(windowId);
        if (!view) {
            return;
        }

        NSWindow* nativeWindow = [view window];
        if (!nativeWindow) {
            return;
        }

        // Hide the window title text
        [nativeWindow setTitleVisibility:NSWindowTitleHidden];

        // Create or get the toolbar and set it to unified style
        // - Windows with toolbars get larger corner radius (~26pt)
        // - Title-bar-only windows get smaller radius (~16pt)
        NSToolbar* toolbar = [nativeWindow toolbar];
        if (!toolbar) {
            toolbar = [[NSToolbar alloc] initWithIdentifier:@"roundedCornersToolbar"];
            [toolbar setDisplayMode:NSToolbarDisplayModeIconOnly];
            [toolbar setSizeMode:NSToolbarSizeModeSmall];
            [toolbar setAllowsUserCustomization:NO];
            [toolbar setAutosavesConfiguration:NO];
            [nativeWindow setToolbar:toolbar];
        }

        [nativeWindow setToolbarStyle:NSWindowToolbarStyleUnified];
    }
}

void macutils::startSystemMove(QWindow* window) {
    if (!window) {
        return;
    }

    WId windowId = window->winId();
    if (!windowId) {
        return;
    }

    NSView* view = reinterpret_cast<NSView*>(windowId);
    if (!view) {
        return;
    }

    NSWindow* nativeWindow = [view window];
    if (!nativeWindow) {
        return;
    }

    // override qt startSystemMove to include NSEventTypePressure

    NSEvent* currentEvent = [NSApp currentEvent];
    switch (NSApp.currentEvent.type) {
    case NSEventTypeLeftMouseDown:
    case NSEventTypeRightMouseDown:
    case NSEventTypeOtherMouseDown:
    case NSEventTypeMouseMoved:
    case NSEventTypeLeftMouseDragged:
    case NSEventTypeRightMouseDragged:
    case NSEventTypeOtherMouseDragged:
    case NSEventTypePressure:
    if ([nativeWindow respondsToSelector:@selector(performWindowDragWithEvent:)]) {
        [nativeWindow performWindowDragWithEvent:currentEvent];
        return;
    }
    default:
        break;
    }
}
