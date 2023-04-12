/*
 * Copyright (C) 2022-2023 Savoir-faire Linux Inc.
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
import QtWebEngine
import Qt5Compat.GraphicalEffects
import net.jami.Constants 1.1

Rectangle {
    id: root
    property string html: ""
    property bool isVideo: false

    anchors.fill: parent
    color: JamiTheme.secondaryBackgroundColor
    layer.enabled: true

    WebEngineView {
        id: wev
        anchors.fill: parent
        anchors.topMargin: root.isVideo ? 0 : wev.implicitHeight / 2
        anchors.verticalCenter: root.verticalCenter
        backgroundColor: JamiTheme.secondaryBackgroundColor
        settings.fullScreenSupportEnabled: root.isVideo
        settings.javascriptCanOpenWindows: false

        Component.onCompleted: loadHtml(root.html, 'file://')
        onFullScreenRequested: function (request) {
            if (request.toggleOn) {
                layoutManager.pushFullScreenItem(this, root, null, function () {
                        wev.fullScreenCancelled();
                    });
            } else if (!request.toggleOn) {
                layoutManager.removeFullScreenItem(this);
            }
            request.accept();
        }
    }

    layer.effect: OpacityMask {
        maskSource: Item {
            height: root.height
            width: root.width

            Rectangle {
                anchors.centerIn: parent
                height: root.height
                radius: JamiTheme.swarmDetailsPageDocumentsMediaRadius
                width: root.width
            }
        }
    }
}
