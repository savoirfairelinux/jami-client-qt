/*
 * Copyright (C) 2020-2022 Savoir-faire Linux Inc.
 * Author: Sébastien Blin <sebastien.blin@savoirfairelinux.com>
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

Item {
    id: root

    property var participantOverlays: []
    property var participantComponent: Qt.createComponent("ParticipantOverlay.qml")

    // returns true if participant is not fully maximized
    function showMaximize(pX, pY, pW, pH) {
        // Hack: -1 offset added to avoid problems with odd sizes
        return (pX - distantRenderer.contentRect.x !== 0
                || pY - distantRenderer.contentRect.y !== 0
                || pW < (distantRenderer.width - distantRenderer.contentRect.x * 2 -  1)
                || pH < (distantRenderer.height - distantRenderer.contentRect.y * 2 - 1))
    }

    function update(infos) {
        // TODO: in the future the conference layout should be entirely managed by the client
        // Hack: truncate and ceil participant's overlay position and size to correct
        // when they are not exacts
        callOverlay.updateUI()
        var showMax = false
        var showMin = false

        var deletedUris = []
        var currentUris = []
        for (var p in participantOverlays) {
            if (participantOverlays[p]) {
                var participant = infos.find(e => e.uri === participantOverlays[p].uri);
                if (participant) {
                    // Update participant's information
                    participantOverlays[p].x = Math.trunc(distantRenderer.contentRect.x
                                                          + participant.x * distantRenderer.xScale)
                    participantOverlays[p].y = Math.trunc(distantRenderer.contentRect.y
                                                          + participant.y * distantRenderer.yScale)
                    participantOverlays[p].width = Math.ceil(participant.w * distantRenderer.xScale)
                    participantOverlays[p].height = Math.ceil(participant.h * distantRenderer.yScale)
                    participantOverlays[p].visible = participant.w !== 0 && participant.h !== 0

                    showMax = showMaximize(participantOverlays[p].x,
                                           participantOverlays[p].y,
                                           participantOverlays[p].width,
                                           participantOverlays[p].height)

                    participantOverlays[p].setMenu(participant.uri, participant.bestName,
                                                   participant.isLocal, participant.active, showMax)
                    if (participant.videoMuted)
                        participantOverlays[p].setAvatar(true, participant.uri, participant.isLocal)
                    else
                        participantOverlays[p].setAvatar(false)
                    currentUris.push(participantOverlays[p].uri)
                } else {
                    // Participant is no longer in conference
                    deletedUris.push(participantOverlays[p].uri)
                    participantOverlays[p].destroy()
                }
            }
        }
        participantOverlays = participantOverlays.filter(part => !deletedUris.includes(part.uri))

        if (infos.length === 0) { // Return to normal call
            for (var part in participantOverlays) {
                if (participantOverlays[part]) {
                    participantOverlays[part].destroy()
                }
            }
            participantOverlays = []
        } else {
            for (var infoVariant in infos) {
                // Only create overlay for new participants
                if (!currentUris.includes(infos[infoVariant].uri)) {
                    const infoObj = {
                        x: Math.trunc(distantRenderer.contentRect.x
                                      + infos[infoVariant].x * distantRenderer.xScale),
                        y: Math.trunc(distantRenderer.contentRect.y
                                      + infos[infoVariant].y * distantRenderer.yScale),
                        width: Math.ceil(infos[infoVariant].w * distantRenderer.xScale),
                        height: Math.ceil(infos[infoVariant].h * distantRenderer.yScale),
                        visible: infos[infoVariant].w !== 0 && infos[infoVariant].h !== 0
                    }
                    var hover = participantComponent.createObject(root, infoObj)
                    if (!hover) {
                        console.log("Error when creating the hover")
                        return
                    }

                    showMax = showMaximize(hover.x, hover.y, hover.width, hover.height)

                    hover.setMenu(infos[infoVariant].uri, infos[infoVariant].bestName,
                                  infos[infoVariant].isLocal, infos[infoVariant].active, showMax)
                    if (infos[infoVariant].videoMuted)
                        hover.setAvatar(true, infos[infoVariant].uri, infos[infoVariant].isLocal)
                    else
                        hover.setAvatar(false)
                    participantOverlays.push(hover)
                }
            }
        }
    }
}
