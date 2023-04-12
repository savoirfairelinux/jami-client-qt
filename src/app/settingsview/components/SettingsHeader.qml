/*
 * Copyright (C) 2020-2023 Savoir-faire Linux Inc.
 * Author: Aline Gondim Santos <aline.gondimsantos@savoirfairelinux.com>
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

    spacing: 10

    signal backArrowClicked

    BackButton {
        id: backToSettingsMenuButton
        Layout.preferredHeight: JamiTheme.preferredFieldHeight
        Layout.preferredWidth: JamiTheme.preferredFieldHeight
        visible: viewNode.isSinglePane

        onClicked: backArrowClicked()
    }
    Label {
        Layout.fillWidth: true
        Layout.leftMargin: backToSettingsMenuButton.visible ? 0 : JamiTheme.preferredSettingsMarginSize
        color: JamiTheme.textColor
        font.kerning: true
        font.pixelSize: JamiTheme.settingsHeaderPixelSize
        horizontalAlignment: Text.AlignLeft
        text: root.title
        verticalAlignment: Text.AlignVCenter
    }
}
