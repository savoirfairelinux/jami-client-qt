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
import QtQuick.Effects
import net.jami.Adapters 1.1
import net.jami.Models 1.1
import net.jami.Constants 1.1
import "../../commoncomponents"

Item {
    id: root

    signal digitPressed(string digit)

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
        "*": "",
        "0": "",
        "#": "",
        "+": ""
    }

    property alias radius: inputPanelContent.radius
    property alias topRightRadius: inputPanelContent.topRightRadius
    property alias bottomRightRadius: inputPanelContent.bottomRightRadius

    implicitWidth: inputPanelContent.implicitWidth
    implicitHeight: inputPanelContent.implicitHeight

    Rectangle {
        id: inputPanelContent
        implicitWidth: sipInputPanelRectGridLayout.implicitWidth + 20
        implicitHeight: sipInputPanelRectGridLayout.implicitHeight + 20
        topLeftRadius: JamiTheme.sipInputPanelRadius
        bottomLeftRadius: JamiTheme.sipInputPanelRadius
        topRightRadius: JamiTheme.sipInputPanelRadius
        bottomRightRadius: JamiTheme.sipInputPanelRadius
        anchors.fill: parent

        color: Qt.rgba(JamiTheme.globalIslandColor.r, JamiTheme.globalIslandColor.g, JamiTheme.globalIslandColor.b, 0.9)

        layer.enabled: true
        layer.effect: MultiEffect {
            autoPaddingEnabled: true

            shadowEnabled: true
            shadowBlur: JamiTheme.shadowBlur
            shadowColor: JamiTheme.shadowColor
            shadowHorizontalOffset: JamiTheme.shadowHorizontalOffset
            shadowVerticalOffset: JamiTheme.shadowVerticalOffset
            shadowOpacity: JamiTheme.shadowOpacity
        }

        GridLayout {
            id: sipInputPanelRectGridLayout

            anchors.centerIn: parent

            columns: 3

            Repeater {
                id: sipInputPanelRectGridLayoutRepeater
                model: ["1", "2", "3", "4", "5", "6", "7", "8", "9", "*", "0", "#", "+"]

                RoundButton {
                    id: sipInputPanelButton

                    Layout.preferredWidth: JamiTheme.sipInputPanelKeyDiameter
                    Layout.preferredHeight: JamiTheme.sipInputPanelKeyDiameter
                    // Center the '+' button in its row
                    Layout.columnSpan: modelData === "+" ? 3 : 1
                    Layout.alignment: modelData === "+" ? Qt.AlignHCenter : 0

                    contentItem: Item {
                        anchors.fill: parent

                        Text {
                            text: modelData
                            font.pointSize: 12
                            horizontalAlignment: Text.AlignHCenter

                            color: JamiTheme.blackColor

                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.top: digitToLetters[modelData] !== "" ? parent.top : undefined
                            anchors.centerIn: digitToLetters[modelData] === "" ? parent : undefined
                            anchors.topMargin: 6
                        }
                        Text {
                            text: digitToLetters[modelData]
                            font.pointSize: 6
                            horizontalAlignment: Text.AlignHCenter

                            color: JamiTheme.blackColor
                            opacity: 0.8

                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 6

                            visible: text !== ""
                        }
                    }

                    background: Rectangle {
                        id: circle
                        radius: width / 2
                        color: sipInputPanelButton.down ? (JamiTheme.pressedButtonColor) : (sipInputPanelButton.hovered ? JamiTheme.hoveredButtonColor : JamiTheme.normalButtonColor)
                    }

                    onClicked: {
                        CallAdapter.sipInputPanelPlayDTMF(modelData);
                        root.digitPressed(modelData);
                    }
                }
            }
        }
    }
}
