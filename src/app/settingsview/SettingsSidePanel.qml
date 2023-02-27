/*
 * Copyright (C) 2020-2023 Savoir-faire Linux Inc.
 * Author: Mingrui Zhang <mingrui.zhang@savoirfairelinux.com>
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
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import net.jami.Enums 1.1
import net.jami.Models 1.1

import "../mainview/components"
import "../commoncomponents"
import "components"

SidePanelBase {
    id: root
    objectName: "SettingsSidePanel"

    color: JamiTheme.backgroundColor

    Page {
        id: page

        anchors.fill: parent

        background: Rectangle {
            color: JamiTheme.backgroundColor
        }

        header: AccountComboBox {
            width: parent.width
            height: JamiTheme.accountListItemHeight
            onSettingBtnClicked: {
                !viewCoordinator.inSettings ?
                            viewCoordinator.present("SettingsView") :
                            viewCoordinator.dismiss("SettingsView")}
        }

        Rectangle {
            id: settingsMenu
            objectName: "settingsMenu"

            anchors.fill: parent

            // Bind to requests for a settings page to be selected via shorcut.
            Connections {
                target: JamiQmlUtils
                function onSettingsPageRequested(index) {
                    buttonGroup.checkedButton = buttonGroup.buttons[index]
                }
            }

            ButtonGroup {
                id: buttonGroup
                buttons: settingsButtons.children

                // When the selection changes, we present the SettingsView at
                // the selected index.
                onCheckedButtonChanged: {
                    for (var i = 0; i < buttons.length; i++)
                        if (buttons[i] === checkedButton) {
                            viewCoordinator.getView("SettingsView").selectedMenu = i
                        }
                }
            }

            Column {
                id: settingsButtons

                spacing: 0
                anchors.left: parent.left
                anchors.right: parent.right
                height: childrenRect.height

                component SMB: SettingsMenuButton { normalColor: root.color }

                SMB {
                    buttonText: JamiStrings.accountSettingsMenuTitle
                    source: JamiResources.account_24dp_svg
                }

                SMB {
                    buttonText: JamiStrings.generalSettingsTitle
                    source: JamiResources.gear_black_24dp_svg
                }

                SMB {
                    buttonText: JamiStrings.avSettingsMenuTitle
                    source: JamiResources.media_black_24dp_svg
                }

                SMB {
                    buttonText: JamiStrings.pluginSettingsTitle
                    source: JamiResources.plugin_settings_black_24dp_svg
                }
            }
        }
    }
}
