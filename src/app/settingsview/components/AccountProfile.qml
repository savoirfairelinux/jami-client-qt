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
import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import "../../commoncomponents"

ColumnLayout {
    id: root

    spacing: 8

    Text {
        Layout.fillWidth: true
        Layout.preferredHeight: JamiTheme.preferredFieldHeight

        text: JamiStrings.profile
        elide: Text.ElideRight

        font.pointSize: JamiTheme.headerFontSize
        font.kerning: true
        color: JamiTheme.textColor

        horizontalAlignment: Text.AlignLeft
        verticalAlignment: Text.AlignVCenter
    }

    PhotoboothView {
        id: currentAccountAvatar
        width: avatarSize
        height: avatarSize

        Layout.alignment: Qt.AlignCenter

        imageId: LRCInstance.currentAccountId
        avatarSize: 180
    }

    ModalTextEdit {
        id: displayNameLineEdit

        Layout.alignment: Qt.AlignCenter
        Layout.preferredHeight: JamiTheme.preferredFieldHeight + 8
        Layout.preferredWidth: JamiTheme.preferredFieldWidth

        staticText: CurrentAccount.alias
        placeholderText: JamiStrings.enterNickname

        onAccepted: AccountAdapter.setCurrAccDisplayName(dynamicText)
    }
}
