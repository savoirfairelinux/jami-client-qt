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
    property bool isActive: LRCInstance.indexOfActiveCall(ConfId, ActionUri, DeviceId) !== -1
    property bool isRemoteImage

    author: Author
    bubble.color: {
        if (ConfId === "" && Duration === 0) {
            // If missed, we can add a darker pattern
            return isOutgoing ? Qt.lighter(CurrentConversation.color, 1.15) : Qt.darker(JamiTheme.messageInBgColor, 1.15);
        }
        return isOutgoing ? CurrentConversation.color : JamiTheme.messageInBgColor;
    }
    formattedTime: MessagesAdapter.getFormattedTime(Timestamp)
    isOutgoing: Author === CurrentAccount.uri
    opacity: 0
    readers: Readers
    visible: isActive || ConfId === "" || Duration > 0

    Component.onCompleted: opacity = 1

    Connections {
        enabled: root.isActive
        target: CurrentConversation

        function onActiveCallsChanged() {
            root.isActive = LRCInstance.indexOfActiveCall(ConfId, ActionUri, DeviceId) !== -1;
        }
    }

    component JoinCallButton: PushButton {
        border.color: callLabel.color
        border.width: 1
        hoveredColor: Qt.rgba(255, 255, 255, 0.2)
        imageColor: callLabel.color
        normalColor: "transparent"
        preferredSize: 40
        toolTipText: JamiStrings.joinCall
        visible: root.isActive
    }

    innerContent.children: [
        RowLayout {
            id: msg
            anchors.right: isOutgoing ? parent.right : undefined
            spacing: 10
            visible: root.visible

            Label {
                id: callLabel
                Layout.fillWidth: true
                Layout.margins: 8
                color: UtilsAdapter.luma(bubble.color) ? JamiTheme.chatviewTextColorLight : JamiTheme.chatviewTextColorDark
                font.bold: true
                font.hintingPreference: Font.PreferNoHinting
                font.pixelSize: JamiTheme.emojiBubbleSize
                horizontalAlignment: Qt.AlignHCenter
                padding: 10
                renderType: Text.NativeRendering
                text: {
                    if (root.isActive)
                        return JamiStrings.joinCall;
                    return Body;
                }
                textFormat: Text.MarkdownText
            }
            JoinCallButton {
                id: joinCallInAudio
                source: JamiResources.place_audiocall_24dp_svg

                onClicked: MessagesAdapter.joinCall(ActionUri, DeviceId, ConfId, true)
            }
            JoinCallButton {
                id: joinCallInVideo
                Layout.rightMargin: parent.spacing
                source: JamiResources.videocam_24dp_svg

                onClicked: MessagesAdapter.joinCall(ActionUri, DeviceId, ConfId)
            }
        }
    ]
    Behavior on opacity  {
        NumberAnimation {
            duration: 100
        }
    }
}
