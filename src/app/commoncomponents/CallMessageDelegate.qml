/*
 * Copyright (C) 2022-2024 Savoir-faire Linux Inc.
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
import Qt5Compat.GraphicalEffects
import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1

SBSMessageBase {
    id: root

    property var confId: ConfId
    property var currentCallId: CurrentCall.id
    component JoinCallButton: MaterialButton {
        visible: root.isActive && root.currentCallId !== root.confId
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
    bubble.color: JamiTheme.messageInBgColor
    bubble.opacity: 0.6

    Connections {
        target: CurrentConversation
        enabled: root.isActive

        function onActiveCallsChanged() {
            root.isActive = LRCInstance.indexOfActiveCall(root.confId, ActionUri, DeviceId) !== -1;
            if (root.isActive) {
                bubble.mask.border.color = CurrentConversation.color;
                bubble.mask.border.width = 1.5;
                bubble.mask.z = -2;
            }
        }
    }

    property bool isActive: LRCInstance.indexOfActiveCall(root.confId, ActionUri, DeviceId) !== -1
    visible: isActive || root.confId === "" || Duration > 0

    property var baseColor: JamiTheme.messageInBgColor

    innerContent.children: [
        RowLayout {
            id: msg
            anchors.right: isOutgoing ? parent.right : undefined
            spacing: 10
            visible: root.visible

            Image {
                id: statusIcon
                Layout.leftMargin: 8
                width: 10
                height: 10
                verticalAlignment: Qt.AlignVCenter
                visible: !root.isActive

                source: {
                    if (root.isOutgoing) {
                        if (Duration > 0)
                            return "qrc:/icons/outgoing-call.svg";
                        else
                            return "qrc:/icons/missed-outgoing-call.svg";
                    } else {
                        if (Duration > 0)
                            return "qrc:/icons/incoming-call.svg";
                        else
                            return "qrc:/icons/missed-incoming-call.svg";
                    }
                }
                layer {
                    enabled: true
                    effect: ColorOverlay {
                        color: {
                            if (Duration > 0)
                                return UtilsAdapter.luma(root.baseColor) ? JamiTheme.chatviewTextColorLight : JamiTheme.chatviewTextColorDark
                            return JamiTheme.redColor
                        }
                    }
                }

            }

            TextEdit {
                id: callLabel
                objectName: "callLabel"

                topPadding: 8
                bottomPadding: 8

                Layout.fillWidth: true
                Layout.rightMargin: root.isActive && root.currentCallId !== root.confId ? 0 : root.timeWidth + 16
                Layout.leftMargin: root.isActive ? 10 : -5 /* spacing is 10 and we want 5px with icon */

                text: {
                    if (root.isActive)
                        return JamiStrings.startedACall;
                    return Body;
                }
                verticalAlignment: Qt.AlignVCenter
                horizontalAlignment: Qt.AlignHCenter

                font.pointSize: JamiTheme.smallFontSize
                font.hintingPreference: Font.PreferNoHinting
                renderType: Text.NativeRendering
                textFormat: Text.MarkdownText

                color: UtilsAdapter.luma(root.baseColor) ? JamiTheme.chatviewTextColorLight : JamiTheme.chatviewTextColorDark
            }

            JoinCallButton {
                id: joinCallWithDeviceAudio
                objectName: "joinCallWithDeviceAudio"
                Layout.topMargin: 4
                Layout.bottomMargin: 4

                text: JamiStrings.joinWithDeviceAudio
                onClicked: MessagesAdapter.joinCall(ActionUri, DeviceId, root.confId, true)
            }

            JoinCallButton {
                id: joinCallWithVideo
                objectName: "joinCallWithVideo"
                text: JamiStrings.joinWithVideo
                Layout.topMargin: 4
                Layout.bottomMargin: 4

                onClicked: MessagesAdapter.joinCall(ActionUri, DeviceId, root.confId)
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
        bubble.timestampItem.visible = !root.isActive || root.currentCallId === root.confId;
        opacity = 1;
    }
}
