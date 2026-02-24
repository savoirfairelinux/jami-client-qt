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
import QtQuick.Effects

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
    property bool isRendezVous

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
        case UsernameTextEdit.NameRegistrationState.SEARCHING:
            return JamiResources.jami_rolling_spinner_gif;
        case UsernameTextEdit.NameRegistrationState.BLANK:
        default:
            return JamiResources.person_24dp_svg;
        }
    }
    leadingIconIsSpinning: root.nameRegistrationState === UsernameTextEdit.NameRegistrationState.SEARCHING

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

    placeholderText: root.isRendezVous ? JamiStrings.chooseAName : JamiStrings.chooseUsername
    textFieldContent: root.isActive ? registeredName : (registeredName ? registeredName : infohash)
    inputIsValid: modifiedTextFieldContent.length === 0 || nameRegistrationState === UsernameTextEdit.NameRegistrationState.FREE
    validator: RegularExpressionValidator {
        // up to 32 unicode code points
        regularExpression: /^.{0,32}$/
    }

    trailingIconSource: JamiResources.outline_info_24dp_svg
    trailingIconChecked: infoPopup.opened

    onTrailingIconClicked: {
        if (infoPopup.opened)
            infoPopup.close()
        else
            infoPopup.open()
    }

    supportingText: {
        switch (root.nameRegistrationState) {
        case UsernameTextEdit.NameRegistrationState.BLANK:
            return "";
        case UsernameTextEdit.NameRegistrationState.SEARCHING:
            return "";
        case UsernameTextEdit.NameRegistrationState.FREE:
            return "";
        case UsernameTextEdit.NameRegistrationState.INVALID:
            return root.isRendezVous ? JamiStrings.invalidName :
                                       JamiStrings.invalidUsername;
        case UsernameTextEdit.NameRegistrationState.TAKEN:
            return root.isRendezVous ? JamiStrings.nameAlreadyTaken :
                                       JamiStrings.usernameAlreadyTaken;
        }
    }
    supportingTextColor: "#CC0022"

    borderColor: {
        switch (root.nameRegistrationState) {
        case UsernameTextEdit.NameRegistrationState.INVALID:
        case UsernameTextEdit.NameRegistrationState.TAKEN:
            return "#CC0022"
        default:
            return JamiTheme.tintedBlue
        }
    }

    onModifiedTextFieldContentChanged: lookupTimer.restart()

    Popup {
        id: infoPopup

        parent: parent
        x: parent.width - width
        y: - (parent.height + 16)

        padding: 8

        visible: false
        opacity: visible ? 1.0 : 0.0

        contentItem: Text {
            text: JamiStrings.usernameToolTip
            color: JamiTheme.textColor
            lineHeight: JamiTheme.wizardViewTextLineHeight
            verticalAlignment: Text.AlignVCenter

            font.kerning: true
            font.pixelSize: JamiTheme.infoBoxDescFontSize
        }

        Behavior on opacity {
            NumberAnimation {
                duration: JamiTheme.shortFadeDuration
            }
        }

        background: Rectangle {
            color: JamiTheme.globalIslandColor
            radius: 12

            layer.enabled: true
            layer.effect: MultiEffect {
                anchors.fill: infoPopup.background
                shadowEnabled: true
                shadowBlur: JamiTheme.shadowBlur
                shadowColor: JamiTheme.shadowColor
                shadowHorizontalOffset: JamiTheme.shadowHorizontalOffset
                shadowVerticalOffset: JamiTheme.shadowVerticalOffset
                shadowOpacity: JamiTheme.shadowOpacity
            }
        }
    }

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
