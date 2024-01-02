/*
 * Copyright (C) 2022-2024 Savoir-faire Linux Inc.
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
    id: column
    width: parent.width

    property real maxHeight: 250

    property var iconSize: 26
    property var margin: 5
    property var prefWidth: 170

    property color textColor: JamiTheme.textColor
    property color iconColor: JamiTheme.tintedBlue

    RowLayout {
        id: rowlayout
        Layout.preferredHeight: opened ? 0 : childrenRect.height
        Layout.leftMargin: 15
        Layout.alignment: Qt.AlignLeft

        ResponsiveImage {
            id: icon

            visible: !opened

            Layout.alignment: Qt.AlignLeft
            Layout.topMargin: column.margin
            Layout.preferredWidth: column.iconSize
            Layout.preferredHeight: column.iconSize

            containerHeight: Layout.preferredHeight
            containerWidth: Layout.preferredWidth

            source: JamiResources.glasses_tips_svg
            color: column.iconColor
        }

        Label {
            text: JamiStrings.tip
            color: column.textColor
            font.weight: Font.Medium
            Layout.topMargin: column.margin
            visible: !opened
            Layout.alignment: Qt.AlignLeft
            Layout.leftMargin: 8
            Layout.preferredWidth: column.prefWidth - 2 * column.margin - column.iconSize
            font.pixelSize: JamiTheme.tipBoxTitleFontSize
            horizontalAlignment: Text.AlignLeft
            elide: Qt.ElideRight
        }
    }

    Text {
        id: title
        Layout.preferredHeight: contentHeight
        Layout.preferredWidth: opened ? 140 : 150
        Layout.leftMargin: 20
        Layout.topMargin: opened ? 0 : 8
        Layout.bottomMargin: 8
        font.pixelSize: JamiTheme.tipBoxContentFontSize
        wrapMode: Text.WordWrap
        font.weight: opened ? Font.Medium : Font.Normal
        text: root.title
        horizontalAlignment: Text.AlignLeft
        color: column.textColor
    }

    JamiFlickable {
        Layout.preferredWidth: root.width - 32
        Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
        property real maxDescriptionHeight: maxHeight - rowlayout.Layout.preferredHeight - title.Layout.preferredHeight - 2 * JamiTheme.preferredMarginSize
        Layout.preferredHeight: opened ? Math.min(contentHeight, maxDescriptionHeight) : 0
        contentHeight: description.height
        Text {
            id: description
            width: parent.width
            font.pixelSize: JamiTheme.tipBoxContentFontSize
            visible: opened
            wrapMode: Text.WordWrap
            text: root.description
            horizontalAlignment: Text.AlignLeft
            color: column.textColor
        }
    }
}
