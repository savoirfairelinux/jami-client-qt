import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt.labs.platform
import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import "../../commoncomponents"

ColumnLayout {
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
    RowLayout {
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

                TextMetrics {
                    id: installManuallyTextSize
                    font.weight: Font.Black
                    font.pixelSize: JamiTheme.wizardViewButtonFontPixelSize
                    font.capitalization: Font.Capitalize
                    text: JamiStrings.installManually
                }
                secondary: true
                preferredWidth: installManuallyTextSize.width
                text: JamiStrings.installManually
                toolTipText: JamiStrings.installManually
                fontSize: 15
                onClicked: installPlugin()
            }
        }
    }

    Flow {
        id: pluginStoreList

        Layout.fillWidth: true
        spacing: 20
        Layout.preferredHeight: childrenRect.height
        clip: true
        Repeater {
            model: PluginStoreListModel

            delegate: PluginAvailableDelagate {
                id: pluginItemDelegate

                width: 350
                height: 400
                pluginId: Id
                pluginTitle: Title
                pluginIcon: IconPath
                pluginBackground: Background === '' ? JamiTheme.backgroundColor : Background
                pluginDescription: Description
                pluginAuthor: Author
                pluginShortDescription: ""
            }
        }
    }
}
