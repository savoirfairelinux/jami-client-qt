/*
 * Copyright (C) 2020-2024 Savoir-faire Linux Inc.
 * Author: Mingrui Zhang <mingrui.zhang@savoirfairelinux.com>
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
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import net.jami.Helpers 1.1
import QtQuick 2.15

Control {
    id: root


    property real scaleFactor: 1.0
    readonly property real dimension: 250
    readonly property real maxScaleFactor: 1.5
    readonly property real minScaleFactor: 0.5

    width: dimension * scaleFactor
    height: dimension * scaleFactor

    required property string imagePath

    background: Rectangle {
        color: "white"
    }
    padding: 6

    contentItem: Image {
        id: contentLoader
        source: root.imagePath
        fillMode: Image.PreserveAspectFit
        smooth: false
    }
}
