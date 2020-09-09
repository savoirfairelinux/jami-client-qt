import QtQuick 2.0

MouseArea {

    height: 5
    width: 5

    property int previousX
    property int previousY

    cursorShape: Qt.SizeFDiagCursor

    onPressed: {
        previousX = mouseX
        previousY = mouseY
    }

    onPositionChanged: {
        var dx = mouseX - previousX
        var dy = mouseY - previousY
        mainViewWindow.setHeight(mainViewWindow.height + dy)
        mainViewWindow.setWidth(mainViewWindow.width + dx)
    }
}
