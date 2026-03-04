/*
 * Copyright (C) 2020-2026 Savoir-faire Linux Inc.
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

import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import "../../commoncomponents"

BaseModalDialog {
    id: root

    titleText: JamiStrings.shareAccount

    contentItem: Control {
        padding: 8
        contentItem: Image {
            id: userQrImage

            property int size: JamiTheme.qrCodeImageSize

            width: size
            height: size

            smooth: false
            fillMode: Image.PreserveAspectFit

            sourceSize.width: size
            sourceSize.height: size
            source: "image://qrImage/account_" + CurrentAccount.id
        }

        background: Rectangle {
            color: JamiTheme.whiteColor
            radius: 4
        }
    }

}


