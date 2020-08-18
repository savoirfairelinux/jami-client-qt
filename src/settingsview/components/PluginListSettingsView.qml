/**
 * Copyright (C) 2019-2020 by Savoir-faire Linux
 * Author: Aline Gondim Sanots  <aline.gondimsantos@savoirfairelinux.com>
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
import QtQuick.Window 2.14
import QtQuick.Controls 2.14
import QtQuick.Controls.Universal 2.12
import QtQuick.Layouts 1.3
import Qt.labs.platform 1.1
import QtGraphicalEffects 1.14
import net.jami.Models 1.0
import "../../commoncomponents"

Rectangle {
    id: pluginListSettingsViewRect

    property PluginListPreferencesView pluginListPreferencesView
    property int size: 0
    visible: false
    signal scrollView

    function updatePluginListDisplayed() {
        // settings
        updateAndShowPluginsSlot()
    }

    function openPluginFileSlot(){
        pluginPathDialog.open()
    }

    function updateAndShowPluginsSlot()
    {
        getSize()
        pluginItemListModel.reset()
    }

    function loadPluginSlot(pluginId, isLoaded){
        var loaded = false
        if (isLoaded)
            ClientWrapper.pluginModel.unloadPlugin(pluginId)
        else
            loaded = ClientWrapper.pluginModel.loadPlugin(pluginId)
        if(pluginListPreferencesView.pluginId === pluginId)
            pluginListPreferencesView.isLoaded = loaded
        updateAndShowPluginsSlot()
    }

    function openPreferencesPluginSlot(pluginName, pluginIcon, pluginId, isLoaded){
        updateAndShowPluginPreferenceSlot(pluginName, pluginIcon, pluginId, isLoaded)
    }

    function updateAndShowPluginPreferenceSlot(pluginName, pluginIcon, pluginId, isLoaded){
        pluginListPreferencesView.pluginName = pluginName
        pluginListPreferencesView.pluginIcon = pluginIcon
        if (pluginListPreferencesView.pluginId == pluginId || pluginListPreferencesView.pluginId == "")
            pluginListPreferencesView.visible = !pluginListPreferencesView.visible
        pluginListPreferencesView.pluginId = pluginId
        pluginListPreferencesView.isLoaded = isLoaded
        pluginListPreferencesView.updatePreferenceListDisplayed()
    }

    function getSize()
    {
        size = 50 * pluginItemListModel.numPlugins
        pluginListPreferencesView.Layout.topMargin =  100 + 50 * pluginItemListModel.numPlugins 
        if (visible) {
            pluginListView.height = size + 15
            pluginListPreferencesView.Layout.minimunHeight = 150 + size
        } else {
            height = 15
            pluginListView.height = 0
        }
    }

    JamiFileDialog {
        id: pluginPathDialog

        mode: JamiFileDialog.OpenFile
        title: qsTr("Select A Plugin to Install")
        folder: StandardPaths.writableLocation(StandardPaths.DownloadLocation)

        nameFilters: [qsTr("Plugin Files") + " (*.jpl)", qsTr(
                "All files") + " (*)"]

        onRejected: {}

        onVisibleChanged: {
            if (!visible) {
                rejected()
            }
        }

        onAccepted: {
            var url = ClientWrapper.utilsAdaptor.getAbsPath(file.toString())
            ClientWrapper.pluginModel.installPlugin(url, true)
            updateAndShowPluginsSlot()
        }
    }

    PluginItemListModel {
        id: pluginItemListModel
    }

    Layout.fillHeight: true
    Layout.fillWidth: true

    ColumnLayout {
        id: pluginListViewLayout

        Layout.fillHeight: true
        width: parent.width

        Label {
            Layout.fillWidth: true
            Layout.minimumHeight: 25
            Layout.preferredHeight: 25
            Layout.maximumHeight: 25

            text: qsTr("Installed plugins")
            font.pointSize: JamiTheme.headerFontSize
            font.kerning: true

            horizontalAlignment: Text.AlignLeft
            verticalAlignment: Text.AlignVCenter
        }

        ColumnLayout {
            spacing: 6

            Layout.fillWidth: true
            Layout.topMargin: 6

            HoverableRadiusButton {
                id: installButton

                Layout.fillWidth: true

                Layout.minimumHeight: 30
                Layout.preferredHeight: 30
                Layout.maximumHeight: 30

                radius: height / 2

                text: qsTr("+ Install plugin")
                fontPointSize: JamiTheme.settingsFontSize
                font.kerning: true

                onClicked: {
                    openPluginFileSlot()
                }
            }

            ListViewJami {
                id: pluginListView

                border.color: "white"
                color: "white"

                Layout.fillWidth: true

                Layout.minimumHeight: 0
                Layout.preferredHeight: height
                Layout.maximumHeight: 1000

                model: pluginItemListModel

                delegate: PluginItemDelegate{
                    id: pluginItemDelegate

                    width: pluginListView.width
                    height: 50

                    pluginName : PluginName
                    pluginId: PluginId
                    pluginIcon: PluginIcon
                    isLoaded: IsLoaded

                    onClicked: {
                        pluginListView.currentIndex = index
                    }

                    onBtnLoadPluginToggled:{
                        loadPluginSlot(pluginId, isLoaded)
                    }

                    onBtnPreferencesPluginClicked:{
                        openPreferencesPluginSlot(pluginName, pluginIcon, pluginId, isLoaded)
                    }
                }
            }
        }
    }
}
 