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
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import net.jami.Adapters 1.1
import net.jami.Models 1.1
import net.jami.Constants 1.1
import "../../commoncomponents"

// Overlay menu for conference moderation
Item {
    id: root
    property int buttonPreferredSize: 20
    property alias hovered: hover.hovered
    property int iconButtonPreferredSize: 16
    property bool isBarLayout: root.width > 220
    property int isSmall: !isBarLayout && (root.height < 100 || root.width < 160)
    property int shapeHeight: 30
    property int shapeRadius: 10
    property bool showHangup: false
    property bool showMaximize: false
    property bool showMinimize: false
    property bool showModeratorMute: false
    property bool showModeratorUnmute: false
    property bool showSetModerator: false
    property bool showUnsetModerator: false

    HoverHandler {
        id: hover
    }
    Loader {
        sourceComponent: isBarLayout ? barComponent : rectComponent
    }
    Component {
        id: rectComponent
        Control {
            height: root.height
            hoverEnabled: false
            width: root.width

            ParticipantControlLayout {
                id: buttonsRect
                anchors.centerIn: parent
            }

            background: Rectangle {
                property int buttonsSize: buttonsRect.visibleButtons * 24 + 8 * 2
                property bool isOverlayRect: buttonsSize + 32 > root.width

                anchors.centerIn: parent
                anchors.fill: isOverlayRect ? undefined : parent
                color: JamiTheme.darkGreyColorOpacity
                height: isOverlayRect ? 80 : parent.height
                radius: isOverlayRect ? 10 : 0
                width: isOverlayRect ? buttonsSize + 32 : parent.width
            }
        }
    }
    Component {
        id: barComponent
        Control {
            height: shapeHeight
            hoverEnabled: false
            width: barButtons.implicitWidth + 16

            ParticipantControlLayout {
                id: barButtons
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
            }

            background: Item {
                clip: true

                Rectangle {
                    anchors.fill: parent
                    anchors.leftMargin: -radius
                    anchors.topMargin: -radius
                    color: JamiTheme.darkGreyColorOpacity
                    height: parent.height + 2 * radius
                    radius: shapeRadius
                    width: parent.width + 2 * radius
                }
            }
        }
    }
}
