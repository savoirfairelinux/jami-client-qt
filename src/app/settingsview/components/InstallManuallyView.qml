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
                var isInstall = PluginModel.installPlugin(url, true);
                if (isInstall) {
                    PluginListModel.addPlugin();
                } else {
                    presentErrorMessage();
                }
            });
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

    Label {
        Layout.fillWidth: true
        Layout.bottomMargin: 20

        text: JamiStrings.installManually
        font.pixelSize: JamiTheme.settingsTitlePixelSize
        font.kerning: true
        color: JamiTheme.textColor

        horizontalAlignment: Text.AlignLeft
        verticalAlignment: Text.AlignVCenter
    }
    Text {
        id: descriptionInstallManually
        Layout.fillWidth: true
        font.pixelSize: JamiTheme.popuptextSize
        color: JamiTheme.textColor
        text: JamiStrings.installMannuallyDescription
        wrapMode: Text.WordWrap
        horizontalAlignment: Qt.AlignLeft
        lineHeight: 1.5
        textFormat: Text.PlainText
    }
    MaterialButton {
        id: installManually
        radius: JamiTheme.chatViewHeaderButtonRadius
        TextMetrics {
            id: textSize
            font.weight: Font.Black
            font.pixelSize: JamiTheme.wizardViewButtonFontPixelSize
            font.capitalization: Font.AllUppercase
            text: installManually.text
        }
        primary: true
        preferredWidth: textSize.width + 2 * JamiTheme.buttontextWizzardPadding
        text: JamiStrings.install
        fontSize: JamiTheme.popuptextSize
        onClicked: installPlugin()
    }
}
