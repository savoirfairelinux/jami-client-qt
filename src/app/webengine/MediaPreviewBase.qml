/*
 * Copyright (C) 2021-2023 Savoir-faire Linux Inc.
 * Author: Andreas Traczyk <andreas.traczyk@savoirfairelinux.com>
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
import Qt5Compat.GraphicalEffects
import QtWebEngine
import net.jami.Models 1.1
import net.jami.Constants 1.1
import net.jami.Adapters 1.1
import "../commoncomponents"

WebEngineView {
    id: wev
    readonly property real adjustedWidth: Math.min(maxSize, Math.max(minSize, innerContent.width - senderMargin))
    readonly property real aspectRatio: 1 / .75
    property string html
    property bool isVideo
    readonly property real maxSize: 256
    readonly property real minSize: 192

    anchors.right: isOutgoing ? parent.right : undefined
    height: isVideo ? isFullScreen ? parent.height : Math.ceil(adjustedWidth / aspectRatio) : 54
    layer.enabled: !isFullScreen
    settings.fullScreenSupportEnabled: isVideo
    settings.javascriptCanOpenWindows: false
    width: isFullScreen ? parent.width : adjustedWidth

    Component.onCompleted: loadHtml(html, 'file://')
    onContextMenuRequested: function (request) {
        request.accepted = true;
    }
    onFullScreenRequested: function (request) {
        if (request.toggleOn) {
            layoutManager.pushFullScreenItem(this, localMediaCompLoader, null, function () {
                    wev.fullScreenCancelled();
                });
        } else if (!request.toggleOn) {
            layoutManager.removeFullScreenItem(this);
        }
        request.accept();
    }

    layer.effect: OpacityMask {
        maskSource: MessageBubble {
            height: wev.height
            out: isOutgoing
            radius: msgRadius
            type: seq
            width: wev.width
        }
    }
}
