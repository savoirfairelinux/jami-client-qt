/*
 * Copyright (C) 2020-2023 Savoir-faire Linux Inc.
 * Author: Aline Gondim Santos <aline.gondimsantos@savoirfairelinux.com>
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

import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Enums 1.1
import net.jami.Constants 1.1

import "../../commoncomponents"

ColumnLayout {
    id:root

    property int itemWidth
    property string downloadPath: UtilsAdapter.getDirDownload()

    onDownloadPathChanged: {
        if(downloadPath === "") return
        UtilsAdapter.setDownloadPath(downloadPath)
    }

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

    Label {
        Layout.fillWidth: true

        text: JamiStrings.system
        color: JamiTheme.textColor
        font.pointSize: JamiTheme.headerFontSize
        font.kerning: true

        horizontalAlignment: Text.AlignLeft
        verticalAlignment: Text.AlignVCenter
    }



    SettingsComboBox {
        id: themeComboBoxSettings

        Layout.fillWidth: true
        Layout.leftMargin: JamiTheme.preferredMarginSize

        property var nativeDarkThemeShift: UtilsAdapter.hasNativeDarkTheme() ? 1 : 0

        labelText: JamiStrings.applicationTheme
        fontPointSize: JamiTheme.settingsFontSize

        comboModel: ListModel {
            id: themeModel
            Component.onCompleted: {
                if (themeComboBoxSettings.nativeDarkThemeShift)
                    append({ textDisplay: JamiStrings.system })
                append({ textDisplay: JamiStrings.light })
                append({ textDisplay: JamiStrings.dark })
            }
        }
        widthOfComboBox: itemWidth
        tipText: JamiStrings.applicationTheme
        role: "textDisplay"

        modelIndex: {
            var theme = UtilsAdapter.getAppValue(Settings.Key.AppTheme)
            if (themeComboBoxSettings.nativeDarkThemeShift && theme === "System")
                return 0
            if (theme === "Light") {
                return 0 + nativeDarkThemeShift
            } else if (theme === "Dark") {
                return 1 + nativeDarkThemeShift
            }
            return nativeDarkThemeShift
        }

        onActivated: {
            if (modelIndex === 0 + nativeDarkThemeShift)
                UtilsAdapter.setAppValue(Settings.Key.AppTheme, "Light")
            else if (modelIndex === 1 + nativeDarkThemeShift)
                UtilsAdapter.setAppValue(Settings.Key.AppTheme, "Dark")
            else if (modelIndex === 0)
                UtilsAdapter.setAppValue(Settings.Key.AppTheme, "System")
        }
    }

    ToggleSwitch {
        id: notificationCheckBox
        Layout.fillWidth: true
        Layout.leftMargin: JamiTheme.preferredMarginSize

        checked: UtilsAdapter.getAppValue(Settings.EnableNotifications)

        labelText: JamiStrings.showNotifications
        fontPointSize: JamiTheme.settingsFontSize

        tooltipText: JamiStrings.enableNotifications

        onSwitchToggled: UtilsAdapter.setAppValue(Settings.Key.EnableNotifications, checked)
    }

    ToggleSwitch {
        id: closeOrMinCheckBox
        Layout.fillWidth: true
        Layout.leftMargin: JamiTheme.preferredMarginSize
        checked: UtilsAdapter.getAppValue(Settings.MinimizeOnClose)

        labelText: JamiStrings.keepMinimized
        fontPointSize: JamiTheme.settingsFontSize

        onSwitchToggled: UtilsAdapter.setAppValue(Settings.Key.MinimizeOnClose, checked)
    }

    ToggleSwitch {
        id: applicationOnStartUpCheckBox
        Layout.fillWidth: true
        Layout.leftMargin: JamiTheme.preferredMarginSize

        checked: UtilsAdapter.checkStartupLink()

        labelText: JamiStrings.runStartup
        fontPointSize: JamiTheme.settingsFontSize

        tooltipText: JamiStrings.tipRunStartup

        onSwitchToggled: UtilsAdapter.setRunOnStartUp(checked)
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.preferredHeight: JamiTheme.preferredFieldHeight
        Layout.leftMargin: JamiTheme.preferredMarginSize

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
        Layout.leftMargin: JamiTheme.preferredMarginSize

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
                    if (keys[i] == currentKey)
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

        function onChangeFontSize() {
            zoomSpinBox.valueField = Math.round(UtilsAdapter.getAppValue(Settings.BaseZoom) * 100.0)
        }

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

    SettingSpinBox {
        id: zoomSpinBox
        Layout.fillWidth: true
        Layout.leftMargin: JamiTheme.preferredMarginSize

        title: JamiStrings.textZoom
        tooltipText: JamiStrings.changeTextSize
        itemWidth: root.itemWidth

        bottomValue: 50
        topValue: 200
        step: 10

        valueField: UtilsAdapter.getAppValue(Settings.BaseZoom) * 100.0

        onNewValue: UtilsAdapter.setAppValue(Settings.BaseZoom, valueField / 100.0)
    }
}
