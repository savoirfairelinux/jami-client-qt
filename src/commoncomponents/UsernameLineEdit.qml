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

import QtQuick 2.9
import QtQuick.Controls 2.2
import net.jami.Models 1.0

MaterialLineEdit {
    id: root

//    enum NameRegistrationState {
//        BLANK,
//        INVALID,
//        TAKEN,
//        FREE,
//        SEARCHING
//    }

    property int nameRegistrationState: 0

    Connections {
        id: registeredNameFoundConnection

        target: NameDirectory
        enabled: root.text.length !== 0

        onRegisteredNameFound: {
            if (text === name) {
                switch(status) {
                case NameDirectory.LookupStatus.NOT_FOUND:
                    nameRegistrationState = 3
                    break
                case NameDirectory.LookupStatus.ERROR:
                case NameDirectory.LookupStatus.INVALID_NAME:
                case NameDirectory.LookupStatus.INVALID:
                    nameRegistrationState = 1
                    break
                case NameDirectory.LookupStatus.SUCCESS:
                    nameRegistrationState = 2
                    break
                }
            }
        }
    }

    Timer {
        id: lookupTimer

        repeat: false
        interval: 200

        onTriggered: {
            if (text.length !== 0 && readOnly === false) {
                nameRegistrationState = 4
                NameDirectory.lookupName("", text)
            } else {
                nameRegistrationState = 0
            }
        }
    }

    selectByMouse: true
    font.pointSize: 9
    //font.kerning: true

    borderColorMode: {
        switch (nameRegistrationState){
        case 0:
            return 0
        case 1:
        case 2:
            return 3
        case 3:
            return 2
        case 4:
            return 1
        }
    }

    onTextChanged: lookupTimer.restart()
}
