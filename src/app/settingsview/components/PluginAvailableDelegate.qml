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
    property string pluginId
    property string pluginIcon
    property string pluginBackground: JamiTheme.pluginDefaultBackgroundColor
    property string pluginDescription
    property string pluginAuthor
    property string pluginShortDescription
    property int pluginStatus
    property string backgroundLocalPath: UtilsAdapter.getCachePath() + '/backgrounds/' + pluginId + '.jpg'
    property string iconLocalPath: UtilsAdapter.getCachePath() + '/icons/' + pluginId + '.svg'
    readonly property real scalingFactor: 1 + hovered * 0.02
    property int duration: JamiTheme.shortFadeDuration
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
                "buttonCallBacks": [],
                "buttonRoles": [DialogButtonBox.AcceptRole]
            });
    }
    function growSize(x) {
        return !hovered * x;
    }
    Rectangle {
        id: mask
        anchors.fill: parent
        radius: 5
        color: JamiTheme.secondaryBackgroundColor
    }

    background: null

    Page {
        id: plugin
        anchors.fill: parent
        states: [
            State {
                name: "normal"
                when: !hovered
                PropertyChanges {
                    target: plugin
                    leftInset: 5
                    rightInset: 5
                    bottomInset: 3
                    topInset: 3
                }
            },
            State {
                name: "hovered"
                when: hovered
                PropertyChanges {
                    target: plugin
                    leftInset: 0
                    rightInset: 0
                    bottomInset: 0
                    topInset: 0
                }
            }
        ]
        transitions: [
            Transition {
                to: "normal"
                enabled: duration
                PropertyAnimation {
                    properties: "leftInset,rightInset,bottomInset,topInset"
                    duration: root.duration * 0.5
                }
            },
            Transition {
                to: "hovered"
                enabled: duration
                PropertyAnimation {
                    properties: "leftInset,rightInset,bottomInset,topInset"
                    duration: root.duration
                }
            },
            Transition {
                to: ""
                enabled: duration
                PropertyAnimation {
                    properties: "leftInset,rightInset,bottomInset,topInset"
                    duration: root.duration
                }
            }
        ]
        background: Rectangle {
            clip: true
            radius: 5
            color: JamiTheme.secondaryBackgroundColor
            CachedImage {
                id: background
                defaultImage: JamiResources.default_plugin_background_jpg
                downloadUrl: PluginAdapter.getBackgroundImageUrl(pluginId)
                anchors.fill: parent
                localPath: root.backgroundLocalPath === undefined ? '' : root.backgroundLocalPath
                imageFillMode: Image.PreserveAspectCrop
                layer {
                    enabled: true
                    effect: OpacityMask {
                        maskSource: mask
                    }
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
                    color: JamiTheme.whiteColor
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
                        secHoveredColor: JamiTheme.darkBlueGreen
                        radius: JamiTheme.chatViewHeaderButtonRadius
                        TextMetrics {
                            id: installTextSize
                            font.weight: Font.Black
                            font.pixelSize: JamiTheme.wizardViewButtonFontPixelSize
                            font.capitalization: Font.Medium
                            text: install.text
                        }
                        contentColorProvider: JamiTheme.whiteColor
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
                    Layout.topMargin: JamiTheme.iconMargin
                    Layout.bottomMargin: JamiTheme.iconMargin
                    CachedImage {
                        id: icon
                        defaultImage: JamiResources.plugins_default_icon_svg
                        width: 65
                        height: 65
                        downloadUrl: PluginAdapter.getIconUrl(pluginId)
                        localPath: root.iconLocalPath
                    }
                }
            }
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
                    color: JamiTheme.whiteColor
                    font.pixelSize: JamiTheme.popuptextSize
                    textFormat: Text.PlainText
                    wrapMode: Text.WrapAnywhere
                }
                Text {
                    id: description
                    Layout.fillWidth: true
                    bottomPadding: 5
                    font.pixelSize: JamiTheme.popuptextSize
                    color: JamiTheme.whiteColor
                    text: pluginDescription
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Qt.AlignLeft
                    lineHeight: 1.25
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
                color: JamiTheme.whiteColor

                font.pixelSize: JamiTheme.settingsFontSize
                font.kerning: true
                font.italic: true
                text: JamiStrings.by.arg(pluginAuthor)
                wrapMode: Text.WordWrap
                verticalAlignment: Text.AlignVCenter
            }
        }
    }
    function installPlugin() {
        switch (pluginStatus) {
        case PluginStatus.DOWNLOADING:
            PluginAdapter.cancelDownload(pluginId);
            break;
        case PluginStatus.INSTALLABLE:
            PluginAdapter.installRemotePlugin(pluginId);
            break;
        case PluginStatus.FAILED:
            PluginAdapter.installRemotePlugin(pluginId);
            break;
        case PluginStatus.INSTALLING:
            break;
        }
    }
}
