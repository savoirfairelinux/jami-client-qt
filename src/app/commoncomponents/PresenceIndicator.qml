/*
 * Copyright (C) 2020-2026 Savoir-faire Linux Inc.
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
import net.jami.Models 1.1
import net.jami.Constants 1.1

// Serves as either account or contact presence indicator.
// TODO: this should be part of an avatar component at some point.
Rectangle {
    id: root

    // This is set to REGISTERED for contact presence
    // as status is not currently tracked for contact items.
    property int status: Account.Status.REGISTERED
    property int size: 15

    MaterialToolTip {
        visible: text !== "" && hoverHandler.hovered
        delay: Qt.styleHints.mousePressAndHoldInterval
        text: status === 2 ? qsTr("Connected") : status === 1 ? qsTr("Available") : ""
    }

    HoverHandler {
        id: hoverHandler
        target: parent
    }

    width: size
    height: size
    radius: size * 0.5
    border {
        color: JamiTheme.backgroundColor
        width: 2
    }
    color: {
        if (status === Account.Status.REGISTERED)
            return JamiTheme.presenceGreen;
        else if (status === Account.Status.TRYING)
            return JamiTheme.unPresenceOrange;
        else if (status === 2)
            return JamiTheme.presenceGreen;
        else if (status === 1)
            return JamiTheme.unPresenceOrange;
        return JamiTheme.notificationRed;
    }
}
