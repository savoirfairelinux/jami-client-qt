/*
 * Copyright (C) 2026 Savoir-faire Linux Inc.
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
import QtQuick.Controls.impl

import net.jami.Constants 1.1

RowLayout {
    property alias iconSource: iconImage.source
    property alias infoText: infoLabel.text

    Layout.fillWidth: true

    spacing: 8

    IconImage {
        id: iconImage
        objectName: "infoRowIcon"

        Layout.alignment: Qt.AlignVCenter

        width: JamiTheme.iconButtonMedium
        height: JamiTheme.iconButtonMedium

        sourceSize.width: JamiTheme.iconButtonMedium
        sourceSize.height: JamiTheme.iconButtonMedium

        color: JamiTheme.textColor
    }

    Text {
        id: infoLabel
        objectName: "infoRowText"

        Layout.fillWidth: true
        Layout.alignment: Qt.AlignVCenter

        verticalAlignment: Text.AlignVCenter
        wrapMode: Text.WordWrap

        font.pixelSize: JamiTheme.infoBoxTitleFontSize

        color: JamiTheme.textColor
    }
}
