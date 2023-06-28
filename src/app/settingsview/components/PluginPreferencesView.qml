/*
 * Copyright (C) 2022-2023 Savoir-faire Linux Inc.
 * Author: Aline Gondim Santos   <aline.gondimsantos@savoirfairelinux.com>
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
import SortFilterProxyModel 0.2
import net.jami.Models 1.1
import net.jami.Constants 1.1
import "../../commoncomponents"

Rectangle {
    id: root
    required property int currentIndex
    signal closed
    color: JamiTheme.secondaryBackgroundColor
    ListView {
        id: pluginPreferenceListView
        height: parent.height
        width: parent.width
        model: SortFilterProxyModel {
            sourceModel: PluginListModel
            filters: [
                ExpressionFilter {
                    expression: index === currentIndex
                    enabled: true
                }
            ]
        }
        delegate: Page {
            id: settings
            width: parent ? parent.width : 0
            height: parent ? parent.height : 0

            header: Control {
                padding: 10
                background: Rectangle {
                    color: JamiTheme.pluginViewBackgroundColor
                }
                contentItem: ColumnLayout {
                    width: parent.width
                    PushButton {
                        Layout.alignment: Qt.AlignRight
                        Layout.preferredWidth: JamiTheme.preferredFieldHeight
                        Layout.preferredHeight: JamiTheme.preferredFieldHeight

                        imageColor: JamiTheme.textColor
                        toolTipText: JamiStrings.closeSettings

                        preferredSize: 32
                        source: JamiResources.round_close_24dp_svg
                        onClicked: {
                            closed();
                        }
                    }

                    RowLayout {
                        Layout.preferredWidth: parent.width
                        Label {
                            Layout.topMargin: 34
                            Layout.preferredHeight: 64
                            Layout.preferredWidth: 64
                            background: Rectangle {
                                width: parent.width
                                height: parent.height
                                color: 'transparent'
                                Image {
                                    source: PluginIcon === "" ? JamiResources.plugins_24dp_svg : "file:" + PluginIcon
                                    sourceSize: Qt.size(256, 256)
                                    anchors.fill: parent
                                    mipmap: true
                                }
                            }
                        }
                        Label {
                            Layout.alignment: Qt.AlignVCenter
                            text: PluginName
                            font.pointSize: JamiTheme.headerFontSize
                            font.kerning: true
                            color: JamiTheme.textColor

                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        Item {
                            Layout.fillHeight: true
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            MaterialButton {
                                id: update
                                anchors.right: parent.right
                                TextMetrics {
                                    id: updateTextSize
                                    font.weight: Font.Bold
                                    font.pixelSize: JamiTheme.wizardViewButtonFontPixelSize
                                    font.capitalization: Font.AllUppercase
                                    text: JamiStrings.updatePlugin
                                }
                                visible: Status === PluginStatus.UPDATABLE
                                secondary: true
                                preferredWidth: updateTextSize.width
                                text: JamiStrings.updatePlugin
                                fontSize: 15
                            }
                        }
                    }
                    Flickable {
                        Layout.fillWidth: true
                        Layout.preferredHeight: childrenRect.height
                        Layout.maximumHeight: 88
                        contentWidth: description.width
                        contentHeight: description.height
                        clip: true
                        flickableDirection: Flickable.VerticalFlick
                        ScrollBar.vertical: ScrollBar {
                            id: scrollBar
                            policy: ScrollBar.AsNeeded
                        }
                        Text {
                            id: description
                            width: settings.width - 2 * scrollBar.width
                            text: PluginDescription
                            wrapMode: Text.WordWrap
                        }
                    }
                }
            }
            ColumnLayout {
                width: root.width
                PluginPreferencesListView {
                    id: pluginGeneralSettingsView
                    Layout.fillWidth: true
                    pluginId: PluginId
                }
                PluginPreferencesListView {
                    id: pluginAccountSettingsView
                    Layout.fillWidth: true
                    accountId: LRCInstance.currentAccountId
                    pluginId: PluginId
                }
                MaterialButton {
                    id: uninstallButton

                    Layout.alignment: Qt.AlignCenter

                    preferredWidth: JamiTheme.preferredFieldWidth
                    buttontextHeightMargin: JamiTheme.buttontextHeightMargin
                    contentColorProvider: JamiTheme.buttonTintedRed
                    color: JamiTheme.buttonTintedBlack
                    hoveredColor: JamiTheme.buttonTintedBlackHovered
                    pressedColor: JamiTheme.buttonTintedBlackPressed
                    tertiary: true
                    toolTipText: JamiStrings.pluginUninstallConfirmation.arg(PluginId)

                    text: JamiStrings.uninstall

                    onClicked: viewCoordinator.presentDialog(appWindow, "commoncomponents/SimpleMessageDialog.qml", {
                            "title": JamiStrings.uninstallPlugin,
                            "infoText": JamiStrings.pluginUninstallConfirmation.arg(PluginName),
                            "buttonTitles": [JamiStrings.optionOk, JamiStrings.optionCancel],
                            "buttonStyles": [SimpleMessageDialog.ButtonStyle.TintedBlue, SimpleMessageDialog.ButtonStyle.TintedBlack],
                            "buttonCallBacks": [function () {
                                    pluginPreferencesView.visible = false;
                                    PluginModel.uninstallPlugin(PluginId);
                                    PluginListModel.removePlugin(index);
                                    var pluginPath = PluginId.split('/');
                                    PluginListModel.setVersionStatus(pluginPath[pluginPath.length - 1], PluginStatus.INSTALLABLE);
                                }]
                        })
                }
            }
        }
    }
}
