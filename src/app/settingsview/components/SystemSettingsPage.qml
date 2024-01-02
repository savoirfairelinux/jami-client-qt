/*
 * Copyright (C) 2024 Savoir-faire Linux Inc.
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

                checked: UtilsAdapter.getAppValue(Settings.EnableNotifications)
                labelText: JamiStrings.showNotifications
                tooltipText: JamiStrings.enableNotifications
                onSwitchToggled: UtilsAdapter.setAppValue(Settings.Key.EnableNotifications, checked)
            }

            ToggleSwitch {
                id: enableDonation
                Layout.fillWidth: true
                visible: (new Date() >= new Date(Date.parse("2023-11-01")) && !APPSTORE)

                checked: UtilsAdapter.getAppValue(Settings.Key.IsDonationVisible)
                labelText: JamiStrings.enableDonation
                tooltipText: JamiStrings.enableDonation
                onSwitchToggled: {
                    UtilsAdapter.setAppValue(Settings.Key.IsDonationVisible, checked);
                    if (checked) {
                        UtilsAdapter.setToDefault(Settings.Key.Donation2023VisibleDate);
                    }
                }
            }

            ToggleSwitch {
                id: closeOrMinCheckBox
                Layout.fillWidth: true

                visible: UtilsAdapter.isSystemTrayIconVisible()
                checked: UtilsAdapter.getAppValue(Settings.MinimizeOnClose) && UtilsAdapter.isSystemTrayIconVisible()
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

                labelText: JamiStrings.language
                tipText: JamiStrings.language
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

                widthOfComboBox: itemWidth
                role: "textDisplay"

                onActivated: {
                    UtilsAdapter.setAppValue(Settings.Key.LANG, comboModel.get(modelIndex).id);
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
                notificationCheckBox.checked = UtilsAdapter.getDefault(Settings.Key.EnableNotifications);
                closeOrMinCheckBox.checked = UtilsAdapter.getDefault(Settings.Key.MinimizeOnClose);
                checkboxCallSwarm.checked = UtilsAdapter.getDefault(Settings.Key.EnableExperimentalSwarm);
                langComboBoxSetting.modelIndex = 0;
                UtilsAdapter.setToDefault(Settings.Key.EnableNotifications);
                UtilsAdapter.setToDefault(Settings.Key.MinimizeOnClose);
                UtilsAdapter.setToDefault(Settings.Key.LANG);
                UtilsAdapter.setToDefault(Settings.Key.EnableExperimentalSwarm);
                UtilsAdapter.setToDefault(Settings.Key.IsDonationVisible);
                UtilsAdapter.setToDefault(Settings.Key.Donation2023VisibleDate);
                enableDonation.checked = Qt.binding(() => UtilsAdapter.getAppValue(Settings.Key.IsDonationVisible));
            }
        }
    }
}
