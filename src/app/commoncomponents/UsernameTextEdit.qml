/*
 * Copyright (C) 2022-2026 Savoir-faire Linux Inc.
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
import QtQuick.Controls.Basic
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import net.jami.Models 1.1

NewMaterialTextField {
    id: root

    property bool isActive: true
    property string infohash: CurrentAccount.uri
    property string accountId: CurrentAccount.id
    property string registeredName: CurrentAccount.registeredName
    property int nameRegistrationState: UsernameTextEdit.NameRegistrationState.BLANK

    enum NameRegistrationState {
        BLANK,
        INVALID,
        TAKEN,
        FREE,
        SEARCHING
    }

    leadingIconSource: {
        switch (nameRegistrationState) {
        case UsernameTextEdit.NameRegistrationState.FREE:
            return JamiResources.circled_green_check_svg;
        case UsernameTextEdit.NameRegistrationState.INVALID:
        case UsernameTextEdit.NameRegistrationState.TAKEN:
            return JamiResources.circled_red_cross_svg;
        case UsernameTextEdit.NameRegistrationState.BLANK:
        default:
            return JamiResources.person_24dp_svg;
        }
    }

    leadingIconColor: {
        switch (nameRegistrationState) {
        case UsernameTextEdit.NameRegistrationState.FREE:
            return "#009980";
        case UsernameTextEdit.NameRegistrationState.INVALID:
        case UsernameTextEdit.NameRegistrationState.TAKEN:
            return "#CC0022";
        case UsernameTextEdit.NameRegistrationState.BLANK:
        default:
            return JamiTheme.editLineColor;
        }
    }

    placeholderText: JamiStrings.chooseAUsername
    textFieldContent: root.isActive ? registeredName : (registeredName ? registeredName : infohash)
    inputIsValid: modifiedTextFieldContent.length === 0 || nameRegistrationState === UsernameTextEdit.NameRegistrationState.FREE
    validator: RegularExpressionValidator {
        // up to 32 unicode code points
        regularExpression: /^.{0,32}$/
    }

    trailingIconSource: JamiResources.outline_info_24dp_svg
    trailingIconChecked: false

    onModifiedTextFieldContentChanged: lookupTimer.restart()

    Connections {
        id: registeredNameFoundConnection

        target: NameDirectory
        enabled: modifiedTextFieldContent.length !== 0

        function onRegisteredNameFound(status, address, registeredName, requestedName) {
            if (modifiedTextFieldContent === requestedName) {
                switch (status) {
                case NameDirectory.LookupStatus.NOT_FOUND:
                    nameRegistrationState = UsernameTextEdit.NameRegistrationState.FREE;
                    break;
                case NameDirectory.LookupStatus.ERROR:
                case NameDirectory.LookupStatus.INVALID_NAME:
                case NameDirectory.LookupStatus.INVALID:
                    nameRegistrationState = UsernameTextEdit.NameRegistrationState.INVALID;
                    break;
                case NameDirectory.LookupStatus.SUCCESS:
                    nameRegistrationState = UsernameTextEdit.NameRegistrationState.TAKEN;
                    break;
                }
            }
        }
    }

    Timer {
        id: lookupTimer

        repeat: false
        interval: JamiTheme.usernameTextEditlookupInterval

        onTriggered: {
            if (modifiedTextFieldContent.length !== 0) {
                nameRegistrationState = UsernameTextEdit.NameRegistrationState.SEARCHING;
                NameDirectory.lookupName(root.accountId, modifiedTextFieldContent);
            } else {
                nameRegistrationState = UsernameTextEdit.NameRegistrationState.BLANK;
            }
        }
    }
}
