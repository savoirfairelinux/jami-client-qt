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
    layer {
        enabled: hovered
        effect: DropShadow {
            z: -1
            radius: 16
            color: Qt.rgba(0, 0.34, 0.6, 0.16)
            transparentBorder: true
            samples: radius + 1
            cached: true
        }
    }
    Rectangle {
        id: mask
        anchors.fill: parent
        radius: 15
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
            padding: 10
            background: Rectangle {
                color: Qt.lighter(pluginBackground, 2)
            }
            contentItem: ColumnLayout {
                RowLayout {
                    Layout.alignment: Qt.AlignTop | Qt.AlignRight
                    MaterialButton {
                        id: install
                        hoverEnabled: pluginStatus !== PluginStatus.INSTALLING
                        Layout.alignment: Qt.AlignRight
                        Layout.rightMargin: 8
                        Layout.topMargin: 8
                        Layout.preferredHeight: 35
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
                        width: 50
                        height: 50
                        downloadUrl: PluginAdapter.baseUrl + "/icon/" + pluginName
                        fileExtension: '.svg'
                        localPath: UtilsAdapter.getCachePath() + '/plugins/' + pluginName + '.svg'
                    }
                    ColumnLayout {
                        Label {
                            text: pluginName
                            font.kerning: true
                            color: "black"
                            font.pointSize: JamiTheme.settingsFontSize
                            verticalAlignment: Text.AlignVCenter
                        }
                        Label {
                            color: "black"
                            text: pluginShortDescription
                            font.kerning: true
                            font.pointSize: JamiTheme.settingsFontSize
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
                }
            }
        }
        Rectangle {
            id: contentContainer
            anchors.fill: parent
            color: JamiTheme.pluginViewBackgroundColor
        }
        JamiFlickable {
            anchors.fill: parent
            anchors.margins: 10
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
                    leftPadding: 40
                    rightPadding: 40
                }
            }
        }
        footer: Control {
            padding: 10
            background: Rectangle {
                color: JamiTheme.pluginViewBackgroundColor
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
