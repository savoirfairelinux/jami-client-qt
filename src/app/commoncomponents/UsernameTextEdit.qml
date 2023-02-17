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

import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import net.jami.Models 1.1

ModalTextEdit {
    id: root

    prefixIconSrc: {
        switch(nameRegistrationState){
        case UsernameLineEdit.NameRegistrationState.FREE:
            return JamiResources.circled_green_check_svg
        case UsernameLineEdit.NameRegistrationState.INVALID:
        case UsernameLineEdit.NameRegistrationState.TAKEN:
            return JamiResources.circled_red_cross_svg
        case UsernameLineEdit.NameRegistrationState.BLANK:
        default:
            return JamiResources.person_24dp_svg
        }
    }
    prefixIconColor: {
        switch(nameRegistrationState){
        case UsernameLineEdit.NameRegistrationState.FREE:
            return "#009980"
        case UsernameLineEdit.NameRegistrationState.INVALID:
        case UsernameLineEdit.NameRegistrationState.TAKEN:
            return "#CC0022"
        case UsernameLineEdit.NameRegistrationState.BLANK:
        default:
            return JamiTheme.editLineColor
        }
    }
    suffixIconSrc: JamiResources.outline_info_24dp_svg
    suffixIconColor: JamiTheme.buttonTintedBlue

    property string infohash: CurrentAccount.uri
    property string registeredName: CurrentAccount.registeredName
    property bool hasRegisteredName: registeredName !== ''

    infoTipText: JamiStrings.usernameToolTip
    placeholderText: JamiStrings.chooseAUsername

    enum NameRegistrationState { BLANK, INVALID, TAKEN, FREE, SEARCHING }
    property int nameRegistrationState: UsernameLineEdit.NameRegistrationState.BLANK

    inputIsValid: dynamicText.length === 0
                  || nameRegistrationState === UsernameLineEdit.NameRegistrationState.FREE

    Connections {
        target: CurrentAccount

        function onRegisteredNameChanged() {
            root.editMode = false
        }
    }

    Connections {
        id: registeredNameFoundConnection

        target: NameDirectory
        enabled: dynamicText.length !== 0

        function onRegisteredNameFound(status, address, name) {
            if (dynamicText === name) {
                switch(status) {
                case NameDirectory.LookupStatus.NOT_FOUND:
                    nameRegistrationState = UsernameLineEdit.NameRegistrationState.FREE
                    break
                case NameDirectory.LookupStatus.ERROR:
                case NameDirectory.LookupStatus.INVALID_NAME:
                case NameDirectory.LookupStatus.INVALID:
                    nameRegistrationState = UsernameLineEdit.NameRegistrationState.INVALID
                    break
                case NameDirectory.LookupStatus.SUCCESS:
                    nameRegistrationState = UsernameLineEdit.NameRegistrationState.TAKEN
                    break
                }
            }
        }
    }

    Timer {
        id: lookupTimer

        repeat: false
        interval: JamiTheme.usernameLineEditlookupInterval

        onTriggered: {
            if (dynamicText.length !== 0) {
                nameRegistrationState = UsernameLineEdit.NameRegistrationState.SEARCHING
                NameDirectory.lookupName(CurrentAccount.id, dynamicText)
            } else {
                nameRegistrationState = UsernameLineEdit.NameRegistrationState.BLANK
            }
        }
    }
    onDynamicTextChanged: lookupTimer.restart()

    function startEditing() {
        if (!hasRegisteredName) {
            root.editMode = true
            forceActiveFocus()
            nameRegistrationState = UsernameLineEdit.NameRegistrationState.BLANK
        }
    }
}
