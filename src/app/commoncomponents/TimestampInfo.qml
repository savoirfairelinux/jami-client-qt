import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import "../mainview/components/"


ColumnLayout{
    id:root

    property bool showTime
    property bool showDay
    property string formattedTime
    property string formattedDay

    ColumnLayout {
        Layout.topMargin: 30
        Layout.fillHeight: true
        Layout.fillWidth: true
        visible: showDay
        spacing:0

        Rectangle {
            Layout.fillWidth: true
            Layout.bottomMargin: -dayRectangle.height
            height: 2
            color:JamiTheme.jamiTimestamp
            z:-1
        }

        Rectangle {
            id:dayRectangle

            border { color:  JamiTheme.jamiTimestamp; width: 1 }
            Layout.alignment: Qt.AlignHCenter
            color: JamiTheme.timestampBackgroundColor
            width: 111
            height: 30
            radius: 5

            Text {
                id:myText

                anchors { verticalCenter: parent.verticalCenter; horizontalCenter: parent.horizontalCenter}
                text:formattedDay
            }
        }
    }

    Label {
        id: formattedTimeLabel

        text: formattedTime
        Layout.bottomMargin: 40
        Layout.topMargin: 20
        Layout.alignment: Qt.AlignHCenter
        color: showTime? JamiTheme.timestampColor : JamiTheme.redColor
        visible: showTime
        height: visible * implicitHeight
        font.pointSize: 9
    }
}
