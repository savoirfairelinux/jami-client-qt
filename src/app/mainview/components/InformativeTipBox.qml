/*
 * Copyright (C) 2022-2023 Savoir-faire Linux Inc.
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

import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1

import "../../commoncomponents"


ColumnLayout {

    width: parent.width


    RowLayout {

        Layout.leftMargin: 15
        Layout.alignment: Qt.AlignLeft

        ResponsiveImage {
            id: icon

            visible: !opened

            Layout.alignment: Qt.AlignLeft
            Layout.topMargin: 5
            Layout.preferredWidth: 26
            Layout.preferredHeight: 26

            containerHeight: Layout.preferredHeight
            containerWidth: Layout.preferredWidth

            source: JamiResources.glasses_tips_svg
            color: JamiTheme.buttonTintedBlue
        }

        Label {
            text: JamiStrings.tip
            color: JamiTheme.textColor
            font.weight: Font.Medium
            Layout.topMargin: 5
            visible: !opened
            Layout.alignment: Qt.AlignLeft
            Layout.leftMargin: 8
            font.pixelSize: JamiTheme.tipBoxTitleFontSize
        }
    }

    Text {

        Layout.preferredWidth: opened ? 140 : 150
        Layout.leftMargin: 20
        Layout.topMargin: opened ? 0 : 8
        Layout.bottomMargin: 15
        font.pixelSize: JamiTheme.tipBoxContentFontSize
        wrapMode: Text.WordWrap
        font.weight: opened ?  Font.Medium : Font.Normal
        text: root.title
        color: JamiTheme.textColor
    }

    Text {
        Layout.preferredWidth: root.width - 32
        Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
        font.pixelSize: JamiTheme.tipBoxContentFontSize
        visible: opened
        wrapMode: Text.WordWrap
        text: root.description
        color: JamiTheme.textColor
    }
}
