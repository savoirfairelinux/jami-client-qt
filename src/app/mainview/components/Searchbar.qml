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

    property bool isOpen: detailsPanel.isOpen(ChatView.MessagesResearchPanel)
    onIsOpenChanged: if (isOpen) textArea.forceActiveFocus()

    PushButton {
        id: startSearchMessages

        source: JamiResources.search_svg
        normalColor: JamiTheme.chatviewBgColor
        imageColor: JamiTheme.chatviewButtonColor

        onClicked: chatViewHeader.searchClicked()
    }

    Rectangle {
        id: rectTextArea

        Layout.preferredHeight: startSearchMessages.height
        Layout.alignment: Qt.AlignVCenter

        color: "transparent"
        border.color: JamiTheme.chatviewTextColor
        radius: 10
        border.width: 2

        opacity: isOpen
        visible: opacity
        Behavior on opacity { NumberAnimation { duration: 150 } }

        Layout.preferredWidth: isOpen ? JamiTheme.searchbarSize : 0
        Behavior on Layout.preferredWidth { NumberAnimation { duration: 150 } }

        TextField {
            id: textArea

            background.visible: false
            anchors.right: clearTextButton.left
            anchors.left: rectTextArea.left
            color: JamiTheme.chatviewTextColor
            placeholderText: JamiStrings.search
            placeholderTextColor: JamiTheme.chatviewTextColor

            onTextChanged: {
                MessagesAdapter.searchbarPrompt = text
            }
        }

        PushButton {
            id: clearTextButton

            anchors.verticalCenter: rectTextArea.verticalCenter
            anchors.right: rectTextArea.right
            anchors.margins: 5
            preferredSize: 21

            radius: rectTextArea.radius
            visible: textArea.text.length
            opacity: visible ? 1 : 0
            normalColor: "transparent"
            imageColor: JamiTheme.chatviewButtonColor
            source: JamiResources.ic_clear_24dp_svg
            toolTipText: JamiStrings.clearText

            property string convId: CurrentConversation.id
            onConvIdChanged: {
                textArea.clear()
            }

            onClicked: {
                textArea.clear()
                textArea.forceActiveFocus()
            }

            Behavior on opacity {
                NumberAnimation { duration: 500; easing.type: Easing.OutCubic }
            }
        }
    }
}
