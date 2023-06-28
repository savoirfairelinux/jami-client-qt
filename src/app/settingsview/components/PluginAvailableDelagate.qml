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
    property string pluginId
    property string pluginTitle
    property string pluginIcon
    property string pluginBackground
    property string pluginDescription
    property string pluginAuthor
    property string pluginShortDescription
    property int pluginStatus

    Rectangle {
        id: mask
        color: Qt.rgba(0, 0, 0, 1)
        anchors.fill: parent
        radius: 15
    }
    Page {
        anchors.fill: parent
        header: Control {
            padding: 10
            background: Rectangle {
                color: pluginBackground
            }
            contentItem: ColumnLayout {
                RowLayout {
                    Layout.alignment: Qt.AlignTop | Qt.AlignRight
                    MaterialButton {
                        id: install
                        Layout.alignment: Qt.AlignRight
                        Layout.rightMargin: 8
                        Layout.topMargin: 8
                        Layout.preferredHeight: 20
                        TextMetrics {
                            id: installTextSize
                            font.weight: Font.Black
                            font.pixelSize: JamiTheme.wizardViewButtonFontPixelSize
                            font.capitalization: Font.Medium
                            text: isDownloading() ? JamiStrings.cancel : JamiStrings.install
                        }
                        onClicked: installPlugin()
                        secondary: true
                        preferredWidth: installTextSize.width + JamiTheme.buttontextWizzardPadding
                        text: isDownloading() ? JamiStrings.cancel : JamiStrings.install
                        fontSize: 15
                    }
                }
                RowLayout {
                    spacing: 10

                    CachedImage {
                        id: icon
                        Component.onCompleted: {
                            pluginBackground = PluginStoreListModel.computeAverageColorOfImage("file://" + UtilsAdapter.getCachePath() + '/plugins/' + pluginId + '.svg');
                        }
                        width: 50
                        height: 50
                        downloadUrl: PluginAdapter.baseUrl + "/icon/" + pluginId // TODO: check if the extension is an extension exist
                        fileExtension: '.svg'
                        localPath: UtilsAdapter.getCachePath() + '/plugins/' + pluginId + '.svg'
                    }
                    ColumnLayout {
                        Label {
                            text: pluginTitle
                            font.kerning: true
                            color: JamiTheme.textColor
                            font.pointSize: JamiTheme.settingsFontSize
                            verticalAlignment: Text.AlignVCenter
                        }
                        Label {
                            color: JamiTheme.textColor
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
            color: JamiTheme.pluginViewBackgroundColor
            anchors.fill: parent
        }

        Flickable {
            anchors.fill: parent
            anchors.margins: 10
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
                width: parent.width
                color: JamiTheme.textColor
                text: pluginDescription
                wrapMode: Text.WordWrap
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
                text: "By " + pluginAuthor
                verticalAlignment: Text.AlignVCenter
            }
        }
        layer {
            enabled: true
            effect: OpacityMask {
                maskSource: mask
            }
        }
    }
    function installPlugin() {
        if (isDownloading()) {
            return;
        }
        PluginAdapter.installRemotePlugin(pluginId);
    }

    function isDownloading() {
        return pluginStatus === PluginStatus.DOWNLOADING;
    }
}
