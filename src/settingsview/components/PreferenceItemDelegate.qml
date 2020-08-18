/*
 * Copyright (C) 2019-2020 by Savoir-faire Linux
 * Author: Yang Wang   <yang.wang@savoirfairelinux.com>
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

import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Universal 2.12
import QtQuick.Layouts 1.3
import QtGraphicalEffects 1.14
import QtQuick.Controls.Styles 1.4
import net.jami.Models 1.0

import "../../commoncomponents"

ItemDelegate {
    id: preferenceItemDelegate

    enum Type {
        LIST,
        USERLIST,
        DEFAULT
    }

    property string preferenceName: ""
    property string preferenceSummary: ""
    property int preferenceType: -1
    property string preferenceCurrentValue: ""
    property string preferenceNewValue: ""
    property string pluginId: ""
    property PluginListPreferenceModel pluginListPreferenceModel

    signal btnPreferenceClicked

    function getNewPreferenceValueSlot(index)
    {
        pluginListPreferenceModel.idx = index
        preferenceNewValue = pluginListPreferenceModel.preferenceNewValue
        btnPreferenceClicked()
    }

    RowLayout{
        anchors.fill: parent

        ColumnLayout{
            visible: preferenceType === PreferenceItemDelegate.DEFAULT
            Layout.fillWidth: true
            Layout.fillHeight: true

            Layout.topMargin: 7
            Layout.bottomMargin: 7
            Layout.leftMargin: 7

            Layout.minimumHeight: 30

            Label{
                Layout.minimumHeight: 10
                width: 320 - 36

                font.pointSize: 10
                font.kerning: true
                font.bold: true
                text: preferenceName
            }
        }

        HoverableRadiusButton{
            id: btnPreference
            visible: preferenceType === PreferenceItemDelegate.DEFAULT
            backgroundColor: "white"

            Layout.alignment: Qt.AlignRight
            Layout.rightMargin: 7

            Layout.minimumWidth: 30
            Layout.preferredWidth: 30
            Layout.maximumWidth: 30

            Layout.minimumHeight: 30
            Layout.preferredHeight: 30
            Layout.maximumHeight: 30

            buttonImageHeight: 20
            buttonImageWidth: 20

            source:{
                return "qrc:/images/icons/round-settings-24px.svg"
            }

            ToolTip.visible: hovered
            ToolTip.text: {
                return qsTr("Edit preference")
            }

            onClicked: {
                btnPreferenceClicked()
            }
        }

        ElidedTextLabel {
            visible: preferenceType === PreferenceItemDelegate.LIST
            Layout.fillWidth: true

            eText: preferenceName
            fontSize: JamiTheme.settingsFontSize
        }


        SettingParaCombobox {
            id: preferenceComboBox
            visible: preferenceType === PreferenceItemDelegate.LIST

            font.pointSize: JamiTheme.settingsFontSize
            font.kerning: true

            model: pluginListPreferenceModel
            textRole: qsTr("PreferenceValue")
            tooltipText: qsTr("Choose the preference")
            onActivated: {
                getNewPreferenceValueSlot(index)
            }
        }
    }
}
