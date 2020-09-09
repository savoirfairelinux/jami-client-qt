import QtQuick 2.0
import net.jami.Models 1.0

Rectangle {

    id: frameBar

    height: 64
    color: JamiTheme.backgroundColor


    // Allows dragging of the window
    MouseArea {
        anchors.fill: parent
        property int previousX
        property int previousY


        onPressed: {
            previousX = mouseX
            previousY = mouseY
        }

        onPositionChanged: {
            var dx = mouseX - previousX
            var dy = mouseY - previousY
            mainViewWindow.setY(mainViewWindow.y + dy)
            mainViewWindow.setX(mainViewWindow.x + dx)
        }
    }




    // Frame Buttons
    HoverableRadiusButton {
        id: closeAppButton

        anchors.right: frameBar.right
        anchors.rightMargin: 15
        anchors.verticalCenter: frameBar.verticalCenter

        height: 25
        width: 25
        buttonImageHeight: 0.7 * height
        buttonImageWidth: 0.7 * width

        source: "qrc:/images/icons/baseline-close-24px.svg"
        onClicked: {
            // Terminate the application
            close()
        }
    }
    HoverableRadiusButton {
        id: maximizeButton

        anchors.right: closeAppButton.left
        anchors.rightMargin: 15
        anchors.verticalCenter: frameBar.verticalCenter

        height: 25
        width: 25
        buttonImageHeight: 0.7 * height
        buttonImageWidth: 0.7 * width
        radius: height / 2


        source: "qrc:/images/icons/maximize-24px.svg"
        onClicked: {
            // Maximize
            if (visibility != 4)
                showMaximized()
            else
                showNormal()
        }
    }
    HoverableRadiusButton {
        id: minimizeButton

        anchors.right: maximizeButton.left
        anchors.rightMargin: 15
        anchors.verticalCenter: frameBar.verticalCenter

        height: 25
        width: 25
        buttonImageHeight: 0.7 * height
        buttonImageWidth: 0.7 * width
        radius: height / 2


        source: "qrc:/images/icons/minimize-24px.svg"
        onClicked: {
            // Minimize
            showMinimized()
        }
    }
}
