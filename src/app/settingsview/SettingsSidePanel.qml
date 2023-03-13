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

    //    property var select: function(index) {
    //        buttonGroup.checkedButton = buttonGroup.buttons[index]
    //    }
    //    property var deselect: function() { buttonGroup.checkedButton = null }

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

        //        ButtonGroup {
        //            id: buttonGroup
        //            buttons: settingsButtons.children

        //            onCheckedButtonChanged: {
        //                for (var i = 0; i < buttons.length; i++)
        //                    if (buttons[i] === checkedButton) {
        //                        indexSelected(i)
        //                        return
        //                    }
        //                indexSelected(-1)
        //            }
        //        }


        Flickable {
            id: flick
            width: root.width
            height: childrenRect.height
            clip: true
            contentHeight: col.implicitHeight
            property var headers: [
                {
                    "title": JamiStrings.accountSettingsMenuTitle,
                    "icon": JamiResources.account_24dp_svg,
                    "children": [
                        {
                            "id": 0,
                            "title": JamiStrings.manageAccountSettingsTitle
                        },
                        {
                            "id": 1,
                            "title": JamiStrings.customizeProfileSettingsTitle
                        },
                        {
                            "id": 2,
                            "title": JamiStrings.linkedDevicesSettingsTitle
                        },
                        {
                            "id": 3,
                            "title": JamiStrings.advancedSettingsTitle
                        }
                    ]
                },
                {
                    "title": JamiStrings.generalSettingsTitle,
                    "icon": JamiResources.gear_black_24dp_svg,
                    "children": [
                        {
                            "id": 4,
                            "title": JamiStrings.system
                        },
                        {
                            "id": 5,
                            "title": JamiStrings.callSettingsTitle
                        },
                        {
                            "id": 6,
                            "title": JamiStrings.appearence
                        },
                        {
                            "id": 7,
                            "title": JamiStrings.locationSharingLabel
                        },
                        {
                            "id": 8,
                            "title": JamiStrings.fileTransfer
                        },
                        {
                            "id": 9,
                            "title": JamiStrings.callRecording
                        },
                        {
                            "id": 10,
                            "title": JamiStrings.troubleshootTitle
                        },
                        {
                            "id": 11,
                            "title": JamiStrings.updatesTitle
                        }
                    ]
                },{
                    "title": JamiStrings.audioVideoSettingsTitle,
                    "icon": JamiResources.media_black_24dp_svg,
                    "children": [
                        {
                            "id": 12,
                            "title": JamiStrings.audio
                        },
                        {
                            "id": 13,
                            "title": JamiStrings.video
                        },
                        {
                            "id": 14,
                            "title": JamiStrings.screenSharing
                        }
                    ]
                },{
                    "title": JamiStrings.pluginSettingsTitle,
                    "icon": JamiResources.plugins_24dp_svg,
                    "children": [
                        {
                            "id": 15,
                            "title": JamiStrings.pluginSettingsTitle
                        }
                    ]
                }
            ]

            Column {
                id: col
                anchors.left: parent.left
                anchors.right: parent.right
                Component.onCompleted: clv.createObject(this, {"base":flick.headers});
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
                        PushButton {

                            property var sprite: null
                            property var isChildren: {

                                var ob = base[modelData]
                                var c = ob["children"]
                                return c === undefined
                            }


                            alignement: Text.AlignLeft
                            circled: false
                            radius: 0

                            Layout.fillWidth: true
                            buttonText: {
                                return base[modelData]["title"]
                            }
                            hoveredColor: "transparent"
                            preferredWidth: root.width
                            source: {

                                if (!isChildren)
                                    return base[modelData]["icon"]
                                else return ""
                            }

                            Layout.leftMargin: isChildren ? 40 : 0
                            height: 64

                            onClicked: {
                                var ob = base[modelData]
                                if(sprite === null) {
                                    if (repeater.selected)
                                        repeater.selected.destroy()
                                    var c = ob["children"]
                                    if (c !== undefined) {
                                        sprite = clv.createObject(parent, {"base" : c});
                                        repeater.selected = sprite
                                        indexSelected(c[0]["id"])
                                    } else {
                                        indexSelected(ob["id"])
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

    }
}
