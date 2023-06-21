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
    // Ici qu'on doit mettre les propriétés du plugin avec l'API?
    property string pluginId: ""
    property string pluginTitle: ""
    property string pluginIcon: ""
    property string pluginBackground: 'blue'
    property string pluginDescription: ""
    property string pluginAuthor: ""
    property string pluginShortDescription: ""
    property var pluginStatus: PluginAdapter.INSTALLABLE
    property bool isDownloading: false
    Connections {
        target: PluginAdapter
        function onChangedStatus(pluginId, status) {
            if (pluginId !== root.pluginId) {
                return;
            }
            pluginStatus = status;
            print(this, "should be call when status changed", root.pluginId, pluginStatus);
        }
    }
    Rectangle {
        id: mask
        color: Qt.rgba(0, 0, 0, 1)
        anchors.fill: parent
        radius: 15
    }
    Page {
        anchors.fill: parent
        header: Rectangle {
            color: pluginBackground
            height: root.height / 3
            ColumnLayout {
                anchors.top: parent.top
                width: parent.width
                RowLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignTop | Qt.AlignRight
                    MaterialButton {
                        id: install
                        Layout.rightMargin: 8
                        Layout.topMargin: 8
                        TextMetrics {
                            id: installTextSize
                            font.weight: Font.Black
                            font.pixelSize: JamiTheme.wizardViewButtonFontPixelSize
                            font.capitalization: Font.Medium
                            text: isDownloading ? JamiStrings.cancel : JamiStrings.install
                        }
                        onClicked: installPlugin()
                        secondary: true
                        preferredWidth: installTextSize.width + JamiTheme.buttontextWizzardPadding
                        text: isDownloading ? JamiStrings.cancel : JamiStrings.install
                        fontSize: 15
                    }
                }
                RowLayout {
                    Layout.fillWidth: true
                    //                Label {
                    //                    id: pluginImage
                    //                    Layout.leftMargin: 8
                    //                    Layout.topMargin: 8
                    //                    Layout.alignment: Qt.AlignLeft | Qt.AlingVCenter
                    //                    width: JamiTheme.preferredFieldHeight
                    //                    Layout.fillHeight: true

                    //                    background: Rectangle {
                    //                        color: "transparent"
                    //                        Image {
                    //                            anchors.centerIn: parent
                    //                            source: "file:" + icon // TODO: should check the file path
                    //                            sourceSize: Qt.size(256, 256)
                    //                            mipmap: true
                    //                            width: JamiTheme.preferredFieldHeight
                    //                            height: JamiTheme.preferredFieldHeight
                    //                        }
                    //                    }
                    //                }
                    ColumnLayout {
                        Layout.fillWidth: true
                        Label {
                            Layout.fillWidth: true
                            Layout.leftMargin: 8
                            text: pluginTitle
                            font.kerning: true
                            color: JamiTheme.textColor
                            font.pointSize: JamiTheme.settingsFontSize
                            verticalAlignment: Text.AlignVCenter
                        }
                        Label {
                            Layout.fillWidth: true
                            Layout.leftMargin: 8
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
        Label {
            width: parent.width
            height: parent.height
            text: pluginDescription
            color: JamiTheme.textColor
            font.kerning: true
            font.pointSize: JamiTheme.settingsFontSize
            wrapMode: Text.WordWrap
        }

        footer: Rectangle {
            height: root.height / 8
            color: JamiTheme.pluginViewBackgroundColor
            Label {
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
        if (isDownloading) {
            return;
        }
        PluginAdapter.installRemotePlugin(pluginId);
    }
}
