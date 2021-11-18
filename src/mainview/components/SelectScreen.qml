/*
 * Copyright (C) 2020 by Savoir-faire Linux
 * Author: Mingrui Zhang <mingrui.zhang@savoirfairelinux.com>
 *         Aline Gondim Santos <aline.gondimsantos@savoirfairelinux.com>
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

import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.15

import net.jami.Adapters 1.1
import net.jami.Models 1.1
import net.jami.Constants 1.1

import "../js/screenrubberbandcreation.js" as ScreenRubberBandCreation
import "../../commoncomponents"

// SelectScreenWindow as a seperate window,
// is to make user aware of which screen they want to share,
// during the video call, if the context menu item is selected.
Window {
    id: root

    property int minWidth: 650
    property int minHeight: 500

    property int selectedScreenNumber: -1
    property bool selectAllScreens: false
    property var screens: []

    // How many rows the ScrollView should have.
    function calculateRepeaterModel() {
        screens = []
        for (var idx in Qt.application.screens) {
            screens.push(qsTr("Screen") + " " + idx)
        }
        var screenList = AvAdapter.getListWindowsNames()
        for (var idx in screenList) {
            screens.push(screenList[idx])
        } 

        return screens.length
    }

    onActiveChanged: {
        if (!active) {
            selectedScreenNumber = -1
            selectAllScreens = false
        }
        calculateRepeaterModel()
        screenInfo.model = {}
        screenInfo.model = screens.length
        screenInfo2.model = {}
        screenInfo2.model = screens.length
        AvAdapter.captureAllScreens()
    }
    minimumWidth: minWidth
    minimumHeight: minHeight

    width: minWidth
    height: minHeight

    screen: JamiQmlUtils.mainApplicationScreen

    modality: Qt.ApplicationModal

    title: JamiStrings.selectScreen

    Rectangle {
        id: selectScreenWindowRect

        anchors.fill: parent

        color: JamiTheme.backgroundColor

        ScrollView {
            id: screenSelectionScrollView

            anchors.topMargin: JamiTheme.preferredMarginSize
            anchors.horizontalCenter: selectScreenWindowRect.horizontalCenter

            width: selectScreenWindowRect.width
            height: selectScreenWindowRect.height -
                    (selectButton.height + JamiTheme.preferredMarginSize * 4)

            clip: true

            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
            ScrollBar.vertical.policy: ScrollBar.AlwaysOn

            Flow {
                id: screenSelectionScrollViewFlow

                anchors.fill: parent
                topPadding: JamiTheme.preferredMarginSize
                rightPadding: JamiTheme.preferredMarginSize
                leftPadding: JamiTheme.preferredMarginSize

                spacing: 10

                Text {
                    width: screenSelectionScrollView.width
                    height: JamiTheme.preferredFieldHeight

                    font.pointSize: JamiTheme.menuFontSize
                    font.bold: true
                    text: "Screens"
                    color: JamiTheme.textColor
                }

                Repeater {
                    id: screenInfo

                    model: screens ? screens.length : 0

                    delegate: Rectangle {
                        id: screenItem

                        color: JamiTheme.secondaryBackgroundColor

                        width: screenSelectionScrollView.width / 2 -
                                screenSelectionScrollViewFlow.spacing / 2 - JamiTheme.preferredMarginSize
                        height: 3 * width / 4

                        border.color: selectedScreenNumber === index ? JamiTheme.screenSelectionBorderGreen : JamiTheme.tabbarBorderColor
                        visible: JamiStrings.selectScreen !== screens[index] && index < Qt.application.screens.length

                        Image {
                            id: screenShot

                            anchors.top: screenItem.top
                            anchors.topMargin: 10
                            anchors.horizontalCenter: screenItem.horizontalCenter

                            height: screenItem.height - 50
                            width: screenItem.width - 50

                            fillMode: Image.PreserveAspectFit
                            mipmap: true

                            Component.onCompleted: {
                                if (index < Qt.application.screens.length) {
                                    AvAdapter.captureScreen(index)
                                }
                            }
                        }

                        Text {
                            id: screenName

                            anchors.top: screenShot.bottom
                            anchors.topMargin: 10
                            anchors.horizontalCenter: screenItem.horizontalCenter
                            width: parent.width
                            font.pointSize: JamiTheme.textFontSize - 2
                            text: screens[index] ? screens[index] : ""
                            elide: Text.ElideMiddle
                            horizontalAlignment: Text.AlignHCenter
                            color: JamiTheme.textColor
                        }

                        MouseArea {
                            anchors.fill: screenItem
                            acceptedButtons: Qt.LeftButton

                            onClicked: {
                                selectAllScreens = false
                                if (selectedScreenNumber == -1
                                        || selectedScreenNumber !== index) {
                                    selectedScreenNumber = index
                                }
                            }
                        }

                        Connections {
                            target: AvAdapter

                            function onScreenCaptured(screenNumber, source) {
                                if (screenNumber === -1)
                                    screenShotAll.source = JamiQmlUtils.base64StringTitle + source
                                if (screenNumber === index)
                                    screenShot.source = JamiQmlUtils.base64StringTitle + source
                            }
                        }
                    }
                }

                Rectangle {
                    id: screenSelectionRectAll

                    color: JamiTheme.secondaryBackgroundColor

                    width: screenSelectionScrollView.width / 2 -
                                screenSelectionScrollViewFlow.spacing / 2 - JamiTheme.preferredMarginSize
                    height: 3 * width / 4

                    border.color: selectAllScreens ? JamiTheme.screenSelectionBorderGreen : JamiTheme.tabbarBorderColor

                    Image {
                        id: screenShotAll

                        anchors.top: screenSelectionRectAll.top
                        anchors.topMargin: 10
                        anchors.horizontalCenter: screenSelectionRectAll.horizontalCenter

                        height: screenSelectionRectAll.height - 50
                        width: screenSelectionRectAll.width - 50

                        fillMode: Image.PreserveAspectFit
                        mipmap: true
                    }

                    Text {
                        id: screenNameAll

                        anchors.top: screenShotAll.bottom
                        anchors.topMargin: 10
                        anchors.horizontalCenter: screenSelectionRectAll.horizontalCenter

                        font.pointSize: JamiTheme.textFontSize - 2
                        text: qsTr("All Screens")
                        color: JamiTheme.textColor
                    }

                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton

                        onClicked: {
                            selectedScreenNumber = -1
                            selectAllScreens = true
                        }
                    }
                }

                Text {
                    width: screenSelectionScrollView.width
                    height: JamiTheme.preferredFieldHeight

                    font.pointSize: JamiTheme.menuFontSize
                    font.bold: true
                    text: "Windows"
                    color: JamiTheme.textColor
                }

                Repeater {
                    id: screenInfo2

                    model: screens ? screens.length : 0

                    delegate: Rectangle {
                        id: screenItem2

                        color: JamiTheme.secondaryBackgroundColor

                        width: screenSelectionScrollView.width - JamiTheme.preferredFieldHeight
                        height: JamiTheme.preferredFieldHeight

                        border.color: selectedScreenNumber === index ? JamiTheme.screenSelectionBorderGreen : JamiTheme.tabbarBorderColor
                        visible: JamiStrings.selectScreen !== screens[index] && index >= Qt.application.screens.length

                        Text {
                            id: screenName2

                            anchors.fill: parent
                            anchors.leftMargin: JamiTheme.preferredMarginSize
                            font.pointSize: JamiTheme.textFontSize
                            text: screens[index] ? screens[index] : ""
                            elide: Text.ElideMiddle
                            verticalAlignment: Text.AlignVCenter
                            color: JamiTheme.textColor
                        }

                        MouseArea {
                            anchors.fill: screenItem2
                            acceptedButtons: Qt.LeftButton

                            onClicked: {
                                selectAllScreens = false
                                if (selectedScreenNumber == -1
                                        || selectedScreenNumber !== index) {
                                    selectedScreenNumber = index
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    MaterialButton {
        id: selectButton

        anchors.bottom: selectScreenWindowRect.bottom
        anchors.bottomMargin: JamiTheme.preferredMarginSize
        anchors.horizontalCenter: selectScreenWindowRect.horizontalCenter

        preferredWidth: 200

        enabled: selectedScreenNumber != -1 || selectAllScreens
        opacity: enabled ? 1.0 : 0.5

        color: JamiTheme.buttonTintedBlack
        hoveredColor: JamiTheme.buttonTintedBlackHovered
        pressedColor: JamiTheme.buttonTintedBlackPressed
        outlined: true
        // enabled: true

        text: JamiStrings.shareScreen

        onClicked: {
            if (selectAllScreens)
                AvAdapter.shareAllScreens()
            else {
                if (selectedScreenNumber < Qt.application.screens.length)
                    AvAdapter.shareEntireScreen(selectedScreenNumber)
                else {
                    AvAdapter.shareWindow(screens[selectedScreenNumber])
                }
            }
            root.close()
        }
    }
}
