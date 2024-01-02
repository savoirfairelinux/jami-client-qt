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
import QtQuick.Controls
import QtQuick.Layouts
import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import "../../commoncomponents"

Item {
    id: root
    focus: true
    width: parent.width
    height: backupLayout.height

    property real iconSize: 26
    property real margin: 5
    property real preferredWidth: 170

    property real maxHeight: 250

    property color textColor: JamiTheme.textColor
    property color iconColor: JamiTheme.tintedBlue

    ColumnLayout {
        id: backupLayout

        anchors.top: parent.top
        width: parent.width

        RowLayout {
            id: rowlayout

            Layout.leftMargin: 15
            Layout.alignment: Qt.AlignLeft

            ResponsiveImage {
                id: icon

                visible: !opened

                Layout.alignment: Qt.AlignLeft
                Layout.topMargin: root.margin
                Layout.preferredWidth: root.iconSize
                Layout.preferredHeight: root.iconSize

                containerHeight: Layout.preferredHeight
                containerWidth: Layout.preferredWidth

                color: JamiTheme.tintedBlue

                source: JamiResources.favorite_black_24dp_svg
            }

            Text {
                id: title
                text: JamiStrings.donation
                color: root.textColor
                font.weight: Font.Medium
                Layout.topMargin: root.margin
                Layout.alignment: Qt.AlignLeft
                Layout.leftMargin: root.margin
                Layout.preferredWidth: root.preferredWidth - 2 * root.margin - root.iconSize
                font.pixelSize: JamiTheme.tipBoxTitleFontSize
                horizontalAlignment: Text.AlignLeft
                elide: Qt.ElideRight
            }
        }

        Text {
            id: content
            Layout.preferredWidth: root.preferredWidth
            focus: true
            Layout.leftMargin: 20
            Layout.topMargin: 8
            Layout.bottomMargin: 8
            font.pixelSize: JamiTheme.tipBoxContentFontSize
            visible: true
            wrapMode: Text.WordWrap
            font.weight: Font.Normal
            text: JamiStrings.donationTipBoxText
            color: root.textColor
            horizontalAlignment: Text.AlignLeft
            linkColor: JamiTheme.buttonTintedBlue
            onLinkActivated: {
                Qt.openUrlExternally(JamiTheme.donationUrl);
            }
        }
    }
}
