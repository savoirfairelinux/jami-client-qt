import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Controls.Styles 1.4
import net.jami.Constants 1.0

TextField{
//    enum BorderColorMode{
//        NORMAL,
//        RIGHT,
//        ERROR
//    }

    property int fieldLayoutWidth: 256
    property int fieldLayoutHeight: 30
    property bool layoutFillwidth: false

    property int borderColorMode: 0
    property var backgroundColor: JamiTheme.rgb256(240,240,240)
    property var borderColor: {
        switch(borderColorMode){
        case 0:
            return "transparent"
        case 1:
            return "green"
        case 2:
            return "red"
        }
    }

    wrapMode: Text.Wrap
    color: JamiTheme.textColor
    readOnly: false
    selectByMouse: true
    font.pointSize: JamiTheme.settingsFontSize
    //font.kerning: true
    horizontalAlignment: Text.AlignLeft
    verticalAlignment: Text.AlignVCenter

    background: Rectangle {
        anchors.fill: parent
        radius: readOnly? 0 : height / 2
        border.color: readOnly? "transparent" : borderColor
        border.width:readOnly? 0 : 2
        color: readOnly? "transparent" : backgroundColor
    }
}
