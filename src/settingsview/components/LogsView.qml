import QtQuick 2.14
import QtQuick.Controls 2.14
import QtQuick.Controls.Universal 2.14
import QtQuick.Layouts 1.14
import QtGraphicalEffects 1.14
import Qt.labs.platform 1.1
import QtQuick.Dialogs 1.2

import net.jami.Models 1.0
import net.jami.Adapters 1.0
import net.jami.Constants 1.0

import "../../commoncomponents"



Dialog {
    id: dialog
    property bool cancelPressed: false



    title: "Debug"
    modality: Qt.NonModal

    width: 700
    height: 700
    property int itemWidth: Math.min(dialog.width / 2 - 50, 350)
    property int buttonTopAdjustment: 4
    property int widthDivisor: 3



    standardButtons: StandardButton.NoButton
    ColumnLayout{
        spacing: 2
        Layout.alignment: Qt.AlignHCenter
        anchors.centerIn: parent
        Layout.fillWidth: true
        Layout.fillHeight: true
        height: dialog.height
        width: dialog.width


        Rectangle{

            Layout.fillWidth: true
            Layout.fillHeight: true
            border.color: JamiTheme.backgroundColor
            border.width: 0
            color: JamiTheme.backgroundColor
            width: 700
            height: JamiTheme.preferredFieldHeight*1.5
            RowLayout{
                Layout.alignment: Qt.AlignTop| Qt.AlignHCenter

                MaterialButton{
                    id: dumpBut
                    text: "Dump"
                    Layout.preferredHeight: JamiTheme.preferredFieldHeight
                    Layout.preferredWidth: itemWidth/widthDivisor

                    Layout.topMargin: JamiTheme.preferredMarginSize
                    Layout.bottomMargin: JamiTheme.preferredMarginSize
                    Layout.leftMargin: JamiTheme.preferredMarginSize


                    color: JamiTheme.buttonTintedBlack
                    hoveredColor: JamiTheme.buttonTintedBlackHovered
                    pressedColor: JamiTheme.buttonTintedBlackPressed
                    outlined: true


                    onClicked:{
                        dialog.cancelPressed = false
                        monitorAndReceiveLogs(false)
                    }
                }
                MaterialButton{
                    id: logBut
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredHeight: JamiTheme.preferredFieldHeight
                    Layout.preferredWidth: itemWidth/widthDivisor

                    color: JamiTheme.buttonTintedBlack
                    hoveredColor: JamiTheme.buttonTintedBlackHovered
                    pressedColor: JamiTheme.buttonTintedBlackPressed
                    outlined: true

                    text: "Log"
                    onClicked:{
                        dialog.cancelPressed = false
                        monitorAndReceiveLogs(true)
                    }
                }
                MaterialButton{
                    id: copyBut
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredHeight: JamiTheme.preferredFieldHeight
                    Layout.preferredWidth: itemWidth/widthDivisor
                    color: JamiTheme.buttonTintedBlack
                    hoveredColor: JamiTheme.buttonTintedBlackHovered
                    pressedColor: JamiTheme.buttonTintedBlackPressed
                    outlined: true
                    text: "Copy"
                    onClicked:{
                        text.selectAll()
                        text.copy()
                        text.deselect()
                    }
                }
                MaterialButton{
                    id: reportBut
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredHeight: JamiTheme.preferredFieldHeight
                    Layout.preferredWidth: itemWidth/(widthDivisor/1.5)
                    color: JamiTheme.buttonTintedBlack
                    hoveredColor: JamiTheme.buttonTintedBlackHovered
                    pressedColor: JamiTheme.buttonTintedBlackPressed
                    outlined: true
                    text: "Report Bug"
                    onClicked: Qt.openUrlExternally("https://jami.net/bugs-and-improvements/")
                }
                MaterialButton{
                    id: clearBut
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredHeight: JamiTheme.preferredFieldHeight
                    Layout.preferredWidth: itemWidth/widthDivisor
                    color: JamiTheme.buttonTintedBlack
                    hoveredColor: JamiTheme.buttonTintedBlackHovered
                    pressedColor: JamiTheme.buttonTintedBlackPressed
                    outlined: true
                    text: "Clear"
                    onClicked: text.clear()
                }

                MaterialButton{
                    id: cancelButton
                    Layout.alignment: Qt.AlignHCenter
                    text: "Cancel"
                    Layout.preferredHeight: JamiTheme.preferredFieldHeight
                    Layout.preferredWidth: itemWidth/widthDivisor
                    Layout.topMargin: JamiTheme.preferredMarginSize
                    Layout.bottomMargin: JamiTheme.preferredMarginSize
                    Layout.rightMargin: JamiTheme.preferredMarginSize
                    color: JamiTheme.buttonTintedBlack
                    hoveredColor: JamiTheme.buttonTintedBlackHovered
                    pressedColor: JamiTheme.buttonTintedBlackPressed
                    outlined: true
                    onClicked: {
                        dialog.cancelPressed = true
                        monitorAndReceiveLogs(false)
                        text.clear()
                        close()
                    }
                }
            }
        }

        Rectangle{
            id: rect
            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: true
            Layout.fillHeight: true
            border.color: "white"
            border.width: 0


            width: 600
            height: 500
            color: JamiTheme.backgroundColor

            property alias text: text.text
            Flickable {
                id: flickable
                anchors.fill: rect
                Layout.fillWidth: true

                width: 600
                height: 600
                boundsBehavior: Flickable.StopAtBounds
                maximumFlickVelocity: 3000
                TextArea.flickable: TextArea {
                    id: text
                    readOnly: true
                    text: ""
                    color: JamiTheme.textColor
                    wrapMode: TextArea.Wrap
                    selectByMouse: true
                    leftPadding: rect.border.width + 3
                    rightPadding: rect.border.width + 3
                    topPadding: rect.border.width + 3
                    bottomPadding: rect.border.width + 3
                }
                ScrollBar.vertical: ScrollBar {

                    id: scroll
                }
            }
        }

    }

    Connections{
        target: SettingsAdapter
        function onDebugMessageReceived(message){
            var initialPosition = scroll.position
            var oldContent = flickable.contentY

            if (!dialog.cancelPressed){
                text.append(message);
            }

            if (text.lineCount >= 10000){
                var index = findNthIndexInText("\n", 10)
                text.remove(0, index)
            }

            var approximateBottom = (1.0 - flickable.visibleArea.heightRatio);
                if (initialPosition < 0){
                    flickable.flick(0, -(flickable.maximumFlickVelocity))
                }

                else if (initialPosition >= approximateBottom * .85){
                    flickable.contentY = flickable.contentHeight - flickable.height
                    flickable.flick(0, -(flickable.maximumFlickVelocity))
                }
                else{
                    flickable.contentY = oldContent
                }
        }

    }
    function findNthIndexInText(substring, n){
        var i;
        var t = text.text
        var index = t.indexOf(substring)
        for (i = 0; i < n - 1; i++){
            index = t.indexOf(substring, index + 1)
        }
        return index
    }






}
