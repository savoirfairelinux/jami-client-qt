/*
 * Copyright (C) 2022-2024 Savoir-faire Linux Inc.
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
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import net.jami.Models 1.1

ModalTextEdit {
    id: root

    prefixIconSrc: {
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
    prefixIconColor: {
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
    suffixIconSrc: JamiResources.outline_info_24dp_svg
    suffixIconColor: JamiTheme.buttonTintedBlue

    property bool isActive: false
    property string infohash: CurrentAccount.uri
    property string accountId: CurrentAccount.id
    property string registeredName: CurrentAccount.registeredName
    staticText: root.isActive ? registeredName : (registeredName ? registeredName : infohash)

    infoTipText: JamiStrings.usernameToolTip
    placeholderText: JamiStrings.chooseAUsername

    textValidator: RegularExpressionValidator {
        regularExpression: /[A-Za-z0-9-]{0,32}/
    }

    enum NameRegistrationState {
        BLANK,
        INVALID,
        TAKEN,
        FREE,
        SEARCHING
    }
    property int nameRegistrationState: UsernameTextEdit.NameRegistrationState.BLANK

    inputIsValid: dynamicText.length === 0 || nameRegistrationState === UsernameTextEdit.NameRegistrationState.FREE

    onActiveChanged: function (active) {
        root.isActive = active;
    }

    Connections {
        target: CurrentAccount

        function onRegisteredNameChanged() {
            root.editMode = false;
        }
    }

    Connections {
        id: registeredNameFoundConnection

        target: NameDirectory
        enabled: dynamicText.length !== 0

        function onRegisteredNameFound(status, address, name) {
            if (dynamicText === name) {
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
            if (dynamicText.length !== 0) {
                nameRegistrationState = UsernameTextEdit.NameRegistrationState.SEARCHING;
                NameDirectory.lookupName(root.accountId, dynamicText);
            } else {
                nameRegistrationState = UsernameTextEdit.NameRegistrationState.BLANK;
            }
        }
    }

    onDynamicTextChanged: lookupTimer.restart()

    function startEditing() {
        if (!registeredName) {
            root.editMode = true;
            forceActiveFocus();
            nameRegistrationState = UsernameTextEdit.NameRegistrationState.BLANK;
        }
    }
}
