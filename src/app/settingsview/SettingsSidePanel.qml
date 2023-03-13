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

    color: JamiTheme.backgroundColor
    property int currentIndex

    Page {
        id: page

        anchors.fill: parent

        background: null

        header: AccountComboBox {}

        // Bind to requests for a settings page to be selected via shorcut.
        Connections {
            target: JamiQmlUtils
            function onSettingsPageRequested(index) {
                viewCoordinator.present("SettingsView")

                buttonGroup.checkedButton = buttonGroup.buttons[index]
            }
        }



        Flickable {
            id: flick
            width: root.width
            height: childrenRect.height
            clip: true
            contentHeight: col.implicitHeight

            function getHeaders() {
                return [
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
                            "title": JamiStrings.linkedDevicesSettingsTitle,
                            "visible": CurrentAccount.type !== Profile.Type.SIP
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
                            "title": JamiStrings.updatesTitle,
                            "visible": Qt.platform.os.toString() === "windows" 
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
}
            Column {
                id: col
                anchors.left: parent.left
                Component.onCompleted: clv.createObject(this, {"base":flick.getHeaders()});
        Connections {
            target: CurrentAccount
            function onIdChanged() {
                console.warn("onIdChanged")
                root.currentIndex = 0
                indexSelected(0)
                clv.repeater.base = flick.getHeaders()
            }
        }

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
                        id: clvButtons
                        spacing: 0
                        Layout.fillWidth: true

                        PushButton {

                            property var sprite: null
                            property var isChildren: {
                                var ob = base[modelData]
                                var c = ob["children"]
                                return c === undefined
                            }

                            visible: {
                                var ob = base[modelData]
                                var c = ob["visible"]
                                if (c === undefined)
                                        return true
                                return c
                            }

                            property bool isOpen: !isChildren && sprite != null
                            property bool isChildOpen: isChildren && (base[modelData]["id"] === root.currentIndex)

                            alignement: Text.AlignLeft
                            Layout.preferredWidth: root.width
                            Layout.leftMargin: isChildren ? 40 : 0
                            preferredMargin: isChildren ? 35 : 25

                            imageContainerWidth: !isChildren ? 30 : 0
                            height: isChildren ? JamiTheme.settingsMenuChildrenButtonHeight : JamiTheme.settingsMenuHeaderButtonHeight

                            circled: false
                            radius: 0

                            buttonText: {
                                return base[modelData]["title"]
                            }

                            buttonTextFont.pixelSize: !isChildren ? JamiTheme.settingsDescriptionPixelSize : JamiTheme.settingMenuPixelSize
                            buttonTextColor: isOpen || isChildOpen ? JamiTheme.tintedBlue : JamiTheme.primaryForegroundColor
                            buttonTextFont.weight: isOpen || isChildOpen ? Font.Medium : Font.Normal

                            normalColor: isOpen ? JamiTheme.smartListSelectedColor : "transparent"
                            hoveredColor: JamiTheme.smartListHoveredColor
                            imageColor: !isChildren ? JamiTheme.tintedBlue : null

                            source: {

                                if (!isChildren)
                                    return base[modelData]["icon"]
                                else return ""
                            }



                            onClicked: {
                                var ob = base[modelData]
                                if(sprite === null) {
                                    //deselect the current selection and collapse menu
                                    if (repeater.selected)
                                        repeater.selected.destroy()

                                    var c = ob["children"]
                                    if (c !== undefined) {
                                        sprite = clv.createObject(parent, {"base" : c});
                                        repeater.selected = sprite
                                        indexSelected(c[0]["id"])
                                        root.currentIndex = c[0]["id"]
                                    } else {
                                        indexSelected(ob["id"])
                                        root.currentIndex = ob["id"]
                                    }
                                }

                            }

                            Keys.onPressed: function (keyEvent) {
                                if (keyEvent.key === Qt.Key_Enter ||
                                        keyEvent.key === Qt.Key_Return) {
                                    clicked()
                                    keyEvent.accepted = true
                                }
                            }
                        }
                    }
                }
            }
        }

    }
}
