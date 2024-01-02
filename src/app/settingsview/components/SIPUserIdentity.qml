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

ColumnLayout {
    id: root

    property int itemWidth

    SettingsMaterialTextEdit {
        id: usernameSIP

        Layout.fillWidth: true

        staticText: CurrentAccount.username

        titleField: JamiStrings.username
        itemWidth: root.itemWidth

        onEditFinished: CurrentAccount.username = dynamicText
    }

    SettingsMaterialTextEdit {
        id: hostnameSIP

        Layout.fillWidth: true

        staticText: CurrentAccount.hostname

        titleField: JamiStrings.server
        itemWidth: root.itemWidth

        onEditFinished: CurrentAccount.hostname = dynamicText
    }

    SettingsMaterialTextEdit {
        id: passSIPlineEdit

        Layout.fillWidth: true

        staticText: CurrentAccount.password

        titleField: JamiStrings.password
        itemWidth: root.itemWidth
        isPassword: true

        onEditFinished: CurrentAccount.password = dynamicText
    }

    SettingsMaterialTextEdit {
        id: proxySIP

        Layout.fillWidth: true

        staticText: CurrentAccount.routeset

        titleField: JamiStrings.proxy
        itemWidth: root.itemWidth

        onEditFinished: CurrentAccount.routeset = dynamicText
    }
}
