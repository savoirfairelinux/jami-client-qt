import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt.labs.platform
import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import "../../commoncomponents"

ColumnLayout {
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
                fontSize: 15
            }
        }
    }

    ListView {
        id: pluginStoreList

        Layout.fillWidth: true
        Layout.bottomMargin: 10
        Layout.preferredHeight: childrenRect.height
        clip: true

        model: PluginStoreListModel

        delegate: PluginAvailableDelagate {
            id: pluginItemDelegate

            width: 350
            height: 400
            pluginId: Id
            pluginTitle: Title
            pluginIcon: IconPath
            pluginBackground: Background
            pluginDescription: Description
            pluginAuthor: Author
            pluginShortDescription: ""
        }
    }
}
