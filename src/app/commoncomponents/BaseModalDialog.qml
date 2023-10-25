/*
 * Copyright (C) 2020-2023 Savoir-faire Linux Inc.
 * Author: Andreas Traczyk <andreas.traczyk@savoirfairelinux.com>
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
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import net.jami.Constants 1.1
import "../mainview/components"

Popup {
    id: root

    // convient access to closePolicy
    property bool autoClose: true
    property alias backgroundColor: container.color
    property alias title: titleText.text
    property var popupcontainerSubContentLoader: containerSubContentLoader

    property bool closeButtonVisible: true
    property variant button1Clicked: null
    property variant button2Clicked: null
    property alias button1: action1
    property alias button2: action2
    property alias popupContentLoadStatus: containerSubContentLoader.status
    property alias popupContent: containerSubContentLoader.sourceComponent
    property int popupContentMargins: JamiTheme.preferredMarginSize
    property int popupMargins: 30
    property int buttonMargin: 20

    parent: Overlay.overlay
    anchors.centerIn: parent
    modal: true

    focus: true
    closePolicy: autoClose ? (Popup.CloseOnEscape | Popup.CloseOnPressOutside) : Popup.NoAutoClose

    contentItem: Control {
        id: container

        property color color: JamiTheme.secondaryBackgroundColor
        anchors.centerIn: parent
        leftPadding: popupMargins
        bottomPadding: action1.visible || action2.visible ? 20 :popupMargins

        background: Rectangle {

            id: bgRect
            radius: 5
            color: container.color
            layer.enabled: true
            layer.effect: DropShadow {
                horizontalOffset: 3.0
                verticalOffset: 3.0
                radius: bgRect.radius * 4
                color: JamiTheme.shadowColor
                source: bgRect
                transparentBorder: true
                samples: radius + 1
            }
        }

        contentItem: ColumnLayout {
            id: contentLayout

            JamiPushButton {
                id: closeButton

                visible: closeButtonVisible

                Layout.alignment: Qt.AlignRight | Qt.AlignTop
                Layout.preferredHeight: 20
                Layout.preferredWidth: 20
                Layout.topMargin: 5
                Layout.rightMargin: 5

                imageColor: "grey"
                normalColor: "transparent"
                source: JamiResources.round_close_24dp_svg
                onClicked: close()
                }

            Label {
                id: titleText
                Layout.rightMargin: popupMargins
                Layout.bottomMargin: 20
                Layout.topMargin: closeButtonVisible ? 0 : 30
                Layout.alignment: Qt.AlignLeft
                font.pointSize: JamiTheme.menuFontSize
                color: JamiTheme.textColor

                font.bold: true
                visible: text.length > 0
                }

            Loader {
                id: containerSubContentLoader
                Layout.rightMargin: popupMargins
                Layout.alignment: Qt.AlignCenter
                Layout.maximumWidth: 600 - 60
            }

            RowLayout {
                id: buttonsLayout

                Layout.rightMargin: 10
                spacing: 1.5

                Layout.alignment: Qt.AlignRight

                MaterialButton {
                    id: action1

                    visible: {
                        if (text.length > 0){
                            parent.visible = true;
                            return true;
                        }
                        else {
                            parent.visible = false;
                            return false;
                        }
                    }

                    Layout.alignment: Qt.AlignHCenter
                    rightPadding: buttonMargin
                    leftPadding: buttonMargin

                    buttontextHeightMargin: JamiTheme.buttontextHeightMargin

                    tertiary: true
                    autoAccelerator: true

                    onClicked: {
                        if (button1Clicked) {
                            button1Clicked();
                        }
                    }
                }

                MaterialButton {
                    id: action2

                    visible: text.length > 0

                    Layout.alignment: Qt.AlignHCenter
                    rightPadding: buttonMargin
                    leftPadding: buttonMargin

                    buttontextHeightMargin: JamiTheme.buttontextHeightMargin

                    tertiary: true
                    autoAccelerator: true

                    onClicked: {
                        if (button2Clicked) {
                            button2Clicked();
                        }
                    }
                }
            }
        }
    }

    background: Rectangle {
        color: JamiTheme.transparentColor
    }

    Overlay.modal: Rectangle {
        color: JamiTheme.transparentColor

        // Color animation for overlay when pop up is shown.
        ColorAnimation on color  {
            to: JamiTheme.popupOverlayColor
            duration: 500
        }
    }

    enter: Transition {
        NumberAnimation {
            properties: "opacity"
            from: 0.0
            to: 1.0
            duration: JamiTheme.shortFadeDuration
        }
    }
    exit: Transition {
        NumberAnimation {
            properties: "opacity"
            from: 1.0
            to: 0.0
            duration: JamiTheme.shortFadeDuration
        }
    }
}
