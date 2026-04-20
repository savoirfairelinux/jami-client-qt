/*
 * Copyright (C) 2022-2026 Savoir-faire Linux Inc.
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

import net.jami.Constants 1.1
import net.jami.Adapters 1.1
import "../../commoncomponents"

Control {
    id: root

    anchors.right: webView.right
    anchors.top: webView.top
    anchors.margins: 10

    padding: 4

    contentItem: Row {
        NewIconButton {
            id: btnUnpin

            iconSource: JamiResources.bidirectional_unpin_24dp_svg
            iconSize: JamiTheme.iconButtonMedium
            toolTipText: !isUnpin ? JamiStrings.unpin : JamiStrings.pinWindow

            onClicked: {
                if (!isUnpin) {
                    PositionManager.unPinMap(attachedAccountId);
                } else {
                    PositionManager.pinMap(attachedAccountId);
                }
            }
        }

        NewIconButton {
            id: btnCenter

            iconSource: JamiResources.share_location_24dp_svg
            iconSize: JamiTheme.iconButtonMedium
            toolTipText: JamiStrings.centerMapTooltip

            onClicked: {
                webView.runJavaScript("zoomTolayersExtent()");
            }
        }

        NewIconButton {
            id: btnMove

            iconSource: JamiResources.move_24dp_svg
            iconSize: JamiTheme.iconButtonMedium
            toolTipText: JamiStrings.dragMapTooltip

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

        NewIconButton {
            id: btnMaximise

            iconSource: mapObject.isFullScreen ? JamiResources.close_fullscreen_24dp_svg : JamiResources.open_in_full_24dp_svg
            iconSize: JamiTheme.iconButtonMedium
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

        NewIconButton {
            id: btnClose

            iconSource: JamiResources.round_close_24dp_svg
            iconSize: JamiTheme.iconButtonMedium
            toolTipText: JamiStrings.closeMapTooltip

            visible: !isUnpin

            onClicked: {
                PositionManager.setMapInactive(attachedAccountId);
                PositionManager.mapAutoOpening = false;
            }
        }
    }

    background: Rectangle {
        radius: (JamiTheme.iconButtonMedium * 1.5) + padding
        color: JamiTheme.mapButtonsOverlayColor
    }
}