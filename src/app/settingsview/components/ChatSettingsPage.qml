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
                    sourceModel: SpellCheckAdapter.getDictionaryListModel()

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

                    Component.onCompleted: {
                        spellCheckLangComboBoxSetting.enabled =
                                Qt.binding(function() {
                                    return installedDictionariesModel.count > 0;
                                });
                    }
                }
                widthOfComboBox: itemWidth
                role: "NativeName"

                // Show placeholder when disabled
                placeholderText: qsTr("None")

                function getCurrentLocaleIndex() {
                    var currentLang = UtilsAdapter.getAppValue(Settings.Key.SpellLang)
                    for (var i = 0; i < comboModel.count; i++) {
                        var item = comboModel.get(i)
                        if (item.Locale === currentLang)
                            return i
                    }
                    return -1
                }

                // Set initial selection based on current spell language setting
                Component.onCompleted: modelIndex = getCurrentLocaleIndex()

                property string locale
                property string filePath
                function setForIndex(index) {
                    var selectedDict = comboModel.get(index)
                    if (selectedDict && selectedDict.Locale && selectedDict.Installed) {
                        filePath = selectedDict.FilePath // capture the file path
                        locale = selectedDict.Locale
                    }
                }
                onLocaleChanged: {
                    console.info("Locale changed to:", locale)
                    UtilsAdapter.setAppValue(Settings.Key.SpellLang, locale)
                    SpellCheckAdapter.setDictionaryPath(filePath)
                }

                // When the count changes, we might need to update the model index
                readonly property int count: installedDictionariesModel.count
                onCountChanged: {
                    modelIndex = getCurrentLocaleIndex()
                    // If the new index is -1 and we still have dictionaries, use the first one
                    if (modelIndex === -1 && installedDictionariesModel.count > 0) {
                        modelIndex = 0
                    }
                }

                // If the model index changes programmatically, we need to update the dictionary path
                onModelIndexChanged: setForIndex(modelIndex)
            }

            // A button to open the dictionary install view as a popup
            MaterialButton {
                id: dictionaryInstallButton

                Layout.fillWidth: true
                Layout.topMargin: 10

                text: qsTr("Manage Dictionaries")
                onClicked: {
                    viewCoordinator.presentDialog(appWindow, "commoncomponents/ManageDictionariesDialog.qml");
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

