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

    bubble.color: {
        if (ConfId === "" && Duration == 0) {
            // If missed, we can add a darker pattern
            return isOutgoing ?
                        Qt.darker(JamiTheme.messageOutBgColor, 1.5) :
                        Qt.darker(JamiTheme.messageInBgColor, 1.5)
        }
        return isOutgoing ?
                    JamiTheme.messageOutBgColor :
                    CurrentConversation.isCoreDialog ? JamiTheme.messageInBgColor : Qt.lighter(CurrentConversation.color, 1.5)
    }

    innerContent.children: [
        RowLayout {
            id: msg
            anchors.right: isOutgoing ? parent.right : undefined
            spacing: 10

            Label {
                id: callLabel
                padding: 10
                Layout.margins: 8
                Layout.fillWidth: true

                text:{
                    if (root.isActive)
                        return JamiStrings.joinCall
                    return Body
                }
                horizontalAlignment: Qt.AlignHCenter
                font.pointSize: JamiTheme.contactEventPointSize
                font.bold: true
                color: UtilsAdapter.luma(bubble.color) ?
                       JamiTheme.chatviewTextColorLight :
                       JamiTheme.chatviewTextColorDark
            }

            PushButton {
                id: joinCallInAudio
                visible: root.isActive

                source: JamiResources.place_audiocall_24dp_svg
                toolTipText: JamiStrings.joinCall

                preferredSize: 40
                imageColor: callLabel.color
                normalColor: "transparent"
                hoveredColor: Qt.rgba(255, 255, 255, 0.2)
                border.width: 1
                border.color: callLabel.color

                onClicked: MessagesAdapter.joinCall(Id, ActionUri, DeviceId, true)
            }

            PushButton {
                id: joinCallInVideo
                visible: root.isActive

                source: JamiResources.videocam_24dp_svg
                toolTipText: JamiStrings.joinCall

                preferredSize: 40
                imageColor: callLabel.color
                normalColor: "transparent"
                hoveredColor: Qt.rgba(255, 255, 255, 0.2)
                border.width: 1
                border.color: callLabel.color

                onClicked: MessagesAdapter.joinCall(Id, ActionUri, DeviceId)

                Layout.rightMargin: parent.spacing
            }
        }
    ]

    opacity: 0
    Behavior on opacity { NumberAnimation { duration: 100 } }
    Component.onCompleted: opacity = 1
}