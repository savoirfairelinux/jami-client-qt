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
import Qt.labs.platform 1.1

import net.jami.Models 1.0
import net.jami.Adapters 1.0
import net.jami.Constants 1.0

import "../../commoncomponents"

Rectangle {
    id: incomingCallPage

    property int buttonPreferredSize: 48

    signal callCancelButtonIsClicked
    signal callAcceptButtonIsClicked

    color: "transparent"
    
    ListModel {
        id: incomeControlsModel
        ListElement { type: "cancel"; image: "qrc:/images/icons/round-close-24px.svg" }
        ListElement { type: "accept"; image: "qrc:/images/icons/check-24px.svg" }
        ListElement { type: "cam"; image: "qrc:/images/icons/videocam-24px.svg" }
        ListElement { type: "chat"; image: "qrc:/images/icons/chat-24px.svg" }
    }

    function updateUI(accountId, convUid, isAudioOnly) {
        userInfoIncomingCallPage.updateUI(accountId, convUid, isAudioOnly, true)
        if (isAudioOnly)
            incomeControlsModel.setProperty(2, "image", "qrc:/images/icons/videocam_off-24px.svg")
        else
            incomeControlsModel.setProperty(2, "image", "qrc:/images/icons/videocam-24px.svg")
        incomeControlButtons.model = incomeControlsModel
    }

    // Prevent right click propagate to VideoCallPage.
    MouseArea {
        anchors.fill: parent
        propagateComposedEvents: false
        acceptedButtons: Qt.AllButtons
        onDoubleClicked: mouse.accepted = true
    }

    ColumnLayout {
        id: incomingCallPageColumnLayout

        anchors.fill: parent

        // Common elements with OutgoingCallPage
        UserInfoCallPage {
            id: userInfoIncomingCallPage
            Layout.fillWidth: true
            Layout.fillHeight: true
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
                    id: incomeControlButtons
                    model: incomeControlsModel

                    delegate: ColumnLayout {
                        PushButton {
                            Layout.leftMargin: 10
                            Layout.rightMargin: 10
                            Layout.topMargin: 10

                            Layout.preferredWidth: buttonPreferredSize
                            Layout.preferredHeight: buttonPreferredSize

                            pressedColor: {
                                var theme = JamiTheme.invertedPressedButtonColor
                                if (type === "cancel" )
                                    theme = JamiTheme.declineButtonPressedRed
                                else if (type === "accept")
                                    theme = JamiTheme.acceptButtonPressedGreen
                                return theme
                            }
                            hoveredColor: {
                                var theme = JamiTheme.invertedHoveredButtonColor
                                if (type === "cancel" )
                                    theme = JamiTheme.declineButtonHoverRed
                                else if (type === "accept")
                                    theme = JamiTheme.acceptButtonHoverGreen
                                return theme
                            }
                            normalColor: {
                                var theme = JamiTheme.invertedHoveredButtonColor
                                if (type === "cancel" )
                                    theme = JamiTheme.declineButtonRed
                                else if (type === "accept")
                                    theme = JamiTheme.acceptButtonGreen
                                return theme
                            }
                            
                            source: image
                            imageColor: JamiTheme.whiteColor

                            toolTipText: {
                                return type === "cancel" ? JamiStrings.hangup : ""                                
                            }

                            onClicked: { 
                                if (type === "cancel")
                                    callCancelButtonIsClicked()
                                else if (type === "accept")
                                    callAcceptButtonIsClicked()
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
                                else if (type === "accept")
                                    return JamiStrings.accept
                                else if (type === "cam")
                                    return JamiStrings.camera
                                else if (type === "chat")
                                    return JamiStrings.message
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

    Shortcut {
        sequence: "Ctrl+Y"
        context: Qt.ApplicationShortcut
        onActivated: {
            incomingCallPage.close()
            CallAdapter.acceptACall(responsibleAccountId,
                                    responsibleConvUid)
            communicationPageMessageWebView.setSendContactRequestButtonVisible(false)
        }
    }

    Shortcut {
        sequence: "Ctrl+Shift+D"
        context: Qt.ApplicationShortcut
        onActivated: {
            incomingCallPage.close()
            CallAdapter.refuseACall(responsibleAccountId,
                                    responsibleConvUid)
        }
    }
}
