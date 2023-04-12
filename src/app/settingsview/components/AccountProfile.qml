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
        color: JamiTheme.textColor
        elide: Text.ElideRight
        font.kerning: true
        font.pointSize: JamiTheme.headerFontSize
        horizontalAlignment: Text.AlignLeft
        text: JamiStrings.profile
        verticalAlignment: Text.AlignVCenter
    }
    PhotoboothView {
        id: currentAccountAvatar
        Layout.alignment: Qt.AlignCenter
        avatarSize: 180
        height: avatarSize
        imageId: LRCInstance.currentAccountId
        width: avatarSize
    }
    ModalTextEdit {
        id: displayNameLineEdit
        Layout.alignment: Qt.AlignCenter
        Layout.preferredHeight: JamiTheme.preferredFieldHeight + 8
        Layout.preferredWidth: JamiTheme.preferredFieldWidth
        placeholderText: JamiStrings.enterNickname
        staticText: CurrentAccount.alias

        onAccepted: AccountAdapter.setCurrAccDisplayName(dynamicText)
    }
}
