/*
 * Copyright (C) 2023 Savoir-faire Linux Inc.
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

    property var select: function(index) {
        buttonGroup.checkedButton = buttonGroup.buttons[index]
    }
    property var deselect: function() { buttonGroup.checkedButton = null }

    color: JamiTheme.backgroundColor

    Page {
        id: page

        anchors.fill: parent

        background: Rectangle {
            color: JamiTheme.backgroundColor
        }

        header: AccountComboBox {}

        // Bind to requests for a settings page to be selected via shorcut.
        Connections {
            target: JamiQmlUtils
            function onSettingsPageRequested(index) {
                viewCoordinator.present("SettingsView")
                buttonGroup.checkedButton = buttonGroup.buttons[index]
            }
        }

        ButtonGroup {
            id: buttonGroup
            buttons: settingsButtons.children

            onCheckedButtonChanged: {
                for (var i = 0; i < buttons.length; i++)
                    if (buttons[i] === checkedButton) {
                        indexSelected(i)
                        return
                    }
                indexSelected(-1)
            }
        }

        Column {
            id: settingsButtons

            spacing: 0
            anchors.left: parent.left
            anchors.right: parent.right
            height: childrenRect.height

            component SMB: PushButton {
                normalColor: root.color

                preferredHeight: 64
                preferredMargin: 24

                anchors.left: parent.left
                anchors.right: parent.right

                buttonTextFont.pointSize: JamiTheme.textFontSize + 2
                textHAlign: Text.AlignLeft

                imageColor: JamiTheme.textColor
                imageContainerHeight: 40
                imageContainerWidth: 40

                pressedColor: Qt.lighter(JamiTheme.pressedButtonColor, 1.25)
                checkedColor: JamiTheme.smartListSelectedColor
                hoveredColor: JamiTheme.smartListHoveredColor

                duration: 0
                checkable: true
                radius: 0
            }

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
