// SPDX-FileCopyrightText: © 2022 Savoir-faire Linux Inc.
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtQuick.Controls

import net.jami.Constants 1.1

TextField {
    id: root

    property bool isActive: activeFocus

    property int inputIsValid: text.length <= 5

    property color accent: isActive
                           ? (inputIsValid ? '#03b9e9' : 'red')
                           : '#005699'
    property color baseColor: '#000000'
    color: (inputIsValid || readOnly) ? JamiTheme.textColor : accent
    placeholderTextColor: !isActive ? 'transparent' : 'grey'

    wrapMode: Text.Wrap
    font.kerning: true
    selectByMouse: true
    mouseSelectionMode: TextInput.SelectCharacters

    leftPadding: 32
    rightPadding: 32
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
        } else if (event.key === Qt.Key_Escape) {
            focus = false
        }
    }

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
        anchors.bottom: root.bottom
        anchors.bottomMargin: root.font.pointSize * 0.75
        color: root.accent
        visible: !readOnly
    }

    Rectangle {
        id: statusIcon
        width: 16
        height: 16
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: -root.bottomPadding / 2
        color: root.accent
        visible: root.isActive && !readOnly
    }

    Label {
        id: underBaseLineLabel
        font.pointSize: root.font.pointSize / 1.5
        anchors.top: baselineLine.bottom
        anchors.topMargin: 2
        text: root.placeholderText
        color: root.baseColor
        visible: root.text.toString() !== '' && !readOnly
    }

    Rectangle {
        id: infoIcon
        width: 16
        height: 16
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: -root.bottomPadding / 2
        color: '#005699'
        visible: !readOnly
    }

    background: null
}
