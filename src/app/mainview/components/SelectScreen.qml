/*
 * Copyright (C) 2020-2022 Savoir-faire Linux Inc.
 * Author: Mingrui Zhang <mingrui.zhang@savoirfairelinux.com>
 * Author: Aline Gondim Santos <aline.gondimsantos@savoirfairelinux.com>
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

import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts

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

    property bool window: false

    property int selectedScreenNumber: -1
    property bool selectAllScreens: false
    property string currentPreview: ""
    property var screens: []
    property real componentMinWidth: 200
    property real componentWidthDoubleColumn: screenSelectionScrollView.width / 2 -
                                            screenSelectionScrollViewFlow.spacing / 2 - JamiTheme.preferredMarginSize
    property real componentWidthSingleColumn: screenSelectionScrollView.width -
                                              2 * JamiTheme.preferredMarginSize

    modality: Qt.ApplicationModal
    title: window ? JamiStrings.selectWindow : JamiStrings.selectScreen

    // How many rows the ScrollView should have.
    function calculateRepeaterModel() {
        screens = []
        var idx
        for (idx in Qt.application.screens) {
            screens.push(JamiStrings.screen.arg(idx))
        }
        AvAdapter.getListWindows()
        for (idx in AvAdapter.windowsNames) {
            screens.push(AvAdapter.windowsNames[idx])
        }

        return screens.length
    }

    onActiveChanged: {
        if (!active) {
            selectedScreenNumber = -1
            selectAllScreens = false
        }
        screenInfo.model = {}
        screenInfo2.model = {}
        calculateRepeaterModel()
        screenInfo.model = screens.length
        screenInfo2.model = screens.length
        windowsText.visible = root.window
    }

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

                spacing: JamiTheme.preferredMarginSize

                Text {
                    width: screenSelectionScrollView.width
                    height: JamiTheme.preferredFieldHeight

                    font.pointSize: JamiTheme.menuFontSize
                    font.bold: true
                    text: JamiStrings.screens
                    verticalAlignment: Text.AlignBottom
                    color: JamiTheme.textColor
                    visible: !root.window
                }

                Repeater {
                    id: screenInfo

                    model: screens ? screens.length : 0

                    delegate: Rectangle {
                        id: screenItem

                        color: JamiTheme.secondaryBackgroundColor

                        width: componentWidthDoubleColumn > componentMinWidth ? componentWidthDoubleColumn : componentWidthSingleColumn
                        height: 3 * width / 4

                        border.color: selectedScreenNumber === index ? JamiTheme.screenSelectionBorderColor : JamiTheme.tabbarBorderColor
                        visible: !root.window && JamiStrings.selectScreen !== screens[index] && index < Qt.application.screens.length

                        Text {
                            id: screenName

                            anchors.top: screenItem.top
                            anchors.topMargin: 10
                            anchors.horizontalCenter: screenItem.horizontalCenter
                            width: parent.width
                            font.pointSize: JamiTheme.textFontSize
                            text: screens[index] ? screens[index] : ""
                            elide: Text.ElideMiddle
                            horizontalAlignment: Text.AlignHCenter
                            color: JamiTheme.textColor
                        }

                        VideoView {
                            id: screenPreview

                            anchors.top: screenName.bottom
                            anchors.topMargin: 10
                            anchors.horizontalCenter: screenItem.horizontalCenter
                            height: screenItem.height - 50
                            width: screenItem.width - 50

                            Component.onDestruction: {
                                if (rendererId !== "" && rendererId !== currentPreview) {
                                    VideoDevices.stopDevice(rendererId)
                                }
                            }
                            Component.onCompleted: {
                                if (visible) {
                                    const rId = AvAdapter.getSharingResource(index, "")
                                    if (rId !== "") {
                                        rendererId = VideoDevices.startDevice(rId)
                                    }
                                }
                            }
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
                            }
                        }
                    }
                }

                Rectangle {
                    id: screenSelectionRectAll

                    color: JamiTheme.secondaryBackgroundColor

                    width: componentWidthDoubleColumn > componentMinWidth ? componentWidthDoubleColumn : componentWidthSingleColumn
                    height: 3 * width / 4

                    border.color: selectAllScreens ? JamiTheme.screenSelectionBorderColor : JamiTheme.tabbarBorderColor

                    visible: !root.window && Qt.application.screens.length > 1

                    Text {
                        id: screenNameAll

                        anchors.top: screenSelectionRectAll.top
                        anchors.topMargin: 10
                        anchors.horizontalCenter: screenSelectionRectAll.horizontalCenter

                        font.pointSize: JamiTheme.textFontSize
                        text: JamiStrings.allScreens
                        color: JamiTheme.textColor
                    }

                    VideoView {
                        id: screenShotAll

                        anchors.top: screenNameAll.bottom
                        anchors.topMargin: 10
                        anchors.horizontalCenter: screenSelectionRectAll.horizontalCenter
                        height: screenSelectionRectAll.height - 50
                        width: screenSelectionRectAll.width - 50

                        Component.onDestruction: {
                            if (rendererId !== "" && rendererId !== currentPreview) {
                                VideoDevices.stopDevice(rendererId)
                            }
                        }
                        Component.onCompleted: {
                            if (visible) {
                                const rId = AvAdapter.getSharingResource(-1, "")
                                if (rId !== "") {
                                    rendererId = VideoDevices.startDevice(rId)
                                }
                            }
                        }
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
                    id: windowsText
                    width: screenSelectionScrollView.width
                    height: JamiTheme.preferredFieldHeight

                    font.pointSize: JamiTheme.menuFontSize
                    font.bold: true
                    text: JamiStrings.windows
                    verticalAlignment: Text.AlignBottom
                    color: JamiTheme.textColor
                    visible: root.window
                }

                Repeater {
                    id: screenInfo2

                    model: screens ? screens.length : 0

                    delegate: Rectangle {
                        id: screenItem2

                        color: JamiTheme.secondaryBackgroundColor

                        width: componentWidthDoubleColumn > componentMinWidth ? componentWidthDoubleColumn : componentWidthSingleColumn
                        height: 3 * width / 4

                        border.color: selectedScreenNumber === index ? JamiTheme.screenSelectionBorderColor : JamiTheme.tabbarBorderColor
                        visible: root.window && JamiStrings.selectScreen !== screens[index] && index >= Qt.application.screens.length

                        Text {
                            id: screenName2

                            anchors.top: screenItem2.top
                            anchors.topMargin: 10
                            anchors.horizontalCenter: screenItem2.horizontalCenter
                            width: parent.width
                            font.pointSize: JamiTheme.textFontSize
                            text: screens[index] ? screens[index] : ""
                            elide: Text.ElideMiddle
                            horizontalAlignment: Text.AlignHCenter
                            color: JamiTheme.textColor
                        }

                        VideoView {
                            id: screenPreview2

                            anchors.top: screenName2.bottom
                            anchors.topMargin: 10
                            anchors.horizontalCenter: screenItem2.horizontalCenter
                            anchors.leftMargin: 25
                            anchors.rightMargin: 25
                            height: screenItem2.height - 60
                            width: screenItem2.width - 50

                            Component.onDestruction: {
                                if (rendererId !== "" && rendererId !== currentPreview) {
                                    VideoDevices.stopDevice(rendererId)
                                }
                            }
                            Component.onCompleted: {
                                if (visible) {
                                    const rId = AvAdapter.getSharingResource(-2, AvAdapter.windowsIds[index - Qt.application.screens.length])
                                    if (rId !== "") {
                                        rendererId = VideoDevices.startDevice(rId)
                                    }
                                }
                            }
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

    RowLayout {
        anchors.bottom: selectScreenWindowRect.bottom
        anchors.bottomMargin: JamiTheme.preferredMarginSize
        anchors.horizontalCenter: selectScreenWindowRect.horizontalCenter

        width: parent.width
        height: childrenRect.height
        spacing: JamiTheme.preferredMarginSize

        MaterialButton {
            id: selectButton

            Layout.maximumWidth: 200
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            Layout.leftMargin: JamiTheme.preferredMarginSize

            enabled: selectedScreenNumber != -1 || selectAllScreens
            opacity: enabled ? 1.0 : 0.5

            color: JamiTheme.buttonTintedBlack
            hoveredColor: JamiTheme.buttonTintedBlackHovered
            pressedColor: JamiTheme.buttonTintedBlackPressed
            secondary: true
            autoAccelerator: true

            text: window ? JamiStrings.shareWindow : JamiStrings.shareScreen

            onClicked: {
                if (selectAllScreens)
                    AvAdapter.shareAllScreens()
                else {
                    if (selectedScreenNumber < Qt.application.screens.length)
                        AvAdapter.shareEntireScreen(selectedScreenNumber)
                    else {
                        AvAdapter.shareWindow(AvAdapter.windowsIds[selectedScreenNumber - Qt.application.screens.length])
                    }
                }
                root.close()
            }
        }

        MaterialButton {
            id: cancelButton

            Layout.maximumWidth: 200
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            Layout.rightMargin: JamiTheme.preferredMarginSize

            color: JamiTheme.buttonTintedBlack
            hoveredColor: JamiTheme.buttonTintedBlackHovered
            pressedColor: JamiTheme.buttonTintedBlackPressed
            secondary: true
            autoAccelerator: true

            text: JamiStrings.optionCancel

            onClicked: root.close()
        }
    }
}
