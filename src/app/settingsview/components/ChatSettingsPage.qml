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
import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Enums 1.1
import net.jami.Constants 1.1
import net.jami.Helpers 1.1
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
                comboModel: ListModel {
                    id: installedSpellCheckLangModel
                    Component.onCompleted: {
                        var supported = SpellCheckDictionaryManager.getInstalledDictionaries();
                        var keys = Object.keys(supported);
                        var currentKey = UtilsAdapter.getAppValue(Settings.Key.SpellLang);
                        for (var i = 0; i < keys.length; ++i) {
                            var dictInfo = supported[keys[i]];
                            append({
                                    "displayText": dictInfo.nativeName,
                                    "id": keys[i],
                                    "path": dictInfo.path
                                });
                            if (keys[i] === currentKey)
                                spellCheckLangComboBoxSetting.modelIndex = i;
                        }
                    }
                }
                widthOfComboBox: itemWidth
                role: "displayText"
                onActivated: {
                    // Get selected dictionary
                    var selectedDict = comboModel.get(modelIndex);
                    if (!selectedDict)
                        return;

                    // Download dictionary
                    SpellCheckDictionaryManager.getBestDictionary(selectedDict.id);

                    // Dialog will handle the rest through onDownloadFinished signal
                    // which will properly update both lists
                }
            }

            SettingsComboBox {
                id: spellCheckAvailableLangComboBoxSetting

                Layout.fillWidth: true
                height: JamiTheme.preferredFieldHeight

                labelText: JamiStrings.availableTextLanguages
                tipText: JamiStrings.availableTextLanguages
                comboModel: ListModel {
                    id: availableSpellCheckLangModel
                    Component.onCompleted: {
                        var dictionaries = SpellCheckDictionaryManager.getAvailableDictionaries();
                        var keys = Object.keys(dictionaries);
                        var currentKey = UtilsAdapter.getAppValue(Settings.Key.SpellLang);
                        for (var i = 0; i < keys.length; ++i) {
                            var dictInfo = dictionaries[keys[i]];
                            append({
                                    "displayText": dictInfo.nativeName,
                                    "id": keys[i],
                                    "path": dictInfo.path
                                });
                            if (keys[i] === currentKey)
                                spellCheckAvailableLangComboBoxSetting.modelIndex = i;
                        }
                    }
                }

                widthOfComboBox: itemWidth
                role: "displayText"
                onActivated: {
                    SpellCheckDictionaryManager.getBestDictionary(comboModel.get(modelIndex).id);
                    // First refresh dictionaries to update both cached lists
                    SpellCheckDictionaryManager.refreshDictionaries();

                    // Save current selection
                    var langIdx = spellCheckLangComboBoxSetting.modelIndex;

                    // Update installed languages list
                    installedSpellCheckLangModel.clear();
                    var supported = SpellCheckDictionaryManager.getInstalledDictionaries();
                    var currentKey = UtilsAdapter.getAppValue(Settings.Key.SpellLang);
                    var keys = Object.keys(supported);
                    for (var i = 0; i < keys.length; ++i) {
                        var dictInfo = supported[keys[i]];
                        installedSpellCheckLangModel.append({
                                "displayText": dictInfo.nativeName,
                                "id": keys[i],
                                "path": dictInfo.path
                            });
                        // Restore selection
                        if (keys[i] === currentKey) {
                            spellCheckLangComboBoxSetting.modelIndex = i;
                        }
                    }

                    // Update available languages list
                    availableSpellCheckLangModel.clear();
                    var dictionaries = SpellCheckDictionaryManager.getAvailableDictionaries();
                    var availableKeys = Object.keys(dictionaries);
                    for (var j = 0; j < availableKeys.length; ++j) {
                        var availableDictInfo = dictionaries[availableKeys[j]];
                        availableSpellCheckLangModel.append({
                                "displayText": availableDictInfo.nativeName,
                                "id": availableKeys[j],
                                "path": availableDictInfo.path
                            });
                    }
                }
            }

            DownloadDictionaryPopup {
                id: downloadDictionaryPopup
                visible: false
            }

            Connections {
                target: SpellCheckDictionaryManager

                function onDownloadFinished() {
                    // Show success popup
                    downloadDictionaryPopup.success = true;
                    downloadDictionaryPopup.visible = true;
                    downloadDictionaryPopup.enabled = true;

                    // First refresh dictionaries to ensure caches are updated
                    SpellCheckDictionaryManager.refreshDictionaries();

                    // Update installed languages list
                    installedSpellCheckLangModel.clear();
                    var supported = SpellCheckDictionaryManager.getInstalledDictionaries();
                    var currentKey = UtilsAdapter.getAppValue(Settings.Key.SpellLang);
                    var keys = Object.keys(supported);

                    // Populate installed languages
                    for (var i = 0; i < keys.length; ++i) {
                        var dictInfo = supported[keys[i]];
                        installedSpellCheckLangModel.append({
                                "displayText": dictInfo.nativeName,
                                "id": keys[i],
                                "path": dictInfo.path
                            });
                        // Set current selection if this is the active language
                        if (keys[i] === currentKey) {
                            spellCheckLangComboBoxSetting.modelIndex = i;
                        }
                    }

                    // Update available languages list
                    availableSpellCheckLangModel.clear();
                    var dictionaries = SpellCheckDictionaryManager.getAvailableDictionaries();
                    var availableKeys = Object.keys(dictionaries);
                    for (var j = 0; j < availableKeys.length; ++j) {
                        var availableDictInfo = dictionaries[availableKeys[j]];
                        availableSpellCheckLangModel.append({
                                "displayText": availableDictInfo.nativeName,
                                "id": availableKeys[j],
                                "path": availableDictInfo.path
                            });
                    }
                }

                function onDictionaryDownloadFailed(localPath) {
                    // Show failure popup
                    downloadDictionaryPopup.success = false;
                    downloadDictionaryPopup.visible = true;
                    downloadDictionaryPopup.enabled = true;
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
