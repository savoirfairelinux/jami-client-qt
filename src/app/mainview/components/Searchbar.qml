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

    property real messagesResearchPanel: JamiTheme.detailsPageMinWidth

    //TO DO: find a design to set dynamically the size of the searchbar
    property real searchBarWidth: JamiTheme.searchbarSize

    property string currentConversationId: CurrentConversation.id
    property bool isOpened: false

    function openSearchBar() {
        if (isOpened)
            return
        searchBarOpened()
        rectTextArea.isSearch = true
        anim.start()
        textArea.forceActiveFocus()
        isOpened = true
    }

    function closeSearchbar() {
        if (!isOpened)
            return
        searchBarClosed()
        rectTextArea.isSearch = false
        anim.start()
        isOpened = false
    }

    Connections {
        target: chatViewHeader
        function onShowDetailsClicked() {
            if (rectTextArea.isSearch)
                closeSearchbar()
        }
    }

    onCurrentConversationIdChanged: {
        if (isOpened)
            closeSearchbar()
    }


    PushButton {
        id: startSearchMessages

        source: JamiResources.search_svg
        normalColor: JamiTheme.chatviewBgColor
        imageColor: JamiTheme.chatviewButtonColor

        onClicked: {
            if (rectTextArea.isSearch)
                closeSearchbar()
            else
                openSearchBar()
        }
    }


    SequentialAnimation {
        id: anim

        PropertyAnimation {
            target: rectTextArea; properties: "visible"
            to: true
            duration: 0
        }

        ParallelAnimation {

            NumberAnimation {
                target: rectTextArea; properties: "opacity"
                from: rectTextArea.isSearch ? 0 : 1
                to: rectTextArea.isSearch ? 1 : 0
                duration: 150
            }

            NumberAnimation {
                target: rectTextArea; properties: "Layout.preferredWidth"
                from: rectTextArea.isSearch ? 0 : root.searchBarWidth
                to: rectTextArea.isSearch ? root.searchBarWidth : 0
                duration: 150
            }
        }

        PropertyAnimation {
            target: rectTextArea; properties: "visible"
            to: rectTextArea.isSearch
            duration: 0
        }

    }
    Rectangle {
        id: rectTextArea

        visible: false
        Layout.preferredHeight: startSearchMessages.height
        Layout.alignment: Qt.AlignVCenter
        color: "transparent"
        border.color: JamiTheme.chatviewTextColor
        radius: 10
        border.width: 2

        property bool isSearch: false
        property int textAreaWidth: 200
        property alias searchBarWidth: root.searchBarWidth

        onSearchBarWidthChanged: {
            Layout.preferredWidth = root.searchBarWidth
        }

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
