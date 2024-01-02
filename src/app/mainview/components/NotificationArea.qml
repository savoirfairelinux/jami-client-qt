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

Rectangle {
    id: root

    opacity: visible
    color: CurrentConversation.color

    property string id: ""
    property string uri: ""
    property string device: ""

    property string textColor: UtilsAdapter.luma(root.color) ? JamiTheme.chatviewTextColorLight : JamiTheme.chatviewTextColorDark
    RowLayout {
        anchors.fill: parent
        anchors.margins: JamiTheme.preferredMarginSize
        spacing: 0

        Text {
            id: errorLabel
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            Layout.margins: 0
            text: JamiStrings.wantToJoin
            color: root.textColor
            font.pixelSize: JamiTheme.headerFontSize
            elide: Text.ElideRight
        }

        PushButton {
            id: joinCallInAudio
            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
            Layout.rightMargin: JamiTheme.preferredMarginSize

            source: JamiResources.place_audiocall_24dp_svg
            toolTipText: JamiStrings.joinCall

            imageColor: root.textColor
            normalColor: "transparent"
            hoveredColor: Qt.rgba(255, 255, 255, 0.2)
            border.width: 1
            border.color: root.textColor

            onClicked: MessagesAdapter.joinCall(uri, device, id, true)
        }

        PushButton {
            id: joinCallInVideo
            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
            Layout.rightMargin: JamiTheme.preferredMarginSize

            source: JamiResources.videocam_24dp_svg
            toolTipText: JamiStrings.joinCall

            imageColor: root.textColor
            normalColor: "transparent"
            hoveredColor: Qt.rgba(255, 255, 255, 0.2)
            border.width: 1
            border.color: root.textColor
            visible: CurrentAccount.videoEnabled_Video

            onClicked: MessagesAdapter.joinCall(uri, device, id)
        }

        PushButton {
            id: btnClose
            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter

            imageColor: root.textColor
            normalColor: JamiTheme.transparentColor

            source: JamiResources.round_close_24dp_svg

            onClicked: ConversationsAdapter.ignoreActiveCall(CurrentConversation.id, id, uri, device)
        }
    }

    Behavior on opacity  {
        NumberAnimation {
            from: 0
            duration: JamiTheme.shortFadeDuration
        }
    }
}
