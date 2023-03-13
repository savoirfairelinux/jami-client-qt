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

Rectangle {
    id: root

    property int contentWidth: manageAccountEnableColumnLayout.width
    property int preferredHeight: manageAccountEnableColumnLayout.implicitHeight
    property int preferredWidth: Math.min(JamiTheme.maximumWidthSettingsView , root.width - JamiTheme.preferredMarginSize*4)
    property string downloadPath: UtilsAdapter.getDirDownload()
    property int itemWidth: 150

    property bool isSIP

    signal navigateToMainView
    signal navigateToNewWizardView

    color: JamiTheme.secondaryBackgroundColor

    onDownloadPathChanged: {
        if(downloadPath === "") return
        UtilsAdapter.setDownloadPath(downloadPath)
    }

    ColumnLayout {

        id: manageAccountEnableColumnLayout
        anchors.left: root.left
        width: Math.min(JamiTheme.maximumWidthSettingsView, root.width)
        spacing: JamiTheme.wizardViewPageBackButtonMargins *2
        anchors.topMargin: JamiTheme.wizardViewPageBackButtonSize

        ColumnLayout {
            id: enableAccount

            Layout.topMargin: JamiTheme.wizardViewPageBackButtonMargins

            width: preferredWidth
            spacing: 15

            FolderDialog {
                id: downloadPathDialog

                title: JamiStrings.selectFolder
                currentFolder: StandardPaths.writableLocation(StandardPaths.DownloadLocation)
                options: FolderDialog.ShowDirsOnly

                onAccepted: {
                    var dir = UtilsAdapter.getAbsPath(folder.toString())
                    downloadPath = dir
                }

            }

            ToggleSwitch {
                id: notificationCheckBox
                Layout.fillWidth: true

                checked: UtilsAdapter.getAppValue(Settings.EnableNotifications)

                labelText: JamiStrings.showNotifications
                fontPointSize: JamiTheme.settingsFontSize

                tooltipText: JamiStrings.enableNotifications

                onSwitchToggled: UtilsAdapter.setAppValue(Settings.Key.EnableNotifications, checked)
            }

            ToggleSwitch {
                id: closeOrMinCheckBox
                Layout.fillWidth: true
                checked: UtilsAdapter.getAppValue(Settings.MinimizeOnClose)

                labelText: JamiStrings.keepMinimized
                fontPointSize: JamiTheme.settingsFontSize

                onSwitchToggled: UtilsAdapter.setAppValue(Settings.Key.MinimizeOnClose, checked)
            }

            ToggleSwitch {
                id: applicationOnStartUpCheckBox
                Layout.fillWidth: true

                checked: UtilsAdapter.checkStartupLink()

                labelText: JamiStrings.runStartup
                fontPointSize: JamiTheme.settingsFontSize

                tooltipText: JamiStrings.tipRunStartup

                onSwitchToggled: UtilsAdapter.setRunOnStartUp(checked)
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: JamiTheme.preferredFieldHeight

                Label {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

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
                    preferredHeight: JamiTheme.preferredFieldHeight

                    toolTipText: JamiStrings.tipChooseDownloadFolder
                    text: downloadPath
                    iconSource: JamiResources.round_folder_24dp_svg
                    color: JamiTheme.buttonTintedGrey
                    hoveredColor: JamiTheme.buttonTintedGreyHovered
                    pressedColor: JamiTheme.buttonTintedGreyPressed

                    onClicked: downloadPathDialog.open()
                }
            }

            SettingsComboBox {
                id: langComboBoxSetting

                Layout.fillWidth: true
                Layout.preferredHeight: JamiTheme.preferredFieldHeight

                labelText: JamiStrings.language
                tipText: JamiStrings.language
                fontPointSize: JamiTheme.settingsFontSize
                comboModel: ListModel {
                    id: langModel
                    Component.onCompleted: {
                        var supported = UtilsAdapter.supportedLang();
                        var keys = Object.keys(supported);
                        var currentKey = UtilsAdapter.getAppValue(Settings.Key.LANG);
                        for (var i = 0 ; i < keys.length ; ++i) {
                            append({ textDisplay: supported[keys[i]], id: keys[i] })
                            if (keys[i] === currentKey)
                                langComboBoxSetting.modelIndex = i
                        }
                    }
                }
                widthOfComboBox: itemWidth
                role: "textDisplay"

                onActivated: {
                    UtilsAdapter.setAppValue(Settings.Key.LANG, comboModel.get(modelIndex).id)
                }
            }

            Connections {
                target: UtilsAdapter

                function onChangeLanguage() {
                    var idx = themeComboBoxSettings.modelIndex
                    themeModel.clear()
                    if (themeComboBoxSettings.nativeDarkThemeShift)
                        themeModel.append({ textDisplay: JamiStrings.system })
                    themeModel.append({ textDisplay: JamiStrings.light })
                    themeModel.append({ textDisplay: JamiStrings.dark })
                    themeComboBoxSettings.modelIndex = idx

                    var langIdx = langComboBoxSetting.modelIndex
                    langModel.clear()
                    var supported = UtilsAdapter.supportedLang();
                    var keys = Object.keys(supported);
                    for (var i = 0 ; i < keys.length ; ++i) {
                        langModel.append({ textDisplay: supported[keys[i]], id: keys[i] })
                    }
                    langComboBoxSetting.modelIndex = langIdx
                }
            }


        }

        ColumnLayout {

            width: preferredWidth
            spacing: 15

            Text {
                id: experimentalTitle

                Layout.alignment: Qt.AlignLeft
                Layout.preferredWidth: Math.min(350, root.width - JamiTheme.preferredMarginSize * 2)

                text: JamiStrings.experimental
                color: JamiTheme.textColor
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
                wrapMode : Text.WordWrap

                font.pixelSize: 22
                font.kerning: true

            }

            ToggleSwitch {
                id: checkboxCallSwarm
                Layout.fillWidth: true
                checked: UtilsAdapter.getAppValue(Settings.EnableExperimentalSwarm)
                labelText: JamiStrings.experimentalCallSwarm
                fontPointSize: JamiTheme.settingsFontSize
                tooltipText: JamiStrings.experimentalCallSwarmTooltip
                onSwitchToggled: {
                    UtilsAdapter.setAppValue(Settings.Key.EnableExperimentalSwarm, checked)
                }
            }


        }


    }
}
