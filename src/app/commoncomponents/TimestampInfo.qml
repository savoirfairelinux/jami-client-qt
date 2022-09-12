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

    Rectangle {
        id:dayRectangle

        visible: showDay
        border { color:  JamiTheme.timestampColor; width: 2 }
        Layout.alignment: Qt.AlignHCenter
        width: 111
        height: 30
        radius: 5
        color: JamiTheme.chatviewBgColor
        Layout.topMargin: 30
        Layout.fillHeight: true

        Rectangle {
            id: line

            height: 2
            color:JamiTheme.timestampColor
            width: chatView.width * 0.98
            anchors.centerIn: parent
            z:-1
        }

        Text {
            id:formattedDayLabel

            color: JamiTheme.daytimestampColor
            anchors { verticalCenter: parent.verticalCenter; horizontalCenter: parent.horizontalCenter}
            text:formattedDay
        }
    }

    Label {
        id: formattedTimeLabel

        text: formattedTime
        Layout.bottomMargin: 40
        Layout.topMargin: 20
        Layout.alignment: Qt.AlignHCenter
        color: JamiTheme.timestampColor
        visible: showTime
        height: visible * implicitHeight
        font.pointSize: 9
    }
}
