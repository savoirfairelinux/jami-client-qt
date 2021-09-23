/*
 * Copyright (C) 2020 by Savoir-faire Linux
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

import QtQuick 2.14
import QtQuick.Layouts 1.14
import QtQuick.Controls 2.14
import QtQuick.Controls.Universal 2.14
import QtGraphicalEffects 1.14
import Qt.labs.platform 1.1

import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1

import "../../commoncomponents"

ColumnLayout {
    id: root

    property string accountId: LRCInstance.currentAccountId

    property int itemWidth
    property alias settingsVisible: pluginSettingsView.visible
    signal showAccountPluginSettingsRequest

    onVisibleChanged: {
        if (visible)
            installedPluginsModel.reset()
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.bottomMargin: 8

        Text {
            Layout.fillWidth: true
            Layout.preferredHeight: JamiTheme.preferredFieldHeight

            font.pointSize: JamiTheme.headerFontSize
            font.kerning: true

            horizontalAlignment: Text.AlignLeft
            verticalAlignment: Text.AlignVCenter
            color: JamiTheme.textColor

            text: qsTr("Account Plugins Settings")
            elide: Text.ElideRight
        }

        PushButton {
            Layout.preferredWidth: JamiTheme.preferredFieldHeight
            Layout.preferredHeight: JamiTheme.preferredFieldHeight
            Layout.alignment: Qt.AlignHCenter

            imageColor: JamiTheme.textColor
            toolTipText: JamiStrings.tipAccountPluginSettingsDisplay

            preferredSize: 32
            source: pluginSettingsView.visible ?
                        JamiResources.expand_less_24dp_svg :
                        JamiResources.expand_more_24dp_svg

            onClicked: {
                pluginSettingsView.visible = !pluginSettingsView.visible
                showAccountPluginSettingsRequest()
            }
        }
    }

    ListView {
        id: pluginSettingsView

        Layout.fillWidth: true
        Layout.minimumHeight: 0
        Layout.preferredHeight: childrenRect.height
        Layout.bottomMargin: 10
        visible: false

        model: PluginListModel {
            id: installedPluginsModel

            lrcInstance: LRCInstance
            filterAccount: true
            onLrcInstanceChanged: {
                this.reset()
            }
        }

        maximumFlickVelocity: 1024

        delegate: PluginItemDelegate {
            id: pluginItemDelegate

            width: pluginSettingsView.width
            implicitHeight: 40

            pluginName: PluginName
            pluginId: PluginId
            pluginIcon: PluginIcon
            isLoaded: IsLoaded
            accountId: LRCInstance.currentAccountId

            background: Rectangle {
                anchors.fill: parent
                color: "transparent"
            }
        }
    }
}
