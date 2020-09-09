import QtQuick 2.14
import QtQuick.Layouts 1.14
import net.jami.Models 1.0
import net.jami.Adapters 1.0

GridLayout {

    id: root

    rows: 3
    columns: 3
    rowSpacing: 0
    columnSpacing: 0

    property int refX
    property int refY

    // Right Side
    MouseArea {
        width: JamiTheme.frameHandlesThickness
        cursorShape: Qt.SizeHorCursor
        Layout.row: 1
        Layout.column: 2
        Layout.fillHeight: true
        onPressed: {
            refX = UtilsAdapter.getCursorX() - mainViewWindow.width
        }
        onPositionChanged: {
            mainViewWindow.setWidth(UtilsAdapter.getCursorX() - refX)
        }
    }
    // Top Right Corner
    MouseArea {
        height: JamiTheme.frameHandlesThickness
        width: JamiTheme.frameHandlesThickness
        cursorShape: Qt.SizeBDiagCursor
        Layout.row: 0
        Layout.column: 2
        onPressed: {
            refX = UtilsAdapter.getCursorX() - mainViewWindow.width
            refY = UtilsAdapter.getCursorY() + mainViewWindow.height
        }
        onPositionChanged: {
            mainViewWindow.setWidth(UtilsAdapter.getCursorX() - refX)
            mainViewWindow.setHeight(refY - UtilsAdapter.getCursorY())
            mainViewWindow.setY(UtilsAdapter.getCursorY())
        }
    }
    // Top Side
    MouseArea {
        height: JamiTheme.frameHandlesThickness
        cursorShape: Qt.SizeVerCursor
        Layout.row: 0
        Layout.column: 1
        Layout.fillWidth: true
        onPressed: {
            refY = UtilsAdapter.getCursorY() + mainViewWindow.height
        }
        onPositionChanged: {
            mainViewWindow.setHeight(refY - UtilsAdapter.getCursorY())
            mainViewWindow.setY(UtilsAdapter.getCursorY())
        }
    }
    // Top Left Corner
    MouseArea {
        height: JamiTheme.frameHandlesThickness
        width: JamiTheme.frameHandlesThickness
        cursorShape: Qt.SizeFDiagCursor
        Layout.row: 0
        Layout.column: 0
        onPressed: {
            refX = UtilsAdapter.getCursorX() + mainViewWindow.width
            refY = UtilsAdapter.getCursorY() + mainViewWindow.height
        }
        onPositionChanged: {
            mainViewWindow.setWidth(refX - UtilsAdapter.getCursorX())
            mainViewWindow.setX(UtilsAdapter.getCursorX())
            mainViewWindow.setHeight(refY - UtilsAdapter.getCursorY())
            mainViewWindow.setY(UtilsAdapter.getCursorY())
        }
    }
    // Left Side
    MouseArea {
        width: JamiTheme.frameHandlesThickness
        cursorShape: Qt.SizeHorCursor
        Layout.row: 1
        Layout.column: 0
        Layout.fillHeight: true
        onPressed: {
            refX = UtilsAdapter.getCursorX() + mainViewWindow.width
        }
        onPositionChanged: {
            mainViewWindow.setWidth(refX - UtilsAdapter.getCursorX())
            mainViewWindow.setX(UtilsAdapter.getCursorX())
        }
    }
    // Bottom Left Corner
    MouseArea {
        height: JamiTheme.frameHandlesThickness
        width: JamiTheme.frameHandlesThickness
        cursorShape: Qt.SizeBDiagCursor
        Layout.row: 2
        Layout.column: 0
        onPressed: {
            refX = UtilsAdapter.getCursorX() + mainViewWindow.width
            refY = UtilsAdapter.getCursorY() - mainViewWindow.height
        }
        onPositionChanged: {
            mainViewWindow.setWidth(refX - UtilsAdapter.getCursorX())
            mainViewWindow.setX(UtilsAdapter.getCursorX())
            mainViewWindow.setHeight(UtilsAdapter.getCursorY() - refY)
        }
    }
    // Bottom Side
    MouseArea {
        height: JamiTheme.frameHandlesThickness
        cursorShape: Qt.SizeVerCursor
        Layout.row: 2
        Layout.column: 1
        Layout.fillWidth: true
        onPressed: {
            refY = UtilsAdapter.getCursorY() - mainViewWindow.height
        }
        onPositionChanged: {
             mainViewWindow.setHeight(UtilsAdapter.getCursorY() - refY)
        }
    }
    // Bottom Right Corner
    MouseArea {
        height: JamiTheme.frameHandlesThickness
        width: JamiTheme.frameHandlesThickness
        cursorShape: Qt.SizeFDiagCursor
        Layout.row: 2
        Layout.column: 2
        onPressed: {
            refX = UtilsAdapter.getCursorX() - mainViewWindow.width
            refY = UtilsAdapter.getCursorY() - mainViewWindow.height
        }
        onPositionChanged: {
            mainViewWindow.setWidth(UtilsAdapter.getCursorX() - refX)
            mainViewWindow.setHeight(UtilsAdapter.getCursorY() - refY)
        }
    }
}
