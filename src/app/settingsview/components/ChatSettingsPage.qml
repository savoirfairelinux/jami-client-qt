/*
 * Copyright (C) 2024-2025 Savoir-faire Linux Inc.
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
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Enums 1.1
import net.jami.Constants 1.1
import net.jami.Helpers 1.1
import SortFilterProxyModel 0.2
import "../../commoncomponents"
import "../../mainview/components"
import "../../mainview/js/contactpickercreation.js" as ContactPickerCreation

SettingsPageBase {
    id: root

    property int itemWidth: 188
    title: JamiStrings.chatSettingsTitle

    flickableContent: ColumnLayout {
        id: callSettingsColumnLayout

        anchors.topMargin: 10
        width: contentFlickableWidth
        spacing: 2 * JamiTheme.settingsCategorySpacing
        anchors.left: parent.left
        anchors.leftMargin: JamiTheme.preferredSettingsMarginSize

        ColumnLayout {

            width: parent.width
            spacing: JamiTheme.settingsCategorySpacing

            Text {
                id: spellcheckingTitle

                Layout.alignment: Qt.AlignLeft
                Layout.preferredWidth: parent.width

                text: JamiStrings.spellchecking
                color: JamiTheme.textColor
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
                wrapMode: Text.WordWrap

                font.pixelSize: JamiTheme.settingsTitlePixelSize
                font.kerning: true
            }

            ToggleSwitch {
                id: enableSpellCheckToggleSwitch
                Layout.fillWidth: true
                visible: true

                checked: UtilsAdapter.getAppValue(Settings.Key.EnableSpellCheck)
                labelText: JamiStrings.checkSpelling
                tooltipText: JamiStrings.checkSpelling
                onSwitchToggled: {
                    UtilsAdapter.setAppValue(Settings.Key.EnableSpellCheck, checked);
                }
            }

            SettingsComboBox {
                id: spellCheckLangComboBoxSetting
                Layout.fillWidth: true
                height: JamiTheme.preferredFieldHeight
                labelText: JamiStrings.textLanguage
                tipText: JamiStrings.textLanguage
                comboModel: SortFilterProxyModel {
                    id: installedDictionariesModel
                    sourceModel: SpellCheckDictionaryListModel

                    // Filter to show only installed dictionaries
                    filters: ValueFilter {
                        roleName: "Installed"
                        value: true
                    }

                    // Sort alphabetically by native name
                    sorters: RoleSorter {
                        roleName: "NativeName"
                        sortOrder: Qt.AscendingOrder
                    }
                }
                widthOfComboBox: itemWidth
                role: "NativeName"

                // Disable when no dictionaries are installed
                enabled: installedDictionariesModel.count > 0

                // Show placeholder when disabled
                placeholderText: installedDictionariesModel.count === 0 ?
                    qsTr("No dictionaries installed") : ""

                // Set initial selection based on current spell language setting
                Component.onCompleted: {
                    var currentLang = UtilsAdapter.getAppValue(Settings.Key.SpellLang)
                    for (var i = 0; i < comboModel.count; i++) {
                        var item = comboModel.get(i)
                        if (item.Locale === currentLang) {
                            modelIndex = i
                            break
                        }
                    }
                }

                onActivated: {
                    var selectedDict = comboModel.get(modelIndex)
                    if (selectedDict && selectedDict.Locale) {
                        UtilsAdapter.setAppValue(Settings.Key.SpellLang, selectedDict.Locale)
                    }
                }
            }

            // A new widget to replace the ones above (Test first) that harnesses our new model
            // and provides a more user-friendly interface for managing spell check dictionaries.

            // Search bar for filtering dictionaries
            Searchbar {
                id: dictionarySearchBar
                Layout.fillWidth: true
                Layout.preferredHeight: 35
                Layout.bottomMargin: 8

                placeHolderText: JamiStrings.search + " " + JamiStrings.availableTextLanguages.toLowerCase()


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
                    sourceModel: SpellCheckDictionaryListModel

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
                Layout.fillWidth: true
                Layout.preferredHeight: Math.max(JamiTheme.preferredFieldHeight * 4,
                                                 Math.min(JamiTheme.preferredFieldHeight * 6,
                                                          contentHeight + 20))
                Layout.minimumHeight: JamiTheme.preferredFieldHeight * 4

                readonly property int itemMargins: 20
                topMargin: itemMargins / 2
                bottomMargin: itemMargins / 2

                spacing: 8
                clip: true

                // Add a subtle background
                Rectangle {
                    anchors.fill: parent
                    color: JamiTheme.backgroundColor
                    radius: JamiTheme.primaryRadius
                    border.color: "#ccc"
                    border.width: 1
                    opacity: 0.3
                }

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
                                        SpellCheckDictionaryListModel.installDictionary(model.Locale)
                                    }
                                }

                                visible: !model.Installed && model.Locale !== undefined && model.Locale !== ""
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
                                        SpellCheckDictionaryListModel.uninstallDictionary(model.Locale)
                                    }
                                }

                                visible: model.Installed && model.Locale !== undefined && model.Locale !== ""
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
                            text: "🌭🌮"
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

        ColumnLayout {
            id: generalSettings

            width: parent.width
            spacing: JamiTheme.settingsCategorySpacing

            Text {
                id: enableAccountTitle

                Layout.alignment: Qt.AlignLeft
                Layout.preferredWidth: parent.width

                text: JamiStrings.view
                color: JamiTheme.textColor
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
                wrapMode: Text.WordWrap

                font.pixelSize: JamiTheme.settingsTitlePixelSize
                font.kerning: true
            }

            ToggleSwitch {
                id: displayImagesCheckbox
                visible: WITH_WEBENGINE

                Layout.fillWidth: true

                checked: UtilsAdapter.getAppValue(Settings.DisplayHyperlinkPreviews)

                labelText: JamiStrings.displayHyperlinkPreviews
                descText: JamiStrings.displayHyperlinkPreviewsDescription

                tooltipText: JamiStrings.displayHyperlinkPreviews

                onSwitchToggled: {
                    UtilsAdapter.setAppValue(Settings.Key.DisplayHyperlinkPreviews, checked);
                }
            }
        }

        ColumnLayout {
            id: textFormattingSettings

            width: parent.width
            spacing: JamiTheme.settingsCategorySpacing

            Text {
                id: textFormattingTitle

                Layout.alignment: Qt.AlignLeft
                Layout.preferredWidth: parent.width

                text: JamiStrings.textFormatting
                color: JamiTheme.textColor
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
                wrapMode: Text.WordWrap

                font.pixelSize: JamiTheme.settingsTitlePixelSize
                font.kerning: true
            }

            Text {
                id: textFormattingDescription

                Layout.alignment: Qt.AlignLeft
                Layout.preferredWidth: parent.width

                text: JamiStrings.textFormattingDescription
                color: JamiTheme.textColor
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
                wrapMode: Text.WordWrap
            }

            Flow {

                Layout.preferredWidth: parent.width
                Layout.preferredHeight: childrenRect.height
                spacing: 10

                ButtonGroup {
                    id: optionsB
                }

                MaterialRadioButton {
                    id: enterButton

                    width: 130
                    height: 40
                    backgroundColor: JamiTheme.chatSettingButtonBackgroundColor
                    textColor: JamiTheme.chatSettingButtonTextColor
                    checkedColor: JamiTheme.chatSettingButtonBorderColor
                    borderColor: JamiTheme.chatSettingButtonBorderColor

                    text: JamiStrings.enter
                    ButtonGroup.group: optionsB

                    onCheckedChanged: {
                        if (checked)
                            UtilsAdapter.setAppValue(Settings.Key.ChatViewEnterIsNewLine, true);
                    }
                }

                MaterialRadioButton {
                    id: shiftEnterButton

                    width: 210
                    height: 40
                    backgroundColor: JamiTheme.chatSettingButtonBackgroundColor
                    textColor: JamiTheme.chatSettingButtonTextColor
                    checkedColor: JamiTheme.chatSettingButtonBorderColor
                    borderColor: JamiTheme.chatSettingButtonBorderColor

                    text: JamiStrings.shiftEnter
                    ButtonGroup.group: optionsB

                    onCheckedChanged: {
                        if (checked)
                            UtilsAdapter.setAppValue(Settings.Key.ChatViewEnterIsNewLine, false);
                    }
                }

                Component.onCompleted: {
                    if (UtilsAdapter.getAppValue(Settings.Key.ChatViewEnterIsNewLine))
                        enterButton.checked = true;
                    else
                        shiftEnterButton.checked = true;
                }
            }
        }

        ColumnLayout {
            id: fileTransferSettings

            width: parent.width
            spacing: JamiTheme.settingsCategorySpacing

            Text {
                id: fileTransferTitle

                Layout.alignment: Qt.AlignLeft
                Layout.preferredWidth: parent.width

                text: JamiStrings.fileTransfer
                color: JamiTheme.textColor
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
                wrapMode: Text.WordWrap

                font.pixelSize: JamiTheme.settingsTitlePixelSize
                font.kerning: true
            }

            ToggleSwitch {
                id: autoAcceptFilesCheckbox
                Layout.fillWidth: true

                checked: CurrentAccount.autoTransferFromTrusted
                labelText: JamiStrings.autoAcceptFiles
                tooltipText: JamiStrings.autoAcceptFiles
                onSwitchToggled: CurrentAccount.autoTransferFromTrusted = checked
            }

            SettingSpinBox {
                id: acceptTransferBelowSpinBox
                Layout.fillWidth: true

                title: JamiStrings.acceptTransferBelow
                tooltipText: JamiStrings.acceptTransferTooltip
                itemWidth: root.itemWidth
                bottomValue: 0

                valueField: CurrentAccount.autoTransferSizeThreshold
                onNewValue: CurrentAccount.autoTransferSizeThreshold = valueField
            }
        }

        MaterialButton {
            id: defaultSettings

            Layout.topMargin: 20

            TextMetrics {
                id: defaultSettingsTextSize
                font.weight: Font.Bold
                font.pixelSize: JamiTheme.wizardViewButtonFontPixelSize
                font.capitalization: Font.AllUppercase
                text: defaultSettings.text
            }

            secondary: true

            text: JamiStrings.defaultSettings
            preferredWidth: defaultSettingsTextSize.width + 2 * JamiTheme.buttontextWizzardPadding

            onClicked: {
                autoAcceptFilesCheckbox.checked = UtilsAdapter.getDefault(Settings.Key.AutoAcceptFiles);
                acceptTransferBelowSpinBox.valueField = UtilsAdapter.getDefault(Settings.Key.AcceptTransferBelow);
                UtilsAdapter.setToDefault(Settings.Key.AutoAcceptFiles);
                UtilsAdapter.setToDefault(Settings.Key.AcceptTransferBelow);
                UtilsAdapter.setToDefault(Settings.Key.ChatViewEnterIsNewLine);
                UtilsAdapter.setToDefault(Settings.Key.DisplayHyperlinkPreviews);
                displayImagesCheckbox.checked = UtilsAdapter.getAppValue(Settings.DisplayHyperlinkPreviews);
                if (UtilsAdapter.getAppValue(Settings.Key.ChatViewEnterIsNewLine))
                    enterButton.checked = true;
                else
                    shiftEnterButton.checked = true;
            }
        }
    }
}

