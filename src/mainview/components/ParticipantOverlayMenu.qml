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

    property bool hasMinimumWidth: true
    property real scaleFactor: 1 // hasMinimumWidth? 1.5 : 1
    property int buttonPreferredSize: 30

    property var bestName: ""
    property bool active: false
    property bool showHangup: false
    property bool showMaximize: false
    property bool showMinimize: false
    property bool showSetModerator: false
    property bool showUnsetModerator: false
    property bool isMuted: false
    property bool isModerator: false
    property bool participantIsModerator: false

    width: 182
    height: 114

    opacity: (hasMinimumWidth && isModerator)? 1 : 0.77
    color: (hasMinimumWidth && isModerator)? "transparent"
                                           : JamiTheme.darkGreyColor
    ColumnLayout {
        id: layout
        anchors.horizontalCenter: root.horizontalCenter
        anchors.verticalCenter: root.verticalCenter
        spacing: 12

        Text {
            id: participantName

            TextMetrics {
                id: participantMetrics
                text: bestName
                elide: Text.ElideRight
                elideWidth: root.width - JamiTheme.preferredMarginSize * 2
            }

            text: participantMetrics.elidedText
            color: JamiTheme.whiteColor
            font.pointSize: JamiTheme.headerFontSize
            Layout.alignment: Qt.AlignCenter

            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter | Qt.AlignBottom
            spacing: 8

            PushButton {
                id: toggleModerator
                visible: isModerator && (showSetModerator || showUnsetModerator)
                Layout.preferredWidth: buttonPreferredSize
                Layout.preferredHeight: buttonPreferredSize

                normalColor: JamiTheme.buttonConference
                hoveredColor: JamiTheme.buttonConferenceHovered
                pressedColor: JamiTheme.buttonConferencePressed

                source: "qrc:/images/icons/moderator.svg"
                imageColor: hovered? JamiTheme.darkGreyColor
                                   : JamiTheme.whiteColor

                onClicked: CallAdapter.setModerator(uri, showSetModerator)

                onHoveredChanged: toggleModeratorToolTip.visible = hovered

                Text {
                    id: toggleModeratorToolTip
                    visible: false
                    width: parent.width
                    text: showSetModerator? JamiStrings.setModerator
                                          : JamiStrings.unsetModerator
                    horizontalAlignment: Text.AlignHCenter
                    anchors.top: parent.bottom
                    color: JamiTheme.whiteColor
                }
            }

            PushButton {
                id: toggleMute
                visible: isModerator
                Layout.preferredWidth: buttonPreferredSize
                Layout.preferredHeight: buttonPreferredSize

                normalColor: JamiTheme.buttonConference
                hoveredColor: JamiTheme.buttonConferenceHovered
                pressedColor: JamiTheme.buttonConferencePressed

                source: "qrc:/images/icons/mic_off-24px.svg"
                imageColor: hovered? JamiTheme.darkGreyColor
                                   : JamiTheme.whiteColor

                onClicked: CallAdapter.muteParticipant(uri, !isMuted)
                onHoveredChanged: toggleParticipantToolTip.visible = hovered

                Text {
                    id: toggleParticipantToolTip
                    visible: false
                    width: parent.width
                    text: !isMuted? JamiStrings.muteParticipant
                                  : JamiStrings.unmuteParticipant
                    horizontalAlignment: Text.AlignHCenter
                    anchors.top: parent.bottom
                    color: JamiTheme.whiteColor
                }
            }

            PushButton {
                id: maximizeParticipant
                visible: isModerator && showMaximize
                Layout.preferredWidth: buttonPreferredSize
                Layout.preferredHeight: buttonPreferredSize

                normalColor: JamiTheme.buttonConference
                hoveredColor: JamiTheme.buttonConferenceHovered
                pressedColor: JamiTheme.buttonConferencePressed

                source: "qrc:/images/icons/open_in_full-24px.svg"
                imageColor: hovered? JamiTheme.darkGreyColor
                                   : JamiTheme.whiteColor


                onClicked: CallAdapter.maximizeParticipant(uri, active)
                onHoveredChanged: maximizeParticipantToolTip.visible = hovered

                Text {
                    id: maximizeParticipantToolTip
                    visible: false
                    width: parent.width
                    text: JamiStrings.maximizeParticipant
                    horizontalAlignment: Text.AlignHCenter
                    anchors.top: parent.bottom
                    color: JamiTheme.whiteColor
                }
            }

            PushButton {
                id: minimizeParticipant
                visible: isModerator && showMinimize
                Layout.preferredWidth: buttonPreferredSize
                Layout.preferredHeight: buttonPreferredSize

                normalColor: JamiTheme.buttonConference
                hoveredColor: JamiTheme.buttonConferenceHovered
                pressedColor: JamiTheme.buttonConferencePressed

                source: "qrc:/images/icons/close_fullscreen-24px.svg"
                imageColor: hovered? JamiTheme.darkGreyColor
                                   : JamiTheme.whiteColor

                onClicked: CallAdapter.minimizeParticipant()
                onHoveredChanged: minimizeParticipantToolTip.visible = hovered

                Text {
                    id: minimizeParticipantToolTip
                    visible: false
                    width: parent.width
                    text: JamiStrings.minimizeParticipant
                    horizontalAlignment: Text.AlignHCenter
                    anchors.top: parent.bottom
                    color: JamiTheme.whiteColor
                }
            }

            PushButton {
                id: hangupParticipant
                visible: isModerator && showHangup
                Layout.preferredWidth: buttonPreferredSize
                Layout.preferredHeight: buttonPreferredSize

                normalColor: JamiTheme.buttonConference
                hoveredColor: JamiTheme.buttonConferenceHovered
                pressedColor: JamiTheme.buttonConferencePressed

                source: "qrc:/images/icons/ic_block_24px.svg"
                imageColor: hovered? JamiTheme.darkGreyColor
                                   : JamiTheme.whiteColor

                onClicked: CallAdapter.hangupCall(uri)
                onHoveredChanged: hangupParticipantToolTip.visible = hovered

                Text {
                    id: hangupParticipantToolTip
                    visible: false
                    width: parent.width
                    text: JamiStrings.hangupParticipant
                    horizontalAlignment: Text.AlignHCenter
                    anchors.top: parent.bottom
                    color: JamiTheme.whiteColor
                }
            }
        }
    }
}
