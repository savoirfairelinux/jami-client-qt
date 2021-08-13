/*
 * Copyright (C) 2020 by Savoir-faire Linux
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

import QtQuick 2.14
import QtQuick.Controls 2.14
import QtQuick.Controls.Universal 2.14
import QtQuick.Layouts 1.14
import Qt.labs.platform 1.1
import QtGraphicalEffects 1.14

import net.jami.Adapters 1.0
import net.jami.Models 1.0
import net.jami.Constants 1.0

import "../../commoncomponents"

Rectangle {
    id: root

    property int contentWidth: pluginSettingsColumnLayout.width
    property int preferredHeight: pluginSettingsColumnLayout.implicitHeight

    color: JamiTheme.secondaryBackgroundColor

    ColumnLayout {
        id: pluginSettingsColumnLayout

        anchors.horizontalCenter: root.horizontalCenter

        width: Math.min(JamiTheme.maximumWidthSettingsView, root.width)

        ToggleSwitch {
            id: enabledplugin

            signal hidePreferences
            checked: PluginAdapter.isEnabled

            Layout.alignment: Qt.AlignTop | Qt.AlignHCenter
            Layout.fillWidth: true
            Layout.topMargin: JamiTheme.preferredMarginSize
            Layout.leftMargin: JamiTheme.preferredMarginSize
            Layout.rightMargin: JamiTheme.preferredMarginSize

            labelText: JamiStrings.enable
            fontPointSize: JamiTheme.headerFontSize

            onSwitchToggled: {
                console.log (PluginAdapter.isEnabled, checked)
                PluginAdapter.isEnabled = checked
                console.log (PluginAdapter.isEnabled, checked)

                pluginListSettingsView.visible = checked
                if (!pluginListSettingsView.visible) {
                    hidePreferences()
                }
            }
        }

        PluginListSettingsView {
            id: pluginListSettingsView

            visible: PluginAdapter.isEnabled

            Layout.alignment: Qt.AlignTop | Qt.AlignHCenter
            Layout.fillWidth: true
            Layout.leftMargin: JamiTheme.preferredMarginSize
            Layout.rightMargin: JamiTheme.preferredMarginSize

            Layout.topMargin: JamiTheme.preferredMarginSize
            Layout.minimumHeight: 0
            Layout.preferredHeight: childrenRect.height
        }
    }
}
