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
import net.jami.Constants 1.1
import "../../commoncomponents"

PushButton {
    id: root
    property alias toolTipText: toolTip.text

    hoverEnabled: false
    hoveredColor: JamiTheme.buttonConferenceHovered
    imageColor: JamiTheme.whiteColor
    normalColor: JamiTheme.buttonConference
    pressedColor: JamiTheme.buttonConferencePressed

    Rectangle {
        id: toolTipRect
        color: isBarLayout ? JamiTheme.darkGreyColorOpacity : "transparent"
        height: 16
        radius: 2
        visible: hover.hovered && !isSmall
        width: toolTip.width + 8

        anchors {
            horizontalCenter: parent.horizontalCenter
            top: parent.bottom
            topMargin: isBarLayout ? 6 : 2
        }
        Text {
            id: toolTip
            anchors.centerIn: parent
            color: JamiTheme.whiteColor
            font.pointSize: JamiTheme.tinyFontSize
            horizontalAlignment: Text.AlignHCenter
        }
    }
    Item {
        anchors.fill: parent

        HoverHandler {
            id: hover
            onHoveredChanged: {
                root.forceHovered = hover.hovered;
            }
        }
    }
}
