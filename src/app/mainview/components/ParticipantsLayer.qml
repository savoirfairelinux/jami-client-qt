/*
 * Copyright (C) 2020-2023 Savoir-faire Linux Inc.
 * Authors: Sébastien Blin <sebastien.blin@savoirfairelinux.com>
 *          Aline Gondim Santos <aline.gondimsantos@savoirfairelinux.com>
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
import QtQuick.Layouts
import QtQuick.Controls
import SortFilterProxyModel 0.2
import net.jami.Adapters 1.1
import net.jami.Models 1.1
import net.jami.Constants 1.1
import net.jami.Enums 1.1
import "../../commoncomponents"

Item {
    id: root
    property int count: 0
    property bool enableHideSpectators: CallParticipantsModel.count > 1 && CurrentCall.hideSpectators
    property bool hoveredOverVideoMuted: true
    property string hoveredOverlaySinkId: ""
    property string hoveredOverlayUri: ""
    property bool inLine: CallParticipantsModel.conferenceLayout === CallParticipantsModel.ONE_WITH_SMALL
    property bool participantsSide
    property bool screenshotButtonHovered: false

    onVisibleChanged: {
        CurrentCall.hideSelf = UtilsAdapter.getAppValue(Settings.HideSelf);
        CurrentCall.hideSpectators = UtilsAdapter.getAppValue(Settings.HideSpectators);
        CurrentCall.flipSelf = UtilsAdapter.getAppValue(Settings.FlipSelf);
    }

    Component {
        id: callVideoMedia
        ParticipantOverlay {
            id: overlay
            anchors.fill: parent
            anchors.leftMargin: leftMargin_
            bestName: {
                if (bestName_ === uri_)
                    NameDirectory.lookupAddress(CurrentAccount.id, uri_);
                return bestName_;
            }
            deviceId: deviceId_
            isLocalMuted: audioLocalMuted_
            isMe: isLocal_
            isRecording: isRecording_
            isScreenshotButtonHovered: screenshotButtonHovered && hoveredOverlaySinkId === sinkId_
            isSharing: isSharing_
            opacity: screenshotButtonHovered ? hoveredOverlaySinkId !== sinkId ? 0.1 : 1 : 1
            participantHandIsRaised: isHandRaised_
            participantIsActive: active_
            participantIsModerator: isModerator_
            participantIsModeratorMuted: audioModeratorMuted_
            sinkId: sinkId_
            uri: uri_
            videoMuted: videoMuted_
            voiceActive: voiceActive_

            onParticipantHoveredChanged: {
                if (participantHovered) {
                    hoveredOverlayUri = overlay.uri;
                    hoveredOverlaySinkId = overlay.sinkId;
                    hoveredOverVideoMuted = videoMuted_;
                }
            }

            Connections {
                id: registeredNameFoundConnection
                enabled: bestName_ === uri_
                target: NameDirectory

                function onRegisteredNameFound(status, address, name) {
                    if (address === uri_ && status === NameDirectory.LookupStatus.SUCCESS) {
                        bestName_ = name;
                    }
                }
            }
        }
    }
    SortFilterProxyModel {
        id: genericParticipantsModel
        sourceModel: CallParticipantsModel

        filters: AllOf {
            ValueFilter {
                roleName: "Active"
                value: false
            }
            ValueFilter {
                enabled: CallParticipantsModel.count > 1 && CurrentCall.hideSelf
                roleName: "IsLocal"
                value: false
            }
            ValueFilter {
                enabled: root.enableHideSpectators
                roleName: "HideSpectators"
                value: false
            }
        }
    }
    SortFilterProxyModel {
        id: activeParticipantsModel
        sourceModel: CallParticipantsModel

        filters: ValueFilter {
            roleName: "Active"
            value: true
        }
    }
    ParticipantsLayoutVertical {
        anchors.fill: parent
        participantComponent: callVideoMedia
        visible: !participantsSide

        onLayoutCountChanged: root.count = layoutCount
    }
    ParticipantsLayoutHorizontal {
        anchors.fill: parent
        participantComponent: callVideoMedia
        visible: participantsSide

        onLayoutCountChanged: root.count = layoutCount
    }
}
