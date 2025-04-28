/*
 * Copyright (C) 2022-2025 Savoir-faire Linux Inc.
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
    property string currentCallId: CurrentCall.id
    property bool isRemoteImage
    property color baseColor: JamiTheme.messageInBgColor
    property bool isActive: LRCInstance.indexOfActiveCall(root.confId, ActionUri, DeviceId) !== -1

    isOutgoing: Author === CurrentAccount.uri
    author: Author
    readers: Readers
    formattedTime: MessagesAdapter.getFormattedTime(Timestamp)

    bubble.border.color: CurrentConversation.color
    bubble.border.width: 0
    bubble.color: JamiTheme.messageInBgColor
    bubble.opacity: 1

    visible: isActive || root.confId === "" || Duration > 0

    component JoinCallButton: PushButton {
        visible: root.isActive && root.currentCallId !== root.confId
        toolTipText: JamiStrings.joinCall
        normalColor: JamiTheme.buttonCallLightGreen
        hoveredColor: JamiTheme.buttonCallDarkGreen
        imageColor: hovered ? JamiTheme.buttonCallLightGreen : JamiTheme.blackColor
        Layout.fillHeight: true
        Layout.fillWidth: true
        radius: 0

    }

    innerContent.children: [

        RowLayout {
            id: msg
            anchors.right: isOutgoing ? parent.right : undefined
            spacing: 0

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

            Text {
                visible: isActive
                text: JamiStrings.callStarted
                Layout.leftMargin: 10
                color: UtilsAdapter.luma(root.baseColor) ? JamiTheme.chatviewTextColorLight : JamiTheme.chatviewTextColorDark

            }

            Text {
                id: callLabel
                objectName: "callLabel"

                topPadding: 8
                bottomPadding: 8

                Layout.fillWidth: true
                Layout.rightMargin: root.isActive && root.currentCallId !== root.confId ? 0 : root.timeWidth + 16
                Layout.leftMargin: root.isActive ? 10 : 5

                text: isActive ? bubble.timestampItem.formattedTime : Body

                verticalAlignment: Qt.AlignVCenter
                horizontalAlignment: Qt.AlignHCenter

                font.pointSize: JamiTheme.smallFontSize
                font.hintingPreference: Font.PreferNoHinting
                renderType: Text.NativeRendering
                textFormat: Text.MarkdownText

                color: UtilsAdapter.luma(root.baseColor) ? JamiTheme.chatviewTextColorLight : JamiTheme.chatviewTextColorDark
            }


            JoinCallButton {
                id: joinCallWithAudio
                Layout.topMargin: 0.5 // For better sub-pixel rendering
                objectName: "joinCallWithAudio"
                source: JamiResources.place_audiocall_24dp_svg
                Layout.leftMargin: 10
                onClicked: MessagesAdapter.joinCall(ActionUri, DeviceId, root.confId, true)
            }

            JoinCallButton {
                id: joinCallWithVideo

                Layout.topMargin: 0.5 // For better sub-pixel rendering
                objectName: "joinCallWithVideo"
                source: JamiResources.videocam_24dp_svg
                onClicked: MessagesAdapter.joinCall(ActionUri, DeviceId, root.confId, true)

                layer.enabled: true
                layer.effect: OpacityMask {
                    source: joinCallWithVideo
                    maskSource: Rectangle {
                        radius: 10
                        width: joinCallWithVideo.width
                        height: joinCallWithVideo.height
                        Rectangle {
                            width: parent.width / 2
                            height: parent.height
                        }
                    }
                }
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
        bubble.timestampItem.visible = (!root.isActive || root.currentCallId === root.confId) && !isActive;
        opacity = 1;
    }
}
