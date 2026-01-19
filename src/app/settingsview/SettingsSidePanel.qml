/*
 * Copyright (C) 2024-2026 Savoir-faire Linux Inc.
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
    topPadding: Qt.platform.os.toString() === "osx" ? 20 : undefined
    objectName: "SettingsSidePanel"

    color: JamiTheme.backgroundColor
    // Default to -1 (no selection, all menus collapsed).
    // In dual pane mode, SettingsView will sync this to the content index.
    property int currentIndex: -1
    property bool isSinglePane
    signal updated

    function getHeaders() {
        if (AppVersionManager.isUpdaterEnabled()) {
            return [{
                    "title": JamiStrings.accountSettingsMenuTitle,
                    "icon": JamiResources.account_24dp_svg,
                    "first": 0,
                    "last": 4,
                    "children": [{
                            "id": 0,
                            "title": JamiStrings.manageAccountSettingsTitle
                        }, {
                            "id": 1,
                            "title": JamiStrings.customizeProfile
                        }, {
                            "id": 2,
                            "title": JamiStrings.linkedDevicesSettingsTitle,
                            "visible": CurrentAccount.type !== Profile.Type.SIP
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
                    "first": 5,
                    "last": 11,
                    "children": [{
                            "id": 5,
                            "title": JamiStrings.system
                        }, {
                            "id": 6,
                            "title": JamiStrings.appearance
                        }, {
                            "id": 7,
                            "title": JamiStrings.chatSettingsTitle
                        }, {
                            "id": 8,
                            "title": JamiStrings.locationSharingLabel
                        }, {
                            "id": 9,
                            "title": JamiStrings.callRecording
                        }, {
                            "id": 10,
                            "title": JamiStrings.troubleshootTitle
                        }, {
                            "id": 11,
                            "title": JamiStrings.updatesTitle,
                            "visible": AppVersionManager.isUpdaterEnabled()
                        }]
                }, {
                    "title": JamiStrings.mediaSettingsTitle,
                    "icon": JamiResources.media_black_24dp_svg,
                    "first": 12,
                    "last": 14,
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
                    "title": JamiStrings.extensionSettingsTitle,
                    "icon": JamiResources.plugins_24dp_svg,
                    "first": 15,
                    "last": 15,
                    "children": [{
                            "id": 15,
                            "title": JamiStrings.extensionSettingsTitle
                        }]
                }];
        } else {
            return [{
                    "title": JamiStrings.accountSettingsMenuTitle,
                    "icon": JamiResources.account_24dp_svg,
                    "first": 0,
                    "last": 4,
                    "children": [{
                            "id": 0,
                            "title": JamiStrings.manageAccountSettingsTitle
                        }, {
                            "id": 1,
                            "title": JamiStrings.customizeProfile
                        }, {
                            "id": 2,
                            "title": JamiStrings.linkedDevicesSettingsTitle,
                            "visible": CurrentAccount.type !== Profile.Type.SIP
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
                    "first": 5,
                    "last": 11,
                    "children": [{
                            "id": 5,
                            "title": JamiStrings.system
                        }, {
                            "id": 6,
                            "title": JamiStrings.appearance
                        }, {
                            "id": 7,
                            "title": JamiStrings.chatSettingsTitle
                        }, {
                            "id": 8,
                            "title": JamiStrings.locationSharingLabel
                        }, {
                            "id": 9,
                            "title": JamiStrings.callRecording
                        }, {
                            "id": 10,
                            "title": JamiStrings.troubleshootTitle
                        }]
                }, {
                    "title": JamiStrings.mediaSettingsTitle,
                    "icon": JamiResources.media_black_24dp_svg,
                    "first": 12,
                    "last": 14,
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
                    "title": JamiStrings.extensionSettingsTitle,
                    "icon": JamiResources.plugins_24dp_svg,
                    "first": 15,
                    "last": 15,
                    "children": [{
                            "id": 15,
                            "title": JamiStrings.extensionSettingsTitle
                        }]
                }];
        }
    }

    function updateModel() {
        if (visible) {
            listView.model = getHeaders();
            root.updated()
        }
    }

    Timer {
        id: timerTranslate

        interval: 100
        repeat: false

        onTriggered: {
            updateModel()
        }
    }

    Connections {
        target: CurrentAccount

        function onTypeChanged() {
            updateModel();
            select(-1);
        }
    }

    Connections {
        target: UtilsAdapter

        function onChangeLanguage() {
            // For some reason, under Qt 6.5.3, even if locale is changed before
            // model is not computer correctly.
            // Delaying the update works
            timerTranslate.restart()
        }
    }

    // Bind to requests for a settings page to be selected via shorcut.
    Connections {
        target: JamiQmlUtils
        function onSettingsPageRequested(index) {
            viewCoordinator.present("SettingsView");
            root.indexSelected(index);
            root.currentIndex = index;
        }
    }

    onIsSinglePaneChanged: {
        if (visible && !isSinglePane)
            select(root.currentIndex);
    }

    function open(index) {
        indexSelected(index);
        root.currentIndex = index;
    }

    function deselect() {
        indexSelected(-1);
        root.currentIndex = -1;
    }

    function select(index) {
        if (!root.isSinglePane)
            indexSelected(index);
        root.currentIndex = index;
    }

    Page {
        id: page

        anchors.fill: parent

        background: null

        header: AccountComboBox { QWKSetParentHitTestVisible {}
            id: accountComboBox
        }

        ListView {
            id: listView
            objectName: "listView"

            width: page.width
            height: page.height
            clip: true
            contentHeight: contentItem.childrenRect.height

            // HACK: remove after migration to Qt 6.7+
            boundsBehavior: Flickable.StopAtBounds

            model: getHeaders()
            delegate: ColumnLayout {
                id: col
                width: page.width
                spacing: 0
                property bool isChildSelected: root.currentIndex >= modelData.first && root.currentIndex <= modelData.last

                PushButton {
                    id: sectionHeader
                    buttonText: modelData.title
                    circled: false
                    radius: 0

                    alignement: Text.AlignLeft
                    Layout.fillWidth: true
                    Layout.leftMargin: 0
                    preferredLeftMargin: 25

                    imageContainerWidth: 30
                    height: JamiTheme.settingsMenuHeaderButtonHeight

                    buttonTextFont.pixelSize: JamiTheme.settingsDescriptionPixelSize
                    buttonTextColor: isChildSelected ? JamiTheme.tintedBlue : JamiTheme.primaryForegroundColor
                    buttonTextFont.weight: isChildSelected ? Font.Medium : Font.Normal
                    buttonTextEnableElide: true

                    normalColor: JamiTheme.backgroundColor
                    hoveredColor: JamiTheme.smartListHoveredColor
                    imageColor: JamiTheme.tintedBlue

                    source: modelData.icon

                    onClicked: select(modelData.first)
                    Keys.onPressed: function (keyEvent) {
                        if (keyEvent.key === Qt.Key_Enter || keyEvent.key === Qt.Key_Return) {
                            clicked();
                            keyEvent.accepted = true;
                        }
                    }
                }

                ListView {
                    id: childListView
                    Layout.fillWidth: true
                    height: childrenRect.height
                    clip: true
                    visible: isChildSelected

                    // HACK: remove after migration to Qt 6.7+
                    boundsBehavior: Flickable.StopAtBounds

                    model: modelData.children
                    delegate: ColumnLayout {
                        id: childCol
                        width: childListView.width
                        spacing: 0
                        // In single pane mode, don't show child selection until user explicitly navigates
                        property bool isSelected: !root.isSinglePane && root.currentIndex === modelData.id
                        PushButton {
                            visible: modelData.visible !== undefined ? modelData.visible : true
                            buttonText: modelData.title
                            circled: false
                            radius: 0

                            alignement: Text.AlignLeft
                            Layout.fillWidth: true
                            preferredLeftMargin: 74

                            imageContainerWidth: 0
                            height: JamiTheme.settingsMenuChildrenButtonHeight

                            buttonTextFont.pixelSize: JamiTheme.settingMenuPixelSize
                            buttonTextColor: isSelected ? JamiTheme.tintedBlue : JamiTheme.primaryForegroundColor
                            buttonTextFont.weight: isSelected ? Font.Medium : Font.Normal
                            buttonTextEnableElide: true

                            normalColor: isSelected ? JamiTheme.smartListSelectedColor : JamiTheme.backgroundColor
                            hoveredColor: JamiTheme.smartListHoveredColor

                            onClicked: open(modelData.id)

                            Keys.onPressed: function (keyEvent) {
                                if (keyEvent.key === Qt.Key_Enter || keyEvent.key === Qt.Key_Return) {
                                    clicked();
                                    keyEvent.accepted = true;
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
