/*
 * Copyright (C) 2020-2022 Savoir-faire Linux Inc.
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

    ToggleSwitch {
        id: darkThemeCheckBox
        Layout.fillWidth: true
        Layout.leftMargin: JamiTheme.preferredMarginSize

        checked: UtilsAdapter.getAppValue(Settings.EnableDarkTheme)

        labelText: JamiStrings.enableDarkTheme
        fontPointSize: JamiTheme.settingsFontSize

        tooltipText: JamiStrings.enableDarkTheme

        onSwitchToggled: {
            JamiTheme.setTheme(checked)
            UtilsAdapter.setAppValue(Settings.Key.EnableDarkTheme, checked)
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
        fontPointSize: JamiTheme.settingsFontSize
        comboModel: ListModel {
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
    }

    SettingSpinBox {
        id: zoomSpinBox
        Layout.fillWidth: true
        Layout.leftMargin: JamiTheme.preferredMarginSize

        title: JamiStrings.textZoom
        itemWidth: root.itemWidth

        valueField: Math.round(UtilsAdapter.getAppValue(Settings.BaseZoom) * 100.0)

        onNewValue: {
            // here, avoid validator cause it can be painful for the user to change
            // values by modifying the whole field.
            if (valueField < 10)
                valueField = 10
            else if (valueField > 200)
                valueField = 200
            UtilsAdapter.setAppValue(Settings.BaseZoom, Math.round(valueField / 100.0))
        }
    }
}
