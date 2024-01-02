/*
 * Copyright (C) 2019-2024 Savoir-faire Linux Inc.
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
import Qt5Compat.GraphicalEffects
import net.jami.Constants 1.1
import "../../commoncomponents"

ItemDelegate {
    id: root
    property string pluginName: ""
    property string pluginPath: ""
    property string pluginIcon: ""
    property string pluginId: ""
    property int pluginStatus
    property bool isLoaded: false
    height: implicitHeight
    Connections {
        target: PluginListModel
        function onDisabled(id) {
            if (root.pluginPath === id) {
                isLoaded = false;
                loadSwitch.checked = false;
            }
        }
        function onErrorOccurred(id) {
            if (root.pluginId !== id) {
                return;
            }
            presentErrorMessage();
        }
    }
    onClicked: {
        pluginListView.currentIndex = index;
    }
    Component.onCompleted: {
        PluginAdapter.checkVersionStatus(pluginPath);
    }

    function presentErrorMessage() {
        viewCoordinator.presentDialog(appWindow, "commoncomponents/SimpleMessageDialog.qml", {
                "title": JamiStrings.installationFailed,
                "infoText": JamiStrings.pluginInstallationFailed,
                "buttonStyles": [SimpleMessageDialog.ButtonStyle.TintedBlue],
                "buttonTitles": [JamiStrings.optionOk],
                "buttonCallBacks": []
            });
    }

    Rectangle {
        id: mask
        anchors.fill: parent
        color: {
            if (pluginHover.hovered && pluginListView.currentIndex !== index) {
                return JamiTheme.smartListHoveredColor;
            } else {
                return JamiTheme.pluginViewBackgroundColor;
            }
        }
        border.width: 2
        border.color: {
            if (pluginListView.currentIndex === index) {
                return JamiTheme.switchHandleCheckedBorderColor;
            }
            return "transparent";
        }
        radius: 5
    }

    ColumnLayout {
        width: parent.width - 20
        height: parent.height
        anchors.centerIn: parent
        Item {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignCenter
            Layout.preferredHeight: childrenRect.height

            Label {
                id: pluginImage
                anchors.left: parent.left
                width: JamiTheme.preferredFieldHeight
                height: parent.height

                background: Rectangle {
                    color: "transparent"
                    ResponsiveImage {
                        anchors.centerIn: parent
                        source: "file:" + pluginIcon
                        containerWidth: JamiTheme.preferredFieldHeight
                        containerHeight: JamiTheme.preferredFieldHeight
                    }
                }
            }

            Label {
                width: contentWidth
                height: parent.height
                anchors.left: pluginImage.right
                anchors.leftMargin: 8
                color: JamiTheme.textColor

                font.pointSize: JamiTheme.tinyCreditsTextSize
                font.kerning: true
                text: pluginName === "" ? pluginId : pluginName
                verticalAlignment: Text.AlignVCenter
            }

            MaterialButton {
                id: update
                anchors.right: itemSwitch.left
                buttontextHeightMargin: 10.0
                TextMetrics {
                    id: updateTextSize
                    font.weight: Font.Bold
                    font.pixelSize: JamiTheme.wizardViewButtonFontPixelSize
                    font.capitalization: Font.AllUppercase
                    text: JamiStrings.updateDialogTitle
                }
                visible: pluginStatus === PluginStatus.UPDATABLE
                secondary: true
                preferredWidth: updateTextSize.width
                text: JamiStrings.updateDialogTitle
                fontSize: 15
                onClicked: PluginAdapter.installRemotePlugin(pluginId)
            }
            Item {
                id: itemSwitch
                height: parent.height
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: 78
                ToggleSwitch {
                    id: loadSwitch
                    anchors.topMargin: parent.height / 2
                    width: parent.width
                    height: parent.height
                    property bool isHovering: false

                    tooltipText: JamiStrings.loadUnload

                    checked: isLoaded
                    onSwitchToggled: {
                        if (isLoaded)
                            PluginModel.unloadPlugin(pluginPath);
                        else
                            PluginModel.loadPlugin(pluginPath);
                        PluginListModel.pluginChanged(index);
                    }
                }
            }
        }
    }
}
