/*
 * Copyright (C) 2022 Savoir-faire Linux Inc.
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
import Qt5Compat.GraphicalEffects

import net.jami.Constants 1.1

TextField {
    id: root

    // We need to remove focus when another widget takes activeFocus,
    // except the context menu.
    property bool isActive: activeFocus || contextMenu.active
    onActiveFocusChanged: {
        if (!activeFocus && !contextMenu.active) {
            root.focus = false
        }
    }

    property bool inputIsValid: true

    property string prefixIconSrc
    property alias prefixIconColor: prefixIcon.color
    property string suffixIconSrc
    property alias suffixIconColor: suffixIcon.color
    property color accent: isActive
                           ? prefixIconColor
                           : JamiTheme.buttonTintedBlue
    property color baseColor: JamiTheme.primaryForegroundColor
    color: JamiTheme.textColor
    placeholderTextColor: !isActive
                          ? JamiTheme.transparentColor
                          : JamiTheme.placeholderTextColor

    property alias infoTipText: infoTip.text

    wrapMode: Text.Wrap
    font.pointSize: JamiTheme.materialLineEditPointSize
    font.kerning: true
    selectByMouse: true
    mouseSelectionMode: TextInput.SelectCharacters

    height: implicitHeight
    leftPadding: readOnly || prefixIconSrc === '' ? 0 : 32
    rightPadding: readOnly || suffixIconSrc === '' ? 0 : 32
    bottomPadding: 20
    topPadding: 2

    onIsActiveChanged: if (!isActive && !readOnly) text = ''
    Keys.onPressed: function (event) {
        if (event.key === Qt.Key_Enter
                || event.key === Qt.Key_Return) {
            if (inputIsValid) {
                root.accepted()
            }
            event.accepted = true
        }
    }

    // Context menu.
    LineEditContextMenu {
        id: contextMenu

        lineEditObj: root
        selectOnly: readOnly
    }
    onReleased: function (event) {
        if (event.button === Qt.RightButton)
            contextMenu.openMenuAt(event)
    }

    // The centered placeholder that appears in the design specs.
    Label {
        id: overBaseLineLabel
        font.pointSize: root.font.pointSize
        anchors.baseline: root.baseline
        anchors.horizontalCenter: root.horizontalCenter
        text: root.placeholderText
        color: root.baseColor
        visible: !root.isActive && !readOnly
    }

    Rectangle {
        id: baselineLine
        width: parent.width
        height: 1
        anchors.top: root.baseline
        anchors.topMargin: root.font.pointSize
        color: root.accent
        visible: !readOnly
    }

    component TextFieldIcon: ResponsiveImage {
        property real size: 18
        width: visible ? size : 0
        height: size
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: -root.bottomPadding / 2
        opacity: root.isActive && !readOnly && source.toString() !== ''
        visible: opacity
        HoverHandler { cursorShape: Qt.ArrowCursor }
        Behavior on opacity {
            NumberAnimation { duration: JamiTheme.longFadeDuration }
        }
    }

    TextFieldIcon {
        id: prefixIcon
        anchors.left: parent.left
        color: prefixIconColor
        source: prefixIconSrc
    }

    Label {
        id: underBaseLineLabel
        font.pointSize: root.font.pointSize - 3
        anchors.top: baselineLine.bottom
        anchors.topMargin: 2
        text: root.placeholderText
        color: root.baseColor

        // Show the alternate placeholder while the user types.
        visible: root.text.toString() !== '' && !readOnly
    }

    TextFieldIcon {
        id: suffixIcon
        size: 20
        anchors.right: parent.right
        color: suffixIconColor
        source: suffixIconSrc

        MaterialToolTip {
            id: infoTip
            textColor: JamiTheme.blackColor
            backGroundColor: JamiTheme.whiteColor
            visible: parent.hovered && infoTipText.toString() !== ''
            delay: Qt.styleHints.mousePressAndHoldInterval
        }
    }

    background: null
}
