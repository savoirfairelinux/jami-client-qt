/*
 * Copyright (C) 2020 by Savoir-faire Linux
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

import QtQuick 2.14
import QtQuick.Controls 2.14
import QtQuick.Window 2.14

Image {
    id: root

    // FromUrl here is for grabToImage image url
    enum Mode {
        FromAccount = 0,
        FromFile,
        FromContactUri,
        FromConvUid,
        FromUrl,
        Default
    }

    property int mode: AvatarImage.Mode.FromAccount
    property string imageProviderIdPrefix: {
        switch(mode) {
        case AvatarImage.Mode.FromAccount:
            return "account_"
        case AvatarImage.Mode.FromFile:
            return "file_"
        case AvatarImage.Mode.FromContactUri:
            return "contact_"
        case AvatarImage.Mode.FromConvUid:
            return "conversation_"
        default:
            return ""
        }
    }
    property string imageProviderUrl: "image://avatarImage/" + imageProviderIdPrefix
    property string imageId: ""
    property string defaultImgUrl: "qrc:/images/default_avatar_overlay.svg"

    function updateImage(updatedId) {
        source = ""
        imageId = updatedId
        if (mode === AvatarImage.Mode.FromUrl)
            source = imageId
        else if (imageId)
            source = imageProviderUrl + imageId

        // return the updatedId
        return imageId
    }

    cache: false
    smooth: false
    antialiasing: true

    sourceSize.width: Math.max(24, width)
    sourceSize.height: Math.max(24, height)

    fillMode: Image.PreserveAspectFit

    onModeChanged: {
        if (mode === AvatarImage.Mode.Default)
            source = defaultImgUrl
    }

    Component.onCompleted: {
        if (imageId)
            return source = imageProviderUrl + imageId
        return source = ""
    }
}
