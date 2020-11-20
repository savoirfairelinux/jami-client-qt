/*
 * Copyright (C) 2020 by Savoir-faire Linux
 * Author: Sébastien Blin <sebastien.blin@savoirfairelinux.com>
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
import QtGraphicalEffects 1.14
import net.jami.Models 1.0
import QtQuick.Layouts 1.14

import "../../commoncomponents"

// Buttons for conference moderation
Rectangle {
    id: root

    property var participantName: "Juan Balderramas Romero"
    property var minimumOverlayWidth: 200

    property bool isModerator: false
    property bool isMuted: false
    property bool isMaximized: false
    property bool isHost: false
    property bool participantIsHost: false
    property bool isMinimumWidth: true
    property real scaleFactor: isMinimumWidth? 1.5 : 1
    property int buttonPreferredSize: 32 * scaleFactor

    width: 180
    height: 120
    radius: 8
    color: isMinimumWidth? "transparent" : "gray"

    ColumnLayout {
        id: lay
        //Layout.fillWidth: true
        //Layout.fillHeight: true
        //Layout.alignment: Qt.AlignHCenter | Qt.AlignBottom
        anchors.horizontalCenter: root.horizontalCenter
        anchors.verticalCenter: root.verticalCenter
        spacing: 12 * scaleFactor

        Text {
            id: pName

            TextMetrics {
                id: participantMetrics
                text: participantName
                elide: Text.ElideRight
                elideWidth: root.width - JamiTheme.preferredMarginSize * 2
            }

            text: participantMetrics.elidedText

            color: "white"
            font.pointSize: JamiTheme.headerFontSize
            Layout.alignment: Qt.AlignHCenter

            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter | Qt.AlignBottom
            spacing: 8 * scaleFactor

            PushButton {
                id: toggleModerator

                Layout.preferredWidth: buttonPreferredSize
                Layout.preferredHeight: buttonPreferredSize

                normalColor: JamiTheme.buttonTintedBlue
                hoveredColor: JamiTheme.buttonTintedBlueHovered
                pressedColor: JamiTheme.buttonTintedBluePressed

                source: "qrc:/images/icons/moderator.svg"
                imageColor: JamiTheme.blackColor

                toolTipText: !isModerator? JamiStrings.setModerator
                                         : JamiStrings.unsetModerator

                onClicked: CallAdapter.hangUpThisCall()
            }

            PushButton {
                id: toggleMute

                Layout.preferredWidth: buttonPreferredSize
                Layout.preferredHeight: buttonPreferredSize

                normalColor: JamiTheme.buttonTintedBlue
                hoveredColor: JamiTheme.buttonTintedBlueHovered
                pressedColor: JamiTheme.buttonTintedBluePressed

                source: "qrc:/images/icons/mic_off-24px.svg"
                imageColor: JamiTheme.blackColor

                toolTipText: !isMuted? JamiStrings.muteParticipant
                                     : JamiStrings.unmuteParticipant


                onClicked: CallAdapter.muteParticipant(uri, !isMuted)
            }

            PushButton {
                id: toggleMaximize

                Layout.preferredWidth: buttonPreferredSize
                Layout.preferredHeight: buttonPreferredSize

                normalColor: JamiTheme.buttonTintedBlue
                hoveredColor: JamiTheme.buttonTintedBlueHovered
                pressedColor: JamiTheme.buttonTintedBluePressed

                source: !isMaximized? "qrc:/images/icons/open_in_full-24px.svg"
                                    : "qrc:/images/icons/close_fullscreen-24px.svg"
                imageColor: JamiTheme.blackColor

                toolTipText: !isMaximized? JamiStrings.maximizeParticipant
                                         : JamiStrings.minimizeParticipant

                onClicked: {
                    if (!isMaximized) {
                        CallAdapter.maximizeParticipant(uri, active)
                    } else {
                        CallAdapter.minimizeParticipant()
                    }
                }
            }

            PushButton {
                id: hangupParticipant

                Layout.preferredWidth: buttonPreferredSize
                Layout.preferredHeight: buttonPreferredSize

                normalColor: JamiTheme.buttonTintedBlue
                hoveredColor: JamiTheme.buttonTintedBlueHovered
                pressedColor: JamiTheme.buttonTintedBluePressed

                source: "qrc:/images/icons/ic_block_24px.svg"
                imageColor: JamiTheme.blackColor

                toolTipText: JamiStrings.hangupParticipant

                onClicked: CallAdapter.hangupCall(uri)
            }
        }
    }
}
