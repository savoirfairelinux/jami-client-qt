/*
 * Copyright (C) 2022-2023 Savoir-faire Linux Inc.
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
import net.jami.Enums 1.1
import net.jami.Models 1.1
import "../../commoncomponents"
import "../js/keyboardshortcuttablecreation.js" as KeyboardShortcutTableCreation

Item {
    id: welcomeLogo

    property bool hasCustomLogo: viewNode.hasCustomLogo
    property string logoUrl: viewNode.customLogoUrl

    property bool alwaysVisible: false
    visible: (root.width > root.thresholdSize) || alwaysVisible

    height: getHeight()
    width: getWidth()

    function getWidth() {
        return 250;
    }

    function getHeight() {
        return 200;
    }

    Behavior on width  {
        NumberAnimation {
            duration: JamiTheme.shortFadeDuration
        }
    }

    Behavior on height  {
        NumberAnimation {
            duration: JamiTheme.shortFadeDuration
        }
    }

    CachedImage {
        id: cachedImgLogo
        objectName: "cachedImgLogo"
        downloadUrl: logoUrl
        defaultImage: JamiResources.logo_jami_standard_coul_svg
        visible: welcomeLogo.visible
        anchors.fill: parent
        opacity: visible ? 1 : 0
        customLogo: hasCustomLogo
        localPath: UtilsAdapter.getCachePath() + "/" + CurrentAccount.id + "/welcomeview/" + UtilsAdapter.base64Encode(downloadUrl) + fileExtension

        imageFillMode: Image.PreserveAspectFit

        Behavior on opacity  {
            NumberAnimation {
                duration: JamiTheme.shortFadeDuration
            }
        }
    }
}
