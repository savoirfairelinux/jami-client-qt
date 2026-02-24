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

// This component will attempt to occupy the maximum width of the layout
// If width constraints are required, use Layout.maximumWidth
ColumnLayout {
    id: root

    property bool isTall: false

    // Leading icon properties
    // The icon colour is only exposed here for the sake of UsernameTextEdit,
    // ideally it should remain untouched for consistency throughout the UI
    property color leadingIconColor: JamiTheme.textColor
    property string leadingIconSource: ""

    // TextField properties
    property real textFieldHeight: isTall ? JamiTheme.newMaterialTextFieldTallHeight : JamiTheme.newMaterialTextFieldHeight
    property string placeholderText: ""
    property alias textFieldContent: textField.text
    property string modifiedTextFieldContent
    property int maxCharacters: -1
    property bool readOnly: false
    property real textFieldFontPixelSize: JamiTheme.materialLineEditPixelSize
    property int echoMode: TextInput.Normal
    property bool inputIsValid: true
    property var validator: RegularExpressionValidator {
        id: defaultValidator
    }
    signal accepted()

    // Trailing icon properties
    property color trailingIconColor: JamiTheme.textColor
    property string trailingIconSource: ""
    property string trailingIconToolTipText: ""
    property bool trailingIconChecked: false
    signal trailingIconClicked()

    // Tooltip properties
    property alias toolTipText: toolTip.text

    // Supporting text
    property string supportingText: ""
    property color supportingTextColor: JamiTheme.textColor

    // Background properties
    property color borderColor: JamiTheme.tintedBlue

    opacity: textField.activeFocus ? 1.0 : 0.7

    Behavior on opacity {
        NumberAnimation {
            duration: JamiTheme.shortFadeDuration
        }
    }

    Layout.fillWidth: true

    Control {
        id: textFieldEditor

        Layout.fillWidth: true
        Layout.preferredHeight: root.textFieldHeight
        Layout.maximumHeight: root.textFieldHeight

        leftPadding: root.leadingIconSource !== "" ? JamiTheme.newMaterialTextFieldIconHorizontalPadding : JamiTheme.newMaterialTextFieldHorizontalPadding
        rightPadding: root.trailingIconSource !== "" ? JamiTheme.newMaterialTextFieldIconHorizontalPadding : JamiTheme.newMaterialTextFieldHorizontalPadding
        topPadding: (textFieldHeight / JamiTheme.iconButtonMedium) / 2
        bottomPadding: (textFieldHeight / JamiTheme.iconButtonMedium) / 2

        contentItem: RowLayout {
            spacing: 0

            Button {
                id: leadingIcon

                Layout.alignment: Qt.AlignVCenter

                width: JamiTheme.iconButtonMedium
                height: JamiTheme.iconButtonMedium

                icon.width: JamiTheme.iconButtonMedium
                icon.height: JamiTheme.iconButtonMedium
                icon.source: root.leadingIconSource
                icon.color: root.leadingIconColor

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
                horizontalAlignment: TextInput.AlignLeft

                color: JamiTheme.textColor
                font.pixelSize: root.textFieldFontPixelSize

                maximumLength: root.maxCharacters ? root.maxCharacters : 32767
                readOnly: root.readOnly
                wrapMode: TextInput.NoWrap

                echoMode: root.echoMode
                validator: root.validator

                background: null

                onReleased: function (event) {
                    if (event.button === Qt.RightButton)
                        contextMenu.openMenuAt(event);
                }

                onAccepted: {
                        root.accepted()
                }

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

                checked: root.trailingIconChecked

                background: null

                visible: root.trailingIconSource !== "" && !readOnly

                Behavior on opacity {
                    NumberAnimation {
                        duration: JamiTheme.shortFadeDuration
                    }
                }
            }
        }

        background: Rectangle {
            id: bgRect

            color: JamiTheme.searchBarColor
            radius: JamiTheme.iconButtonMedium / 2 + parent.rightPadding

            border.width: 1
            border.color: textField.activeFocus ? root.borderColor : JamiTheme.transparentColor

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
        Layout.topMargin: JamiTheme.newMaterialTextFieldSupportingTextTopPadding
        Layout.leftMargin: textFieldEditor.background.radius
        Layout.rightMargin: textFieldEditor.background.radius

        visible: root.supportingText !== ""

        Text {
            Layout.fillWidth: true
            text: root.supportingText
            font.pixelSize: JamiTheme.mediumFontSize
            color: root.supportingTextColor
        }
    }
}
