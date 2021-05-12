/*
 * Copyright (C) 2020 by Savoir-faire Linux
 * Author: Mingrui Zhang <mingrui.zhang@savoirfairelinux.com>
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

import QtQuick 2.14
import QtQuick.Controls 2.14
import QtQuick.Layouts 1.14
import QtQuick.Controls.Universal 2.14

import net.jami.Models 1.0
import net.jami.Adapters 1.0
import net.jami.Constants 1.0

import "../../commoncomponents"

Rectangle {
    id: outgoingCallPageRect

    property int buttonPreferredSize: 40
    property int callStatus: 0
    signal callCancelButtonIsClicked

    function updateUI(accountId, convUid) {
        userInfoCallPage.updateUI(accountId, convUid)
        outgoingControlButtons.model = outgoingControlsModel
    }

    anchors.fill: parent

    color: "black"

    ListModel {
        id: outgoingControlsModel
        ListElement { type: "cancel"; image: "qrc:/images/icons/round-close-24px.svg"; enable: true }
    }

    // Prevent right click propagate to VideoCallPage.
    MouseArea {
        anchors.fill: parent
        propagateComposedEvents: false
        acceptedButtons: Qt.AllButtons
        onDoubleClicked: mouse.accepted = true
    }

    ColumnLayout {
        id: outgoingCallPageRectColumnLayout

        anchors.fill: parent

        UserInfoCallPage {
            id: userInfoCallPage
            Layout.fillHeight: true
            Layout.fillWidth: true
        }

        AnimatedImage {
            id: spinnerImage

            Layout.alignment: Qt.AlignCenter
            Layout.preferredWidth: 24
            Layout.preferredHeight: 8

            source: "qrc:/images/waiting.gif"
        }

        Text {
            id: callStatusText

            Layout.alignment: Qt.AlignCenter
            Layout.preferredWidth: outgoingCallPageRect.width
            Layout.preferredHeight: 30

            font.pointSize: JamiTheme.textFontSize

            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter

            text: UtilsAdapter.getCallStatusStr(callStatus) + "…"
            color: Qt.lighter("white", 1.5)
        }

        Rectangle {
            Layout.alignment: Qt.AlignCenter
            Layout.bottomMargin: 48
            Layout.preferredWidth: childrenRect.width
            Layout.preferredHeight: childrenRect.height

            color: JamiTheme.darkGreyColorOpacity
            radius: 4

            RowLayout {
                Repeater {
                    id: outgoingControlButtons
                    model: outgoingControlsModel

                    delegate: ColumnLayout {
                        PushButton {
                            Layout.leftMargin: 10
                            Layout.rightMargin: 10
                            Layout.topMargin: 10

                            Layout.preferredWidth: buttonPreferredSize
                            Layout.preferredHeight: buttonPreferredSize

                            pressedColor: {
                                return type === "cancel" ? JamiTheme.declineButtonPressedRed : JamiTheme.invertedPressedButtonColor
                            }
                            hoveredColor: { 
                                return type === "cancel" ? JamiTheme.declineButtonHoverRed : JamiTheme.invertedHoveredButtonColor
                            }
                            normalColor: { 
                                return type === "cancel" ? JamiTheme.declineButtonRed : JamiTheme.invertedNormalButtonColor
                            }

                            source: image
                            imageColor: JamiTheme.whiteColor

                            toolTipText: {
                                return type === "cancel" ? JamiStrings.hangup : ""                                
                            }

                            onClicked: { 
                                if (type === "cancel")
                                    callCancelButtonIsClicked()
                            }
                        }

                        Label {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.preferredHeight: 20

                            font.pointSize: JamiTheme.indicatorFontSize
                            font.kerning: true
                            color: JamiTheme.whiteColor
                            wrapMode:Text.Wrap

                            text: {
                                if (type === "cancel")
                                    return JamiStrings.optionCancel
                                else
                                    return ""
                            }

                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
                }
            }
        }
    }
}
