/*
 * Copyright (C) 2025 Savoir-faire Linux Inc.
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
import Qt5Compat.GraphicalEffects
import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1

import "../mainview/components"

import SortFilterProxyModel 0.2

// Search bar for filtering dictionaries
ColumnLayout {
    id: root
    spacing: 0

    height: 300

    Searchbar {
        id: dictionarySearchBar
        Layout.fillWidth: true
        Layout.preferredHeight: 35

        placeHolderText: JamiStrings.searchAvailableTextLanguages

        // Override the default background
        color: "transparent"

        // Enhanced visual feedback
        property bool hasFocus: activeFocus

        // Smooth scale animation on focus
        scale: hasFocus ? 1.02 : 1.0
        Behavior on scale {
            NumberAnimation {
                duration: 200
                easing.type: Easing.OutCubic
            }
        }

        // Subtle glow effect when focused
        layer.enabled: hasFocus
        layer.effect: DropShadow {
            horizontalOffset: 0
            verticalOffset: 0
            radius: 12
            samples: 24
            color: Qt.rgba(JamiTheme.buttonTintedBlue.r,
                            JamiTheme.buttonTintedBlue.g,
                            JamiTheme.buttonTintedBlue.b, 0.3)
            transparentBorder: true
        }

        onSearchBarTextChanged: function(text) {
            dictionaryProxyModel.filterPattern = text
        }
    }

    JamiListView {
        id: spellCheckDictionaryListView

        Layout.fillWidth: true
        Layout.fillHeight: true

        // Smooth transitions for filtering and sorting
        add: Transition {
            NumberAnimation {
                property: "opacity"
                from: 0
                to: 1
                duration: 300
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                property: "scale"
                from: 0.8
                to: 1.0
                duration: 300
                easing.type: Easing.OutBack
                easing.overshoot: 1.2
            }
        }

        remove: Transition {
            NumberAnimation {
                property: "opacity"
                to: 0
                duration: 200
                easing.type: Easing.InCubic
            }
            NumberAnimation {
                property: "scale"
                to: 0.8
                duration: 200
                easing.type: Easing.InCubic
            }
        }

        displaced: Transition {
            NumberAnimation {
                properties: "x,y"
                duration: 400
                easing.type: Easing.OutCubic
            }
        }

        populate: Transition {
            NumberAnimation {
                property: "opacity"
                from: 0
                to: 1
                duration: 600
                easing.type: Easing.OutCubic
            }
        }

        model: SortFilterProxyModel {
            id: dictionaryProxyModel
            sourceModel: SpellCheckAdapter.getDictionaryListModel()

            filterRoleName: "NativeName"
            filterCaseSensitivity: Qt.CaseInsensitive

            // Also search in locale if native name doesn't match
            filters: AnyOf {
                RegExpFilter {
                    roleName: "NativeName"
                    pattern: dictionaryProxyModel.filterPattern
                    caseSensitivity: Qt.CaseInsensitive
                }
                RegExpFilter {
                    roleName: "Locale"
                    pattern: dictionaryProxyModel.filterPattern
                    caseSensitivity: Qt.CaseInsensitive
                }
            }

            sorters: [
                // Sort by native name alphabetically
                RoleSorter {
                    roleName: "NativeName"
                    sortOrder: Qt.AscendingOrder
                }
            ]
        }

        readonly property int itemMargins: 20
        topMargin: itemMargins / 2
        bottomMargin: itemMargins / 2

        spacing: 8
        clip: true

        delegate: ItemDelegate {
            id: dictionaryDelegate
            width: spellCheckDictionaryListView.width
            height: Math.max(JamiTheme.preferredFieldHeight, contentLayout.implicitHeight + 32)

            background: Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width - spellCheckDictionaryListView.itemMargins
                height: parent.height
                color: JamiTheme.backgroundColor
                radius: JamiTheme.primaryRadius
                border.color: "transparent"
                border.width: 1
            }

            RowLayout {
                id: contentLayout
                anchors.fill: parent
                anchors.margins: 16
                spacing: 16

                // Dictionary info
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    Layout.leftMargin: 16
                    spacing: 2

                    Text {
                        id: dictionaryName
                        Layout.fillWidth: true
                        text: model.NativeName || ""
                        color: JamiTheme.textColor
                        font.pixelSize: JamiTheme.settingsDescriptionPixelSize
                        font.weight: Font.Medium
                        elide: Text.ElideRight
                        verticalAlignment: Text.AlignVCenter
                    }

                    Text {
                        id: dictionaryLocale
                        Layout.fillWidth: true
                        text: model.Locale || ""
                        color: JamiTheme.faddedLastInteractionFontColor
                        font.pixelSize: JamiTheme.settingsDescriptionPixelSize - 2
                        elide: Text.ElideRight
                        visible: text !== ""
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                // Installation status and action
                Item {
                    Layout.preferredWidth: 100
                    Layout.preferredHeight: 32
                    Layout.alignment: Qt.AlignVCenter
                    Layout.rightMargin: 16

                    // Install button for available dictionaries
                    MaterialButton {
                        id: installButton
                        anchors.centerIn: parent
                        width: 100
                        height: 32

                        text: JamiStrings.install

                        font.pixelSize: JamiTheme.settingsDescriptionPixelSize - 1
                        font.weight: Font.Medium

                        onClicked: {
                            if (model.Locale) {
                                SpellCheckAdapter.installDictionary(model.Locale)
                            }
                        }

                        visible: !model.Downloading && !model.Installed &&
                                    model.Locale !== undefined && model.Locale !== ""
                    }

                    // Uninstall button for installed dictionaries
                    MaterialButton {
                        id: uninstallButton
                        anchors.centerIn: parent
                        width: 100
                        height: 32

                        text: JamiStrings.uninstall
                        color: "#ff6666"
                        hoveredColor: "#ff9999"

                        font.pixelSize: JamiTheme.settingsDescriptionPixelSize - 1
                        font.weight: Font.Medium

                        onClicked: {
                            if (model.Locale) {
                                SpellCheckAdapter.uninstallDictionary(model.Locale)
                            }
                        }

                        visible: !model.Downloading && model.Installed &&
                                    model.Locale !== undefined && model.Locale !== ""
                    }

                    // Downloading status indicator
                    BusyIndicator {
                        anchors.centerIn: parent
                        visible: model.Downloading
                        running: model.Downloading
                        width: 24
                        height: 24

                        // Use a custom animation for better UX
                        Behavior on running {
                            NumberAnimation { duration: 300; easing.type: Easing.InOutQuad }
                        }
                    }
                }
            }
        }

        // Empty state with better styling
        Item {
            anchors.fill: parent
            visible: dictionaryProxyModel.count === 0

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 16
                width: parent.width * 0.8

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "📚"
                    font.pixelSize: 48
                    opacity: 0.3
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.fillWidth: true
                    text: dictionarySearchBar.textContent.length > 0 ?
                            qsTr("No dictionaries found for '%1'").arg(dictionarySearchBar.textContent) :
                            qsTr("No dictionaries available")
                    color: JamiTheme.faddedLastInteractionFontColor
                    font.pixelSize: JamiTheme.settingsDescriptionPixelSize
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                }
            }
        }
    }
}
