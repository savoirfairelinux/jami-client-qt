/*
 * Copyright (C) 2020-2024 Savoir-faire Linux Inc.
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
import QtQuick.Layouts
import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import "../../commoncomponents"

RowLayout {
    id: root

    property alias titleField: title.text
    property alias textField: button.text
    property alias enabled: button.enabled

    property string source
    property int itemWidth

    signal click

    Text {
        id: title

        Layout.fillWidth: true
        Layout.rightMargin: JamiTheme.preferredMarginSize / 2

        font.pointSize: JamiTheme.settingsFontSize
        font.kerning: true
        wrapMode: Text.WordWrap
        horizontalAlignment: Text.AlignLeft
        verticalAlignment: Text.AlignVCenter

        color: JamiTheme.textColor
    }

    MaterialButton {
        id: button

        preferredWidth: root.itemWidth
        buttontextHeightMargin: JamiTheme.buttontextHeightMargin
        textLeftPadding: JamiTheme.buttontextWizzardPadding / 2
        textRightPadding: JamiTheme.buttontextWizzardPadding / 2

        iconSource: root.source
        secondary: true

        onClicked: click()
    }
}
