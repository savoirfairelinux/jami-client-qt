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
import QtQuick.Controls
import QtQuick.Layouts

import net.jami.Constants 1.1

import "../../commoncomponents"


BaseModalDialog {
    id: root

    titleText: JamiStrings.aboutBotAccountsTitle

    onClosed: {}

    popupContent: ColumnLayout {
        width: 400 - 2 * root.popupMargins

        spacing: 16

        activeFocusOnTab: true

        InfoRow {
            id: typeInfo
            iconSource: JamiResources.jami_logo_icon_24dp_svg
            infoText: JamiStrings.aboutBotAccountsTypeInfo
        }

        InfoRow {
            id: description
            iconSource: JamiResources.robot_2_24dp_svg
            infoText: JamiStrings.aboutBotAccountsDescription
        }

        InfoRow {
            id: profileInfo
            iconSource: JamiResources.id_card_2_24dp_svg
            infoText: JamiStrings.aboutBotAccountsProfileInfo
        }

        Accessible.role: Accessible.StaticText
        Accessible.description: {return     typeInfo.infoText + " " + description.infoText + " " + profileInfo.infoText}
    }

}
