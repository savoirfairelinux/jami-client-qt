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

// WindowDelegate class to handle fullscreen presentation options
@interface WindowDelegate : NSObject <NSWindowDelegate>
@end

@implementation WindowDelegate

- (NSApplicationPresentationOptions)window:(NSWindow *)window
          willUseFullScreenPresentationOptions:(NSApplicationPresentationOptions)proposedOptions {
    // Return options to hide toolbar and menu bar in fullscreen mode
    return NSApplicationPresentationFullScreen | 
           NSApplicationPresentationAutoHideToolbar | 
           NSApplicationPresentationAutoHideMenuBar;
}

@end

bool macutils::isMetalSupported() {
    return ([[MTLCopyAllDevices() autorelease] count] > 0);
}

void macutils::setToolBar(QWindow* window) {
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

        // Create and set the window delegate to hide tool bar on full screen
        static WindowDelegate* windowDelegate = [[WindowDelegate alloc] init];
        [nativeWindow setDelegate:windowDelegate];
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

    // Override Qt's startSystemMove to include NSEventTypePressure

    if (![nativeWindow respondsToSelector:@selector(performWindowDragWithEvent:)]) {
        return;
    }

    NSEvent* currentEvent = [NSApp currentEvent];
    NSEventType eventType = currentEvent.type;

    switch (eventType) {
    case NSEventTypeLeftMouseDown:
    case NSEventTypeRightMouseDown:
    case NSEventTypeOtherMouseDown:
    case NSEventTypeMouseMoved:
    case NSEventTypeLeftMouseDragged:
    case NSEventTypeRightMouseDragged:
    case NSEventTypeOtherMouseDragged:
    case NSEventTypePressure:
        [nativeWindow performWindowDragWithEvent:currentEvent];
        break;
    default:
        break;
    }
}

bool macutils::isMacOS26OrLater() {
    if (@available(macOS 26.0, *)) {
        return true;
    }
    return false;
}
