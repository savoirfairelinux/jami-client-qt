﻿/*
 * Copyright (C) 2021 by Savoir-faire Linux
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
import QtQuick.Controls
import QtQuick.Layouts

import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1

import "../../commoncomponents"


Rectangle {
    id: root

    color: JamiTheme.chatviewBgColor

    signal createSwarmClicked

    RowLayout {
        id: mainLayout

        anchors.fill: parent

        MaterialButton {
            id: btnCreateSwarm

            preferredWidth: JamiTheme.aboutButtonPreferredWidth

            Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
            color: JamiTheme.buttonTintedBlue
            hoveredColor: JamiTheme.buttonTintedBlueHovered
            pressedColor: JamiTheme.buttonTintedBluePressed

            text: JamiStrings.createTheSwarm

            onClicked: {
                ConversationsAdapter.createSwarm()
                createSwarmClicked()
            }
        }
    }
}
