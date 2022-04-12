/*
 * Copyright (C) 2022 Savoir-faire Linux Inc.
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

SBSMessageBase {
    id: root

    property bool isRemoteImage
    property real maxMsgWidth: root.width - senderMargin - 2 * hPadding - avatarBlockWidth

    isOutgoing: Author === ""
    author: Author
    readers: Readers
    formattedTime: MessagesAdapter.getFormattedTime(Timestamp)

    property bool isActive: CurrentConversation.indexOfActiveCall(ConfId, ActionUri, DeviceId) !== -1
    visible: isActive || ConfId === "" || Duration > 0

    innerContent.children: [
        RowLayout {
            id: msg
            anchors.right: isOutgoing ? parent.right : undefined
            spacing: 0

            Label {
                id: callLabel
                padding: 10
                Layout.margins: 8

                width: parent.width
                text:{
                    if (ActionUri === "")
                        return Body
                    if (root.isActive)
                        return JamiStrings.aCallIsInProgress
                    return JamiStrings.callEnded
                }
                horizontalAlignment: Qt.AlignHCenter
                font.pointSize: JamiTheme.contactEventPointSize
                font.bold: true
                color: JamiTheme.chatviewTextColor
            }

            MaterialButton {
                id: btnCall
                text: root.isActive? JamiStrings.joinCall : JamiStrings.callBack
                padding: 8
                Layout.rightMargin: 8
                visible: ActionUri !== ""

                color: JamiTheme.buttonTintedBlue
                hoveredColor: JamiTheme.buttonTintedBlueHovered
                pressedColor: JamiTheme.buttonTintedBluePressed

                onClicked: {
                    root.isActive?
                        MessagesAdapter.joinCall(ConfId, ActionUri, DeviceId) :
                        CallAdapter.placeCall();
                }
            }
        }
    ]

    opacity: 0
    Behavior on opacity { NumberAnimation { duration: 100 } }
    Component.onCompleted: opacity = 1
}