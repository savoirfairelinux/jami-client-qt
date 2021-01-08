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
import QtQuick.Controls.Universal 2.14

import net.jami.Models 1.0
import net.jami.Adapters 1.0
import net.jami.Constants 1.0

import "../../commoncomponents"

MouseArea {
    id: root

    // TODO: Should use Repeater and Model
    property var participantOverlays: []
    property var participantComponent: Qt.createComponent("ParticipantOverlay.qml")

    signal updateVideoCallMenuRequest

    // returns true if participant is not fully maximized
    function showMaximize(pX, pY, pW, pH) {
        // Hack: -1 offset added to avoid problems with odd sizes
        return (pX - distantRenderer.x !== 0
                || pY - distantRenderer.y !== 0
                || pW < (distantRenderer.width - distantRenderer.x * 2 - 1)
                || pH < (distantRenderer.height - distantRenderer.y * 2 - 1))
    }

    // returns true if participant takes renderer's width
    function showMinimize(pX, pW) {
        return (pX - distantRenderer.x === 0
                && pW >= distantRenderer.width - distantRenderer.x * 2 - 1)
    }

    function handleParticipantsInfo(infos) {
        // TODO: in the future the conference layout should be entirely managed by the client
        // Hack: truncate and ceil participant's overlay position and size to correct
        // when they are not exacts

        root.updateVideoCallMenuRequest()

        var showMax = false
        var showMin = false
        var widthScaleFactor = distantRenderer.getWidthScaleFactor()
        var heightScaleFactor = distantRenderer.getHeightScaleFactor()

        var deletedUris = []
        var currentUris = []
        for (var p in participantOverlays) {
            if (participantOverlays[p]) {
                var participant = infos.find(e => e.uri === participantOverlays[p].uri);
                if (participant) {
                    // Update participant's information
                    var newX = Math.trunc(participant.x * widthScaleFactor)
                    var newY = Math.trunc(participant.y * heightScaleFactor)
                    var newWidth = Math.ceil(participant.w * widthScaleFactor)
                    var newHeight = Math.ceil(participant.h * heightScaleFactor)
                    var newVisible = participant.w !== 0 && participant.h !== 0

                    if (participantOverlays[p].x !== newX)
                        participantOverlays[p].x = newX
                    if (participantOverlays[p].y !== newY)
                        participantOverlays[p].y = newY
                    if (participantOverlays[p].width !== newWidth)
                        participantOverlays[p].width = newWidth
                    if (participantOverlays[p].height !== newHeight)
                        participantOverlays[p].height = newHeight
                    if (participantOverlays[p].visible !== newVisible)
                        participantOverlays[p].visible = newVisible

                    showMax = showMaximize(participantOverlays[p].x,
                                           participantOverlays[p].y,
                                           participantOverlays[p].width,
                                           participantOverlays[p].height)
                    showMin = showMinimize(participantOverlays[p].x,
                                           participantOverlays[p].width)

                    participantOverlays[p].setMenu(participant.uri, participant.bestName,
                                                   participant.isLocal, showMax, showMin)
                    if (participant.videoMuted)
                        participantOverlays[p].setAvatar(participant.avatar)
                    else
                        participantOverlays[p].setAvatar("")
                    currentUris.push(participantOverlays[p].uri)
                } else {
                    // Participant is no longer in conference
                    deletedUris.push(participantOverlays[p].uri)
                    participantOverlays[p].destroy()
                }
            }
        }

        participantOverlays = participantOverlays.filter(part => !deletedUris.includes(part.uri))

        if (infos.length === 0) {
            // Return to normal call
            JamiQmlUtils.setVideoCallPagePreviewVisible(true)
            for (var part in participantOverlays) {
                if (participantOverlays[part]) {
                        participantOverlays[part].destroy()
                }
            }
            participantOverlays = []
        } else {
            JamiQmlUtils.setVideoCallPagePreviewVisible(false)
            for (var infoVariant in infos) {
                // Only create overlay for new participants
                if (!currentUris.includes(infos[infoVariant].uri)) {
                    var hover = participantComponent.createObject(distantRenderer, {
                        x: Math.trunc(infos[infoVariant].x * widthScaleFactor),
                        y: Math.trunc(infos[infoVariant].y * heightScaleFactor),
                        width: Math.ceil(infos[infoVariant].w * widthScaleFactor),
                        height: Math.ceil(infos[infoVariant].h * heightScaleFactor),
                        visible: infos[infoVariant].w !== 0 && infos[infoVariant].h !== 0
                    })
                    if (!hover) {
                        console.log("Error when creating the hover")
                        return
                    }

                    showMax = showMaximize(hover.x, hover.y, hover.width, hover.height)
                    showMin = showMinimize(hover.x, hover.width)

                    hover.setMenu(infos[infoVariant].uri, infos[infoVariant].bestName,
                                  infos[infoVariant].isLocal, showMax, showMin)
                    if (infos[infoVariant].videoMuted)
                        hover.setAvatar(infos[infoVariant].avatar)
                    else
                        hover.setAvatar("")
                    participantOverlays.push(hover)
                }
            }
        }
    }

    hoverEnabled: true
    propagateComposedEvents: true
    acceptedButtons: Qt.NoButton

    Connections {
        target: JamiQmlUtils

        function onCurrentDistantRendererIdChanged() {
            distantRenderer.distantRenderId = JamiQmlUtils.currentDistantRendererId
        }

        function onUpdateParticipantsInfo(infos) {
            handleParticipantsInfo(infos)
        }
    }

    VideoRenderingItemBase {
        id: distantRenderer

        anchors.centerIn: parent

        lrcInstance: LRCInstance
        expectedSize: Qt.size(root.width, root.height)
        renderingType: VideoRenderingItemBase.Type.DISTANT

        onUpdateParticipantsInfoRequest: {
            handleParticipantsInfo(CallAdapter.getConferencesInfos())
        }
    }
}
