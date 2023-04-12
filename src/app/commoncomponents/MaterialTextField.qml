/*
 * Copyright (C) 2022-2023 Savoir-faire Linux Inc.
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
    property color accent: isActive || hovered ? prefixIconColor : JamiTheme.buttonTintedBlue
    property color baseColor: JamiTheme.primaryForegroundColor
    property alias icon: container.data
    property alias infoTipLineText: infoTipLine.text
    property alias infoTipText: infoTip.text
    property bool inputIsValid: true

    // We need to remove focus when another widget takes activeFocus,
    // except the context menu.
    property bool isActive: activeFocus || contextMenu.active
    property bool isSettings: false
    property bool isSwarmDetail: false
    property alias prefixIconColor: prefixIcon.color
    property string prefixIconSrc
    property alias suffixBisIconColor: suffixBisIcon.color
    property string suffixBisIconSrc
    property alias suffixIconColor: suffixIcon.color
    property string suffixIconSrc
    property color textColor: JamiTheme.textColor

    background: null
    color: textColor
    font.kerning: true
    font.pixelSize: JamiTheme.materialLineEditPixelSize
    leftPadding: readOnly || prefixIconSrc === '' || (isSwarmDetail && !root.isActive) ? 0 : 32
    mouseSelectionMode: TextInput.SelectCharacters
    placeholderTextColor: !isActive ? JamiTheme.transparentColor : root.color
    rightPadding: {
        var total = 2;
        if (!readOnly) {
            if (suffixIconSrc !== "")
                total = +30;
            if (suffixBisIconSrc !== "")
                total = +30;
        }
        return total;
    }
    selectByMouse: true
    topPadding: 2
    wrapMode: "NoWrap"

    signal keyPressed

    Component.onCompleted: {
        root.cursorPosition = 0;
    }
    Keys.onPressed: function (event) {
        if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return) {
            if (inputIsValid && acceptableInput) {
                root.accepted();
            }
            event.accepted = true;
        } else {
            root.keyPressed();
        }
    }
    onActiveFocusChanged: {
        root.cursorPosition = 0;
        if (!activeFocus && !contextMenu.active) {
            root.focus = false;
        }
        if (root.focus)
            root.cursorPosition = root.text.length;
    }
    onReleased: function (event) {
        if (event.button === Qt.RightButton)
            contextMenu.openMenuAt(event);
    }

    // Context menu.
    LineEditContextMenu {
        id: contextMenu
        lineEditObj: root
        selectOnly: readOnly
    }

    // The centered placeholder that appears in the design specs.
    Label {
        id: overBaseLineLabel
        anchors.baseline: root.baseline
        anchors.horizontalCenter: !isSwarmDetail ? root.horizontalCenter : undefined
        color: isSwarmDetail ? root.color : root.baseColor
        font.pixelSize: root.font.pixelSize
        text: root.placeholderText
        visible: !root.isActive && !readOnly && root.text.toString() === ""
    }
    Rectangle {
        id: baselineLine
        anchors.top: root.baseline
        anchors.topMargin: 10
        color: isSwarmDetail ? textColor : root.accent
        height: visible ? 1 : 0
        visible: {
            if (!readOnly) {
                if (isSwarmDetail && root.hovered || root.isActive) {
                    return true;
                }
                if (isSwarmDetail) {
                    return false;
                }
                return true;
            }
            return false;
        }
        width: parent.width
    }
    TextFieldIcon {
        id: prefixIcon
        anchors.left: parent.left
        anchors.verticalCenter: root.verticalCenter
        anchors.verticalCenterOffset: -root.bottomPadding / 2
        color: prefixIconColor
        source: prefixIconSrc
    }
    Label {
        id: underBaseLineLabel
        anchors.top: baselineLine.bottom
        anchors.topMargin: 2
        color: root.textColor
        font.pixelSize: JamiTheme.materialLineEditSelectedPixelSize
        text: root.placeholderText

        // Show the alternate placeholder while the user types.
        visible: root.isActive && !readOnly && root.text.toString() !== "" && !root.isSettings && !root.isSwarmDetail
    }
    Item {
        id: container
        anchors.right: suffixBisIcon.left
        anchors.rightMargin: suffixBisIconSrc !== '' ? 5 : root.isActive ? 0 : 20
        anchors.verticalCenter: root.verticalCenter
        anchors.verticalCenterOffset: -root.bottomPadding / 2
        height: suffixIcon.height
        visible: !readOnly
        width: suffixIcon.width

        TextFieldIcon {
            id: suffixIcon
            color: suffixIconColor
            size: 20
            source: suffixIconSrc

            MaterialToolTip {
                id: infoTip
                backGroundColor: JamiTheme.whiteColor
                delay: Qt.styleHints.mousePressAndHoldInterval
                textColor: JamiTheme.blackColor
                visible: parent.hovered && infoTipText.toString() !== ""
            }
        }
    }
    TextFieldIcon {
        id: suffixBisIcon
        anchors.right: parent.right
        anchors.verticalCenter: root.verticalCenter
        anchors.verticalCenterOffset: -root.bottomPadding / 2
        color: suffixBisIconColor
        size: 20
        source: suffixBisIconSrc

        TapHandler {
            cursorShape: Qt.ArrowCursor

            onTapped: {
                modalTextEditRoot.icoClicked();
            }
        }
    }
    MaterialToolTip {
        id: infoTipLine
        delay: Qt.styleHints.mousePressAndHoldInterval
        visible: parent.hovered && infoTipLineText.toString() !== "" && !readOnly
        y: implicitHeight
    }

    component TextFieldIcon: ResponsiveImage {
        property real size: 18

        height: size
        opacity: root.isActive && !readOnly && source.toString() !== ''
        visible: opacity
        width: visible ? size : 0

        HoverHandler {
            cursorShape: Qt.ArrowCursor
        }

        Behavior on opacity  {
            NumberAnimation {
                duration: JamiTheme.longFadeDuration / 2
            }
        }
    }
}
