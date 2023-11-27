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

    // convenient access to closePolicy
    property bool autoClose: true
    property alias backgroundColor: container.color
    property alias backgroundOpacity: container.background.opacity
    property alias title: titleText.text
    property var popupcontainerSubContentLoader: containerSubContentLoader

    property bool closeButtonVisible: true
    property int button1Role
    property int button2Role

    property alias button1: action1
    property alias button2: action2

    property alias popupContentLoadStatus: containerSubContentLoader.status
    property alias popupContent: containerSubContentLoader.sourceComponent

    property int popupMargins: 30
    property int buttonMargin: 20
    property int maximumPopupWidth: 600

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
        bottomPadding: action1.visible || action2.visible ? 10 : popupMargins

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
                objectName: "closeButton"

                visible: closeButtonVisible

                Layout.alignment: Qt.AlignRight | Qt.AlignTop
                Layout.preferredHeight: 20
                Layout.preferredWidth: 20
                Layout.topMargin: 5
                Layout.rightMargin: 5

                imageColor: hovered ? JamiTheme.textColor : JamiTheme.buttonTintedGreyHovered
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

            JamiFlickable {
                id: flickable

                Layout.fillHeight: true

                Layout.preferredHeight: Math.min(contentHeight, root.height)
                Layout.preferredWidth: contentItem.childrenRect.width
                Layout.rightMargin: popupMargins
                Layout.alignment: Qt.AlignCenter

                contentHeight: contentItem.childrenRect.height

                contentItem.children: Loader {
                    id: containerSubContentLoader
                }
                ScrollBar.horizontal.visible: false
            }

            DialogButtonBox {
                id: buttonBox
                Layout.alignment: Qt.AlignRight
                spacing: 1.5

                background: Rectangle {

                    color: "transparent"
                    width: buttonBox.childrenRect.width
                    height: buttonBox.childrenRect.height
                }

                visible: action1.text.length > 0
                contentHeight: childrenRect.height + 14

                MaterialButton {
                    id: action1

                    visible: text.length > 0
                    rightPadding: buttonMargin
                    leftPadding: buttonMargin
                    tertiary: true
                    autoAccelerator: true

                    DialogButtonBox.buttonRole: root.button1Role
                }

                MaterialButton {
                    id: action2

                    visible: text.length > 0
                    rightPadding: buttonMargin
                    leftPadding: buttonMargin
                    tertiary: true
                    autoAccelerator: true

                    DialogButtonBox.buttonRole: root.button2Role
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
