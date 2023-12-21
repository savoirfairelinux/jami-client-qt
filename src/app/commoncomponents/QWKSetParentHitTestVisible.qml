/*
 * Copyright (C) 2024 Savoir-faire Linux Inc.
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

Item {
    // Wait for it's parent to be created, then set it to be hit test visible.
    // This avoids having to edit Component.onCompleted of the parent.
    // Note: this is experimental. TBD if this is a good way to do this.
    // This technique makes it clear and simple to implement, but may have
    // side effects beyond just adding a dummy item component.
    // Best alternatives:
    // - Wrap the parent in a custom component that is hit test visible.
    // - Edit the parent's Component.onCompleted to set it to be hit test visible.
    Component.onCompleted: Qt.callLater(function() {
        if (appWindow.useFrameLess)
            windowAgent.setHitTestVisible(parent, true);
    });
}
