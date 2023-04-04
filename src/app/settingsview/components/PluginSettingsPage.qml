/*
 * Copyright (C) 2020-2023 Savoir-faire Linux Inc.
 * Author: Aline Gondim Santos  <aline.gondimsantos@savoirfairelinux.com>
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

import net.jami.Adapters 1.1
import net.jami.Models 1.1
import net.jami.Constants 1.1

import "../../commoncomponents"

SettingsPageBase {
    id: root

    title: JamiStrings.pluginSettingsTitle


    flickableContent: ColumnLayout {
        id: pluginSettingsColumnLayout

        width: contentFlickableWidth
        spacing: JamiTheme.settingsBlockSpacing
        anchors.left: parent.left
        anchors.leftMargin: JamiTheme.preferredSettingsMarginSize


        ColumnLayout {
            id: generalSettings

            width: parent.width
            spacing: JamiTheme.settingsCategorySpacing

            ToggleSwitch {
                id: enabledplugin

                checked: PluginAdapter.isEnabled
                Layout.alignment: Qt.AlignTop | Qt.AlignHCenter
                Layout.fillWidth: true
                labelText: JamiStrings.enable

                onSwitchToggled: {
                    PluginModel.setPluginsEnabled(checked)
                    PluginAdapter.isEnabled = checked
                }
            }

            PluginListView {
                id: pluginListView

                visible: PluginAdapter.isEnabled

                Layout.alignment: Qt.AlignTop | Qt.AlignHCenter
                Layout.preferredWidth: parent.width
                Layout.minimumHeight: 0
                Layout.preferredHeight: childrenRect.height
            }
        }
    }
}
