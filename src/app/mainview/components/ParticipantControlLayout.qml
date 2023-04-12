/*
 * Copyright (C) 2020-2023 Savoir-faire Linux Inc.
 * Author: Albert Babí <albert.babi@savoirfairelinux.com>
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
import QtQuick.Layouts
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import "../../commoncomponents"

RowLayout {
    id: root
    property int visibleButtons: toggleModerator.visible + toggleMute.visible + maximizeParticipant.visible + minimizeParticipant.visible + hangupParticipant.visible

    spacing: 8

    ParticipantOverlayButton {
        id: toggleModerator
        Layout.alignment: Qt.AlignVCenter
        Layout.preferredHeight: buttonPreferredSize
        Layout.preferredWidth: buttonPreferredSize
        preferredSize: iconButtonPreferredSize
        source: JamiResources.moderator_svg
        toolTipText: showSetModerator ? JamiStrings.setModerator : JamiStrings.unsetModerator
        visible: showSetModerator || showUnsetModerator

        onClicked: CallAdapter.setModerator(uri, showSetModerator)
    }
    ParticipantOverlayButton {
        id: toggleMute
        Layout.alignment: Qt.AlignVCenter
        Layout.preferredHeight: buttonPreferredSize
        Layout.preferredWidth: buttonPreferredSize
        checkable: meModerator
        preferredSize: iconButtonPreferredSize
        source: showModeratorMute ? JamiResources.micro_black_24dp_svg : JamiResources.micro_off_black_24dp_svg
        toolTipText: {
            if (!checkable && participantIsModeratorMuted)
                return JamiStrings.mutedByModerator;
            if (showModeratorMute)
                return JamiStrings.muteParticipant;
            else
                return JamiStrings.unmuteParticipant;
        }
        visible: showModeratorMute || showModeratorUnmute

        onClicked: {
            if (participantIsModeratorMuted && isLocalMuted) {
                if (isMe)
                    muteAlertMessage = JamiStrings.mutedLocally;
                else
                    muteAlertMessage = JamiStrings.participantMicIsStillMuted;
                muteAlertActive = true;
            }
            CallAdapter.muteParticipant(uri, deviceId, sinkId, showModeratorMute);
        }
    }
    ParticipantOverlayButton {
        id: maximizeParticipant
        Layout.alignment: Qt.AlignVCenter
        Layout.preferredHeight: buttonPreferredSize
        Layout.preferredWidth: buttonPreferredSize
        preferredSize: iconButtonPreferredSize
        source: JamiResources.open_in_full_24dp_svg
        toolTipText: JamiStrings.maximizeParticipant
        visible: showMaximize

        onClicked: CallAdapter.setActiveStream(uri, deviceId, sinkId)
    }
    ParticipantOverlayButton {
        id: minimizeParticipant
        Layout.alignment: Qt.AlignVCenter
        Layout.preferredHeight: buttonPreferredSize
        Layout.preferredWidth: buttonPreferredSize
        preferredSize: iconButtonPreferredSize
        source: JamiResources.close_fullscreen_24dp_svg
        toolTipText: JamiStrings.minimizeParticipant
        visible: showMinimize

        onClicked: CallAdapter.minimizeParticipant(uri)
    }
    ParticipantOverlayButton {
        id: hangupParticipant
        Layout.alignment: Qt.AlignVCenter
        Layout.preferredHeight: buttonPreferredSize
        Layout.preferredWidth: buttonPreferredSize
        preferredSize: iconButtonPreferredSize
        source: JamiResources.ic_hangup_participant_24dp_svg
        toolTipText: JamiStrings.hangupParticipant
        visible: showHangup

        onClicked: CallAdapter.hangupParticipant(uri, deviceId)
    }
}
