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

import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1

import "../commoncomponents"
import "../settingsview/components"

ItemDelegate {
    id: root

    property string preferenceName: ""
    property string preferenceSummary: ""
    property string preferenceKey: ""
    property int preferenceType: -1
    property string preferenceCurrentValue: ""
    property string preferenceNewValue: ""
    property string pluginId: ""
    property string currentPath: ""
    property bool isImage: false
    property var fileFilters: []
    property PluginListPreferenceModel pluginListPreferenceModel

    signal btnPreferenceClicked

    function getNewPreferenceValueSlot(index) {
        switch (preferenceType) {
            case PreferenceItemListModel.LIST:
                pluginListPreferenceModel.idx = index
                preferenceNewValue = pluginListPreferenceModel.preferenceNewValue
                btnPreferenceClicked()
                break
            case PreferenceItemListModel.PATH:
                if (index === 0) {
                    preferenceFilePathDialog.title = JamiStrings.selectAnImage.arg(preferenceName)
                    preferenceFilePathDialog.nameFilters = fileFilters
                    preferenceFilePathDialog.selectedNameFilter.index = fileFilters.length - 1
                    preferenceFilePathDialog.open()
                }
                else
                    btnPreferenceClicked()
                break
            case PreferenceItemListModel.EDITTEXT:
                preferenceNewValue = editTextPreference.text
                btnPreferenceClicked()
                break
            case PreferenceItemListModel.SWITCH:
                preferenceNewValue = index ? "1" : "0"
                btnPreferenceClicked()
                break
            default:
                break
        }
    }

    JamiFileDialog {
        id: preferenceFilePathDialog

        title: JamiStrings.selectFile
        folder: JamiQmlUtils.qmlFilePrefix + currentPath

        onAccepted: {
            var url = UtilsAdapter.getAbsPath(file.toString())
            preferenceNewValue = url
            btnPreferenceClicked()
        }
    }

    RowLayout{
        anchors.fill: parent

        Text {
            id: prefLlabel
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
            Layout.leftMargin: 8

            text: preferenceName
            color: JamiTheme.textColor
            elide: Text.ElideRight
            font.pointSize: JamiTheme.settingsFontSize
            ToolTip.visible: hovered && preferenceSummary
            ToolTip.text: preferenceSummary
            opacity: enabled ? 1.0 : 0.5
        }

        PushButton {
            id: btnPreferenceDefault

            visible: preferenceType === PreferenceItemListModel.DEFAULT
            normalColor: JamiTheme.primaryBackgroundColor

            Layout.alignment: Qt.AlignRight | Qt.AlingVCenter
            Layout.rightMargin: 8
            Layout.preferredWidth: preferredSize
            Layout.preferredHeight: preferredSize
            imageColor: JamiTheme.textColor

            source: JamiResources.round_settings_24dp_svg

            toolTipText: JamiStrings.editPreference
            opacity: enabled ? 1.0 : 0.5
        }

        ToggleSwitch {
            id: btnPreferenceSwitch

            visible: preferenceType === PreferenceItemListModel.SWITCH
            Layout.alignment: Qt.AlignRight | Qt.AlingVCenter
            Layout.rightMargin: 16
            Layout.preferredHeight: 30
            Layout.preferredWidth: 30
            checked: preferenceCurrentValue === "1"

            onSwitchToggled: getNewPreferenceValueSlot(checked)
            opacity: enabled ? 1.0 : 0.5
        }

        SettingParaCombobox {
            id: listPreferenceComboBox

            visible: preferenceType === PreferenceItemListModel.LIST
            Layout.preferredWidth: root.width / 2 - 8
            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
            Layout.rightMargin: 4

            font.pointSize: JamiTheme.settingsFontSize
            font.kerning: true

            model: pluginListPreferenceModel
            currentIndex: pluginListPreferenceModel.getCurrentSettingIndex()
            textRole: "PreferenceValue"
            tooltipText: JamiStrings.select
            onActivated: getNewPreferenceValueSlot(index)
            opacity: enabled ? 1.0 : 0.5
            comboBoxBackgroundColor: JamiTheme.comboBoxBackgroundColor
        }

        MaterialButton {
            id: pathPreferenceButton

            visible: preferenceType === PreferenceItemListModel.PATH

            preferredWidth: root.width / 2 - 8
            preferredHeight: 30

            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
            Layout.rightMargin: 4

            text: UtilsAdapter.fileName(preferenceCurrentValue)
            toolTipText: JamiStrings.chooseImageFile
            iconSource: JamiResources.round_folder_24dp_svg
            color: JamiTheme.buttonTintedGrey
            hoveredColor: JamiTheme.buttonTintedGreyHovered
            pressedColor: JamiTheme.buttonTintedGreyPressed

            onClicked: getNewPreferenceValueSlot(0)
            opacity: enabled ? 1.0 : 0.5
        }

        MaterialLineEdit {
            id: editTextPreference

            Layout.preferredWidth: root.width / 2 - 8
            Layout.preferredHeight: 30
            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
            Layout.rightMargin: 4

            visible: preferenceType === PreferenceItemListModel.EDITTEXT
            width: root.width / 2 - 8
            padding: 8

            selectByMouse: true
            text: preferenceCurrentValue

            font.pointSize: JamiTheme.settingsFontSize
            wrapMode: Text.NoWrap
            loseFocusWhenEnterPressed: true

            onEditingFinished: getNewPreferenceValueSlot(0)
            opacity: enabled ? 1.0 : 0.5
        }
    }
}
