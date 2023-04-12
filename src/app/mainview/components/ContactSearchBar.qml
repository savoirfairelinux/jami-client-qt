/*
 * Copyright (C) 2020-2023 Savoir-faire Linux Inc.
 * Author: Mingrui Zhang <mingrui.zhang@savoirfairelinux.com>
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
import net.jami.Constants 1.1
import "../../commoncomponents"

Rectangle {
    id: root
    property alias placeHolderText: contactSearchBar.placeholderText
    property alias textContent: contactSearchBar.text

    color: JamiTheme.secondaryBackgroundColor
    radius: JamiTheme.primaryRadius

    function clearText() {
        contactSearchBar.clear();
        contactSearchBar.forceActiveFocus();
    }
    signal contactSearchBarTextChanged(string text)
    signal returnPressedWhileSearching

    Keys.onPressed: function (keyEvent) {
        if (keyEvent.key === Qt.Key_Enter || keyEvent.key === Qt.Key_Return) {
            if (contactSearchBar.text !== "") {
                returnPressedWhileSearching();
                keyEvent.accepted = true;
            }
        }
    }
    onFocusChanged: {
        if (focus) {
            contactSearchBar.forceActiveFocus();
        }
    }

    LineEditContextMenu {
        id: lineEditContextMenu
        lineEditObj: contactSearchBar
    }
    ResponsiveImage {
        id: searchIconImage
        anchors.left: root.left
        anchors.leftMargin: 10
        anchors.verticalCenter: root.verticalCenter
        color: JamiTheme.primaryForegroundColor
        height: 20
        source: JamiResources.ic_baseline_search_24dp_svg
        width: 20
    }
    TextField {
        id: contactSearchBar
        anchors.left: searchIconImage.right
        anchors.right: contactSearchBar.text.length ? clearTextButton.left : root.right
        anchors.verticalCenter: root.verticalCenter
        color: JamiTheme.textColor
        font.kerning: true
        font.pointSize: JamiTheme.textFontSize
        height: root.height - 5
        placeholderText: JamiStrings.search
        placeholderTextColor: JamiTheme.placeholderTextColor
        selectByMouse: true

        onReleased: function (event) {
            if (event.button === Qt.RightButton)
                lineEditContextMenu.openMenuAt(event);
        }
        onTextChanged: root.contactSearchBarTextChanged(contactSearchBar.text)

        background: Rectangle {
            id: searchBarBackground
            color: "transparent"
        }
    }
    PushButton {
        id: clearTextButton
        anchors.right: root.right
        anchors.rightMargin: 10
        anchors.verticalCenter: root.verticalCenter
        imageColor: JamiTheme.primaryForegroundColor
        normalColor: root.color
        opacity: visible ? 1 : 0
        preferredSize: 21
        radius: JamiTheme.primaryRadius
        source: JamiResources.ic_clear_24dp_svg
        toolTipText: JamiStrings.clearText
        visible: contactSearchBar.text.length

        onClicked: contactSearchBar.clear()

        Behavior on opacity  {
            NumberAnimation {
                duration: 500
                easing.type: Easing.OutCubic
            }
        }
    }
}
