/*
 * Copyright (C) 2022-2024 Savoir-faire Linux Inc.
 * Author: Fadi Shehadeh <fadi.shehadeh@savoirfairelinux.com>
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
import QtQuick.Layouts
import QtQuick.Controls
import net.jami.Models 1.1
import net.jami.Constants 1.1

Control {
    id: root

    property string icoSource: ""
    property string icoColor: JamiTheme.tintedBlue
    property string title: ""
    property string description: ""

    width: 190
    height: infos.implicitHeight

    contentItem: ColumnLayout {
        id: infos
        anchors.fill: parent

        RowLayout {

            Layout.alignment: Qt.AlignLeft
            spacing: 24

            ResponsiveImage {
                id: icon

                Layout.alignment: Qt.AlignLeft
                Layout.topMargin: 5
                Layout.preferredWidth: 26
                Layout.preferredHeight: 26

                containerHeight: Layout.preferredHeight
                containerWidth: Layout.preferredWidth

                source: icoSource
                color: icoColor
            }

            Label {

                text: title
                font.weight: Font.Medium
                Layout.topMargin: 5
                Layout.alignment: Qt.AlignCenter
                color: JamiTheme.textColor
                font.pixelSize: JamiTheme.infoBoxTitleFontSize
            }
        }

        Text {

            Layout.preferredWidth: root.width - 10
            Layout.alignment: Qt.AlignLeft
            Layout.topMargin: 8
            Layout.bottomMargin: 15
            font.pixelSize: JamiTheme.infoBoxDescFontSize
            color: JamiTheme.textColor
            wrapMode: Text.WordWrap
            text: description
            lineHeight: 1.3
        }
    }
}
