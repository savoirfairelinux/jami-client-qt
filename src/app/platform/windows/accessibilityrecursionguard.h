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

#pragma once

#include <QObject>

/**
 * Protects native windows against unbounded WM_GETOBJECT recursion.
 *
 * Some third-party accessibility clients (MSAA hooks) answer a
 * WM_GETOBJECT round trip by issuing another WM_GETOBJECT on the same
 * window, which re-enters Qt's UI Automation provider until the stack
 * overflows. Installed as an application event filter, this object
 * subclasses every native window when its surface is created and refuses
 * accessibility requests once they nest too deeply.
 */
class AccessibilityRecursionGuard : public QObject
{
    Q_OBJECT

public:
    explicit AccessibilityRecursionGuard(QObject* parent = nullptr);
    ~AccessibilityRecursionGuard() override;

protected:
    bool eventFilter(QObject* watched, QEvent* event) override;
};
