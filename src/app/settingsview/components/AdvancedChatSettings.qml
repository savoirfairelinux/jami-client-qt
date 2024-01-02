/*
 * Copyright (C) 2020-2024 Savoir-faire Linux Inc.
 * Author: Franck Laurent <franck.laurent@savoirfairelinux.com>
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

ColumnLayout {
    id: root

    property int itemWidth
    spacing: JamiTheme.settingsCategorySpacing

    Text {

        Layout.alignment: Qt.AlignLeft
        Layout.preferredWidth: parent.width
        text: JamiStrings.chatSettingsTitle
        color: JamiTheme.textColor
        horizontalAlignment: Text.AlignLeft
        verticalAlignment: Text.AlignVCenter
        wrapMode: Text.WordWrap

        font.pixelSize: JamiTheme.settingsTitlePixelSize
        font.kerning: true
    }

    ToggleSwitch {
        id: checkBoxSendDisplayed

        tooltipText: JamiStrings.enableReadReceiptsTooltip
        labelText: JamiStrings.enableReadReceipts
        descText: JamiStrings.enableReadReceiptsTooltip

        checked: CurrentAccount.sendReadReceipt

        onSwitchToggled: CurrentAccount.sendReadReceipt = checked
    }
}
