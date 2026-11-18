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

#include "accessibilityrecursionguard.h"

#include "reentrancyguard.h"

#include <QEvent>
#include <QLoggingCategory>
#include <QPlatformSurfaceEvent>
#include <QWindow>

#include <windows.h>
#include <commctrl.h>

Q_LOGGING_CATEGORY(accessibilityGuardLog, "client.accessibility")

namespace {

constexpr UINT_PTR kSubclassId = 0x4a414d49; // 'JAMI'

// Legitimate WM_GETOBJECT nesting is shallow; anything deeper is a
// feedback loop between accessibility clients and the UIA provider.
constexpr int kMaxWmGetObjectDepth = 16;

ReentrancyGuard&
wmGetObjectGuard()
{
    // Window procedures always run on the thread that owns the window,
    // so per-thread accounting matches the actual call stack depth.
    thread_local ReentrancyGuard guard(kMaxWmGetObjectDepth);
    return guard;
}

LRESULT CALLBACK
subclassProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam, UINT_PTR subclassId, DWORD_PTR)
{
    switch (msg) {
    case WM_GETOBJECT: {
        // Warn once per outermost request so a sustained loop cannot flood the log.
        thread_local bool reported = false;
        auto& guard = wmGetObjectGuard();
        ReentrancyGuard::Scope scope(guard);
        if (!scope.entered()) {
            if (!reported) {
                reported = true;
                qCWarning(accessibilityGuardLog)
                    << "Refusing recursive WM_GETOBJECT request beyond depth" << guard.maxDepth();
            }
            // 0 tells the caller that no accessibility object is provided.
            return 0;
        }
        auto result = DefSubclassProc(hwnd, msg, wParam, lParam);
        if (guard.depth() == 1)
            reported = false;
        return result;
    }
    case WM_NCDESTROY:
        RemoveWindowSubclass(hwnd, subclassProc, subclassId);
        break;
    default:
        break;
    }
    return DefSubclassProc(hwnd, msg, wParam, lParam);
}

} // namespace

AccessibilityRecursionGuard::AccessibilityRecursionGuard(QObject* parent)
    : QObject(parent)
{}

AccessibilityRecursionGuard::~AccessibilityRecursionGuard() = default;

bool
AccessibilityRecursionGuard::eventFilter(QObject* watched, QEvent* event)
{
    if (event->type() != QEvent::PlatformSurface)
        return QObject::eventFilter(watched, event);

    auto* window = qobject_cast<QWindow*>(watched);
    if (!window || !window->handle())
        return QObject::eventFilter(watched, event);

    auto hwnd = reinterpret_cast<HWND>(window->winId());
    auto* surfaceEvent = static_cast<QPlatformSurfaceEvent*>(event);
    switch (surfaceEvent->surfaceEventType()) {
    case QPlatformSurfaceEvent::SurfaceCreated:
        if (!SetWindowSubclass(hwnd, subclassProc, kSubclassId, 0))
            qCWarning(accessibilityGuardLog) << "Unable to install accessibility guard on" << window;
        break;
    case QPlatformSurfaceEvent::SurfaceAboutToBeDestroyed:
        RemoveWindowSubclass(hwnd, subclassProc, kSubclassId);
        break;
    }
    return QObject::eventFilter(watched, event);
}
