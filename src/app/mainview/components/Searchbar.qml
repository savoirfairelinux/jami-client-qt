/*
 * Copyright (C) 2023 Savoir-faire Linux Inc.
 * Author: Nicolas Vengeon <nicolas.vengeon@savoirfairelinux.com>
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
import QtQuick.Layouts
import QtQuick.Controls
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import "../../commoncomponents"

RowLayout {
    id: root
    property string currentConversationId: CurrentConversation.id
    property bool isOpen: extrasPanel.isOpen(ChatView.MessagesResearchPanel)

    onIsOpenChanged: if (isOpen)
        textArea.forceActiveFocus()

    PushButton {
        id: startSearchMessages
        imageColor: JamiTheme.chatviewButtonColor
        normalColor: JamiTheme.chatviewBgColor
        source: JamiResources.search_svg

        onClicked: chatViewHeader.searchClicked()
    }
    Rectangle {
        id: rectTextArea
        Layout.alignment: Qt.AlignVCenter
        Layout.preferredHeight: startSearchMessages.height
        Layout.preferredWidth: isOpen ? JamiTheme.searchbarSize : 0
        border.color: JamiTheme.chatviewTextColor
        border.width: 2
        color: "transparent"
        opacity: isOpen
        radius: 10
        visible: opacity

        TextField {
            id: textArea
            anchors.left: rectTextArea.left
            anchors.right: clearTextButton.left
            background.visible: false
            color: JamiTheme.chatviewTextColor
            placeholderText: JamiStrings.search
            placeholderTextColor: JamiTheme.chatviewTextColor

            onTextChanged: {
                MessagesAdapter.searchbarPrompt = text;
            }
        }
        PushButton {
            id: clearTextButton
            property string convId: CurrentConversation.id

            anchors.margins: 5
            anchors.right: rectTextArea.right
            anchors.verticalCenter: rectTextArea.verticalCenter
            imageColor: JamiTheme.chatviewButtonColor
            normalColor: "transparent"
            opacity: visible ? 1 : 0
            preferredSize: 21
            radius: rectTextArea.radius
            source: JamiResources.ic_clear_24dp_svg
            toolTipText: JamiStrings.clearText
            visible: textArea.text.length

            onClicked: {
                textArea.clear();
                textArea.forceActiveFocus();
            }
            onConvIdChanged: {
                textArea.clear();
            }

            Behavior on opacity  {
                NumberAnimation {
                    duration: 500
                    easing.type: Easing.OutCubic
                }
            }
        }

        Behavior on Layout.preferredWidth  {
            NumberAnimation {
                duration: 150
            }
        }
        Behavior on opacity  {
            NumberAnimation {
                duration: 150
            }
        }
    }
}
