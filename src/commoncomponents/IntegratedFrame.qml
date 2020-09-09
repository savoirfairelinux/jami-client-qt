import QtQuick 2.0
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.5
import net.jami.Models 1.0
import net.jami.Adapters 1.0

Rectangle {

    id: root

    height: 32
    color: JamiTheme.backgroundColor

    signal close()
    signal toggleMaximize()
    signal minimize()


    // Allows dragging of the window
    MouseArea {
        anchors.fill: parent
        property int refX
        property int refY


        onPressed: {
            refX = mainViewWindow.x - UtilsAdapter.getCursorX()
            refY = mainViewWindow.y - UtilsAdapter.getCursorY()
        }

        onPositionChanged: {
            mainViewWindow.setX(UtilsAdapter.getCursorX() + refX)
            mainViewWindow.setY(UtilsAdapter.getCursorY() + refY)
        }

        onDoubleClicked: {
            root.toggleMaximize()
        }
    }

    RowLayout {
        id: layout

        layoutDirection: Qt.RightToLeft
        spacing: 10

        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        anchors.left: undefined
        anchors.margins: 10

        // Frame Buttons
        Item {
            height: 20
            width: 20

            HoverableRadiusButton {
                id: closeAppButton

                anchors.fill: parent
                source: "qrc:/images/icons/baseline-close-24px.svg"
                onClicked: {
                    root.close()
                }
            }
        }
        Item {
            height: 20
            width: 20

            HoverableRadiusButton {
                id: maximizeButton

                anchors.fill: parent
                source: "qrc:/images/icons/maximize-24px.svg"
                onClicked: {
                    root.toggleMaximize()
                }
            }
        }
        Item {
            height: 20
            width: 20

            HoverableRadiusButton {
                id: minimizeButton

                anchors.fill: parent
                source: "qrc:/images/icons/minimize-24px.svg"
                onClicked: {
                    root.minimize()
                }
            }
        }
    }
}
