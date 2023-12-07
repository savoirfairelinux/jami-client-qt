/*
 * Copyright (C) 2020-2023 Savoir-faire Linux Inc.
 * Author: Capucine Berthet <capucine.berthet@savoirfairelinux.com>
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
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import QtQuick.Layouts
import "../../commoncomponents"

BaseModalDialog {
    id: root

    title: JamiStrings.goodToKnow
    signal accepted

    onClosed: accepted()

    popupContent: Column {
        spacing: 5
        width: 400 - 2 * root.popupMargins

        InfoBox {
            id: info

            width: root.width - 2 * root.popupMargins
            icoSource: JamiResources.laptop_black_24dp_svg
            title: JamiStrings.local
            description: JamiStrings.localAccount
            icoColor: JamiTheme.wizardIconColor
        }

        InfoBox {
            width: root.width - 2 * root.popupMargins
            icoSource: JamiResources.assignment_ind_black_24dp_svg
            title: JamiStrings.username
            description: JamiStrings.usernameRecommened
            icoColor: JamiTheme.wizardIconColor
        }

        InfoBox {
            width: root.width - 2 * root.popupMargins
            icoSource: JamiResources.lock_svg
            title: JamiStrings.encrypt
            description: JamiStrings.passwordOptional
            icoColor: JamiTheme.wizardIconColor
        }

        InfoBox {
            width: root.width - 2 * root.popupMargins
            icoSource: JamiResources.brush_black_24dp_svg
            title: JamiStrings.customize
            description: JamiStrings.customizeOptional
            icoColor: JamiTheme.wizardIconColor
        }
    }
}

