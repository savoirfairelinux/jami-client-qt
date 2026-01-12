/*
 * Copyright (C) 2022-2026 Savoir-faire Linux Inc.
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

    visible: isActive || root.confId === "" || Duration > 0
    height: visible ? implicitHeight : 0

    isOutgoing: Author === CurrentAccount.uri
    author: Author
    readers: Readers
    formattedTime: MessagesAdapter.getFormattedTime(Timestamp)

    Accessible.role: Accessible.StaticText
    Accessible.name: {
        let name = isOutgoing ? JamiStrings.inReplyToYou : UtilsAdapter.getBestNameForUri(CurrentAccount.id, Author);
        return name + ": " + callLabel.text + " " + formattedDay;
    }
    Accessible.description: {
        let status = "";
        if (bubble.isEdited)
            status += JamiStrings.edited + " ";
        return status + (readers.length > 0 ? JamiStrings.readBy + " " + readers.map(function (uri) {
                return UtilsAdapter.getBestNameForUri(CurrentAccount.id, uri);
            }).join(", ") : "");
    }

    bubble.border.color: CurrentConversation.color
    bubble.border.width: 0
    bubble.color: JamiTheme.messageInBgColor
    bubble.opacity: 1

    Connections {
        target: CurrentConversation
        function onActiveCallsChanged() {
            root.isActive = LRCInstance.indexOfActiveCall(root.confId, ActionUri, DeviceId) !== -1;
        }
    }

    innerContent.children: [
        RowLayout {
            id: msg
            anchors.right: isOutgoing ? parent.right : undefined
            spacing: 0

            Image {
                id: statusIcon
                visible: !root.isActive

                Layout.leftMargin: 8
                width: 10
                height: 10
                verticalAlignment: Qt.AlignVCenter

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
                                return UtilsAdapter.luma(root.baseColor) ? JamiTheme.chatviewTextColorLight : JamiTheme.chatviewTextColorDark;
                            return JamiTheme.redColor;
                        }
                    }
                }
            }

            Text {
                visible: root.isActive
                text: JamiStrings.callStarted
                Layout.leftMargin: 10
                color: UtilsAdapter.luma(root.baseColor) ? JamiTheme.chatviewTextColorLight : JamiTheme.chatviewTextColorDark
                font.pointSize: JamiTheme.smallFontSize
                font.hintingPreference: Font.PreferNoHinting
                renderType: Text.NativeRendering
            }

            Text {
                id: callLabel
                objectName: "callLabel"

                topPadding: 8
                bottomPadding: 8

                Layout.fillWidth: true
                Layout.rightMargin: root.isActive && root.currentCallId !== root.confId ? 0 : root.timeWidth + 16

                Layout.leftMargin: root.isActive ? 10 : 5

                text: root.isActive ? bubble.timestampItem.formattedTime : Body

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
                Layout.fillHeight: true
                Layout.topMargin: 0.5 // For better sub-pixel rendering
                Layout.leftMargin: 10
                objectName: "joinCallWithAudio"
                toolTipText: JamiStrings.joinWithAudio
                source: JamiResources.start_audiocall_24dp_svg
                onClicked: MessagesAdapter.joinCall(ActionUri, DeviceId, root.confId, true)
                visible: root.isActive && root.currentCallId !== root.confId
                roundedRight: !joinCallWithVideo.visible
            }

            JoinCallButton {
                id: joinCallWithVideo
                Layout.fillHeight: true
                Layout.topMargin: 0.5 // For better sub-pixel rendering
                objectName: "joinCallWithVideo"
                toolTipText: JamiStrings.joinWithVideo
                source: JamiResources.videocam_24dp_svg
                onClicked: MessagesAdapter.joinCall(ActionUri, DeviceId, root.confId, false)
                visible: root.isActive && root.currentCallId !== root.confId && CurrentAccount.videoEnabled_Video
                isVideo: true
            }
        }
    ]

    opacity: 0
    Behavior on opacity {
        NumberAnimation {
            duration: 100
        }
    }
    Component.onCompleted: {
        bubble.timestampItem.visible = (!root.isActive || root.currentCallId === root.confId) && !isActive;
        opacity = 1;
    }
}
