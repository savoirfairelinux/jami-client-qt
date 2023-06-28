import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt.labs.platform
import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import "./"

RowLayout {
    id: root
    property string labelText: ""
    property int widthOfSwitch: 50
    property int heightOfSwitch: 10

    property string tooltipText: ""

    property alias toggleSwitch: autoupdate
    property alias checked: autoupdate.checked

    signal switchToggled
    Layout.alignment: Qt.AlignRight
    //preferredWidth: childrenRect.width
    JamiSwitch {
        id: autoupdate
        Layout.alignment: Qt.AlignLeft

        Layout.preferredWidth: widthOfSwitch

        hoverEnabled: true
        toolTipText: tooltipText

        Accessible.role: Accessible.Button
        Accessible.name: JamiStrings.autoUpdate
        Accessible.description: root.tooltipText

        onToggled: switchToggled()
    }
    Text {
        id: description
        Layout.rightMargin: JamiTheme.preferredMarginSize
        text: JamiStrings.autoUpdate
        font.pixelSize: 15
        visible: labelText !== ""
        font.kerning: true
        wrapMode: Text.WordWrap
        verticalAlignment: Text.AlignVCenter

        color: JamiTheme.textColor
    }
    TapHandler {
        target: parent
        enabled: parent.visible
        onTapped: function onTapped(eventPoint) {
            // switchToggled should be emitted as onToggled is not called (because it's only called if the user click on the switch)
            autoupdate.toggle();
            switchToggled();
        }
    }
}
