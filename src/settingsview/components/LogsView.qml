/*
 * Copyright (C) 2021 by Savoir-faire Linux
 * Author: Trevor Tabah <trevor.tabah@savoirfairelinux.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */
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
    id: root
    property bool cancelPressed: false
    property bool startedLogs: false
    property bool isStopped: false
    title: JamiStrings.logsViewTitle
    modality: Qt.NonModal
    width: 800
    height: 700
    property int itemWidth: Math.min(root.width / 2 - 50, 350)
    property int buttonTopAdjustment: 4
    property int widthDivisor: 4
    property int selectStart
    property int selectEnd
    onVisibleChanged: {
        text.clear()
        copiedToolTip.close()
        if (startStopToggle.checked){
            startStopToggle.checked = false
            startedLogs = false
        }
        root.cancelPressed = true
        monitorAndReceiveLogs(false)
    }
    standardButtons: StandardButton.NoButton
    ColumnLayout{
        Layout.alignment: Qt.AlignHCenter
        anchors.centerIn: parent
        Layout.fillWidth: true
        Layout.fillHeight: true
        height: root.height
        width: root.width
        Rectangle{
            Layout.fillWidth: true
            Layout.fillHeight: true
            border.color: JamiTheme.backgroundColor
            border.width: 0
            color: JamiTheme.backgroundColor
            width: 700
            height: JamiTheme.preferredFieldHeight*2
            Layout.alignment: Qt.AlignHCenter
            RowLayout{
                Layout.alignment: Qt.AlignTop| Qt.AlignHCenter
                anchors.centerIn: parent
                ToggleSwitch {
                    id: startStopToggle
                    Layout.fillWidth: true
                    Layout.leftMargin: JamiTheme.preferredMarginSize
                    Layout.rightMargin: JamiTheme.preferredMarginSize
                    checked: false
                    labelText: JamiStrings.logsViewDisplay
                    fontPointSize: JamiTheme.settingsFontSize
                    onSwitchToggled: {
                        startedLogs = !startedLogs
                        if (startedLogs){
                            root.cancelPressed = false
                            monitorAndReceiveLogs(true)
                        }
                        else{
                            isStopped = true
                            root.cancelPressed = true
                            monitorAndReceiveLogs(false)
                        }
                    }
                }
                MaterialButton{
                    id: showStatsBut
                    Layout.alignment: Qt.AlignHCenter
                    text: JamiStrings.logsViewShowStats
                    Layout.preferredHeight: JamiTheme.preferredFieldHeight
                    Layout.preferredWidth: itemWidth/(widthDivisor/1.5)
                    Layout.topMargin: JamiTheme.preferredMarginSize
                    Layout.bottomMargin: JamiTheme.preferredMarginSize
                    color: startedLogs ? JamiTheme.buttonTintedGreyInactive : JamiTheme.buttonTintedBlack
                    hoveredColor: startedLogs ? JamiTheme.buttonTintedGreyInactive : JamiTheme.buttonTintedBlackHovered
                    pressedColor: startedLogs ? JamiTheme.buttonTintedGreyInactive : JamiTheme.buttonTintedBlackPressed
                    outlined: true
                    onClicked:{
                        if (!startedLogs){
                            root.cancelPressed = false
                            monitorAndReceiveLogs(false)
                        }
                    }
                }
                MaterialButton{
                    id: clearBut
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredHeight: JamiTheme.preferredFieldHeight
                    Layout.preferredWidth: itemWidth / widthDivisor
                    color: JamiTheme.buttonTintedBlack
                    Layout.topMargin: JamiTheme.preferredMarginSize
                    Layout.bottomMargin: JamiTheme.preferredMarginSize
                    hoveredColor: JamiTheme.buttonTintedBlackHovered
                    pressedColor: JamiTheme.buttonTintedBlackPressed
                    outlined: true
                    text: JamiStrings.logsViewClear
                    onClicked: {
                        text.clear()
                        startedLogs = false
                        startStopToggle.checked = false
                        root.cancelPressed = true
                        monitorAndReceiveLogs(false)
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
                    text: JamiStrings.logsViewCopy
                    onClicked:{
                        text.selectAll()
                        text.copy()
                        text.deselect()
                        copiedToolTip.open()
                    }
                    ToolTip {
                        id: copiedToolTip
                        height: JamiTheme.preferredFieldHeight

                        TextArea{
                        text: JamiStrings.logsViewCopied
                            color: JamiTheme.textColor
                        }

                        background: Rectangle{
                            color: JamiTheme.primaryBackgroundColor
                        }
                   }
                }
                MaterialButton{
                    id: reportBut
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredHeight: JamiTheme.preferredFieldHeight
                    Layout.preferredWidth: itemWidth/(widthDivisor/1.5)
                    Layout.topMargin: JamiTheme.preferredMarginSize
                    Layout.bottomMargin: JamiTheme.preferredMarginSize
                    Layout.rightMargin: JamiTheme.preferredMarginSize

                    color: JamiTheme.buttonTintedBlack
                    hoveredColor: JamiTheme.buttonTintedBlackHovered
                    pressedColor: JamiTheme.buttonTintedBlackPressed
                    outlined: true
                    text: JamiStrings.logsViewReport
                    onClicked: Qt.openUrlExternally("https://jami.net/bugs-and-improvements/")
                }
            }
        }
        Rectangle{
            id: rect
            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: true
            Layout.fillHeight: true
            border.color: JamiTheme.primaryBackgroundColor
            border.width: 6
            width: 600
            height: 500
            color:  JamiTheme.primaryBackgroundColor
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
                    MouseArea{
                        anchors.fill: text
                        acceptedButtons: Qt.RightButton
                        hoverEnabled: true
                        onClicked:{
                            selectStart = text.selectionStart
                            selectEnd = text.selectionEnd
                            rightClickMenu.open()
                            text.select(selectStart, selectEnd)
                        }
                        Menu{
                            id: rightClickMenu

                            MenuItem{

                                text: JamiStrings.logsViewCopy
                                onTriggered:{
                                    text.copy()
                                }
                            }
                        }
                    }
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
            if (!root.cancelPressed){
                text.append(message);
            }
            if (text.lineCount >= 10000){
                var index = findNthIndexInText("\n", 10)
                text.remove(0, index)
            }
            var approximateBottom = (1.0 - flickable.visibleArea.heightRatio);
            if (!isStopped){
                if (initialPosition < 0){
                    flickable.flick(0, -(100))
                }
                else if (initialPosition >= approximateBottom * .8){
                    flickable.contentY = flickable.contentHeight - flickable.height
                    flickable.flick(0, -(flickable.maximumFlickVelocity))
                }
                else{
                    flickable.contentY = oldContent
                }
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
