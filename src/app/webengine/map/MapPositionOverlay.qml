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

    anchors.right: webView.right
    anchors.top: webView.top
    anchors.margins: 10
    radius: 10
    width: lay.width + 10
    height: lay.height + 10
    color: CurrentConversation.color

    function getBaseColor() {
        var baseColor
        if (UtilsAdapter.luma(root.color))
            baseColor = JamiTheme.chatviewTextColorLight
        else
            baseColor = JamiTheme.chatviewTextColorDark

        return baseColor
    }

    property var buttonColor: getBaseColor()

    RowLayout {
        id: lay

        anchors.centerIn: parent

        PushButton {
            id: btnUnpin

            toolTipText: !isUnpin ? JamiStrings.unpin : JamiStrings.pinWindow
            imageColor: buttonColor
            normalColor: JamiTheme.transparentColor
            source: JamiResources.unpin_svg
            onClicked: {
                if (!isUnpin) {
                    PositionManager.unPinMap(attachedAccountId)
                } else {
                    PositionManager.pinMap(attachedAccountId)
                }
            }
        }

        PushButton {
            id: btnCenter

            toolTipText: JamiStrings.centerMapTooltip
            imageColor: buttonColor
            normalColor: JamiTheme.transparentColor
            source: JamiResources.share_location_svg
            onClicked: {
                webView.runJavaScript("zoomTolayersExtent()" );
            }
        }

        PushButton {
            id: btnMove

            toolTipText: JamiStrings.dragMapTooltip
            imageColor: buttonColor
            normalColor: JamiTheme.transparentColor
            source: JamiResources.move_svg
            visible: !isUnpin

            MouseArea {
                anchors.fill: parent
                drag.target: mapObject
                drag.minimumX: 0
                drag.maximumX: maxWidth - mapObject.width
                drag.minimumY: 0
                drag.maximumY: maxHeight - mapObject.height
            }
        }

        PushButton {
            id: btnClose

            toolTipText: JamiStrings.closeMapTooltip
            imageColor: buttonColor
            normalColor: JamiTheme.transparentColor
            source: JamiResources.round_close_24dp_svg
            visible: !isUnpin

            onClicked: {
                PositionManager.setMapInactive(attachedAccountId)
                PositionManager.mapAutoOpening = false
            }
        }
    }
}
