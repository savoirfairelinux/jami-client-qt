/*
 * Copyright (C) 2020-2025 Savoir-faire Linux Inc.
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
import QtQuick.Controls
import QtQuick.Layouts
import net.jami.Models 1.1
import net.jami.Constants 1.1
import "../../commoncomponents"

RowLayout {
    id: root

    required property string title
    signal backArrowClicked
    spacing: 10

    BackButton {
        id: backToSettingsMenuButton

        Layout.preferredWidth: JamiTheme.preferredFieldHeight
        Layout.preferredHeight: JamiTheme.preferredFieldHeight

        visible: viewNode.isSinglePane

        onClicked: backArrowClicked()
    }

    Label {
        Layout.fillWidth: true
        text: root.title
        font.pixelSize: JamiTheme.settingsHeaderPixelSize
        font.kerning: true
        color: JamiTheme.textColor
        Layout.leftMargin: backToSettingsMenuButton.visible ? 0 : JamiTheme.preferredSettingsMarginSize

        horizontalAlignment: Text.AlignLeft
        verticalAlignment: Text.AlignVCenter
    }
}
