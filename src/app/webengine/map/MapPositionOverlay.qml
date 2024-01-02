/*
 * Copyright (C) 2022-2024 Savoir-faire Linux Inc.
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

    anchors.right: webView.right
    anchors.top: webView.top
    anchors.margins: 10
    radius: 10
    width: lay.width + 10
    height: lay.height + 10
    color: JamiTheme.mapButtonsOverlayColor

    RowLayout {
        id: lay

        anchors.centerIn: parent

        PushButton {
            id: btnUnpin

            toolTipText: !isUnpin ? JamiStrings.unpin : JamiStrings.pinWindow
            imageColor: JamiTheme.mapButtonColor
            normalColor: JamiTheme.mapButtonsOverlayColor
            source: JamiResources.unpin_svg
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

            toolTipText: JamiStrings.centerMapTooltip
            imageColor: JamiTheme.mapButtonColor
            normalColor: JamiTheme.mapButtonsOverlayColor
            source: JamiResources.share_location_svg
            onClicked: {
                webView.runJavaScript("zoomTolayersExtent()");
            }
        }

        PushButton {
            id: btnMove

            toolTipText: JamiStrings.dragMapTooltip
            imageColor: JamiTheme.mapButtonColor
            normalColor: JamiTheme.mapButtonsOverlayColor
            source: JamiResources.move_svg
            visible: !isUnpin

            MouseArea {
                anchors.fill: parent
                drag.target: mapObject
                drag.minimumX: 0
                drag.maximumX: maxWidth - mapObject.maxWidth
                drag.minimumY: 0
                drag.maximumY: maxHeight - mapObject.maxHeight
            }
        }

        PushButton {
            id: btnMaximise

            visible: !isUnpin
            toolTipText: mapObject.isFullScreen ? JamiStrings.reduceMapTooltip : JamiStrings.maximizeMapTooltip
            imageColor: JamiTheme.mapButtonColor
            normalColor: JamiTheme.mapButtonsOverlayColor
            source: mapObject.isFullScreen ? JamiResources.close_fullscreen_24dp_svg : JamiResources.open_in_full_24dp_svg
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

            toolTipText: JamiStrings.closeMapTooltip
            imageColor: JamiTheme.mapButtonColor
            normalColor: JamiTheme.mapButtonsOverlayColor
            source: JamiResources.round_close_24dp_svg
            visible: !isUnpin

            onClicked: {
                PositionManager.setMapInactive(attachedAccountId);
                PositionManager.mapAutoOpening = false;
            }
        }
    }
}
