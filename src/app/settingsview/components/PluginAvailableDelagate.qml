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
import net.jami.Models 1.1
import net.jami.Adapters 1.1
import Qt5Compat.GraphicalEffects
import net.jami.Constants 1.1
import "../../commoncomponents"
import "../../mainview/components"

ItemDelegate {
    id: root
    property string pluginName
    property string pluginIcon
    property string pluginBackground: JamiTheme.pluginDefaultBackgroundColor
    property string pluginDescription
    property string pluginAuthor
    property string pluginShortDescription
    property int pluginStatus
    property string installButtonStatus: {
        switch (pluginStatus) {
        case PluginStatus.DOWNLOADING:
            return JamiStrings.cancel;
        case PluginStatus.INSTALLABLE:
            return JamiStrings.install;
        case PluginStatus.INSTALLING:
            return JamiStrings.installing;
        default:
            return JamiStrings.install;
        }
    }
    onPluginStatusChanged: {
        if (pluginStatus === PluginStatus.FAILED) {
            presentErrorMessage();
        }
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
        radius: 5
    }

    background: null

    Page {
        id: plugin
        anchors.fill: parent
        background: CachedImage {
            id: background
            defaultImage: JamiResources.default_plugin_background_jpg
            downloadUrl: PluginAdapter.getBackgroundImageUrl(pluginName)
            anchors.fill: parent
            localPath: UtilsAdapter.getCachePath() + '/backgrounds/' + pluginName + '.svg'
            imageFillMode: Image.PreserveAspectCrop
            LinearGradient {
                id: gradient
                anchors.fill: parent
                start: Qt.point(0, height / 3)
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "transparent" }
                    GradientStop { position: 1.0; color: "#cc000000" }
                }
            }
        }
        layer {
            enabled: true
            effect: OpacityMask {
                maskSource: mask
            }
        }
        header: Control {
            leftPadding: 20
            rightPadding: 5
            topPadding: 5
            bottomPadding: 20
            contentItem: ColumnLayout {
                SpinningAnimation {
                    id: buttonContainer
                    visible: true
                    Layout.alignment: Qt.AlignTop | Qt.AlignRight
                    Layout.rightMargin: 8
                    Layout.topMargin: 2
                    Layout.preferredHeight: install.height
                    Layout.preferredWidth: install.width
                    color: "white"
                    outerCutRadius: install.radius
                    spinningAnimationDuration: 5000
                    mode: {
                        if (pluginStatus === PluginStatus.INSTALLABLE || pluginStatus === PluginStatus.FAILED) {
                            SpinningAnimation.Mode.Disabled;
                        } else {
                            SpinningAnimation.Mode.Radial;
                        }
                    }

                    MaterialButton {
                        id: install

                        hoverEnabled: pluginStatus !== PluginStatus.INSTALLING
                        buttontextHeightMargin: 10.0
                        secHoveredColor: "#123F4A"
                        radius: JamiTheme.chatViewHeaderButtonRadius
                        TextMetrics {
                            id: installTextSize
                            font.weight: Font.Black
                            font.pixelSize: JamiTheme.wizardViewButtonFontPixelSize
                            font.capitalization: Font.Medium
                            text: install.text
                        }
                        contentColorProvider: "white"
                        onClicked: installPlugin()
                        secondary: true
                        preferredWidth: installTextSize.width + JamiTheme.buttontextWizzardPadding
                        text: {
                            switch (pluginStatus) {
                            case PluginStatus.DOWNLOADING:
                                return JamiStrings.cancel;
                            case PluginStatus.INSTALLABLE:
                                return JamiStrings.install;
                            case PluginStatus.INSTALLING:
                                return JamiStrings.installing;
                            default:
                                return JamiStrings.install;
                            }
                        }
                    }
                }
                RowLayout {
                    Layout.alignment: Qt.AlignCenter
                    CachedImage {
                        id: icon
                        defaultImage: JamiResources.plugins_default_icon_svg
                        width: 65
                        height: 65
                        downloadUrl: PluginAdapter.getIconUrl(pluginName)
                        fileExtension: '.svg'
                        localPath: UtilsAdapter.getCachePath() + '/plugins/' + pluginName + '.svg'
                    }
                }
            }
        }
        Rectangle {
            id: contentContainer
            anchors.fill: parent
            color: "transparent"
        }
        JamiFlickable {
            anchors.fill: parent
            anchors.rightMargin: 20
            anchors.leftMargin: 20
            anchors.bottomMargin: 5
            contentHeight: body.height
            clip: true
            flickableDirection: Flickable.VerticalFlick
            ScrollBar.vertical: JamiScrollBar {
                id: scrollBar
                policy: ScrollBar.AsNeeded
            }
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
            ColumnLayout {
                id: body
                width: parent.width
                Label {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignHCenter
                    text: pluginName
                    font.kerning: true
                    font.bold: true
                    color: "white"
                    font.pixelSize: JamiTheme.popuptextSize
                    textFormat: Text.PlainText
                    wrapMode: Text.WrapAnywhere
                }
                Text {
                    id: description
                    Layout.preferredWidth: contentContainer.width
                    font.pixelSize: JamiTheme.popuptextSize
                    color: "white"
                    text: pluginDescription
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Qt.AlignLeft
                    lineHeight: 1.5
                    textFormat: Text.MarkdownText
                    rightPadding: 40
                }
            }
        }
        footer: Control {
            leftPadding: 20
            bottomPadding: 20
            rightPadding: 20
            contentItem: Text {
                Layout.fillWidth: true
                Layout.preferredHeight: implicitHeight
                Layout.leftMargin: 8
                color: "white"

                font.pointSize: JamiTheme.settingsFontSize
                font.kerning: true
                font.italic: true
                text: JamiStrings.by + " " + pluginAuthor
                wrapMode: Text.WordWrap
                verticalAlignment: Text.AlignVCenter
            }
        }
    }
    function installPlugin() {
        switch (pluginStatus) {
        case PluginStatus.DOWNLOADING:
            PluginAdapter.cancelDownload(pluginName);
            break;
        case PluginStatus.INSTALLABLE:
            PluginAdapter.installRemotePlugin(pluginName);
            break;
        case PluginStatus.FAILED:
            PluginAdapter.installRemotePlugin(pluginName);
            break;
        case PluginStatus.INSTALLING:
            break;
        }
    }
}
