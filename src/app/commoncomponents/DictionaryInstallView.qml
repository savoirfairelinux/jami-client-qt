/*
 * Copyright (C) 2025-2026 Savoir-faire Linux Inc.
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
import "../settingsview/components"
import SortFilterProxyModel 0.2

// Search bar for filtering dictionaries
ColumnLayout {
    id: root

    property int checkBoxWidth: 24

    spacing: 0

    Component.onCompleted: Qt.callLater(dictionarySearchBar.setTextAreaFocus)

    // Header title
    Searchbar {
        id: dictionarySearchBar

        Layout.fillWidth: true
        Layout.preferredHeight: 55

        focus: true

        placeHolderText: JamiStrings.searchTextLanguages

        onSearchBarTextChanged: function (text) {
            dictionaryProxyModel.combinedFilterPattern = text;
            dictionaryProxyModel.invalidate();
        }

        Accessible.name: JamiStrings.searchTextLanguages
        Accessible.role: Accessible.EditableText
        Accessible.description: JamiStrings.searchAvailableTextLanguages

    }

    RowLayout {
        id: headerLayout

        Layout.fillWidth: true
        Layout.preferredHeight: childrenRect.height
        Layout.leftMargin: dictionarySearchBar.radius

        Label {
            text: JamiStrings.showInstalledDictionaries
            color: JamiTheme.faddedLastInteractionFontColor
            font.pixelSize: JamiTheme.settingsDescriptionPixelSize
            Layout.rightMargin: 0
            Layout.preferredHeight: 16
            Layout.alignment: Qt.AlignVCenter
        }

        // Checkbox to filter installed dictionaries
        CheckBox {
            id: showInstalledOnlyCheckbox

            Layout.preferredWidth: 55
            Layout.preferredHeight: 55
            Layout.rightMargin: 0

            checked: false

            indicator: Image {
                anchors.centerIn: parent

                width: checkBoxWidth
                height: checkBoxWidth

                layer {
                    enabled: true
                    effect: ColorOverlay {
                        color: JamiTheme.tintedBlue
                    }
                    mipmap: false
                    smooth: true
                }

                source: showInstalledOnlyCheckbox.checked ? JamiResources.check_box_24dp_svg : JamiResources.check_box_outline_blank_24dp_svg
            }

            Accessible.name: JamiStrings.showInstalledDictionaries
            Accessible.role: Accessible.CheckBox
            Accessible.description: JamiStrings.showInstalledDictionariesDescription
        }
    }

    // Connect to listen for download failure and pop a simple dialog to inform the user
    Connections {
        target: SpellCheckAdapter
        function onDownloadFailed(locale) {
            viewCoordinator.presentDialog(appWindow, "commoncomponents/SimpleMessageDialog.qml", {
                    "title": JamiStrings.error,
                    "infoText": JamiStrings.spellCheckDownloadFailed.arg(locale),
                    "buttonTitles": [JamiStrings.optionOk],
                    "buttonStyles": [SimpleMessageDialog.ButtonStyle.TintedBlue],
                    "buttonRoles": [DialogButtonBox.AcceptRole]
                });
        }
    }

    JamiListView {
        id: spellCheckDictionaryListView

        Layout.fillWidth: true
        Layout.fillHeight: true

        model: SortFilterProxyModel {
            id: dictionaryProxyModel
            sourceModel: SpellCheckAdapter.getDictionaryListModel()

            property string combinedFilterPattern

            filters: AllOf {
                AnyOf {
                    // Filter by dictionary name
                    RegExpFilter {
                        roleName: "Locale"
                        pattern: dictionaryProxyModel.combinedFilterPattern
                        caseSensitivity: Qt.CaseInsensitive
                    }
                    // Filter by native name
                    RegExpFilter {
                        roleName: "NativeName"
                        pattern: dictionaryProxyModel.combinedFilterPattern
                        caseSensitivity: Qt.CaseInsensitive
                    }
                }
                ValueFilter {
                    roleName: "Installed"
                    value: true
                    enabled: showInstalledOnlyCheckbox.checked
                }
            }

            sorters: [
                // Sort by locale alphabetically
                RoleSorter {
                    roleName: "Locale"
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
                radius: height / 2//JamiTheme.primaryRadius
                border.color: "transparent"
                border.width: 1
            }

            RowLayout {
                id: contentLayout

                anchors.fill: parent
                anchors.margins: 16
                anchors.leftMargin: dictionaryDelegate.background.radius
                anchors.rightMargin: dictionaryDelegate.background.radius
                spacing: 16

                // Dictionary info
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    //Layout.leftMargin: 16
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

                    // Install button for available dictionaries
                    MaterialButton {
                        id: installButton
                        anchors.centerIn: parent
                        width: 100
                        height: 32

                        text: JamiStrings.install

                        font.pixelSize: JamiTheme.settingsDescriptionPixelSize - 1
                        font.weight: Font.Medium

                        focusPolicy: Qt.StrongFocus
                        KeyNavigation.tab: {
                            try {
                                if (model.index < dictionaryProxyModel.count - 1) {
                                    var nextItem = spellCheckDictionaryListView.itemAtIndex(model.index + 1);
                                    if (nextItem) {
                                        var nextButton = nextItem.findChild("installButton") || nextItem.findChild("uninstallButton");
                                        return nextButton || null;
                                    }
                                }
                            } catch (e) {
                                console.debug("KeyNavigation error handled:", e);
                            }
                            return null;
                        }

                        onFocusChanged: {
                            if (focus) {
                                spellCheckDictionaryListView.positionViewAtIndex(model.index, ListView.Contain);
                            }
                        }

                        Accessible.name: dictionaryName.text + " " + JamiStrings.install
                        Accessible.role: Accessible.Button

                        onClicked: {
                            if (model.Locale) {
                                SpellCheckAdapter.installDictionary(model.Locale);
                            }
                        }

                        visible: !model.Downloading && !model.Installed && model.Locale !== undefined && model.Locale !== ""
                    }

                    // Uninstall button for installed dictionaries (not system dictionaries)
                    MaterialButton {
                        id: uninstallButton

                        anchors.centerIn: parent

                        width: 100
                        height: 32

                        visible: !model.Downloading && model.Installed && !model.IsSystem && model.Locale !== undefined && model.Locale !== ""

                        text: JamiStrings.uninstall
                        color: "#ff6666"
                        hoveredColor: "#ff9999"

                        font.pixelSize: JamiTheme.settingsDescriptionPixelSize - 1
                        font.weight: Font.Medium

                        focusPolicy: Qt.StrongFocus
                        KeyNavigation.tab: {
                            try {
                                if (model.index < dictionaryProxyModel.count - 1) {
                                    var nextItem = spellCheckDictionaryListView.itemAtIndex(model.index + 1);
                                    if (nextItem) {
                                        var nextButton = nextItem.findChild("installButton") || nextItem.findChild("uninstallButton");
                                        return nextButton || null;
                                    }
                                }
                            } catch (e) {
                                console.debug("KeyNavigation error handled:", e);
                            }
                            return null;
                        }

                        onFocusChanged: {
                            if (focus) {
                                spellCheckDictionaryListView.positionViewAtIndex(model.index, ListView.Contain);
                            }
                        }

                        onClicked: {
                            if (model.Locale) {
                                SpellCheckAdapter.uninstallDictionary(model.Locale);
                            }
                        }


                        Accessible.name: dictionaryName.text + " " + JamiStrings.uninstall
                        Accessible.role: Accessible.Button
                    }

                    // System dictionary indicator
                    Text {
                        anchors.centerIn: parent
                        text: JamiStrings.systemDictionary
                        color: JamiTheme.faddedLastInteractionFontColor
                        font.pixelSize: JamiTheme.settingsDescriptionPixelSize - 2
                        visible: model.IsSystem
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
                            NumberAnimation {
                                duration: 300
                                easing.type: Easing.InOutQuad
                            }
                        }
                    }
                }
            }
        }

        // Empty state for when no dictionaries are found
        Item {
            anchors.fill: parent
            visible: dictionaryProxyModel.count === 0

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 16
                width: parent.width * 0.8

                // Big books emoji
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "📚"
                    font.pixelSize: 48
                    opacity: 0.3
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.fillWidth: true
                    text: dictionarySearchBar.textContent.length > 0 ? JamiStrings.noDictionariesFoundFor.arg(dictionarySearchBar.textContent) : JamiStrings.noDictionariesAvailable
                    color: JamiTheme.faddedLastInteractionFontColor
                    font.pixelSize: JamiTheme.settingsDescriptionPixelSize
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                }
            }
        }
    }
}
