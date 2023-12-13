/*
 * Copyright (C) 2022-2024 Savoir-faire Linux Inc.
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
import "../../commoncomponents"

Control {
    id: root

    property string id: ""
    property string uri: ""
    property string device: ""

    property string textColor: UtilsAdapter.luma(background.color) ? JamiTheme.chatviewTextColorLight : JamiTheme.chatviewTextColorDark

    property string from: CurrentConversation.callFrom

    Connections {
        target: ConversationsAdapter

        function onTimerUpdated(convId) {
            if (CurrentConversation.id === convId)
                time.text = ConversationsAdapter.getElapsedTime(CurrentConversation.id);
        }
    }

    Connections {
        target: CurrentConversation

        function onIdChanged() {
            time.text = ConversationsAdapter.getElapsedTime(CurrentConversation.id);
        }
    }

    component JoinCallButton: MaterialButton {
        toolTipText: JamiStrings.joinCall
        color: JamiTheme.darkTheme ? JamiTheme.whiteColor : JamiTheme.blackColor
        background.opacity: hovered ? 1 : 0.5
        hoveredColor: JamiTheme.darkTheme ? JamiTheme.whiteColor : JamiTheme.blackColor
        contentColorProvider: root.textColor
        textOpacity: hovered ? 1 : 0.7
        buttontextHeightMargin: 16
        textLeftPadding: 9
        textRightPadding: 9
    }

    contentItem: Rectangle {
        anchors.fill: parent
        color: "transparent"
        RowLayout {
            anchors.centerIn: parent

            Avatar {
                id: avatar
                width: 22
                height: 22
                imageId: root.uri
                showPresenceIndicator: false
                mode: Avatar.Mode.Contact
                Layout.rightMargin: 5
            }

            Text {
                id: fromLabel
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                Layout.margins: 0
                text: from + " " + JamiStrings.startedCall + " - "
                color: root.textColor
                font.pixelSize: JamiTheme.buttontextFontPixelSize
                font.bold: true
                elide: Text.ElideRight
            }

            Text {
                id: time
                text: ConversationsAdapter.getElapsedTime(CurrentConversation.id)//JamiStrings.justNow
                color: root.textColor
                font.pixelSize: JamiTheme.buttontextFontPixelSize
                Layout.rightMargin: 5
            }

            JoinCallButton {
                id: joinCallInAudio
                Layout.topMargin: 4
                Layout.bottomMargin: 4

                Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter

                text: JamiStrings.joinInAudio
                onClicked: MessagesAdapter.joinCall(uri, device, id, true)
            }

            JoinCallButton {
                id: joinCallInVideo
                text: JamiStrings.joinInVideo
                Layout.topMargin: 4
                Layout.bottomMargin: 4
                Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter

                onClicked: MessagesAdapter.joinCall(uri, device, id)
                Layout.rightMargin: 4
            }

    }

        JamiPushButton {
            id: btnClose
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.rightMargin: 5
            preferredSize: 24

            imageColor: root.textColor
            normalColor: JamiTheme.transparentColor
            hoveredColor: JamiTheme.darkTheme ? JamiTheme.whiteColor : JamiTheme.blackColor

            source: JamiResources.round_close_24dp_svg

            onClicked: ConversationsAdapter.ignoreActiveCall(CurrentConversation.id, id, uri, device)
        }

    }

    background: Rectangle {
        opacity: parent.visible ? 0.7 : 0
        color: JamiTheme.darkTheme ? JamiTheme.whiteColor : JamiTheme.blackColor

        Behavior on opacity  {
            NumberAnimation {
                from: 0
                duration: JamiTheme.shortFadeDuration
            }
        }
    }
}
