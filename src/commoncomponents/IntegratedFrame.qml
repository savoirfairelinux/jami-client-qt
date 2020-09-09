import QtQuick 2.0
import QtQuick.Layouts 1.3
import net.jami.Models 1.0
import net.jami.Adapters 1.0

Rectangle {

    id: root

    height: 40
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

        anchors.margins: 10
        anchors.verticalCenter: root.verticalCenter


        // Frame Buttons
        HoverableRadiusButton {
            id: closeAppButton

            height: 25
            width: 25
            buttonImageHeight: 0.7 * height
            buttonImageWidth: 0.7 * width
            radius: height / 2


            source: "qrc:/images/icons/baseline-close-24px.svg"
            onClicked: {
                root.close()
            }
        }
        HoverableRadiusButton {
            id: maximizeButton

            height: 25
            width: 25
            buttonImageHeight: 0.7 * height
            buttonImageWidth: 0.7 * width
            radius: height / 2

            source: "qrc:/images/icons/maximize-24px.svg"
            onClicked: {
                root.toggleMaximize()
            }
        }
        HoverableRadiusButton {
            id: minimizeButton

            height: 25
            width: 25
            buttonImageHeight: 0.7 * height
            buttonImageWidth: 0.7 * width
            radius: height / 2

            source: "qrc:/images/icons/minimize-24px.svg"
            onClicked: {
                root.minimize()
            }
        }
    }
}
