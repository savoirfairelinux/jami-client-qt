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
import QtQuick.Window
import QtTest

import "../../../src/app/commoncomponents"

TestCase {
    name: "JamiScrollBar"

    Window {
        id: framelessWindow
        flags: Qt.Window | Qt.FramelessWindowHint

        JamiScrollBar {
            id: scrollBar
        }
    }

    function test_linuxResizeBorderPadding() {
        compare(scrollBar.rightPadding, Qt.platform.os === "linux" ? 10 : 2)
    }
}
