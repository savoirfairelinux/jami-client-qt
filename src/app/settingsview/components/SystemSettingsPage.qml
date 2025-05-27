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
import QtQuick.Controls
import QtQuick.Layouts
import Qt.labs.platform
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import net.jami.Enums 1.1
import net.jami.Models 1.1
import "../../commoncomponents"
import SortFilterProxyModel 0.2

SettingsPageBase {
    id: root

    property string downloadPath: UtilsAdapter.getDirDownload()
    property string downloadPathBestName: UtilsAdapter.dirName(UtilsAdapter.getDirDownload())
    property int itemWidth: 188

    property bool isSIP

    title: JamiStrings.system

    onDownloadPathChanged: {
        if (downloadPath === "")
            return;
        UtilsAdapter.setDownloadPath(downloadPath);
    }

    flickableContent: ColumnLayout {
        id: manageAccountEnableColumnLayout
        width: contentFlickableWidth
        spacing: JamiTheme.settingsBlockSpacing
        anchors.left: parent.left
        anchors.leftMargin: JamiTheme.preferredSettingsMarginSize

        ColumnLayout {
            id: enableAccount

            width: parent.width

            spacing: 10

            FolderDialog {
                id: downloadPathDialog

                title: JamiStrings.selectFolder
                currentFolder: StandardPaths.writableLocation(StandardPaths.DownloadLocation)
                options: FolderDialog.ShowDirsOnly

                onAccepted: {
                    var dir = UtilsAdapter.getAbsPath(folder.toString());
                    var dirName = UtilsAdapter.dirName(folder.toString());
                    downloadPath = dir;
                    downloadPathBestName = dirName;
                }
            }

            ToggleSwitch {
                id: notificationCheckBox
                Layout.fillWidth: true

                checked: AppSettingsManager.settingsMap.EnableNotifications
                labelText: JamiStrings.showNotifications
                tooltipText: JamiStrings.enableNotifications
                onSwitchToggled: AppSettingsManager.settingsMap.EnableNotifications = checked
            }

            ToggleSwitch {
                id: enableDonation
                Layout.fillWidth: true
                visible: (new Date() >= new Date(Date.parse("2023-11-01")) && !APPSTORE)

                checked: AppSettingsManager.settingsMap.IsDonationVisible
                labelText: JamiStrings.enableDonation
                tooltipText: JamiStrings.enableDonation
                onSwitchToggled: {
                    AppSettingsManager.settingsMap.IsDonationVisible = checked;
                    if (checked) {
                        AppSettingsManager.setToDefault(Settings.Key.Donation2023VisibleDate);
                    }
                }
            }

            ToggleSwitch {
                id: closeOrMinCheckBox
                Layout.fillWidth: true

                checked: AppSettingsManager.settingsMap.MinimizeOnClose
                labelText: JamiStrings.keepMinimized
                onSwitchToggled: AppSettingsManager.settingsMap.MinimizeOnClose = checked

            }

            ToggleSwitch {
                id: runOnStartUpCheckBox
                Layout.fillWidth: true

                checked: UtilsAdapter.checkStartupLink()
                labelText: JamiStrings.runStartup
                tooltipText: JamiStrings.tipRunStartup
                onSwitchToggled: UtilsAdapter.setRunOnStartUp(checked)
            }

            RowLayout {
                Layout.fillWidth: true
                height: JamiTheme.preferredFieldHeight

                Text {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.rightMargin: JamiTheme.preferredMarginSize
                    wrapMode: Text.WordWrap
                    color: JamiTheme.textColor
                    text: JamiStrings.downloadFolder
                    font.pointSize: JamiTheme.settingsFontSize
                    font.kerning: true

                    horizontalAlignment: Text.AlignLeft
                    verticalAlignment: Text.AlignVCenter
                }

                MaterialButton {
                    id: downloadButton

                    Layout.alignment: Qt.AlignRight

                    preferredWidth: itemWidth
                    buttontextHeightMargin: JamiTheme.buttontextHeightMargin
                    textLeftPadding: JamiTheme.buttontextWizzardPadding
                    textRightPadding: JamiTheme.buttontextWizzardPadding

                    toolTipText: downloadPath
                    text: downloadPathBestName
                    secondary: true

                    onClicked: downloadPathDialog.open()
                }
            }

            SettingsComboBox {
                id: langComboBoxSetting

                Layout.fillWidth: true
                height: JamiTheme.preferredFieldHeight

                labelText: JamiStrings.userInterfaceLanguage
                tipText: JamiStrings.userInterfaceLanguage
                comboModel: ListModel {
                    id: langModel
                    Component.onCompleted: {
                        var supported = UtilsAdapter.supportedLang();
                        var keys = Object.keys(supported);
                        var currentKey = AppSettingsManager.settingsMap.LANG;
                        for (var i = 0; i < keys.length; ++i) {
                            append({
                                    "textDisplay": supported[keys[i]],
                                    "id": keys[i]
                                });
                            if (keys[i] === currentKey)
                                langComboBoxSetting.modelIndex = i;
                        }
                    }
                }

                widthOfComboBox: itemWidth
                role: "textDisplay"

                onActivated: AppSettingsManager.settingsMap.LANG = comboModel.get(modelIndex).id
            }
        }
        ColumnLayout {

            width: parent.width
            spacing: JamiTheme.settingsCategorySpacing
            visible: (Qt.platform.os.toString() !== "linux") ? false : true

            Text {
                id: spellCheckerTitle

                Layout.alignment: Qt.AlignLeft
                Layout.preferredWidth: parent.width

                text: JamiStrings.spellChecker
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

                checked: AppSettingsManager.settingsMap.EnableSpellCheck
                labelText: JamiStrings.checkSpelling
                descText: JamiStrings.textLanguageDescription
                tooltipText: JamiStrings.checkSpelling
                onSwitchToggled: AppSettingsManager.settingsMap.EnableSpellCheck = checked

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
                        var supported = SpellCheckDictionaryManager.installedDictionaries();
                        var keys = Object.keys(supported);
                        var currentKey = AppSettingsManager.settingsMap.SpellLang;
                        for (var i = 0; i < keys.length; ++i) {
                            append({
                                    "textDisplay": supported[keys[i]],
                                    "id": keys[i]
                                });
                            if (keys[i] === currentKey)
                                spellCheckLangComboBoxSetting.modelIndex = i;
                        }
                    }
                }

                widthOfComboBox: itemWidth
                role: "textDisplay"

                onActivated: AppSettingsManager.settingsMap.SpellLang = comboModel.get(modelIndex).id
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.minimumHeight: JamiTheme.preferredFieldHeight

                Text {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.rightMargin: JamiTheme.preferredMarginSize

                    color: JamiTheme.textColor
                    wrapMode: Text.WordWrap
                    text: JamiStrings.refreshInstalledDictionaries
                    font.pointSize: JamiTheme.settingsFontSize
                    font.kerning: true

                    horizontalAlignment: Text.AlignLeft
                    verticalAlignment: Text.AlignVCenter
                }

                MaterialButton {
                    id: refreshInstalledDictionariesPushButton

                    Layout.alignment: Qt.AlignCenter

                    preferredWidth: textSizeRefresh.width + 2 * JamiTheme.buttontextWizzardPadding
                    buttontextHeightMargin: JamiTheme.buttontextHeightMargin

                    primary: true
                    toolTipText: JamiStrings.refresh

                    text: JamiStrings.refresh

                    onClicked: {
                        SpellCheckDictionaryManager.refreshDictionaries();
                        var langIdx = spellCheckLangComboBoxSetting.modelIndex;
                        installedSpellCheckLangModel.clear();
                        var supported = SpellCheckDictionaryManager.installedDictionaries();
                        var keys = Object.keys(supported);
                        for (var i = 0; i < keys.length; ++i) {
                            installedSpellCheckLangModel.append({
                                    "textDisplay": supported[keys[i]],
                                    "id": keys[i]
                                });
                        }
                        spellCheckLangComboBoxSetting.modelIndex = langIdx;
                    }

                    TextMetrics {
                        id: textSizeRefresh
                        font.weight: Font.Bold
                        font.pixelSize: JamiTheme.wizardViewButtonFontPixelSize
                        font.capitalization: Font.AllUppercase
                        text: refreshInstalledDictionariesPushButton.text
                    }
                }
            }
            property var lang: AppSettingsManager.settingsMap.LANG
            onLangChanged: {
                var langIdx = langComboBoxSetting.modelIndex;
                langModel.clear();
                var supported = UtilsAdapter.supportedLang();
                var keys = Object.keys(supported);
                for (var i = 0; i < keys.length; ++i) {
                    langModel.append({
                            "textDisplay": supported[keys[i]],
                            "id": keys[i]
                        });
                }
                langComboBoxSetting.modelIndex = langIdx;
            }

            property var spellLang: AppSettingsManager.settingsMap.SpellLang
            onSpellLangChanged: {
                    var langIdx = spellCheckLangComboBoxSetting.modelIndex;
                installedSpellCheckLangModel.clear();
                var supported = SpellCheckDictionaryManager.installedDictionaries();
                var keys = Object.keys(supported);
                for (var i = 0; i < keys.length; ++i) {
                    installedSpellCheckLangModel.append({
                            "textDisplay": supported[keys[i]],
                            "id": keys[i]
                        });
                }
                spellCheckLangComboBoxSetting.modelIndex = langIdx;
            }
        }

        ColumnLayout {

            width: parent.width
            spacing: JamiTheme.settingsCategorySpacing

            Text {
                id: experimentalTitle

                Layout.alignment: Qt.AlignLeft
                Layout.preferredWidth: parent.width

                text: JamiStrings.experimental
                color: JamiTheme.textColor
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
                wrapMode: Text.WordWrap

                font.pixelSize: JamiTheme.settingsTitlePixelSize
                font.kerning: true
            }

            ToggleSwitch {
                id: checkboxCallSwarm
                Layout.fillWidth: true
                checked: AppSettingsManager.settingsMap.EnableExperimentalSwarm
                labelText: JamiStrings.experimentalCallSwarm
                tooltipText: JamiStrings.experimentalCallSwarmTooltip
                onSwitchToggled: AppSettingsManager.settingsMap.EnableExperimentalSwarm = checked
            }
        }

        MaterialButton {
            id: defaultSettings

            TextMetrics {
                id: textSize
                font.weight: Font.Bold
                font.pixelSize: JamiTheme.wizardViewButtonFontPixelSize
                font.capitalization: Font.AllUppercase
                text: defaultSettings.text
            }

            secondary: true

            text: JamiStrings.defaultSettings
            preferredWidth: textSize.width + 2 * JamiTheme.buttontextWizzardPadding

            onClicked: {
                langComboBoxSetting.modelIndex = 0;
                spellCheckLangComboBoxSetting.modelIndex = 0;
                AppSettingsManager.setToDefault(Settings.Key.EnableNotifications);
                AppSettingsManager.setToDefault(Settings.Key.MinimizeOnClose);
                AppSettingsManager.setToDefault(Settings.Key.LANG);
                AppSettingsManager.setToDefault(Settings.Key.EnableExperimentalSwarm);
                AppSettingsManager.setToDefault(Settings.Key.IsDonationVisible);
                AppSettingsManager.setToDefault(Settings.Key.Donation2023VisibleDate);
                enableDonation.checked = Qt.binding(() => AppSettingsManager.settingsMap.IsDonationVisible);
            }
        }
    }
}
