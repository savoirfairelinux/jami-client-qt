/*
 * Copyright (C) 2022-2023 Savoir-faire Linux Inc.
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

    component JoinCallButton: PushButton {
        visible: root.isActive
        toolTipText: JamiStrings.joinCall
        preferredSize: 40
        imageColor: callLabel.color
        normalColor: "transparent"
        hoveredColor: Qt.rgba(255, 255, 255, 0.2)
        border.width: 1
        border.color: callLabel.color
    }

    property bool isRemoteImage

    isOutgoing: Author === CurrentAccount.uri
    author: Author
    readers: Readers
    formattedTime: MessagesAdapter.getFormattedTime(Timestamp)

    Connections {
        target: CurrentConversation
        enabled: root.isActive

        function onActiveCallsChanged() {
            root.isActive = LRCInstance.indexOfActiveCall(ConfId, ActionUri, DeviceId) !== -1;
        }
    }

    property bool isActive: LRCInstance.indexOfActiveCall(ConfId, ActionUri, DeviceId) !== -1
    visible: isActive || ConfId === "" || Duration > 0

    bubble.color: {
        if (ConfId === "" && Duration === 0) {
            // If missed, we can add a darker pattern
            return isOutgoing ? Qt.lighter(CurrentConversation.color, 1.15) : Qt.darker(JamiTheme.messageInBgColor, 1.15);
        }
        return isOutgoing ? CurrentConversation.color : JamiTheme.messageInBgColor;
    }

    innerContent.children: [
        RowLayout {
            id: msg
            anchors.right: isOutgoing ? parent.right : undefined
            spacing: 10
            visible: root.visible

            Label {
                id: callLabel
                padding: 10
                Layout.margins: 8
                Layout.fillWidth: true

                text: {
                    if (root.isActive)
                        return JamiStrings.joinCall;
                    return Body;
                }
                horizontalAlignment: Qt.AlignHCenter

                font.pixelSize: JamiTheme.emojiBubbleSize
                font.hintingPreference: Font.PreferNoHinting
                font.bold: true
                renderType: Text.NativeRendering
                textFormat: Text.MarkdownText

                color: UtilsAdapter.luma(bubble.color) ? JamiTheme.chatviewTextColorLight : JamiTheme.chatviewTextColorDark
            }

            JoinCallButton {
                id: joinCallInAudio

                source: JamiResources.place_audiocall_24dp_svg
                onClicked: MessagesAdapter.joinCall(ActionUri, DeviceId, ConfId, true)
            }

            JoinCallButton {
                id: joinCallInVideo

                source: JamiResources.videocam_24dp_svg
                onClicked: MessagesAdapter.joinCall(ActionUri, DeviceId, ConfId)
                Layout.rightMargin: parent.spacing
            }
        }
    ]

    opacity: 0
    Behavior on opacity  {
        NumberAnimation {
            duration: 100
        }
    }
    Component.onCompleted: opacity = 1
}
