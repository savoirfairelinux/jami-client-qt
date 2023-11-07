/*
 * Copyright (C) 2022-2023 Savoir-faire Linux Inc.
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

BaseModalDialog {
    id: root

    property bool isAdmin: {
        var role = UtilsAdapter.getParticipantRole(CurrentAccount.id, CurrentConversation.id, CurrentAccount.uri);
        return role === Member.Role.ADMIN;
    }

    button1.text: isAdmin ? JamiStrings.becomeHostOneCall : JamiStrings.hostThisCall
    button1Role: DialogButtonBox.ApplyRole
    button1.onClicked: {
        MessagesAdapter.joinCall(CurrentAccount.uri, CurrentAccount.deviceId, "0");
        close();
    }

    button2.text: JamiStrings.becomeDefaultHost
    button2Role: DialogButtonBox.ApplyRole
    button2.visible: isAdmin
    button2.toolTipText: JamiStrings.becomeDefaultHost
    button2.onClicked: {
        CurrentConversation.setInfo("rdvAccount", CurrentAccount.uri);
        CurrentConversation.setInfo("rdvDevice", CurrentAccount.deviceId);
        MessagesAdapter.joinCall(CurrentAccount.uri, CurrentAccount.deviceId, "0");
        close();
    }

    popupContent: ColumnLayout {
        id: mainLayout

        Label {
            id: informativeLabel

            Layout.alignment: Qt.AlignCenter
            Layout.bottomMargin: 10
            Layout.fillWidth: true
            Layout.maximumWidth: root.parent.width - 4*JamiTheme.preferredMarginSize
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            text: JamiStrings.needsHost
            color: JamiTheme.primaryForegroundColor
        }
    }
}
