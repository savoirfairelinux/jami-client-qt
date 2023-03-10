/*
 * Copyright (C) 2020-2023 Savoir-faire Linux Inc.
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
import QtQuick.Layouts

import "../../commoncomponents"
import "../../settingsview"

Rectangle {
    id: root

    color: JamiTheme.backgroundColor

    // The following bindings provide the settings menu selection persistence behavior.
    property bool singlePane: viewCoordinator.singlePane
    /////onSinglePaneChanged: {
    /////    if (!viewCoordinator.singlePane && viewCoordinator.inSettings) {
    /////        const idx = viewCoordinator.currentView.selectedMenu
    /////        buttonGroup.checkedButton = buttonGroup.buttons[idx]
    /////    }
    /////}
    /////onVisibleChanged: buttonGroup.checkedButton = visible && !viewCoordinator.singlePane ?
    /////                      buttonGroup.buttons[0] :
    /////                      null


    function selectMenu(i) {
        // TODO: change this (rebase on andreas patch)
        if (viewCoordinator.singlePane) {
            viewCoordinator.present("SettingsView").selectedMenu = i
        } else if (!viewCoordinator.busy) {
            var settingsView = viewCoordinator.getView("SettingsView")
            settingsView.selectedMenu = i
        }
    }

    Flickable {
        id: flick
        width: root.width
        height: childrenRect.height
        clip: true
        contentHeight: col.implicitHeight
        property var headers: [
            {
                "title": "Account", // TODO jamistrings + traduction
                "icon": JamiResources.account_24dp_svg,
                "children": [
                    {
                        "id": 0,
                        "title": "Manage account"
                    },
                    {
                        "id": 1,
                        "title": "Customize profile"
                    },
                    {
                        "id": 2,
                        "title": "Linked devices"
                    },
                    {
                        "id": 3,
                        "title": "Advanced settings"
                    }
                ]
            },
            {
                "title": "General", // TODO jamistrings + traduction
                "icon": JamiResources.account_24dp_svg,
                "children": [
                    {
                        "id": 4,
                        "title": "System"
                    },
                    {
                        "id": 5,
                        "title": "Call settings"
                    },
                    {
                        "id": 6,
                        "title": "Appearence"
                    },
                    {
                        "id": 7,
                        "title": "Location sharing"
                    },
                    {
                        "id": 8,
                        "title": "File transfer"
                    },
                    {
                        "id": 9,
                        "title": "Call recording"
                    },
                    {
                        "id": 10,
                        "title": "Troubleshoot"
                    },
                    {
                        "id": 11,
                        "title": "Updates"
                    }
                ]
            },{
                "title": "Audio and Video", // TODO jamistrings + traduction
                "icon": JamiResources.account_24dp_svg,
                "children": [
                    {
                        "id": 12,
                        "title": "Audio"
                    },
                    {
                        "id": 12,
                        "title": "Video"
                    },
                    {
                        "id": 14,
                        "title": "Screen sharing"
                    }
                ]
            },{
                "title": "Plugins", // TODO jamistrings + traduction
                "icon": JamiResources.account_24dp_svg,
                "children": [
                    {
                        "id": 15,
                        "title": "Plugins"
                    }
                ]
            }
        ]

        Column {
            id: col
            anchors.left: parent.left
            anchors.right: parent.right

            Component.onCompleted: clv.createObject(this, {"objmodel":flick.headers});
        }

        Component {
            id: clv
            Repeater {
                id: repeater
                property var base: ({})
                property var selected: null
                model: Object.keys(base)
                Layout.fillWidth: true

                ColumnLayout {
                    spacing: 0
                    Layout.fillWidth: true

                    Button {
                        property var sprite: null
                        text: {
                            return base[modelData]["title"]
                        }

                        height: 64
                        Layout.fillWidth: true

                        onClicked: {
                            var ob = base[modelData]
                            if(sprite === null) {
                                if (repeater.selected)
                                    repeater.selected.destroy()
                                var c = ob["children"]
                                if (c !== undefined) {
                                    sprite = clv.createObject(parent, {"base" : c});
                                    repeater.selected = sprite
                                    root.selectMenu(c[0]["id"])
                                } else {
                                    root.selectMenu(ob["id"])
                                }
                            }

                        }
                    }
                }
            }
        }
    }

    // Bind to requests for a settings page to be selected via shorcut.
    /*Connections {
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
                    if (viewCoordinator.singlePane) {
                        viewCoordinator.present("SettingsView").selectedMenu = i
                    } else if (!viewCoordinator.busy) {
                        var settingsView = viewCoordinator.getView("SettingsView")
                        settingsView.selectedMenu = i
                    }
                }
        }
    }

    ColumnLayout {
        id: settingsButtons

        spacing: 0
        anchors.left: parent.left
        anchors.right: parent.right
        height: childrenRect.height




        component SMB: SettingsMenuButton {
            normalColor: root.color
            Layout.fillWidth: true
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


        SMB {
            buttonText: JamiStrings.manageAccountSettingsTitle
        }


        SMB {
            buttonText: JamiStrings.customizeProfileSettingsTitle
        }

        SMB {
            buttonText: JamiStrings.linkedDevicesSettingsTitle
        }
        SMB {
            buttonText: JamiStrings.advancedSettingsTitle
        }
        SMB {
            buttonText: JamiStrings.callSettingsTitle
        }
        SMB {
            buttonText: JamiStrings.chatSettingsTitle
        }


    }*/
}

