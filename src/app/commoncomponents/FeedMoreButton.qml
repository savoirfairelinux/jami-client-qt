/*
 * Copyright (C) 2026 Savoir-faire Linux Inc.
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
import net.jami.Constants 1.1

// Opens a feed post's or comment's message options (reactions, edit, delete…) below itself.
NewIconButton {
    id: root
    objectName: "feedMoreButton"

    property string msgId
    property string msgBody
    property int type
    property string transferName
    property bool isOutgoing
    property var emojiReactions
    property Item msgBubble
    property ListView listView

    property bool menuOpen: false

    // Called by the menu when it closes.
    function setBindings() {
        menuOpen = false;
    }

    iconSize: JamiTheme.iconButtonMedium
    iconSource: JamiResources.more_vert_24dp_svg
    toolTipText: JamiStrings.moreOptions

    onClicked: {
        if (menuOpen)
            return;
        const menu = Qt.createComponent("qrc:/commoncomponents/ShowMoreMenu.qml").createObject(root, {
            "emojiReactions": emojiReactions,
            "isOutgoing": isOutgoing,
            "msgId": msgId,
            "msgBody": msgBody,
            "type": type,
            "transferName": transferName,
            "msgBubble": msgBubble,
            "listView": listView
        });
        // Right-aligned under the button, rather than beside a chat bubble.
        menu.x = Qt.binding(() => root.width - menu.width);
        menu.y = Qt.binding(() => root.height);
        menu.open();
        menuOpen = true;
    }
}
