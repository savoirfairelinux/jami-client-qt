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
import net.jami.Adapters 1.1
import net.jami.Models 1.1
import net.jami.Constants 1.1
import "../../commoncomponents"

// SipInputPanel is a key pad that is designed to be
// used in sip calls.

Rectangle {
    id: root

    readonly property var digitToLetters: {
        "1": "",
        "2": "ABC",
        "3": "DEF",
        "4": "GHI",
        "5": "JKL",
        "6": "MNO",
        "7": "PQRS",
        "8": "TUV",
        "9": "WXYZ",
        "0": "+",
        "*": "",
        "#": ""
    }

    function getLetters(letter) {
        return digitToLetters[letter];
    }

    implicitWidth: sipInputPanelRectGridLayout.implicitWidth + 20
    implicitHeight: sipInputPanelRectGridLayout.implicitHeight + 20
    color: JamiTheme.backgroundColor

    GridLayout {
        id: sipInputPanelRectGridLayout

        anchors.centerIn: parent

        columns: 3

        Repeater {
            id: sipInputPanelRectGridLayoutRepeater
            model: ["1", "2", "3", "4", "5", "6", "7", "8", "9", "*", "0", "#"]

            RoundButton {
                id: sipInputPanelButton

                Layout.preferredWidth: 40
                Layout.preferredHeight: 40

                contentItem: Item {
                    anchors.fill: parent

                    Text {
                        text: modelData
                        font.pointSize: 12
                        horizontalAlignment: Text.AlignHCenter

                        color: JamiTheme.textColor

                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: getLetters(modelData) !== "" ? parent.top : null
                        anchors.centerIn: getLetters(modelData) === "" ? parent : null
                        anchors.topMargin: 6
                    }

                    Text {
                        text: getLetters(modelData)
                        font.pointSize: 6
                        horizontalAlignment: Text.AlignHCenter

                        color: JamiTheme.textColor
                        opacity: 0.8

                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 6

                        visible: text !== ""
                    }
                }

                background: Rectangle {
                    radius: width / 2
                    color: sipInputPanelButton.down ? (JamiTheme.buttonTintedGreyPressed) : (sipInputPanelButton.hovered ? JamiTheme.buttonTintedGreyHovered : JamiTheme.buttonTintedGrey)
                    border.color: JamiTheme.tintedBlue
                    border.width: sipInputPanelButton.hovered ? 2 : 1
                }
                onClicked: {
                    CallAdapter.sipInputPanelPlayDTMF(modelData);
                }
            }
        }
    }
}
