/*
 * Copyright (C) 2023 Savoir-faire Linux Inc.
 * Author: Fadi Shehadeh   <fadi.shehadeh@savoirfairelinux.com>
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

SettingsPageBase {
    id: root
    property string downloadPath: UtilsAdapter.getDirDownload()
    property string downloadPathBestName: UtilsAdapter.dirName(UtilsAdapter.getDirDownload())
    property bool isSIP
    property int itemWidth: 188

    title: JamiStrings.system

    onDownloadPathChanged: {
        if (downloadPath === "")
            return;
        UtilsAdapter.setDownloadPath(downloadPath);
    }

    flickableContent: ColumnLayout {
        id: manageAccountEnableColumnLayout
        anchors.left: parent.left
        anchors.leftMargin: JamiTheme.preferredSettingsMarginSize
        spacing: JamiTheme.settingsBlockSpacing
        width: contentFlickableWidth

        ColumnLayout {
            id: enableAccount
            width: parent.width

            FolderDialog {
                id: downloadPathDialog
                currentFolder: StandardPaths.writableLocation(StandardPaths.DownloadLocation)
                options: FolderDialog.ShowDirsOnly
                title: JamiStrings.selectFolder

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
                checked: UtilsAdapter.getAppValue(Settings.EnableNotifications)
                labelText: JamiStrings.showNotifications
                tooltipText: JamiStrings.enableNotifications

                onSwitchToggled: UtilsAdapter.setAppValue(Settings.Key.EnableNotifications, checked)
            }
            ToggleSwitch {
                id: closeOrMinCheckBox
                Layout.fillWidth: true
                checked: UtilsAdapter.getAppValue(Settings.MinimizeOnClose)
                labelText: JamiStrings.keepMinimized

                onSwitchToggled: UtilsAdapter.setAppValue(Settings.Key.MinimizeOnClose, checked)
            }
            ToggleSwitch {
                id: applicationOnStartUpCheckBox
                Layout.fillWidth: true
                checked: UtilsAdapter.checkStartupLink()
                labelText: JamiStrings.runStartup
                tooltipText: JamiStrings.tipRunStartup

                onSwitchToggled: UtilsAdapter.setRunOnStartUp(checked)
            }
            RowLayout {
                Layout.fillWidth: true
                Layout.minimumHeight: JamiTheme.preferredFieldHeight

                Text {
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    Layout.rightMargin: JamiTheme.preferredMarginSize
                    color: JamiTheme.textColor
                    font.kerning: true
                    font.pointSize: JamiTheme.settingsFontSize
                    horizontalAlignment: Text.AlignLeft
                    text: JamiStrings.downloadFolder
                    verticalAlignment: Text.AlignVCenter
                    wrapMode: Text.WordWrap
                }
                MaterialButton {
                    id: downloadButton
                    Layout.alignment: Qt.AlignRight
                    buttontextHeightMargin: JamiTheme.buttontextHeightMargin
                    preferredWidth: itemWidth
                    secondary: true
                    text: downloadPathBestName
                    textLeftPadding: JamiTheme.buttontextWizzardPadding
                    textRightPadding: JamiTheme.buttontextWizzardPadding
                    toolTipText: downloadPath

                    onClicked: downloadPathDialog.open()
                }
            }
            SettingsComboBox {
                id: langComboBoxSetting
                Layout.fillWidth: true
                Layout.preferredHeight: JamiTheme.preferredFieldHeight
                labelText: JamiStrings.language
                role: "textDisplay"
                tipText: JamiStrings.language
                widthOfComboBox: itemWidth

                onActivated: {
                    UtilsAdapter.setAppValue(Settings.Key.LANG, comboModel.get(modelIndex).id);
                }

                comboModel: ListModel {
                    id: langModel
                    Component.onCompleted: {
                        var supported = UtilsAdapter.supportedLang();
                        var keys = Object.keys(supported);
                        var currentKey = UtilsAdapter.getAppValue(Settings.Key.LANG);
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
            }
            Connections {
                target: UtilsAdapter

                function onChangeLanguage() {
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
            }
        }
        ColumnLayout {
            spacing: JamiTheme.settingsCategorySpacing
            width: parent.width

            Text {
                id: experimentalTitle
                Layout.alignment: Qt.AlignLeft
                Layout.preferredWidth: parent.width
                color: JamiTheme.textColor
                font.kerning: true
                font.pixelSize: JamiTheme.settingsTitlePixelSize
                horizontalAlignment: Text.AlignLeft
                text: JamiStrings.experimental
                verticalAlignment: Text.AlignVCenter
                wrapMode: Text.WordWrap
            }
            ToggleSwitch {
                id: checkboxCallSwarm
                Layout.fillWidth: true
                checked: UtilsAdapter.getAppValue(Settings.EnableExperimentalSwarm)
                labelText: JamiStrings.experimentalCallSwarm
                tooltipText: JamiStrings.experimentalCallSwarmTooltip

                onSwitchToggled: {
                    UtilsAdapter.setAppValue(Settings.Key.EnableExperimentalSwarm, checked);
                }
            }
        }
        MaterialButton {
            id: defaultSettings
            preferredWidth: textSize.width + 2 * JamiTheme.buttontextWizzardPadding
            secondary: true
            text: JamiStrings.defaultSettings

            onClicked: {
                notificationCheckBox.checked = UtilsAdapter.getDefault(Settings.Key.EnableNotifications);
                closeOrMinCheckBox.checked = UtilsAdapter.getDefault(Settings.Key.MinimizeOnClose);
                checkboxCallSwarm.checked = UtilsAdapter.getDefault(Settings.Key.EnableExperimentalSwarm);
                langComboBoxSetting.modelIndex = 0;
                UtilsAdapter.setToDefault(Settings.Key.EnableNotifications);
                UtilsAdapter.setToDefault(Settings.Key.MinimizeOnClose);
                UtilsAdapter.setToDefault(Settings.Key.LANG);
                UtilsAdapter.setToDefault(Settings.Key.EnableExperimentalSwarm);
            }

            TextMetrics {
                id: textSize
                font.capitalization: Font.AllUppercase
                font.pixelSize: JamiTheme.wizardViewButtonFontPixelSize
                font.weight: Font.Bold
                text: defaultSettings.text
            }
        }
    }
}
