/*
 * Copyright (C) 2020-2022 Savoir-faire Linux Inc.
 * Author: Andreas Traczyk <andreas.traczyk@savoirfairelinux.com>
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
import QtQuick.Controls

import net.jami.Models 1.1
import net.jami.Constants 1.1

// TODO: these includes should generally be resource uris
import "../../commoncomponents"
import "../../settingsview"

Rectangle {
    id: root

    signal itemSelected(int index)
    signal buttonSelectedManually(int index)

    color: JamiTheme.backgroundColor

    ButtonGroup {
        id: buttonGroup

        buttons: buttons.children
        onCheckedButtonChanged: itemSelected(checkedButton.menuType)
    }

    Column {
        id: buttons

        spacing: 0
        anchors.left: parent.left
        anchors.right: parent.right
        height: childrenRect.height

        SettingsMenuButton {
            id: accountPushButton
            property int menuType: SettingsView.Account
            Connections {
                target: root

                function onButtonSelectedManually(index) {
                    if (accountPushButton.menuType === index)
                        buttonGroup.checkedButton = accountPushButton
                }
            }
            checked: true
            buttonText: JamiStrings.accountSettingsMenuTitle
            source: JamiResources.account_24dp_svg
            normalColor: root.color
        }

        SettingsMenuButton {
            id: generalPushButton
            property int menuType: SettingsView.General
            Connections {
                target: root

                function onButtonSelectedManually(index) {
                    if (generalPushButton.menuType === index)
                        buttonGroup.checkedButton = generalPushButton
                }
            }
            buttonText: JamiStrings.generalSettingsTitle
            source: JamiResources.gear_black_24dp_svg
            normalColor: root.color
        }

        SettingsMenuButton {
            id: mediaPushButton
            property int menuType: SettingsView.Media
            Connections {
                target: root

                function onButtonSelectedManually(index) {
                    if (mediaPushButton.menuType === index)
                        buttonGroup.checkedButton = mediaPushButton
                }
            }
            buttonText: JamiStrings.avSettingsMenuTitle
            source: JamiResources.media_black_24dp_svg
            normalColor: root.color
        }

        SettingsMenuButton {
            id: pluginPushButton
            property int menuType: SettingsView.Plugin
            Connections {
                target: root

                function onButtonSelectedManually(index) {
                    if (pluginPushButton.menuType === index)
                        buttonGroup.checkedButton = pluginPushButton
                }
            }
            buttonText: JamiStrings.pluginSettingsTitle
            source: JamiResources.plugin_settings_black_24dp_svg
            normalColor: root.color
        }
    }
}

