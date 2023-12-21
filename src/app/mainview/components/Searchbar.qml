/*
 * Copyright (C) 2020-2024 Savoir-faire Linux Inc.
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
import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import "../../commoncomponents"

Rectangle {
    id: root

    signal searchBarTextChanged(string text)
    signal returnPressedWhileSearching

    property alias textContent: textArea.text
    property alias placeHolderText: textArea.placeholderText
    property real hoverButtonRadius: JamiTheme.chatViewHeaderButtonRadius
    property string currentConversationId: CurrentConversation.id

    function clearText() {
        textArea.clear();
        textArea.forceActiveFocus();
    }

    radius: JamiTheme.primaryRadius
    color: JamiTheme.secondaryBackgroundColor

    onFocusChanged: {
        if (focus) {
            textArea.forceActiveFocus();
        }
    }

    LineEditContextMenu {
        id: lineEditContextMenu

        lineEditObj: textArea
    }

    ResponsiveImage {
        id: startSearch

        anchors.verticalCenter: root.verticalCenter
        anchors.left: root.left
        anchors.leftMargin: 10
        source: JamiResources.ic_baseline_search_24dp_svg
    }

    Rectangle {
        id: rectTextArea

        height: root.height - 5
        anchors.left: startSearch.right
        anchors.right: root.right
        anchors.verticalCenter: root.verticalCenter
        color: "transparent"
        width: JamiTheme.searchbarSize

        TextField {
            id: textArea

            property bool dontShowFocusState: true

            background.visible: false

            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.right: textArea.text.length ? clearTextButton.left : parent.right

            color: JamiTheme.chatviewTextColor

            placeholderText: JamiStrings.search
            placeholderTextColor: JamiTheme.chatviewTextColor

            height: root.height - 5

            font.pointSize: JamiTheme.textFontSize
            font.kerning: true

            onTextChanged: root.searchBarTextChanged(textArea.text)
            onReleased: function (event) {
                if (event.button === Qt.RightButton)
                    lineEditContextMenu.openMenuAt(event);
            }
        }

        PushButton {
            id: clearTextButton

            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: 15

            preferredSize: 15
            radius: JamiTheme.primaryRadius

            visible: textArea.text.length
            opacity: visible ? 1 : 0

            normalColor: root.color
            imageColor: JamiTheme.primaryForegroundColor

            source: JamiResources.ic_clear_24dp_svg
            toolTipText: JamiStrings.clearText

            onClicked: textArea.clear()

            Behavior on opacity  {
                NumberAnimation {
                    duration: 500
                    easing.type: Easing.OutCubic
                }
            }
        }
    }

    Keys.onPressed: function (keyEvent) {
        if (keyEvent.key === Qt.Key_Enter || keyEvent.key === Qt.Key_Return) {
            if (textArea.text !== "") {
                returnPressedWhileSearching();
                keyEvent.accepted = true;
            }
        }
    }
}
