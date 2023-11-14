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
import Qt5Compat.GraphicalEffects
import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import "../../commoncomponents"

ColumnLayout {
    id: root
    property bool storeAvailable: true
    property bool remotePluginHovered: false
    property bool storeAvailableForPlatform: true

    Component.onCompleted: {
        PluginAdapter.getPluginsFromStore();
    }
    Connections {
        target: PluginAdapter
        function onStoreNotAvailable() {
            storeAvailable = false;
        }
        function onStoreNotAvailableForPlatform() {
            storeAvailableForPlatform = false;
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
            spacing: 10
            Repeater {
                id: pluginStoreRepeater
                model: PluginStoreListModel
                delegate: Item {
                    id: wrapper
                    function widthProvider() {
                        if (JamiTheme.remotePluginDelegateWidth < JamiTheme.remotePluginMinimumDelegateWidth) {
                            return JamiTheme.remotePluginMinimumDelegateWidth;
                        } else if (JamiTheme.remotePluginDelegateWidth > JamiTheme.remotePluginMaximumDelegateWidth) {
                            return JamiTheme.remotePluginMaximumDelegateWidth;
                        }
                        return JamiTheme.remotePluginDelegateWidth;
                    }
                    function heightProvider() {
                        if (JamiTheme.remotePluginDelegateHeight < JamiTheme.remotePluginMinimumDelegateHeight) {
                            return JamiTheme.remotePluginMinimumDelegateHeight;
                        } else if (JamiTheme.remotePluginDelegateHeight > JamiTheme.remotePluginMaximumDelegateHeight) {
                            return JamiTheme.remotePluginMaximumDelegateHeight;
                        }
                        return JamiTheme.remotePluginDelegateHeight;
                    }
                    width: widthProvider() + 10
                    height: heightProvider() + 6
                    PluginAvailableDelegate {
                        id: pluginItemDelegate
                        anchors.centerIn: parent
                        width: wrapper.widthProvider() * scalingFactor
                        height: wrapper.heightProvider() * scalingFactor
                        pluginName: Name
                        pluginId: Id
                        pluginIcon: IconPath
                        pluginDescription: Description
                        pluginAuthor: Author
                        pluginShortDescription: ""
                        pluginStatus: Status
                    }
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
    Loader {
        id: platormNotAvailableLoader
        Layout.fillWidth: true
        active: !storeAvailableForPlatform && storeAvailable
        Layout.preferredHeight: active ? JamiTheme.materialButtonPreferredHeight + 10 : 0
        sourceComponent: Rectangle {
            width: platormNotAvailableLoader.width
            height: platormNotAvailableLoader.height
            color: JamiTheme.lightTintedBlue
            radius: 5
            RowLayout {
                width: parent.width
                height: parent.height
                ResponsiveImage {
                    layer {
                        enabled: true
                        effect: ColorOverlay {
                            color: JamiTheme.darkTintedBlue
                        }
                    }
                    Layout.leftMargin: 5
                    Layout.alignment: Qt.AlignRight | Qt.AlignHCenter
                    width: JamiTheme.popuptextSize
                    height: JamiTheme.popuptextSize
                    source: JamiResources.outline_info_24dp_svg
                }
                Text {
                    Scaffold {
                    }
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignHCenter | Qt.AlignRight
                    wrapMode: Text.WordWrap
                    color: JamiTheme.blackColor
                    font.pixelSize: JamiTheme.popuptextSize
                    text: JamiStrings.storeNotSupportedPlatform
                }
            }
        }
    }
}
