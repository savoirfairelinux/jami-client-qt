/*
 * Copyright (C) 2021-2026 Savoir-faire Linux Inc.
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
import net.jami.Adapters 1.1
import net.jami.UI as JUI

Item {
    id: root

    property alias imageId: avatar.imageId
    property alias presenceStatus: avatar.presenceStatus
    property alias showPresenceIndicator: avatar.showPresenceIndicator
    property alias animationMode: animation.mode

    JUI.SpinningAnimation {
        id: animation

        anchors.fill: root
    }

    JUI.Avatar {
        id: avatar

        anchors.fill: root
        anchors.margins: animation.mode === JUI.SpinningAnimation.Mode.Disabled ? 0 : animation.spinningAnimationWidth

        mode: JUI.Avatar.Mode.Conversation
    }
}
