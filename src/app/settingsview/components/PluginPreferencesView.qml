/*
 * Copyright (C) 2022-2024 Savoir-faire Linux Inc.
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
import Qt5Compat.GraphicalEffects
import SortFilterProxyModel 0.2
import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import "../../commoncomponents"
import "../../mainview/components"

Item {
    id: root
    required property int currentIndex
    signal closed
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
            width: root.width
            height: root.height
            background: Rectangle {
                color: JamiTheme.pluginViewBackgroundColor
            }
            header: Control {
                id: preferenceHeader
                width: root.width
                background: ResponsiveImage {
                    id: background
                    anchors.fill: preferenceHeader
                    fillMode: Image.PreserveAspectCrop
                    source: PluginImage === "" ? JamiResources.default_plugin_background_jpg : "file:" + PluginImage
                    FastBlur {
                        anchors.fill: parent
                        source: background.image
                        radius: 64
                    }
                    LinearGradient {
                        id: gradient
                        anchors.fill: parent
                        start: Qt.point(0, height / 3)
                        gradient: Gradient {
                            GradientStop {
                                position: 0.0
                                color: JamiTheme.transparentColor
                            }
                            GradientStop {
                                position: 1.0
                                color: JamiTheme.darkGreyColorOpacityFade
                            }
                        }
                    }
                }
                contentItem: ColumnLayout {
                    JamiPushButton { QWKSetParentHitTestVisible {}
                        id: closeButton
                        readonly property bool alignLeft: Qt.platform.os.toString() !== "osx"
                        normalColor: Qt.rgba(124, 124, 124, 0.36)
                        hoveredColor: Qt.rgba(124, 124, 124, 0.75)
                        Layout.alignment: alignLeft ? Qt.AlignLeft : Qt.AlignRight
                        Layout.leftMargin: 10
                        Layout.rightMargin: 30
                        Layout.topMargin: 10
                        imageColor: JamiTheme.blackColor
                        toolTipText: JamiStrings.closeSettings
                        source: JamiResources.round_close_24dp_svg
                        onClicked: closed()
                    }

                    ResponsiveImage {
                        Layout.bottomMargin: 10
                        Layout.rightMargin: 10
                        Layout.alignment: Qt.AlignCenter
                        containerWidth: 100
                        containerHeight: 100
                        source: PluginIcon === "" ? JamiResources.plugins_default_icon_svg : "file:" + PluginIcon
                    }

                    Label {
                        Layout.leftMargin: 20
                        text: PluginName
                        font.pixelSize: JamiTheme.settingsDescriptionPixelSize
                        font.kerning: true
                        font.bold: true
                        color: JamiTheme.whiteColor
                        textFormat: Text.PlainText
                    }

                    JamiFlickable {
                        Layout.leftMargin: 20
                        Layout.bottomMargin: 20
                        Layout.preferredWidth: root.width
                        Layout.preferredHeight: childrenRect.height
                        Layout.minimumHeight: childrenRect.height
                        Layout.maximumHeight: 88
                        contentWidth: description.width
                        contentHeight: description.height
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds
                        flickableDirection: Flickable.VerticalFlick
                        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                        ScrollBar.vertical: ScrollBar {
                            id: scrollBar
                            policy: ScrollBar.AsNeeded
                        }
                        Text {
                            id: description
                            width: settings.width - (2 * scrollBar.width + 20)
                            text: PluginDescription
                            font.pixelSize: JamiTheme.popuptextSize
                            color: JamiTheme.whiteColor
                            wrapMode: Text.WordWrap
                            textFormat: Text.MarkdownText
                        }
                    }
                }
            }
            Rectangle {
                anchors.fill: parent
                color: JamiTheme.primaryBackgroundColor
            }
            JamiFlickable {
                anchors.fill: parent
                width: root.width
                contentHeight: contentItem.childrenRect.height
                topMargin: 20
                bottomMargin: JamiTheme.preferredSettingsBottomMarginSize
                boundsBehavior: Flickable.StopAtBounds
                ScrollBar.horizontal.visible: false
                contentItem.children: ColumnLayout {
                    width: root.width
                    ColumnLayout {
                        width: parent.width
                        Label {
                            Layout.leftMargin: 20
                            Layout.fillWidth: true
                            text: JamiStrings.settings
                            font.pixelSize: JamiTheme.settingsDescriptionPixelSize
                            font.bold: true
                            font.kerning: true
                            color: JamiTheme.textColor
                        }
                        PluginPreferencesListView {
                            id: pluginGeneralSettingsView
                            Layout.fillWidth: true
                            pluginId: PluginId
                            isLoaded: IsLoaded
                        }
                        PluginPreferencesListView {
                            id: pluginAccountSettingsView
                            Layout.fillWidth: true
                            accountId: LRCInstance.currentAccountId
                            pluginId: PluginId
                            isLoaded: IsLoaded
                        }
                    }
                    Rectangle {
                        width: parent.width
                        height: childrenRect.height + 40
                        Layout.topMargin: 20
                        color: JamiTheme.pluginViewBackgroundColor
                        ColumnLayout {
                            width: parent.width
                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.topMargin: 20
                            anchors.bottomMargin: 20
                            anchors.leftMargin: 20
                            Label {
                                Layout.fillWidth: true
                                text: JamiStrings.moreInformation
                                font.pixelSize: JamiTheme.settingsDescriptionPixelSize
                                font.bold: true
                                font.kerning: true
                                color: JamiTheme.textColor
                            }
                            Label {
                                Layout.fillWidth: true
                                text: JamiStrings.versionPlugin.arg(PluginVersion)
                                font.pixelSize: JamiTheme.headerFontSize
                                font.kerning: true
                                color: JamiTheme.textColor
                            }
                            Item {
                                width: parent.width
                                height: childrenRect.height
                                visible: Status === PluginStatus.UPDATABLE
                                Label {
                                    width: parent.width
                                    text: JamiStrings.lastUpdate.arg(NewPluginAvailable)
                                    font.pixelSize: JamiTheme.headerFontSize
                                    font.kerning: true
                                    color: JamiTheme.textColor
                                }
                                Item {
                                    width: parent.width
                                    height: childrenRect.height
                                    anchors.right: parent.right
                                    anchors.rightMargin: 40
                                    MaterialButton {
                                        id: update
                                        anchors.right: parent.right
                                        buttontextHeightMargin: 0.0
                                        TextMetrics {
                                            id: updateTextSize
                                            font.weight: Font.Bold
                                            font.pixelSize: JamiTheme.wizardViewButtonFontPixelSize
                                            font.capitalization: Font.AllUppercase
                                            text: JamiStrings.updateDialogTitle
                                        }

                                        secondary: true
                                        preferredWidth: updateTextSize.width
                                        text: JamiStrings.updateDialogTitle
                                        fontSize: 15
                                        onClicked: {
                                            PluginModel.deleteLatestVersion(PluginName);
                                            PluginAdapter.installRemotePlugin(PluginName);
                                        }
                                    }
                                }
                            }
                            Label {
                                visible: PluginAuthor !== ''
                                Layout.fillWidth: true
                                color: JamiTheme.textColor
                                font.pointSize: JamiTheme.settingsFontSize
                                font.kerning: true
                                font.italic: true
                                text: JamiStrings.proposedBy.arg(PluginAuthor)
                                wrapMode: Text.WordWrap
                                verticalAlignment: Text.AlignVCenter
                            }
                        }
                    }
                    MaterialButton {
                        id: uninstallButton
                        Layout.topMargin: 20
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
                                        PluginListModel.setVersionStatus(Id, PluginStatus.INSTALLABLE);
                                        PluginModel.uninstallPlugin(PluginId);
                                        PluginListModel.removePlugin(index);
                                        PluginAdapter.getPluginsFromStore();
                                        // could not call root from here
                                        settings.ListView.view.parent.closed();
                                    }],
                                    "buttonRoles": [DialogButtonBox.AcceptRole, DialogButtonBox.RejectRole]
                            })
                    }
                }
            }
        }
    }
}
