import QtQuick

import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import net.jami.Models 1.1

ModalTextEdit {
    id: root

    prefixIconSrc:

    prefixIconColor:

    suffixIconSrc: JamiResources.outline_info_24dp_svg
    suffixIconColor: JamiTheme.buttonTintedBlue

    property string infohash: CurrentAccount.uri
    property string registeredName: CurrentAccount.registeredName
    property bool hasRegisteredName: registeredName !== ''

    infoTipText: JamiStrings.usernameToolTip
    placeholderText: JamiStrings.chooseAUsername
    staticText: hasRegisteredName ? registeredName : infohash

    enum NameRegistrationState { BLANK, INVALID, TAKEN, FREE, SEARCHING }
    property int nameRegistrationState: UsernameLineEdit.NameRegistrationState.BLANK

    validator: RegularExpressionValidator { regularExpression: /[A-z0-9_]{0,32}/ }
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
