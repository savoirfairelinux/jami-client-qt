/*
 * Copyright (C) 2020 by Savoir-faire Linux
 * Author: Mingrui Zhang <mingrui.zhang@savoirfairelinux.com>
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

import QtQuick 2.14
import QtQuick.Controls 2.14
import QtQuick.Layouts 1.14
import net.jami.Models 1.0
import net.jami.Adapters 1.0
import net.jami.Constants 1.0

import "../../commoncomponents"

Rectangle {
    id: root

    anchors.fill: parent
    color: JamiTheme.secondaryBackgroundColor

    ColumnLayout {
        id: welcomePageColumnLayout

        anchors.centerIn: parent

        width: Math.max(mainViewStackPreferredWidth, root.width - 100)
        height: parent.height

        ColumnLayout {
            Layout.alignment: Qt.AlignCenter
            Layout.preferredWidth: welcomePageColumnLayout.width
            Layout.preferredHeight: implicitHeight
            Layout.topMargin: JamiTheme.preferredMarginSize

            ParticipantOverlayMenu {
                id: overlayMenu
                visible: true
                //anchors.centerIn: parent
                hasMinimumSize: false//root.width > minimumWidth && root.height > minimumHeight

                uri: "albert"
                bestName: "bestName"

                showSetModerator: true

                showModeratorMute: true
                showMaximize: true
                showMinimize: true
                showHangup: true
            }
        }

        MaterialButton {
            id: btnAboutPopUp

            Layout.alignment: Qt.AlignBottom | Qt.AlignHCenter
            Layout.bottomMargin: JamiTheme.preferredMarginSize
            Layout.preferredWidth: 150
            Layout.preferredHeight: 30

            color: JamiTheme.buttonTintedBlack
            hoveredColor: JamiTheme.buttonTintedBlackHovered
            pressedColor: JamiTheme.buttonTintedBlackPressed
            outlined: true

            text: JamiStrings.aboutJami

            onClicked: aboutPopUpDialog.open()
        }
    }

    CustomBorder {
        commonBorder: false
        lBorderwidth: 1
        rBorderwidth: 0
        tBorderwidth: 0
        bBorderwidth: 0
        borderColor: JamiTheme.tabbarBorderColor
    }
}
