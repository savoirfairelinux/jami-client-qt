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
import QtQuick.Layouts
import QtQuick.Controls
import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import "../../commoncomponents"

ColumnLayout {
    id: root

    property int itemWidth

    ElidedTextLabel {
        Layout.fillWidth: true
        Layout.preferredHeight: JamiTheme.preferredFieldHeight

        eText: JamiStrings.voiceMail
        fontSize: JamiTheme.headerFontSize
        maxWidth: width
    }

    SettingsMaterialTextEdit {
        id: lineEditVoiceMailDialCode

        Layout.fillWidth: true
        Layout.leftMargin: JamiTheme.preferredMarginSize
        Layout.preferredHeight: JamiTheme.preferredFieldHeight

        itemWidth: root.itemWidth
        titleField: JamiStrings.voiceMailDialCode

        staticText: CurrentAccount.mailbox

        onEditFinished: CurrentAccount.mailbox = dynamicText
    }
}
