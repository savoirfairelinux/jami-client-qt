/*
 * Copyright (C) 2020-2023 Savoir-faire Linux Inc.
 * Author: Mingrui Zhang <mingrui.zhang@savoirfairelinux.com>
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

// Inspired by
// https://stackoverflow.com/questions/16534489/qml-control-border-width-and-color-on-any-one-side-of-rectangle-element
Rectangle {
    property int bBorderwidth: 1
    property string borderColor: "white"
    property bool commonBorder: true
    property int commonBorderWidth: 1
    property int lBorderwidth: 1
    property int rBorderwidth: 1
    property int tBorderwidth: 1

    color: borderColor
    z: -1

    anchors {
        bottom: parent.bottom
        bottomMargin: commonBorder ? -commonBorderWidth : -bBorderwidth
        left: parent.left
        leftMargin: commonBorder ? -commonBorderWidth : -lBorderwidth
        right: parent.right
        rightMargin: commonBorder ? -commonBorderWidth : -rBorderwidth
        top: parent.top
        topMargin: commonBorder ? -commonBorderWidth : -tBorderwidth
    }
}
