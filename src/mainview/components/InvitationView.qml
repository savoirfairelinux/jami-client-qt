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
import QtGraphicalEffects 1.14

import net.jami.Constants 1.0
import net.jami.Models 1.0

import "../../commoncomponents"

Rectangle {
    id: root

    color: JamiTheme.primaryBackgroundColor

    ListModel {
        id: buttonGroupModel

        ListElement { type: "block"; image: "qrc:/images/icons/round-close-24px.svg"}
        ListElement { type: "refuse"; image: "qrc:/images/icons/place_audiocall-24px.svg"}
        ListElement { type: "accept"; image: "qrc:/images/icons/videocam-24px.svg"}
    }

    Rectangle {
        id: infoRect

        anchors.centerIn: root

        width: root.width
        height: {
            var preferredHeight = invitationViewTopPhraseText.height + avatarImage.height +
                    invitationViewMiddlePhraseText.height + buttonGroupRowLayout.implicitHeight + 85
            return preferredHeight > root.height ? root.height : preferredHeight
        }

        color: JamiTheme.transparentColor

        Text {
            id: invitationViewTopPhraseText

            anchors.horizontalCenter: infoRect.horizontalCenter
            anchors.top: infoRect.top
            anchors.topMargin: 20

            width: infoRect.width - 50

            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter

            font.pointSize: JamiTheme.textFontSize
            color: JamiTheme.textColor
            wrapMode: Text.Wrap

            text: JamiStrings.invitationViewTopPhrase.arg("ssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssss")
        }

        Avatar {
            id: avatarImage

            anchors.horizontalCenter: infoRect.horizontalCenter
            anchors.top: invitationViewTopPhraseText.bottom
            anchors.topMargin: 25

            width: 112
            height: 112

            showPresenceIndicator: false
            mode: Avatar.Mode.Contact
            imageId: "b14387c6938bd0b01242bc6268e4ff924573d73c"
        }

        Text {
            id: invitationViewMiddlePhraseText

            anchors.horizontalCenter: infoRect.horizontalCenter
            anchors.top: avatarImage.bottom
            anchors.topMargin: 20

            width: infoRect.width - 50

            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter

            font.weight: Font.DemiBold
            font.pointSize: JamiTheme.textFontSize + 3
            color: JamiTheme.textColor
            wrapMode: Text.Wrap

            text: JamiStrings.invitationViewMiddlePhrase
        }

        RowLayout {
            id: buttonGroupRowLayout

            anchors.horizontalCenter: infoRect.horizontalCenter
            anchors.top: invitationViewMiddlePhraseText.bottom
            anchors.topMargin: 20

            spacing: 30

            PushButton {
                id: blockButton

                Layout.alignment: Qt.AlignHCenter
                Layout.preferredHeight: 48
                Layout.preferredWidth: 48

                preferredSize: 24
                radius: 25

                toolTipText: JamiStrings.blockContact

                source: "qrc:/images/icons/block_black-24dp.svg"
                imageColor: JamiTheme.primaryBackgroundColor

                normalColor: JamiTheme.blockOrangeTransparency
                pressedColor: JamiTheme.blockOrange
                hoveredColor: JamiTheme.blockOrange
            }

            PushButton {
                id: refuseButton

                Layout.alignment: Qt.AlignHCenter
                Layout.preferredHeight: 48
                Layout.preferredWidth: 48

                preferredSize: 48
                radius: 25

                toolTipText: JamiStrings.declineContactRequest

                source: "qrc:/images/icons/cross_black_24dp.svg"
                imageColor: JamiTheme.primaryBackgroundColor

                normalColor: JamiTheme.refuseRedTransparent
                pressedColor: JamiTheme.refuseRed
                hoveredColor: JamiTheme.refuseRed
            }

            PushButton {
                id: acceptButton

                Layout.alignment: Qt.AlignHCenter
                Layout.preferredHeight: 48
                Layout.preferredWidth: 48

                preferredSize: 24
                radius: 25

                toolTipText: JamiStrings.acceptContactRequest

                source: "qrc:/images/icons/check_black-24dp.svg"
                imageColor: JamiTheme.primaryBackgroundColor

                normalColor: JamiTheme.acceptGreenTransparency
                pressedColor: JamiTheme.acceptGreen
                hoveredColor: JamiTheme.acceptGreen
            }
        }
    }
}
