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

    component JoinCallButton: MaterialButton {
        visible: root.isActive
        toolTipText: JamiStrings.joinCall
        color: JamiTheme.blackColor
        background.opacity: hovered ? 0.2 : 0.1
        hoveredColor: JamiTheme.blackColor
        contentColorProvider: JamiTheme.textColor
        textOpacity: hovered ? 1 : 0.5
        buttontextHeightMargin: 16
        textLeftPadding: 9
        textRightPadding: 9
    }

    property bool isRemoteImage

    isOutgoing: Author === CurrentAccount.uri
    author: Author
    readers: Readers
    formattedTime: MessagesAdapter.getFormattedTime(Timestamp)

    bubble.border.color: CurrentConversation.color
    bubble.border.width: root.isActive ? 1.5 : 0


    signal callFrom(string author)


    Connections {
        target: CurrentConversation
        enabled: root.isActive

        function onActiveCallsChanged() {
            root.isActive = LRCInstance.indexOfActiveCall(ConfId, ActionUri, DeviceId) !== -1;
        }
    }

    property bool isActive: LRCInstance.indexOfActiveCall(ConfId, ActionUri, DeviceId) !== -1
    visible: isActive || ConfId === "" || Duration > 0

    property var baseColor: isOutgoing? CurrentConversation.color : JamiTheme.messageInBgColor

    innerContent.children: [
        RowLayout {
            id: msg
            anchors.right: isOutgoing ? parent.right : undefined
            spacing: 10
            visible: root.visible

            Label {
                id: callLabel

                Layout.margins: 8
                Layout.fillWidth: true
                Layout.rightMargin: root.isActive ? 0 : root.timeWidth + 16
                Layout.leftMargin: root.isActive ? 10 : 8

                text: {
                    if (root.isActive){
                        CurrentConversation.callFrom = root.username;
                        CurrentConversation.callFromId = root.author;
                        print("callFrom: " + root.author);
                        return JamiStrings.startedACall;
                    }
                    return Body;
                }
                horizontalAlignment: Qt.AlignHCenter

                font.pointSize: JamiTheme.mediumFontSize
                font.hintingPreference: Font.PreferNoHinting
                renderType: Text.NativeRendering
                textFormat: Text.MarkdownText

                color: UtilsAdapter.luma(root.baseColor) ? JamiTheme.chatviewTextColorLight : JamiTheme.chatviewTextColorDark
            }

            JoinCallButton {
                id: joinCallInAudio
                Layout.topMargin: 4
                Layout.bottomMargin: 4

                text: JamiStrings.joinInAudio
                onClicked: MessagesAdapter.joinCall(ActionUri, DeviceId, ConfId, true)
            }

            JoinCallButton {
                id: joinCallInVideo
                text: JamiStrings.joinInVideo
                Layout.topMargin: 4
                Layout.bottomMargin: 4

                onClicked: MessagesAdapter.joinCall(ActionUri, DeviceId, ConfId)
                Layout.rightMargin: 4
            }
        }
    ]

    opacity: 0
    Behavior on opacity  {
        NumberAnimation {
            duration: 100
        }
    }
    Component.onCompleted: {
        bubble.timestampItem.visible = !root.isActive;
        opacity = 1;
    }
}
