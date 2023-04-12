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
import net.jami.Constants 1.1
import "."
import "../settingsview/components"

ItemDelegate {
    id: root
    property string currentPath: ""
    property var fileFilters: []
    property bool isImage: false
    property string pluginId: ""
    property PluginListPreferenceModel pluginListPreferenceModel
    property string preferenceCurrentValue: ""
    property string preferenceKey: ""
    property string preferenceName: ""
    property string preferenceNewValue: ""
    property string preferenceSummary: ""
    property int preferenceType: -1

    signal btnPreferenceClicked
    function getNewPreferenceValueSlot(index) {
        switch (preferenceType) {
        case PreferenceItemListModel.LIST:
            pluginListPreferenceModel.idx = index;
            preferenceNewValue = pluginListPreferenceModel.preferenceNewValue;
            btnPreferenceClicked();
            break;
        case PreferenceItemListModel.PATH:
            if (index === 0) {
                var dlg = viewCoordinator.presentDialog(appWindow, "commoncomponents/JamiFileDialog.qml", {
                        "title": JamiStrings.selectAnImage.arg(preferenceName),
                        "fileMode": JamiFileDialog.OpenFile,
                        "folder": JamiQmlUtils.qmlFilePrefix + currentPath,
                        "nameFilters": fileFilters
                    });
                dlg.fileAccepted.connect(function (file) {
                        var url = UtilsAdapter.getAbsPath(file.toString());
                        preferenceNewValue = url;
                        btnPreferenceClicked();
                    });
            } else
                btnPreferenceClicked();
            break;
        case PreferenceItemListModel.EDITTEXT:
            preferenceNewValue = editTextPreference.text;
            btnPreferenceClicked();
            break;
        case PreferenceItemListModel.SWITCH:
            preferenceNewValue = index ? "1" : "0";
            btnPreferenceClicked();
            break;
        default:
            break;
        }
    }

    RowLayout {
        anchors.fill: parent

        Text {
            id: prefLlabel
            Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
            Layout.fillWidth: true
            Layout.leftMargin: 8
            ToolTip.text: preferenceSummary
            ToolTip.visible: hovered && preferenceSummary
            color: JamiTheme.textColor
            elide: Text.ElideRight
            font.pointSize: JamiTheme.settingsFontSize
            opacity: enabled ? 1.0 : 0.5
            text: preferenceName
        }
        PushButton {
            id: btnPreferenceDefault
            Layout.alignment: Qt.AlignRight | Qt.AlingVCenter
            Layout.preferredHeight: preferredSize
            Layout.preferredWidth: preferredSize
            Layout.rightMargin: 8
            imageColor: JamiTheme.textColor
            normalColor: JamiTheme.primaryBackgroundColor
            opacity: enabled ? 1.0 : 0.5
            source: JamiResources.round_settings_24dp_svg
            toolTipText: JamiStrings.editPreference
            visible: preferenceType === PreferenceItemListModel.DEFAULT
        }
        ToggleSwitch {
            id: btnPreferenceSwitch
            Layout.alignment: Qt.AlignRight | Qt.AlingVCenter
            Layout.preferredHeight: 30
            Layout.preferredWidth: 30
            Layout.rightMargin: 16
            checked: preferenceCurrentValue === "1"
            opacity: enabled ? 1.0 : 0.5
            visible: preferenceType === PreferenceItemListModel.SWITCH

            onSwitchToggled: getNewPreferenceValueSlot(checked)
        }
        SettingParaCombobox {
            id: listPreferenceComboBox
            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
            Layout.preferredWidth: root.width / 2 - 8
            Layout.rightMargin: 4
            comboBoxBackgroundColor: JamiTheme.comboBoxBackgroundColor
            currentIndex: pluginListPreferenceModel.getCurrentSettingIndex()
            font.kerning: true
            font.pointSize: JamiTheme.settingsFontSize
            model: pluginListPreferenceModel
            opacity: enabled ? 1.0 : 0.5
            textRole: "PreferenceValue"
            tooltipText: JamiStrings.select
            visible: preferenceType === PreferenceItemListModel.LIST

            onActivated: getNewPreferenceValueSlot(index)
        }
        MaterialButton {
            id: pathPreferenceButton
            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
            Layout.rightMargin: 4
            buttontextHeightMargin: JamiTheme.buttontextHeightMargin
            color: JamiTheme.buttonTintedGrey
            hoveredColor: JamiTheme.buttonTintedGreyHovered
            iconSource: JamiResources.round_folder_24dp_svg
            opacity: enabled ? 1.0 : 0.5
            preferredWidth: root.width / 2 - 8
            pressedColor: JamiTheme.buttonTintedGreyPressed
            text: UtilsAdapter.fileName(preferenceCurrentValue)
            toolTipText: JamiStrings.chooseImageFile
            visible: preferenceType === PreferenceItemListModel.PATH

            onClicked: getNewPreferenceValueSlot(0)
        }
        MaterialLineEdit {
            id: editTextPreference
            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
            Layout.preferredHeight: 30
            Layout.preferredWidth: root.width / 2 - 8
            Layout.rightMargin: 4
            font.pointSize: JamiTheme.settingsFontSize
            loseFocusWhenEnterPressed: true
            opacity: enabled ? 1.0 : 0.5
            padding: 8
            selectByMouse: true
            text: preferenceCurrentValue
            visible: preferenceType === PreferenceItemListModel.EDITTEXT
            width: root.width / 2 - 8
            wrapMode: Text.NoWrap

            onEditingFinished: getNewPreferenceValueSlot(0)
        }
    }
}
