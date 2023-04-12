/*
 * Copyright (C) 2022-2023 Savoir-faire Linux Inc.
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

Rectangle {
    id: root
    property string description: ""
    property string icoColor: JamiTheme.tintedBlue
    property string icoSource: ""
    property string title: ""

    color: JamiTheme.transparentColor
    height: infos.implicitHeight
    width: 190

    ColumnLayout {
        id: infos
        anchors.fill: parent

        RowLayout {
            Layout.alignment: Qt.AlignLeft
            spacing: 24

            ResponsiveImage {
                id: icon
                Layout.alignment: Qt.AlignLeft
                Layout.preferredHeight: 26
                Layout.preferredWidth: 26
                Layout.topMargin: 5
                color: icoColor
                containerHeight: Layout.preferredHeight
                containerWidth: Layout.preferredWidth
                source: icoSource
            }
            Label {
                Layout.alignment: Qt.AlignCenter
                Layout.topMargin: 5
                color: JamiTheme.textColor
                font.pixelSize: JamiTheme.infoBoxTitleFontSize
                font.weight: Font.Medium
                text: title
            }
        }
        Text {
            Layout.alignment: Qt.AlignLeft
            Layout.bottomMargin: 15
            Layout.preferredWidth: 180
            Layout.topMargin: 8
            color: JamiTheme.textColor
            font.pixelSize: JamiTheme.infoBoxDescFontSize
            text: description
            wrapMode: Text.WordWrap
        }
    }
}
