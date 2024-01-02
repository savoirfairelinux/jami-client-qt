/*
 * Copyright (C) 2020-2024 Savoir-faire Linux Inc.
 * Author: Mingrui Zhang <mingrui.zhang@savoirfairelinux.com>
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

    backgroundColor: JamiTheme.darkTheme ? JamiTheme.blackColor : JamiTheme.whiteColor

    popupContent:  Rectangle{
        anchors.centerIn: parent
        width: userQrImage.width + 10
        height: userQrImage.height + 10
        color: JamiTheme.whiteColor
        radius: 5

        Image {
            id: userQrImage
            property int size: JamiTheme.qrCodeImageSize
            width: size
            height: size
            anchors.centerIn: parent
            smooth: false
            fillMode: Image.PreserveAspectFit
            source: "image://qrImage/account_" + CurrentAccount.id
        }
    }
}

