/*
 * Copyright (C) 2020-2021 by Savoir-faire Linux
 * Author: Mingrui Zhang <mingrui.zhang@savoirfairelinux.com>
 *         Aline Gondim Santos <aline.gondimsantos@savoirfairelinux.com>
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
    id: root

    property int buttonPreferredSize: 50
    property bool isIncoming: false
    property var accountPeerPair: ["",""]
    property int callStatus: 0
    property string bestName: "Best Name"

    signal callCancelButtonIsClicked
    signal callAcceptButtonIsClicked

    color: "black"

    ListModel {
        id: incomeControlsModel
        ListElement { type: "refuse"; image: "qrc:/images/icons/round-close-24px.svg"}
        ListElement { type: "accept"; image: "qrc:/images/icons/check-24px.svg"}
    }
    ListModel {
        id: outcomeControlsModel
        ListElement { type: "cancel"; image: "qrc:/images/icons/round-close-24px.svg"}
    }

    onAccountPeerPairChanged: {
        if (accountPeerPair[1]) {
            contactImg.updateImage(accountPeerPair[1])
            root.bestName = UtilsAdapter.getBestName(accountPeerPair[0], accountPeerPair[1])
        }
    }

    // Prevent right click propagate to VideoCallPage.
    MouseArea {
        anchors.fill: parent
        propagateComposedEvents: false
        acceptedButtons: Qt.AllButtons
        onDoubleClicked: mouse.accepted = true
    }

    ColumnLayout {
        anchors.horizontalCenter: root.horizontalCenter
        anchors.verticalCenter: root.verticalCenter

        AvatarImage {
            id: contactImg

            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: JamiTheme.avatarSizeInitialCall
            Layout.preferredHeight: JamiTheme.avatarSizeInitialCall

            mode: AvatarImage.Mode.FromConvUid
            showPresenceIndicator: false
            showSpinningAnimation: true
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: root.width
            Layout.topMargin: 32

            font.pointSize: JamiTheme.titleFontSize

            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter

            text: root.isIncoming ? JamiStrings.incomingCallFrom + " " + root.bestName : root.bestName
            wrapMode: Text.WordWrap
            color: "white"
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: root.width
            Layout.topMargin: 8

            font.pointSize: JamiTheme.textFontSize

            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter

            text: UtilsAdapter.getCallStatusStr(callStatus) + "…"
            color: Qt.lighter("white", 1.5)
            visible: !root.isIncoming
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 32

            Repeater {
                id: controlButtons
                model: root.isIncoming ? incomeControlsModel : outcomeControlsModel

                delegate: ColumnLayout {
                    PushButton {
                        Layout.leftMargin: 10
                        Layout.rightMargin: 10
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: buttonPreferredSize
                        Layout.preferredHeight: buttonPreferredSize

                        pressedColor: {
                            if (type === "accept" )
                                return JamiTheme.acceptButtonPressedGreen
                            return JamiTheme.declineButtonPressedRed
                        }
                        hoveredColor: {
                            if (type === "accept" )
                                return JamiTheme.acceptButtonHoverGreen
                            return JamiTheme.declineButtonHoverRed
                        }
                        normalColor: {
                            if (type === "accept" )
                                return JamiTheme.acceptButtonGreen
                            return JamiTheme.declineButtonRed
                        }

                        source: image
                        imageColor: JamiTheme.whiteColor

                        onClicked: {
                            if (type === "accept")
                                callAcceptButtonIsClicked()
                            else
                                callCancelButtonIsClicked()
                        }
                    }

                    Label {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: 5

                        font.pointSize: JamiTheme.indicatorFontSize
                        font.kerning: true
                        color: JamiTheme.whiteColor

                        text: {
                            if (type === "refuse")
                                return JamiStrings.refuse
                            else if (type === "accept")
                                return JamiStrings.accept
                            else if (type === "cancel")
                                return JamiStrings.endCall
                            return ""
                        }

                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }
        }
    }

    Shortcut {
        sequence: "Ctrl+Y"
        context: Qt.ApplicationShortcut
        onActivated: {
            CallAdapter.acceptACall(root.accountPeerPair[0],
                                    root.accountPeerPair[1])
            communicationPageMessageWebView.setSendContactRequestButtonVisible(false)
        }
    }

    Shortcut {
        sequence: "Ctrl+Shift+D"
        context: Qt.ApplicationShortcut
        onActivated: {
            CallAdapter.hangUpACall(root.accountPeerPair[0],
                                    root.accountPeerPair[1])
        }
    }
}
