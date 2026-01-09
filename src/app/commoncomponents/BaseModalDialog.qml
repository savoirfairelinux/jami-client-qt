/*
 * Copyright (C) 2020-2025 Savoir-faire Linux Inc.
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

Dialog {
    id: root

    // convient access to closePolicy
    property bool autoClose: true
    property alias backgroundColor: background.color
    property alias backgroundOpacity: background.opacity
    property var dialogContentSubContentLoader: dialogContentSubContentLoader

    property bool closeButtonVisible: true
    property int button1Role
    property int button2Role
    property int button3Role

    property alias button1: action1
    property alias button2: action2
    property alias button3: action3

    property alias dialogContentLoadStatus: dialogContentSubContentLoader.status
    property alias dialogContent: root.contentItem// dialogContentSubContentLoader.sourceComponent

    property int popupMargins: 30
    property int buttonMargin: 20
    property int maximumPopupWidth: 600

    parent: Overlay.overlay
    anchors.centerIn: parent
    modal: true

    focus: true
    closePolicy: autoClose ? (Popup.CloseOnEscape | Popup.CloseOnPressOutside) : Popup.NoAutoClose

    header: Control {
        padding: JamiTheme.preferredMarginSize
        
        contentItem: RowLayout {
            Text {
                id: titleText

                Layout.fillWidth: true
                Layout.alignment: Qt.AlignLeft

                text: title
                verticalAlignment: Text.AlignVCenter
                font.pointSize: JamiTheme.menuFontSize
                font.bold: true
                color: JamiTheme.textColor

                visible: text.length > 0
            }

            NewIconButton {
                id: closeButton
                QWKSetParentHitTestVisible {}

                Layout.alignment: Qt.AlignRight

                iconSize: JamiTheme.iconButtonMedium
                iconSource: JamiResources.round_close_24dp_svg
                toolTipText: JamiStrings.close

                visible: closeButtonVisible

                onClicked: close()

                Accessible.role: Accessible.Button
                Accessible.name: JamiStrings.close
            }
        }
    }

    contentItem: ColumnLayout {
        id: dialogContent

        Layout.fillWidth: true
        Layout.fillHeight: true

        JamiFlickable {
            id: flickable

            Layout.fillHeight: true
            Layout.preferredHeight: Math.min(contentHeight, root.height)
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignCenter

            contentHeight: contentItem.childrenRect.height

            contentItem.children: Loader {
                id: dialogContentSubContentLoader
            }

            ScrollBar.horizontal.visible: false
        }
    }

    footer: Control {
        padding: JamiTheme.preferredMarginSize
        
        contentItem: RowLayout {
            MaterialButton {
                id: action1

                Layout.fillWidth: true

                tertiary: true
                autoAccelerator: true
                DialogButtonBox.buttonRole: root.button1Role

                visible: text.length > 0
            }

            MaterialButton {
                id: action2

                Layout.fillWidth: true

                tertiary: true
                autoAccelerator: true
                DialogButtonBox.buttonRole: root.button2Role

                visible: text.length > 0
            }

            MaterialButton {
                id: action3

                Layout.fillWidth: true

                tertiary: true
                autoAccelerator: true
                DialogButtonBox.buttonRole: root.button3Role

                visible: text.length > 0
            }
        }
    }

    background: Rectangle {
        id: background

        color: JamiTheme.globalBackgroundColor
        radius: JamiTheme.commonRadius
    }

    Overlay.modal: Rectangle {
        color: JamiTheme.transparentColor

        // Color animation for overlay when pop up is shown.
        ColorAnimation on color {
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
