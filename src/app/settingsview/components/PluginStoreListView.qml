/*
 * Copyright (C) 2023 Savoir-faire Linux Inc.
 * Author: Xavier Jouslin de Noray  <xjouslindenoray@savoirfairelinux.com>
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
import "../../commoncomponents"

ColumnLayout {
    property bool storeAvailable: true
    Component.onCompleted: {
        PluginAdapter.getPluginsFromStore();
    }
    Connections {
        target: PluginAdapter
        function onStoreNotAvailable() {
            storeAvailable = false;
        }
    }
    Label {
        Layout.fillWidth: true
        Layout.bottomMargin: 20
        text: JamiStrings.pluginStoreTitle
        font.pixelSize: JamiTheme.settingsTitlePixelSize
        font.kerning: true
        color: JamiTheme.textColor
        horizontalAlignment: Text.AlignLeft
        verticalAlignment: Text.AlignVCenter
    }
    Loader {
        active: storeAvailable
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignHCenter
        Layout.preferredHeight: active ? item.height : 0
        sourceComponent: Flow {
            id: pluginStoreList
            height: childrenRect.height
            spacing: 20
            Repeater {
                model: PluginStoreListModel

                delegate: PluginAvailableDelagate {
                    id: pluginItemDelegate
                    width: JamiTheme.remotePluginWidthDelegate
                    height: JamiTheme.remotePluginHeightDelegate
                    pluginName: Name
                    pluginIcon: IconPath
                    pluginDescription: Description
                    pluginAuthor: Author
                    pluginShortDescription: ""
                    pluginStatus: Status
                }
            }
        }
    }
    Loader {
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
        Layout.preferredHeight: active ? JamiTheme.bigFontSize : 0
        active: !storeAvailable
        sourceComponent: Text {
            font.bold: true
            color: JamiTheme.textColor
            font.pixelSize: JamiTheme.bigFontSize
            horizontalAlignment: Text.AlignHCenter
            text: JamiStrings.pluginStoreNotAvailable
        }
    }
}
