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
    id: rootDelegate

    property var confId: ConfId
    property var currentCallId: CurrentCall.id
    component JoinCallButton: MaterialButton {
        visible: rootDelegate.isActive && rootDelegate.currentCallId !== rootDelegate.confId
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

    property bool isRemoteImage

    isOutgoing: Author === CurrentAccount.uri
    author: Author
    readers: Readers
    formattedTime: MessagesAdapter.getFormattedTime(Timestamp)

    bubble.border.color: CurrentConversation.color
    bubble.border.width: rootDelegate.isActive ? 1.5 : 0
    bubble.color: JamiTheme.messageInBgColor
    bubble.opacity: 1

    Connections {
        target: CurrentConversation
        enabled: rootDelegate.isActive

        function onActiveCallsChanged() {
            rootDelegate.isActive = LRCInstance.indexOfActiveCall(rootDelegate.confId, ActionUri, DeviceId) !== -1;
            if (rootDelegate.isActive) {
                bubble.mask.border.color = CurrentConversation.color;
                bubble.mask.border.width = 1.5;
                bubble.mask.z = -2;
            }
        }
    }

    property bool isActive: LRCInstance.indexOfActiveCall(rootDelegate.confId, ActionUri, DeviceId) !== -1
    visible: isActive || rootDelegate.confId === "" || Duration > 0

    property var baseColor: JamiTheme.messageInBgColor

    innerContent.children: [
        RowLayout {
            id: msg
            anchors.right: isOutgoing ? parent.right : undefined
            spacing: 10
            visible: rootDelegate.visible

            Image {
                id: statusIcon
                Layout.leftMargin: 8
                width: 10
                height: 10
                verticalAlignment: Qt.AlignVCenter
                visible: !rootDelegate.isActive

                source: {
                    if (rootDelegate.isOutgoing) {
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
                                return UtilsAdapter.luma(rootDelegate.baseColor) ? JamiTheme.chatviewTextColorLight : JamiTheme.chatviewTextColorDark;
                            return JamiTheme.redColor;
                        }
                    }
                }
            }

            Text {
                id: callLabel
                objectName: "callLabel"

                topPadding: 8
                bottomPadding: 8

                Layout.fillWidth: true
                Layout.rightMargin: rootDelegate.isActive && rootDelegate.currentCallId !== rootDelegate.confId ? 0 : rootDelegate.timeWidth + 16
                Layout.leftMargin: rootDelegate.isActive ? 10 : -5 /* spacing is 10 and we want 5px with icon */

                text: {
                    if (rootDelegate.isActive)
                        return JamiStrings.startedACall;
                    return Body;
                }
                verticalAlignment: Qt.AlignVCenter
                horizontalAlignment: Qt.AlignHCenter

                font.pointSize: JamiTheme.smallFontSize
                font.hintingPreference: Font.PreferNoHinting
                renderType: Text.NativeRendering
                textFormat: Text.MarkdownText

                color: UtilsAdapter.luma(rootDelegate.baseColor) ? JamiTheme.chatviewTextColorLight : JamiTheme.chatviewTextColorDark
            }

            JoinCallButton {
                id: joinCallWithAudio
                objectName: "joinCallWithAudio"
                Layout.topMargin: 4
                Layout.bottomMargin: 4

                text: JamiStrings.joinWithAudio
                onClicked: MessagesAdapter.joinCall(ActionUri, DeviceId, rootDelegate.confId)
            }

            JoinCallButton {
                id: joinCallWithVideo
                objectName: "joinCallWithVideo"
                text: JamiStrings.joinWithVideo
                Layout.topMargin: 4
                Layout.bottomMargin: 4

                onClicked: MessagesAdapter.joinCall(ActionUri, DeviceId, rootDelegate.confId, false)
                Layout.rightMargin: 4
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
        bubble.timestampItem.visible = !rootDelegate.isActive || rootDelegate.currentCallId === rootDelegate.confId;
        opacity = 1;
    }
}
