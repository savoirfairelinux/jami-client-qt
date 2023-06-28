import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt.labs.platform
import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import "../../commoncomponents"

ColumnLayout {
    property bool storeAvailable: true
    function installPlugin() {
        var dlg = viewCoordinator.presentDialog(appWindow, "commoncomponents/JamiFileDialog.qml", {
                "title": JamiStrings.selectPluginInstall,
                "fileMode": JamiFileDialog.OpenFile,
                "folder": StandardPaths.writableLocation(StandardPaths.DownloadLocation),
                "nameFilters": [JamiStrings.pluginFiles, JamiStrings.allFiles]
            });
        dlg.fileAccepted.connect(function (file) {
                var url = UtilsAdapter.getAbsPath(file.toString());
                PluginModel.installPlugin(url, true);
                PluginListModel.addPlugin();
            });
    }
    Component.onCompleted: PluginAdapter.getPluginsFromStore()
    Connections {
        target: PluginAdapter
        function onStoreNotAvailable() {
            storeAvailable = false;
        }
    }
    RowLayout {
        Layout.bottomMargin: 10
        Layout.fillWidth: true
        Layout.fillHeight: true
        Label {
            Layout.fillWidth: true
            Layout.preferredHeight: 25

            text: JamiStrings.pluginStoreTitle
            font.pointSize: JamiTheme.headerFontSize
            font.kerning: true
            color: JamiTheme.textColor

            horizontalAlignment: Text.AlignLeft
            verticalAlignment: Text.AlignVCenter
        }
        RowLayout {
            Layout.alignment: Qt.AlignRight
            MaterialButton {
                id: installManually
                radius: JamiTheme.chatViewHeaderButtonRadius
                buttontextHeightMargin: JamiTheme.pushButtonMargin
                TextMetrics {
                    id: installManuallyTextSize
                    font.weight: Font.Black
                    font.pixelSize: JamiTheme.wizardViewButtonFontPixelSize
                    font.capitalization: Font.Capitalize
                    text: JamiStrings.installManually
                }
                secondary: true
                preferredWidth: installManuallyTextSize.width + JamiTheme.buttontextWizzardPadding
                text: JamiStrings.installManually
                toolTipText: JamiStrings.installManually
                fontSize: JamiTheme.popuptextSize
                onClicked: installPlugin()
            }
        }
    }
    Loader {
        active: storeAvailable
        asynchronous: true
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignHCenter
        Layout.preferredHeight: active ? childrenRect.height : 0
        sourceComponent: Flow {
            id: pluginStoreList
            spacing: 20
            Repeater {
                model: PluginStoreListModel

                delegate: PluginAvailableDelagate {
                    id: pluginItemDelegate
                    width: 350
                    height: 400
                    pluginName: Name
                    pluginIcon: IconPath
                    pluginBackground: Background === '' ? JamiTheme.backgroundColor : Background
                    pluginDescription: Description
                    pluginAuthor: Author
                    pluginShortDescription: ""
                    pluginStatus: Status
                }
            }
        }
    }
    Loader {
        Layout.fillWidth: true
        asynchronous: true
        Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
        Layout.preferredHeight: active ? JamiTheme.bigFontSize : 0
        active: !storeAvailable
        sourceComponent: Text {
            font.bold: true
            font.pixelSize: JamiTheme.bigFontSize
            horizontalAlignment: Text.AlignHCenter
            text: JamiStrings.pluginStoreNotAvailable
        }
    }
}
