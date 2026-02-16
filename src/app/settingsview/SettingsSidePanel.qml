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
import QtQuick.Effects
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
    objectName: "SettingsSidePanel"

    color: JamiTheme.primaryBackgroundColor
    // Default to -1 (no selection, all menus collapsed).
    // In dual pane mode, SettingsView will sync this to the content index.
    property int currentIndex: -1
    property bool isSinglePane
    signal updated

    function getHeaders() {
        if (AppVersionManager.isUpdaterEnabled()) {
            return [
                        {
                            "title": JamiStrings.accountSettingsMenuTitle,
                            "icon": JamiResources.account_24dp_svg,
                            "first": 0,
                            "last": 4,
                            "children": [
                                {
                                    "id": 0,
                                    "title": JamiStrings.manageAccountSettingsTitle
                                },
                                {
                                    "id": 1,
                                    "title": JamiStrings.customizeProfile
                                },
                                {
                                    "id": 2,
                                    "title": JamiStrings.linkedDevicesSettingsTitle,
                                    "visible": CurrentAccount.type !== Profile.Type.SIP
                                },
                                {
                                    "id": 3,
                                    "title": JamiStrings.callSettingsTitle
                                },
                                {
                                    "id": 4,
                                    "title": JamiStrings.advancedSettingsTitle
                                }
                            ]
                        },
                        {
                            "title": JamiStrings.generalSettingsTitle,
                            "icon": JamiResources.settings_24dp_svg,
                            "first": 5,
                            "last": 11,
                            "children": [
                                {
                                    "id": 5,
                                    "title": JamiStrings.system
                                },
                                {
                                    "id": 6,
                                    "title": JamiStrings.appearance
                                },
                                {
                                    "id": 7,
                                    "title": JamiStrings.chatSettingsTitle
                                },
                                {
                                    "id": 8,
                                    "title": JamiStrings.locationSharingLabel
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
                                    "visible": AppVersionManager.isUpdaterEnabled()
                                }
                            ]
                        },
                        {
                            "title": JamiStrings.mediaSettingsTitle,
                            "icon": JamiResources.media_black_24dp_svg,
                            "first": 12,
                            "last": 14,
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
                        },
                        {
                            "title": JamiStrings.extensionSettingsTitle,
                            "icon": JamiResources.plugins_24dp_svg,
                            "first": 15,
                            "last": 15,
                            "children": [
                                {
                                    "id": 15,
                                    "title": JamiStrings.extensionSettingsTitle
                                }
                            ]
                        }
                    ];
        } else {
            return [
                        {
                            "title": JamiStrings.accountSettingsMenuTitle,
                            "icon": JamiResources.account_24dp_svg,
                            "first": 0,
                            "last": 4,
                            "children": [
                                {
                                    "id": 0,
                                    "title": JamiStrings.manageAccountSettingsTitle
                                },
                                {
                                    "id": 1,
                                    "title": JamiStrings.customizeProfile
                                },
                                {
                                    "id": 2,
                                    "title": JamiStrings.linkedDevicesSettingsTitle,
                                    "visible": CurrentAccount.type !== Profile.Type.SIP
                                },
                                {
                                    "id": 3,
                                    "title": JamiStrings.callSettingsTitle
                                },
                                {
                                    "id": 4,
                                    "title": JamiStrings.advancedSettingsTitle
                                }
                            ]
                        },
                        {
                            "title": JamiStrings.generalSettingsTitle,
                            "icon": JamiResources.settings_24dp_svg,
                            "first": 5,
                            "last": 11,
                            "children": [
                                {
                                    "id": 5,
                                    "title": JamiStrings.system
                                },
                                {
                                    "id": 6,
                                    "title": JamiStrings.appearance
                                },
                                {
                                    "id": 7,
                                    "title": JamiStrings.chatSettingsTitle
                                },
                                {
                                    "id": 8,
                                    "title": JamiStrings.locationSharingLabel
                                },
                                {
                                    "id": 9,
                                    "title": JamiStrings.callRecording
                                },
                                {
                                    "id": 10,
                                    "title": JamiStrings.troubleshootTitle
                                }
                            ]
                        },
                        {
                            "title": JamiStrings.mediaSettingsTitle,
                            "icon": JamiResources.media_black_24dp_svg,
                            "first": 12,
                            "last": 14,
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
                        },
                        {
                            "title": JamiStrings.extensionSettingsTitle,
                            "icon": JamiResources.plugins_24dp_svg,
                            "first": 15,
                            "last": 15,
                            "children": [
                                {
                                    "id": 15,
                                    "title": JamiStrings.extensionSettingsTitle
                                }
                            ]
                        }
                    ];
        }
    }

    function updateModel() {
        if (visible) {
            listView.model = getHeaders();
            root.updated();
        }
    }

    Timer {
        id: timerTranslate

        interval: 100
        repeat: false

        onTriggered: {
            updateModel();
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
            timerTranslate.restart();
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

    ColumnLayout {
        anchors.fill: parent
        // Note that the margins should be identical to that of SidePanel
        // Creates The floating rectangle itself
        anchors.margins: viewCoordinator.isInSinglePaneMode ? JamiTheme.sidePanelIslandsSinglePaneModePadding : JamiTheme.sidePanelIslandsPadding
        anchors.rightMargin: {
            if (viewCoordinator.isInSinglePaneMode) {
                return JamiTheme.sidePanelIslandsSinglePaneModePadding;
            }
            // This manual override for the right margin is necessary,
            // otherwise the shadow appears cut-off.
            return 16;
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Rectangle {
                id: settingsListRect

                anchors.fill: parent

                color: JamiTheme.globalIslandColor
                radius: JamiTheme.avatarBasedRadius
                layer.enabled: true
                layer.effect: MultiEffect {
                    anchors.fill: settingsListRect
                    shadowEnabled: true
                    shadowBlur: JamiTheme.shadowBlur
                    shadowColor: JamiTheme.shadowColor
                    shadowHorizontalOffset: JamiTheme.shadowHorizontalOffset
                    shadowVerticalOffset: JamiTheme.shadowVerticalOffset
                    shadowOpacity: JamiTheme.shadowOpacity
                }
            }

            ColumnLayout {
                id: settingsLayout
                QWKSetParentHitTestVisible {}

                anchors.fill: settingsListRect
                anchors.leftMargin: JamiTheme.sidePanelConversationsIslandHorizontalPadding
                anchors.rightMargin: JamiTheme.sidePanelConversationsIslandHorizontalPadding
                ListView {
                    id: listView
                    objectName: "listView"

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 2
                    clip: true
                    contentHeight: contentItem.childrenRect.height

                    // HACK: remove after migration to Qt 6.7+
                    boundsBehavior: Flickable.StopAtBounds

                    model: getHeaders()
                    delegate: ColumnLayout {
                        id: col
                        width: settingsLayout.width
                        spacing: 0
                        property bool isChildSelected: root.currentIndex >= modelData.first
                                                       && root.currentIndex <= modelData.last

                        PushButton {
                            id: sectionHeader
                            buttonText: modelData.title
                            circled: false
                            radius: width / 2

                            alignement: Text.AlignLeft
                            Layout.fillWidth: true

                            imageContainerWidth: 30
                            height: JamiTheme.settingsMenuHeaderButtonHeight

                            buttonTextFont.pixelSize: JamiTheme.settingsDescriptionPixelSize
                            buttonTextColor: isChildSelected ? JamiTheme.tintedBlue :
                                                               JamiTheme.primaryForegroundColor
                            buttonTextFont.weight: isChildSelected ? Font.Medium : Font.Normal
                            buttonTextEnableElide: true

                            normalColor: JamiTheme.globalIslandColor
                            hoveredColor: JamiTheme.smartListHoveredColor
                            imageColor: JamiTheme.tintedBlue

                            source: modelData.icon

                            onClicked: select(modelData.first)
                            Keys.onPressed: function (keyEvent) {
                                if (keyEvent.key === Qt.Key_Enter || keyEvent.key
                                        === Qt.Key_Return) {
                                    clicked();
                                    keyEvent.accepted = true;
                                }
                            }

                            Behavior on buttonTextColor {
                                ColorAnimation {
                                    duration: JamiTheme.shortFadeDuration
                                }
                            }
                        }

                        ListView {
                            id: childListView
                            Layout.fillWidth: true
                            height: childrenRect.height
                            clip: true
                            visible: isChildSelected
                            spacing: 2

                            // HACK: remove after migration to Qt 6.7+
                            boundsBehavior: Flickable.StopAtBounds

                            model: modelData.children
                            delegate: ColumnLayout {
                                id: childCol
                                width: childListView.width
                                spacing: 0
                                // In single pane mode, don't show child selection until user explicitly navigates
                                property bool isSelected: !root.isSinglePane && root.currentIndex
                                                          === modelData.id
                                PushButton {
                                    visible: modelData.visible !== undefined ? modelData.visible :
                                                                               true
                                    buttonText: modelData.title
                                    circled: false
                                    radius: width / 2

                                    alignement: Text.AlignLeft
                                    Layout.fillWidth: true
                                    preferredLeftMargin: 54

                                    imageContainerWidth: 0
                                    height: JamiTheme.settingsMenuChildrenButtonHeight

                                    buttonTextFont.pixelSize: JamiTheme.settingMenuPixelSize
                                    buttonTextColor: isSelected ? JamiTheme.tintedBlue :
                                                                  JamiTheme.primaryForegroundColor
                                    buttonTextFont.weight: isSelected ? Font.Medium : Font.Normal
                                    buttonTextEnableElide: true

                                    normalColor: isSelected ? JamiTheme.smartListSelectedColor :
                                                              JamiTheme.globalIslandColor
                                    hoveredColor: JamiTheme.smartListHoveredColor

                                    onClicked: open(modelData.id)

                                    Keys.onPressed: function (keyEvent) {
                                        if (keyEvent.key === Qt.Key_Enter || keyEvent.key
                                                === Qt.Key_Return) {
                                            clicked();
                                            keyEvent.accepted = true;
                                        }
                                    }

                                    Behavior on buttonTextColor {
                                        ColorAnimation {
                                            duration: JamiTheme.shortFadeDuration
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        AccountComboBox {
            id: accountComboBox

            Layout.fillWidth: true
            Layout.minimumHeight: accountComboBox.height
            Layout.alignment: Qt.AlignBottom
            Layout.topMargin: 8

            Shortcut {
                sequence: "Ctrl+J"
                context: Qt.ApplicationShortcut
                onActivated: accountComboBox.togglePopup()
            }
        }
    }
}
