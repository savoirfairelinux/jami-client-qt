/*
 * Copyright (C) 2023 Savoir-faire Linux Inc.
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

Rectangle {
    id: viewNode

    // True if this view is managed by the view coordinator.
    // False if this view is managed by its parent view, and will
    // only be destroyed when its parent is destroyed.
    property bool managed: true

    // True if this view functions in a single-pane context only.
    property bool singlePaneOnly: false

    // True if this view requires and initial selection from
    // a group of menu options when in single-pane mode (e.g. settings).
    property bool requiresIndex: false

    function dismiss() { viewCoordinator.dismiss(objectName) }

    signal presented
    signal dismissed

    Component.onCompleted: { if (managed) presented(); print("+", this) }
    Component.onDestruction: { if (managed) dismissed(); print("-", this) }
}
