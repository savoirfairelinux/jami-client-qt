/*
 * Copyright (C) 2021-2023 Savoir-faire Linux Inc.
 * Author: Andreas Traczyk <andreas.traczyk@savoirfairelinux.com>
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
import QtQuick

Item {
    id: root
    enum Type {
        None,
        Top,
        Left,
        Bottom,
        Right
    }

    property alias color: rect.color
    property int radius: 0
    property int type: HalfPill.None

    clip: true

    Rectangle {
        id: rect
        property bool bp: type === HalfPill.None
        property bool direction: type === HalfPill.Right || type === HalfPill.Bottom
        property bool horizontal: type === HalfPill.Left || type === HalfPill.Right

        anchors.bottomMargin: !horizontal * !direction * -radius * !bp
        anchors.fill: root
        anchors.leftMargin: horizontal * direction * -radius * !bp
        anchors.rightMargin: horizontal * !direction * -radius * !bp
        anchors.topMargin: !horizontal * direction * -radius * !bp
        height: root.size + radius * !bp
        radius: root.radius
        width: root.size + radius * !bp
    }
}
