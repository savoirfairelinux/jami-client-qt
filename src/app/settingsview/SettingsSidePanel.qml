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
import QtQml.Models
import Qt.labs.qmlmodels
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
    readonly property real sidePanelIslandsMargin: viewCoordinator && viewCoordinator.isInSinglePaneMode ? JamiTheme.sidePanelIslandsSinglePaneModePadding : JamiTheme.sidePanelIslandsPadding
    signal updated

    function settingAliases(index) {
        switch (index) {
        case 0: return "accounts identity username password export";
        case 1: return "profile avatar display name";
        case 2: return "devices link pairing";
        case 3: return "calls ringtone forwarding voicemail";
        case 4: return "privacy security encryption network proxy dht";
        case 5: return "permissions access bots";
        case 6: return "services integrations";
        case 7: return "general notifications startup language spellcheck api";
        case 8: return "theme colors font zoom";
        case 9: return "messages messaging links typing";
        case 10: return "map position";
        case 11: return "recording calls";
        case 12: return "logs diagnostics connectivity";
        case 13: return "update version";
        case 14: return "microphone speaker sound media";
        case 15: return "camera media";
        case 16: return "display monitor media";
        case 17: return "plugins extensions";
        default: return "";
        }
    }

    function matchesSearch(title, searchText) {
        const query = settingsSearch.textContent.trim().toLocaleLowerCase();
        if (!query)
            return true;
        const haystack = (title + " " + searchText).toLocaleLowerCase();
        return query.split(/\s+/).every(function(token) {
            return haystack.includes(token);
        });
    }

    function getHeaders() {
        if (AppVersionManager.isUpdaterEnabled()) {
            return [
                        {
                            "title": JamiStrings.accountSettingsMenuTitle,
                            "icon": JamiResources.account_24dp_svg,
                            "first": 0,
                            "last": 6,
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
                                },
                                {
                                    "id": 5,
                                    "title": JamiStrings.appAccessSettingsTitle
                                },
                                {
                                    "id": 6,
                                    "title": JamiStrings.sharedServicesSettingsTitle,
                                    "visible": CurrentAccount.type !== Profile.Type.SIP
                                }
                            ]
                        },
                        {
                            "title": JamiStrings.generalSettingsTitle,
                            "icon": JamiResources.settings_24dp_svg,
                            "first": 7,
                            "last": 13,
                            "children": [
                                {
                                    "id": 7,
                                    "title": JamiStrings.system
                                },
                                {
                                    "id": 8,
                                    "title": JamiStrings.appearance
                                },
                                {
                                    "id": 9,
                                    "title": JamiStrings.chatSettingsTitle
                                },
                                {
                                    "id": 10,
                                    "title": JamiStrings.locationSharingLabel
                                },
                                {
                                    "id": 11,
                                    "title": JamiStrings.callRecording
                                },
                                {
                                    "id": 12,
                                    "title": JamiStrings.troubleshootTitle
                                },
                                {
                                    "id": 13,
                                    "title": JamiStrings.updatesTitle,
                                    "visible": AppVersionManager.isUpdaterEnabled()
                                }
                            ]
                        },
                        {
                            "title": JamiStrings.mediaSettingsTitle,
                            "icon": JamiResources.media_black_24dp_svg,
                            "first": 14,
                            "last": 16,
                            "children": [
                                {
                                    "id": 14,
                                    "title": JamiStrings.audio
                                },
                                {
                                    "id": 15,
                                    "title": JamiStrings.video
                                },
                                {
                                    "id": 16,
                                    "title": JamiStrings.screenSharing
                                }
                            ]
                        },
                        {
                            "title": JamiStrings.extensionSettingsTitle,
                            "icon": JamiResources.plugins_24dp_svg,
                            "first": 17,
                            "last": 17,
                            "children": [
                                {
                                    "id": 17,
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
                            "last": 6,
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
                                },
                                {
                                    "id": 5,
                                    "title": JamiStrings.appAccessSettingsTitle
                                },
                                {
                                    "id": 6,
                                    "title": JamiStrings.sharedServicesSettingsTitle,
                                    "visible": CurrentAccount.type !== Profile.Type.SIP
                                }
                            ]
                        },
                        {
                            "title": JamiStrings.generalSettingsTitle,
                            "icon": JamiResources.settings_24dp_svg,
                            "first": 7,
                            "last": 12,
                            "children": [
                                {
                                    "id": 7,
                                    "title": JamiStrings.system
                                },
                                {
                                    "id": 8,
                                    "title": JamiStrings.appearance
                                },
                                {
                                    "id": 9,
                                    "title": JamiStrings.chatSettingsTitle
                                },
                                {
                                    "id": 10,
                                    "title": JamiStrings.locationSharingLabel
                                },
                                {
                                    "id": 11,
                                    "title": JamiStrings.callRecording
                                },
                                {
                                    "id": 12,
                                    "title": JamiStrings.troubleshootTitle
                                }
                            ]
                        },
                        {
                            "title": JamiStrings.mediaSettingsTitle,
                            "icon": JamiResources.media_black_24dp_svg,
                            "first": 14,
                            "last": 16,
                            "children": [
                                {
                                    "id": 14,
                                    "title": JamiStrings.audio
                                },
                                {
                                    "id": 15,
                                    "title": JamiStrings.video
                                },
                                {
                                    "id": 16,
                                    "title": JamiStrings.screenSharing
                                }
                            ]
                        },
                        {
                            "title": JamiStrings.extensionSettingsTitle,
                            "icon": JamiResources.plugins_24dp_svg,
                            "first": 17,
                            "last": 17,
                            "children": [
                                {
                                    "id": 17,
                                    "title": JamiStrings.extensionSettingsTitle
                                }
                            ]
                        }
                    ];
        }
    }

    function updateModel() {
        if (visible) {
            settingsModel.rows = getHeaders().map(function(header) {
                return {
                    title: String(header.title),
                    icon: String(header.icon),
                    pageIndex: -1,
                    firstIndex: header.first,
                    searchText: String(header.title),
                    rows: header.children.filter(function(child) {
                        return child.visible !== false;
                    }).map(function(child) {
                        return {
                            title: String(child.title),
                            icon: "",
                            pageIndex: child.id,
                            firstIndex: child.id,
                            searchText: settingAliases(child.id)
                        };
                    })
                };
            });
            Qt.callLater(syncSelection);
            root.updated();
        }
    }

    function modelPageIndex(index) {
        return settingsTree.model.data(index, Qt.EditRole);
    }

    function syncSelection() {
        if (root.currentIndex < 0) {
            settingsSelection.clearCurrentIndex();
            return;
        }
        const headers = getHeaders();
        for (let group = 0; group < headers.length; ++group) {
            const children = headers[group].children.filter(function(child) {
                return child.visible !== false;
            });
            for (let child = 0; child < children.length; ++child) {
                if (children[child].id !== root.currentIndex)
                    continue;
                const index = settingsModel.index([group, child], 0);
                const proxyIndex = settingsFilter.mapFromSource(index);
                if (!proxyIndex.valid) {
                    settingsSearch.textContent = "";
                    settingsFilter.invalidate();
                    Qt.callLater(syncSelection);
                    return;
                }
                settingsTree.expandToIndex(proxyIndex);
                settingsSelection.setCurrentIndex(proxyIndex,
                                                  ItemSelectionModel.ClearAndSelect);
                settingsTree.positionViewAtIndex(proxyIndex, Qt.AlignVCenter);
                return;
            }
        }
        settingsSelection.clearCurrentIndex();
    }

    function activateRow(row) {
        const index = settingsTree.index(row, 0);
        const pageIndex = modelPageIndex(index);
        if (pageIndex < 0) {
            settingsTree.toggleExpanded(row);
            return;
        }
        open(pageIndex);
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

    onCurrentIndexChanged: syncSelection()

    ColumnLayout {
        anchors.fill: parent
        // Note that the margins should be identical to that of SidePanel
        // Creates The floating rectangle itself
        anchors.margins: root.sidePanelIslandsMargin
        anchors.topMargin: JamiQmlUtils.isMacOS26OrLater ? JamiTheme.sidePanelIslandPaddingMac : root.sidePanelIslandsMargin
        anchors.leftMargin: JamiQmlUtils.isMacOS26OrLater ? JamiTheme.sidePanelIslandPaddingMac : root.sidePanelIslandsMargin
        anchors.rightMargin: {
            if (viewCoordinator && viewCoordinator.isInSinglePaneMode) {
                return JamiTheme.sidePanelIslandsSinglePaneModePadding;
            }
            // This manual override for the right margin is necessary,
            // otherwise the shadow appears cut-off.
            return JamiTheme.sidePanelIslandRightPadding;
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Rectangle {
                id: settingsListRect

                anchors.fill: parent

                color: JamiTheme.globalIslandColor
                radius: JamiTheme.avatarBasedRadius
                topLeftRadius: JamiQmlUtils.isMacOS26OrLater ? JamiTheme.macOSTopRadius : JamiTheme.avatarBasedRadius
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
                anchors.topMargin: JamiQmlUtils.isMacOS26OrLater ? JamiTheme.sidePanelTopPaddingMac : 0
                TreeModel {
                    id: settingsModel

                    TableModelColumn {
                        display: "title"
                        decoration: "icon"
                        edit: "pageIndex"
                        statusTip: "firstIndex"
                        whatsThis: "searchText"
                    }
                }

                SortFilterProxyModel {
                    id: settingsFilter

                    model: settingsModel
                    autoAcceptChildRows: true
                    recursiveFiltering: true

                    filters: FunctionFilter {
                        component RoleData: QtObject {
                            property string display
                            property string whatsThis
                        }

                        function filter(data: RoleData): bool {
                            return root.matchesSearch(data.display, data.whatsThis);
                        }
                    }
                }

                Searchbar {
                    id: settingsSearch
                    objectName: "settingsSearchBar"

                    Layout.fillWidth: true
                    Layout.preferredHeight: JamiTheme.searchBarPreferredHeight
                    Layout.topMargin: 8
                    placeHolderText: JamiStrings.search

                    onSearchBarTextChanged: function(text) {
                        settingsFilter.invalidate();
                        Qt.callLater(function() {
                            if (text.length)
                                settingsTree.expandRecursively();
                            else
                                root.syncSelection();
                        });
                    }
                }

                TreeView {
                    id: settingsTree
                    objectName: "settingsTree"

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    model: settingsFilter
                    selectionBehavior: TableView.SelectRows
                    selectionMode: TableView.SingleSelection

                    Accessible.role: Accessible.Tree
                    Accessible.name: JamiStrings.settings

                    selectionModel: ItemSelectionModel {
                        id: settingsSelection
                        model: settingsFilter
                    }

                    delegate: TreeViewDelegate {
                        id: settingsDelegate
                        objectName: "settingsItem-" + row

                        width: settingsTree.width
                        implicitHeight: hasChildren
                                        ? JamiTheme.settingsMenuHeaderButtonHeight
                                        : JamiTheme.settingsMenuChildrenButtonHeight
                        text: model.display
                        icon.source: model.decoration
                        highlighted: current
                        hoverEnabled: true

                        Accessible.role: Accessible.TreeItem
                        Accessible.name: model.display
                        Accessible.focusable: true
                        Accessible.focused: current
                        Accessible.selected: current

                        onClicked: {
                            settingsSelection.setCurrentIndex(
                                        settingsTree.index(row, 0),
                                        ItemSelectionModel.ClearAndSelect);
                            root.activateRow(row);
                        }
                        Keys.onReturnPressed: root.activateRow(row)
                        Keys.onEnterPressed: root.activateRow(row)
                    }

                    ScrollBar.vertical: ScrollBar {}
                }
            }
        }
        AccountComboBox {
            id: accountComboBox

            appContext: root.appContext

            Layout.fillWidth: true
            Layout.minimumHeight: accountComboBox.height
            Layout.alignment: Qt.AlignBottom
            Layout.topMargin: 8
            Layout.leftMargin: 0

            Shortcut {
                sequence: "Ctrl+J"
                context: Qt.ApplicationShortcut
                onActivated: accountComboBox.togglePopup()
            }
        }
    }
}
