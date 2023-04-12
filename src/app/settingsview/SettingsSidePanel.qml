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
import net.jami.Helpers 1.1
import "../mainview/components"
import "../commoncomponents"
import "components"

SidePanelBase {
    id: root
    property int currentIndex

    color: JamiTheme.backgroundColor
    objectName: "SettingsSidePanel"

    function createChild() {
        if (page.menu === undefined) {
            return;
        }
        page.menu.createChild();
    }

    Page {
        id: page
        property var menu: undefined

        anchors.fill: parent
        background: null

        // Bind to requests for a settings page to be selected via shorcut.
        Connections {
            target: JamiQmlUtils

            function onSettingsPageRequested(index) {
                viewCoordinator.present("SettingsView");
                buttonGroup.checkedButton = buttonGroup.buttons[index];
            }
        }
        Flickable {
            id: flick
            clip: true
            contentHeight: col.implicitHeight
            height: childrenRect.height
            width: root.width

            function getHeaders() {
                return [{
                        "title": JamiStrings.accountSettingsMenuTitle,
                        "icon": JamiResources.account_24dp_svg,
                        "children": [{
                                "id": 0,
                                "title": JamiStrings.manageAccountSettingsTitle
                            }, {
                                "id": 1,
                                "title": JamiStrings.customizeProfile
                            }, {
                                "id": 2,
                                "title": JamiStrings.linkedDevicesSettingsTitle,
                                "visible": "isJamiAccount"
                            }, {
                                "id": 3,
                                "title": JamiStrings.callSettingsTitle
                            }, {
                                "id": 4,
                                "title": JamiStrings.advancedSettingsTitle
                            }]
                    }, {
                        "title": JamiStrings.generalSettingsTitle,
                        "icon": JamiResources.gear_black_24dp_svg,
                        "children": [{
                                "id": 5,
                                "title": JamiStrings.system
                            }, {
                                "id": 6,
                                "title": JamiStrings.appearence
                            }, {
                                "id": 7,
                                "title": JamiStrings.locationSharingLabel
                            }, {
                                "id": 8,
                                "title": JamiStrings.fileTransfer
                            }, {
                                "id": 9,
                                "title": JamiStrings.callRecording
                            }, {
                                "id": 10,
                                "title": JamiStrings.troubleshootTitle
                            }, {
                                "id": 11,
                                "title": JamiStrings.updatesTitle,
                                "visible": "isUpdatable"
                            }]
                    }, {
                        "title": JamiStrings.audioVideoSettingsTitle,
                        "icon": JamiResources.media_black_24dp_svg,
                        "children": [{
                                "id": 12,
                                "title": JamiStrings.audio
                            }, {
                                "id": 13,
                                "title": JamiStrings.video
                            }, {
                                "id": 14,
                                "title": JamiStrings.screenSharing
                            }]
                    }, {
                        "title": JamiStrings.pluginSettingsTitle,
                        "icon": JamiResources.plugins_24dp_svg,
                        "children": [{
                                "id": 15,
                                "title": JamiStrings.pluginSettingsTitle
                            }]
                    }];
            }

            Column {
                id: col
                anchors.left: parent.left

                Component.onCompleted: {
                    page.menu = clv.createObject(this, {
                            "base": flick.getHeaders()
                        });
                }
            }
            Component {
                id: clv
                Repeater {
                    id: repeater
                    property var base: ({})
                    property var selected: null

                    Layout.fillWidth: true
                    model: Object.keys(base)

                    function createChild() {
                        itemAt(0).children[0].createChild();
                        root.currentIndex = 0;
                    }

                    ColumnLayout {
                        id: clvButtons
                        Layout.fillWidth: true
                        spacing: 0

                        PushButton {
                            id: btn
                            property bool isChildOpen: isChildren && (base[modelData]["id"] === root.currentIndex)
                            property var isChildren: {
                                var ob = base[modelData];
                                var c = ob["children"];
                                return c === undefined;
                            }
                            property bool isOpen: !isChildren && sprite != null
                            property var sprite: null

                            Layout.leftMargin: isChildren ? 28 : 0
                            Layout.preferredWidth: root.width - (isChildren ? 28 : 0)
                            alignement: Text.AlignLeft
                            buttonText: {
                                return base[modelData]["title"];
                            }
                            buttonTextColor: isOpen || isChildOpen ? JamiTheme.tintedBlue : JamiTheme.primaryForegroundColor
                            buttonTextEnableElide: true
                            buttonTextFont.pixelSize: !isChildren ? JamiTheme.settingsDescriptionPixelSize : JamiTheme.settingMenuPixelSize
                            buttonTextFont.weight: isOpen || isChildOpen ? Font.Medium : Font.Normal
                            circled: false
                            height: isChildren ? JamiTheme.settingsMenuChildrenButtonHeight : JamiTheme.settingsMenuHeaderButtonHeight
                            hoveredColor: JamiTheme.smartListHoveredColor
                            imageColor: !isChildren ? JamiTheme.tintedBlue : null
                            imageContainerWidth: !isChildren ? 30 : 0
                            normalColor: isOpen ? JamiTheme.smartListSelectedColor : "transparent"
                            preferredLeftMargin: isChildren ? 47 : 25
                            radius: 0
                            source: {
                                if (!isChildren)
                                    return base[modelData]["icon"];
                                else
                                    return "";
                            }
                            visible: updateVisibility()

                            function createChild() {
                                var ob = base[modelData];
                                if (sprite === null) {
                                    //deselect the current selection and collapse menu
                                    if (repeater.selected)
                                        repeater.selected.destroy();
                                    var c = ob["children"];
                                    if (c !== undefined) {
                                        sprite = clv.createObject(parent, {
                                                "base": c
                                            });
                                        repeater.selected = sprite;
                                        indexSelected(c[0]["id"]);
                                        root.currentIndex = c[0]["id"];
                                    } else {
                                        indexSelected(ob["id"]);
                                        root.currentIndex = ob["id"];
                                    }
                                }
                            }
                            function updateVisibility() {
                                var currentVisibility = visible;
                                var ob = base[modelData];
                                var c = ob["visible"];
                                if (c === undefined)
                                    return true;
                                var res = false;
                                if (c === "isUpdatable") {
                                    res = UpdateManager.isUpdaterEnabled();
                                } else if (c === "isJamiAccount") {
                                    res = CurrentAccount.type !== Profile.Type.SIP;
                                } else {
                                    console.warn("Visibility condition not managed");
                                }
                                if (currentVisibility !== res && root.currentIndex === ob["id"]) {
                                    // If a menu disappears, go to the first index
                                    root.currentIndex = 0;
                                    root.indexSelected(0);
                                }
                                return res;
                            }

                            Keys.onPressed: function (keyEvent) {
                                if (keyEvent.key === Qt.Key_Enter || keyEvent.key === Qt.Key_Return) {
                                    clicked();
                                    keyEvent.accepted = true;
                                }
                            }
                            onClicked: createChild()
                        }
                    }
                }
            }
        }

        header: AccountComboBox {
        }
    }
}
