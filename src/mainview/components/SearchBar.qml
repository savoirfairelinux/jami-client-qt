/*
 * Copyright (C) 2020 by Savoir-faire Linux
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

import QtQuick 2.14
import QtQuick.Controls 2.14
import QtQuick.Layouts 1.14
import QtGraphicalEffects 1.14

import net.jami.Models 1.0
import net.jami.Constants 1.0

Rectangle {
    id: root

    signal searchBarTextChanged(string text)
    signal returnPressedWhileSearching

    function clearText() {
        searchBar.clear()
        fakeFocus.forceActiveFocus()
    }

    function setText(data) {
        searchBar.text = data
        fakeFocus.forceActiveFocus()
    }

    radius: height / 2
    color: JamiTheme.secondaryBackgroundColor

    FocusScope {
        id: fakeFocus
    }

    Image {
        id: searchIconImage

        anchors.verticalCenter: root.verticalCenter
        anchors.left: root.left
        anchors.leftMargin: 8

        width: 20
        height: 20

        fillMode: Image.PreserveAspectFit
        mipmap: true
        source: "qrc:/images/icons/ic_baseline-search-24px.svg"
    }

    ColorOverlay {
        anchors.fill: searchIconImage
        source: searchIconImage
        color: JamiTheme.searchBarPlaceHolderTextFontColor
    }

    TextField {
        id: searchBar
        color: JamiTheme.textColor

        anchors.verticalCenter: root.verticalCenter
        anchors.left: searchIconImage.right

        width: root.width - searchIconImage.width - 10
        height: root.height - 5

        font.pointSize: JamiTheme.textFontSize
        selectByMouse: true
        selectionColor: JamiTheme.searchBarPlaceHolderTextFontColor

        placeholderText: JamiStrings.contactSearchConversation
        placeholderTextColor: JamiTheme.searchBarPlaceHolderTextFontColor

        background: Rectangle {
            id: searchBarBackground

            color: "transparent"
        }

        onTextChanged: {
            root.searchBarTextChanged(
                        searchBar.text)
        }
    }

    Shortcut {
        sequence: "Ctrl+F"
        context: Qt.ApplicationShortcut
        onActivated: searchBar.forceActiveFocus()
    }

    Shortcut {
        sequence: "Return"
        context: Qt.ApplicationShortcut
        onActivated: {
            if (searchBar.text !== "") {
                returnPressedWhileSearching()
            }
        }
    }
}
