/*
 * Copyright (C) 2021-2022 Savoir-faire Linux Inc.
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
import Qt5Compat.GraphicalEffects

import net.jami.Models 1.1
import net.jami.Constants 1.1

EditableLineEdit {
    id: root

    placeholderText: isRendezVous ? JamiStrings.chooseAName :
                                    JamiStrings.chooseYourUserName

    firstIco: JamiResources.person_24dp_svg
    firstIcoColor: "#03B9E9"

    secondIco: JamiResources.outline_info_24dp_svg
    secondIcoColor: "#005699"

    informationToolTip: JamiStrings.usernameToolTip

    fieldLayoutWidth: 200
    fieldLayoutHeight: 50


    enum NameRegistrationState {
        BLANK,
        INVALID,
        TAKEN,
        FREE,
        SEARCHING
    }

    property int nameRegistrationState: UsernameLineEdit.NameRegistrationState.BLANK
    // property var __iconSource: ""
    wizardInput: true

    selectByMouse: true
    font.pointSize: JamiTheme.usernameLineEditPointSize
    font.kerning: true

    validator: RegularExpressionValidator { regularExpression: /[A-z0-9_]{0,32}/ }

    Connections {
        id: registeredNameFoundConnection

        target: NameDirectory
        enabled: root.text.length !== 0

        function onRegisteredNameFound(status, address, name) {
            if (text === name) {
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
            if (text.length !== 0 && readOnly === false) {
                nameRegistrationState = UsernameLineEdit.NameRegistrationState.SEARCHING
                NameDirectory.lookupName("", text)
            } else {
                nameRegistrationState = UsernameLineEdit.NameRegistrationState.BLANK
            }
        }
    }

    //    ResponsiveImage {
    //        id: lineEditImage

    //        anchors.verticalCenter: parent.verticalCenter
    //        anchors.right: parent.right
    //        anchors.rightMargin: JamiTheme.preferredMarginSize / 2

    //        visible: nameRegistrationState !== UsernameLineEdit.NameRegistrationState.SEARCHING
    //        source: nameRegistrationState === UsernameLineEdit.NameRegistrationState.SEARCHING ?
    //                    "" : __iconSource
    //        color: borderColor
    //    }

    //    AnimatedImage {
    //        anchors.left: lineEditImage.left
    //        anchors.verticalCenter: parent.verticalCenter

    //        width: 24
    //        height: 24

    //        source: nameRegistrationState !== UsernameLineEdit.NameRegistrationState.SEARCHING ?
    //                    "" : __iconSource
    //        playing: true
    //        paused: false
    //        fillMode: Image.PreserveAspectFit
    //        mipmap: true
    //        visible: nameRegistrationState === UsernameLineEdit.NameRegistrationState.SEARCHING
    //    }

    onNameRegistrationStateChanged: {
        if (!enabled)
            borderColor = "transparent"

        switch(nameRegistrationState){
            //        case UsernameLineEdit.NameRegistrationState.SEARCHING:
            ////            __iconSource = JamiResources.jami_rolling_spinner_gif
            //            firstIco = JamiResources.jami_rolling_spinner_gif
            //            borderColor = selectedColor
            //            break
        case UsernameLineEdit.NameRegistrationState.BLANK:
            firstIco=""
            borderColor = "transparent"
            error = false
            validated = false
            break
        case UsernameLineEdit.NameRegistrationState.FREE:
            firstIco = JamiResources.circled_green_check_svg
            borderColor = validatedColor
            firstIcoColor = "transparent"
            validated = true
            error = false

            break
        case UsernameLineEdit.NameRegistrationState.INVALID:
        case UsernameLineEdit.NameRegistrationState.TAKEN:
            firstIco = JamiResources.circled_red_cross_svg
            borderColor = errorColor
            firstIcoColor = "transparent"
            error = true
            validated = false
            break
        }
    }

    onTextChanged: lookupTimer.restart()
}
