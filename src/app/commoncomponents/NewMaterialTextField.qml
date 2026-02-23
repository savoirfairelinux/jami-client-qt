/*
 * Copyright (C) 2026 Savoir-faire Linux Inc.
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

import net.jami.Constants 1.1

ColumnLayout {
    id: root

    // Leading icon properties
    property string leadingIconSource: ""

    // TextField properties
    property string placeholderText: ""
    property alias textFieldContent: textField.text
    property string modifiedTextFieldContent
    property int maxCharacters: -1
    property bool readOnly: false
    property real textFieldFontPixelSize: JamiTheme.materialLineEditPixelSize
    signal accepted()

    // Trailing icon properties
    property string trailingIconSource: ""
    property string trailingIconToolTipText: ""
    signal trailingIconClicked()

    // Tooltip properties
    property alias toolTipText: toolTip.text

    // Background properties
    property color borderColor: JamiTheme.tintedBlue

    opacity: textField.activeFocus ? 1.0 : 0.7

    Behavior on opacity {
        NumberAnimation {
            duration: JamiTheme.shortFadeDuration
        }
    }

    Control {
        id: textFieldEditor

        Layout.fillWidth: true
        Layout.preferredHeight: JamiTheme.newMaterialTextFieldHeight
        Layout.maximumHeight: JamiTheme.newMaterialTextFieldHeight

        leftPadding: root.leadingIconSource !== "" ? 12 : 16
        rightPadding: root.trailingIconSource !== "" ? 12 : 16
        topPadding: 8
        bottomPadding: 8

        contentItem: RowLayout {
            spacing: 0

            Button {
                id: leadingIcon

                Layout.alignment: Qt.AlignVCenter

                width: icon.width
                height: icon.height

                icon.width: JamiTheme.iconButtonMedium
                icon.height: JamiTheme.iconButtonMedium
                icon.source: root.leadingIconSource
                icon.color: JamiTheme.textColor

                background: null

                // This shouldnt be interactive, so we disable its background
                // and fix the icon's colour
                enabled: false

                activeFocusOnTab: false

                visible: root.leadingIconSource !== ""
            }


            TextField {
                id: textField

                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter

                placeholderText: root.placeholderText
                placeholderTextColor: JamiTheme.textColor
                verticalAlignment: TextInput.AlignVCenter
                color: JamiTheme.textColor
                font.pixelSize: root.textFieldFontPixelSize

                maximumLength: root.maxCharacters ? root.maxCharacters : 32767
                readOnly: root.readOnly
                wrapMode: TextInput.NoWrap

                background: null

                onReleased: function (event) {
                    if (event.button === Qt.RightButton)
                        contextMenu.openMenuAt(event);
                }

                onAccepted: root.accepted()

                onTextChanged: root.modifiedTextFieldContent = text

                LineEditContextMenu {
                    id: contextMenu

                    lineEditObj: parent
                    selectOnly: root.readOnly
                }
            }


            NewIconButton {
                id: trailingIcon

                Layout.alignment: Qt.AlignVCenter

                iconSize: JamiTheme.iconButtonMedium
                iconSource: root.trailingIconSource
                toolTipText: root.trailingIconToolTipText

                onClicked: root.trailingIconClicked()

                activeFocusOnTab: iconSource !== ""

                background: null

                Behavior on opacity {
                    NumberAnimation {
                        duration: JamiTheme.shortFadeDuration
                    }
                }
            }
        }

        background: Rectangle {
            id: bgRect

            color: JamiTheme.backgroundColor
            radius: JamiTheme.iconButtonMedium / 2 + parent.rightPadding

            border.width: 2
            border.color: {
                if (textField.activeFocus)
                    root.borderColor
                else
                    JamiTheme.grey_
            }

            Behavior on border.color {
                ColorAnimation  {
                    duration: JamiTheme.shortFadeDuration
                }
            }
        }

        MaterialToolTip {
            id: toolTip

            parent: parent
            visible: parent.hovered && root.toolTipText !== "" && !root.readOnly
            delay: Qt.styleHints.mousePressAndHoldInterval
        }
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: 4
        Layout.leftMargin: textFieldEditor.background.radius
        Layout.rightMargin: textFieldEditor.background.radius

        opacity: textField.activeFocus && root.maxCharacters >= 0 ? 1.0 : 0.0

        Behavior on opacity {
            NumberAnimation {
                duration: JamiTheme.shortFadeDuration
            }
        }

        Text {
            Layout.fillWidth: true
            text: "Maximum characters"
            font.pixelSize: JamiTheme.smallFontSize
            color: JamiTheme.textColor
        }

        Text {
            Layout.alignment: Qt.AlignRight
            Layout.leftMargin: textFieldEditor.background.radius

            visible: maxCharacters !== undefined
            text: textField.text.length + " / " + maxCharacters
            font.pixelSize: JamiTheme.smallFontSize
            color: JamiTheme.textColor
        }
    }
}
