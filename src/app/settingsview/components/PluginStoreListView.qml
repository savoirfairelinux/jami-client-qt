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
    Component.onCompleted: {
        PluginAdapter.getPluginsFromStore();
        PluginAdapter.setPluginsStoreAutoRefresh(true);
    }
    Connections {
        target: PluginAdapter
        function onStoreNotAvailable() {
            storeAvailable = false;
        }
    }
    Label {
        Layout.fillWidth: true
        Layout.bottomMargin: 20
        text: JamiStrings.pluginStoreTitle
        font.pixelSize: JamiTheme.settingsTitlePixelSize
        font.kerning: true
        color: JamiTheme.textColor
        horizontalAlignment: Text.AlignLeft
        verticalAlignment: Text.AlignVCenter
    }
    Loader {
        active: storeAvailable
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignHCenter
        Layout.preferredHeight: active ? item.height : 0
        sourceComponent: Flow {
            id: pluginStoreList
            height: childrenRect.height
            spacing: 20
            Repeater {
                model: PluginStoreListModel

                delegate: PluginAvailableDelagate {
                    id: pluginItemDelegate
                    width: JamiTheme.remotePluginWidthDelegate
                    height: JamiTheme.remotePluginHeightDelegate
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
