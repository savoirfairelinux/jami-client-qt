import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    anchors.left: root.left
    anchors.right: root.right
    anchors.bottomMargin: 20
    RowLayout {
        Label {
            Layout.fillWidth: true
            Layout.preferredHeight: 25

            text: JamiStrings.available
            font.pointSize: JamiTheme.headerFontSize
            font.kerning: true
            color: JamiTheme.textColor

            horizontalAlignment: Text.AlignLeft
            verticalAlignment: Text.AlignVCenter
        }
        RowLayout{
            Layout.alignment: Qt.AlignRight
            MaterialButton {
                id: installManually

                TextMetrics {
                    id: installManuallyTextSize
                    font.weight: Font.Bold
                    font.pixelSize: JamiTheme.wizardViewButtonFontPixelSize
                    font.capitalization: Font.AllUppercase
                    text: JamiStrings.installManually
                }
                secondary: true
                preferredWidth: installManuallyTextSize.width
                text: JamiStrings.installManually
                fontSize: 15
            }
        }
    }
    ListView {
        id: pluginStoreList

        Layout.fillWidth: true
        Layout.minimumHeight: 0
        Layout.bottomMargin: 10
        Layout.preferredHeight: childrenRect.height
        clip: true

        model: PluginListModel {
            id: installedPluginsModel

            lrcInstance: LRCInstance
            onLrcInstanceChanged: {
                this.reset();
            }
        }

        delegate: PluginItemDelegate {
            id: pluginItemDelegate

            width: pluginList.width
            implicitHeight: 50

            pluginName: PluginName
            pluginId: PluginId
            pluginIcon: PluginIcon
            isLoaded: IsLoaded
            activeId: root.activePlugin

            background: Rectangle {
                anchors.fill: parent
                color: "transparent"
            }

            onSettingsClicked: {
                root.activePlugin = root.activePlugin === pluginId ? "" : pluginId;
            }
        }
    }
}
