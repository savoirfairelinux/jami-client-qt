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

    property alias checked: toogleSwitch.checked

    signal switchToggled
    JamiSwitch {
        id: toogleSwitch
        Layout.alignment: Qt.AlignLeft

        Layout.preferredWidth: widthOfSwitch

        hoverEnabled: true
        toolTipText: tooltipText

        Accessible.role: Accessible.Button
        Accessible.name: labelText
        Accessible.description: root.tooltipText

        onToggled: switchToggled()
    }
    Text {
        id: description
        Layout.rightMargin: JamiTheme.preferredMarginSize
        text: labelText
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
            toogleSwitch.toggle();
            switchToggled();
        }
    }
}
