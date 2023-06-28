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
    // Ici qu'on doit mettre les propriétés du plugin avec l'API?
    property string pluginName
    property string pluginIcon
    property string pluginBackground
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

    background: null

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
    Page {
        id: plugin
        anchors.fill: parent
        layer {
            enabled: true
            effect: OpacityMask {
                maskSource: mask
            }
        }
        header: Control {
            leftPadding: 20
            rightPadding: 5
            bottomPadding: 20
            topPadding: 5
            background: Rectangle {
                id: headerBackground
                color: hovered ? Qt.lighter(pluginBackground, 1.9) : Qt.lighter(pluginBackground, 2)
            }
            contentItem: ColumnLayout {
                SpinningAnimation {
                    id: buttonContainer
                    visible: true
                    Layout.alignment: Qt.AlignTop | Qt.AlignRight
                    Layout.rightMargin: 8
                    Layout.topMargin: 2
                    Layout.preferredHeight: childrenRect.height
                    Layout.preferredWidth: childrenRect.width
                    color: "black"
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
                        secHoveredColor: Qt.darker(headerBackground.color, 1.1)
                        buttontextHeightMargin: 10.0
                        radius: JamiTheme.chatViewHeaderButtonRadius
                        TextMetrics {
                            id: installTextSize
                            font.weight: Font.Black
                            font.pixelSize: JamiTheme.wizardViewButtonFontPixelSize
                            font.capitalization: Font.Medium
                            text: install.text
                        }
                        contentColorProvider: "black"
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
                    spacing: 10
                    CachedImage {
                        id: icon
                        Component.onCompleted: {
                            pluginBackground = PluginStoreListModel.computeAverageColorOfImage("file://" + UtilsAdapter.getCachePath() + '/plugins/' + pluginName + '.svg');
                        }
                        width: 65
                        height: 65
                        downloadUrl: PluginAdapter.baseUrl + "/icon/" + pluginName
                        fileExtension: '.svg'
                        localPath: UtilsAdapter.getCachePath() + '/plugins/' + pluginName + '.svg'
                    }
                    ColumnLayout {
                        width: parent.width
                        Label {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignHCenter
                            text: pluginName
                            font.kerning: true
                            color: JamiTheme.textColor
                            font.pointSize: JamiTheme.tinyCreditsTextSize
                            textFormat: Text.PlainText
                            wrapMode: Text.WrapAnywhere
                        }
                        //                        TODO: add short description for each plugin
                        //                        Label {
                        //                            Layout.fillWidth: true
                        //                            color: "black"
                        //                            text: pluginShortDescription
                        //                            font.pointSize: JamiTheme.settingsFontSize
                        //                            textFormat: Text.PlainText
                        //                            wrapMode: Text.WordWrap
                        //                        }
                    }
                }
            }
        }
        Rectangle {
            id: contentContainer
            anchors.fill: parent
            color: hovered ? Qt.darker(JamiTheme.pluginViewBackgroundColor, 1.1) : JamiTheme.pluginViewBackgroundColor
        }
        JamiFlickable {
            anchors.fill: parent
            anchors.margins: 20
            contentHeight: description.height
            clip: true
            flickableDirection: Flickable.VerticalFlick
            ScrollBar.vertical: JamiScrollBar {
                id: scrollBar
                policy: ScrollBar.AsNeeded
            }
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
            ColumnLayout {
                width: parent.width
                Text {
                    id: description
                    Layout.preferredWidth: contentContainer.width
                    font.pixelSize: JamiTheme.popuptextSize
                    color: JamiTheme.textColor
                    text: pluginDescription
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Qt.AlignLeft
                    lineHeight: 1.5
                    textFormat: Text.PlainText
                    rightPadding: 40
                }
            }
        }
        footer: Control {
            padding: 20
            background: Rectangle {
                color: hovered ? Qt.darker(JamiTheme.pluginViewBackgroundColor, 1.1) : JamiTheme.pluginViewBackgroundColor
            }
            contentItem: Text {
                Layout.fillWidth: true
                Layout.preferredHeight: implicitHeight
                Layout.topMargin: 8
                Layout.leftMargin: 8
                color: JamiTheme.textColor

                font.pointSize: JamiTheme.settingsFontSize
                font.kerning: true
                font.italic: true
                text: "By " + pluginAuthor
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
