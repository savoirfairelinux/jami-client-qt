/*
 * Copyright (C) 2019-2023 Savoir-faire Linux Inc.
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
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt.labs.platform
import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import "../../commoncomponents"

Rectangle {
    id: root

    property string activePlugin: ""

    Component.onCompleted: {
        PluginModel.answerTrustPlugin(false, "/./");
    }

    function msgDialogTrustCallBack(trust, rootPath) {
        // have to check if it s the good call to the c++ object
        PluginModel.answerTrustPlugin(trust, rootPath);
    // pluginList.model = PluginAdapter.getPluginSelectableModel();
    // PluginAdapter.pluginHandlersUpdateStatus();
    }

    Connections {
        target: PluginModel

        function onAskTrustPluginIssuer(issuer, companyDivision, pluginName, rootPath) {
            var authorship = companyDivision === "" ? issuer : issuer + " - " + companyDivision;
            msgDialogTrustRequest.buttonCallBacks = [function () {
                    msgDialogTrustCallBack(true, rootPath);
                }, function () {
                    msgDialogTrustCallBack(false, rootPath);
                }];
            msgDialogTrustRequest.openWithParameters(qsTr("Plugin Trust Request"), qsTr("Do you want to trust " + pluginName + "?\n\nAuthor: " + authorship));
        }
    }

    SimpleMessageDialog {
        id: msgDialogTrustRequest

        buttonTitles: [qsTr("Yes"), qsTr("No")]
        buttonStyles: [SimpleMessageDialog.ButtonStyle.TintedBlue, SimpleMessageDialog.ButtonStyle.TintedBlack]
    }

    visible: false
    color: JamiTheme.secondaryBackgroundColor

    ColumnLayout {
        anchors.left: root.left
        anchors.right: root.right
        anchors.bottomMargin: 20
        RowLayout {
            Layout.preferredHeight: JamiTheme.settingsHeaderpreferredHeight
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignRight
            Label {
                Layout.fillWidth: true
                Layout.preferredHeight: 25

                text: JamiStrings.installed
                font.pointSize: JamiTheme.headerFontSize
                font.kerning: true
                color: JamiTheme.textColor

                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
            }
            HeaderToogleSwitch {
                labelText: "auto update"
                tooltipText: "auto update"
                checked: true
                onSwitchToggled: {
                }
            }
            MaterialButton {
                id: disableAll

                TextMetrics {
                    id: disableTextSize
                    font.weight: Font.Bold
                    font.pixelSize: JamiTheme.wizardViewButtonFontPixelSize
                    font.capitalization: Font.AllUppercase
                    text: JamiStrings.disableAll
                }
                secondary: true
                preferredWidth: disableTextSize.width
                text: JamiStrings.disableAll
                fontSize: 15
            }
        }
    }

    ListView {
        id: pluginList

        Layout.fillWidth: true
        Layout.minimumHeight: 0
        Layout.bottomMargin: 10
        Layout.preferredHeight: childrenRect.height
        clip: true

        model: PluginListModel {
            id: installedPluginsModel

            lrcInstance: LRCInstance
            onLrcInstanceChanged: {
                this.reset();
            }
        }

        delegate: PluginItemDelegate {
            id: pluginItemDelegate

            width: pluginList.width
            implicitHeight: 50

            pluginName: PluginName
            pluginId: PluginId
            pluginIcon: PluginIcon
            isLoaded: IsLoaded
            activeId: root.activePlugin

            background: Rectangle {
                anchors.fill: parent
                color: "transparent"
            }

            onSettingsClicked: {
                root.activePlugin = root.activePlugin === pluginId ? "" : pluginId;
            }
        }
    }
}
