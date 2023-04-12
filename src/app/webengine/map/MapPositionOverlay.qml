/*
 * Copyright (C) 2022-2023 Savoir-faire Linux Inc.
 * Author: Nicolas Vengeon <nicolas.vengeon@savoirfairelinux.com>
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
import net.jami.Constants 1.1
import net.jami.Adapters 1.1
import "../../commoncomponents"

Rectangle {
    id: root
    anchors.margins: 10
    anchors.right: webView.right
    anchors.top: webView.top
    color: JamiTheme.mapButtonsOverlayColor
    height: lay.height + 10
    radius: 10
    width: lay.width + 10

    RowLayout {
        id: lay
        anchors.centerIn: parent

        PushButton {
            id: btnUnpin
            imageColor: JamiTheme.mapButtonColor
            normalColor: JamiTheme.transparentColor
            source: JamiResources.unpin_svg
            toolTipText: !isUnpin ? JamiStrings.unpin : JamiStrings.pinWindow

            onClicked: {
                if (!isUnpin) {
                    PositionManager.unPinMap(attachedAccountId);
                } else {
                    PositionManager.pinMap(attachedAccountId);
                }
            }
        }
        PushButton {
            id: btnCenter
            imageColor: JamiTheme.mapButtonColor
            normalColor: JamiTheme.transparentColor
            source: JamiResources.share_location_svg
            toolTipText: JamiStrings.centerMapTooltip

            onClicked: {
                webView.runJavaScript("zoomTolayersExtent()");
            }
        }
        PushButton {
            id: btnMove
            imageColor: JamiTheme.mapButtonColor
            normalColor: JamiTheme.transparentColor
            source: JamiResources.move_svg
            toolTipText: JamiStrings.dragMapTooltip
            visible: !isUnpin

            MouseArea {
                anchors.fill: parent
                drag.maximumX: maxWidth - mapObject.maxWidth
                drag.maximumY: maxHeight - mapObject.maxHeight
                drag.minimumX: 0
                drag.minimumY: 0
                drag.target: mapObject
            }
        }
        PushButton {
            id: btnMaximise
            imageColor: JamiTheme.mapButtonColor
            normalColor: JamiTheme.transparentColor
            source: mapObject.isFullScreen ? JamiResources.close_fullscreen_24dp_svg : JamiResources.open_in_full_24dp_svg
            toolTipText: mapObject.isFullScreen ? JamiStrings.reduceMapTooltip : JamiStrings.maximizeMapTooltip
            visible: !isUnpin

            onClicked: {
                if (!mapObject.isFullScreen) {
                    mapObject.x = mapObject.xPos;
                    mapObject.y = mapObject.yPos;
                }
                mapObject.isFullScreen = !mapObject.isFullScreen;
            }
        }
        PushButton {
            id: btnClose
            imageColor: JamiTheme.mapButtonColor
            normalColor: JamiTheme.transparentColor
            source: JamiResources.round_close_24dp_svg
            toolTipText: JamiStrings.closeMapTooltip
            visible: !isUnpin

            onClicked: {
                PositionManager.setMapInactive(attachedAccountId);
                PositionManager.mapAutoOpening = false;
            }
        }
    }
}
