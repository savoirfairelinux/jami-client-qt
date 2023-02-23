/*
 * Copyright (C) 2020-2023 Savoir-faire Linux Inc.
 * Author: Aline Gondim Santos <aline.gondimsantos@savoirfairelinux.com>
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
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1

import "../../commoncomponents"

ColumnLayout {
    id: root

    property int itemWidth

    // Identity
    Row {
        Layout.fillWidth: true
        Layout.preferredHeight: JamiTheme.preferredFieldHeight

        spacing: width - idLabel.width - currentRingID.width

        Label {
            id: idLabel

            anchors.verticalCenter: parent.verticalCenter

            text: JamiStrings.identifier
            color: JamiTheme.textColor
            font.pointSize: JamiTheme.settingsFontSize
            font.kerning: true

            horizontalAlignment: Text.AlignLeft
            verticalAlignment: Text.AlignVCenter
        }

        MaterialLineEdit {
            id: currentRingID

            anchors.verticalCenter: parent.verticalCenter

            width: parent.width - idLabel.width
                   - JamiTheme.preferredMarginSize
            height: JamiTheme.preferredFieldHeight

            font.pointSize: JamiTheme.textFontSize
            font.kerning: true
            font.bold: true

            padding: 0
            readOnly: true
            selectByMouse: true

            wrapMode: Text.NoWrap
            text: currentRingIDText.elidedText
            color: JamiTheme.textColor

            horizontalAlignment: Text.AlignRight
            verticalAlignment: Text.AlignVCenter

            TextMetrics {
                id: currentRingIDText

                font: currentRingID.font
                elide: Text.ElideRight
                elideWidth: root.width - idLabel.width -
                            JamiTheme.preferredMarginSize * 4

                text: CurrentAccount.uri
            }
        }
    }

    Row {
        Layout.fillWidth: true
        Layout.preferredHeight: JamiTheme.preferredFieldHeight

        spacing: width - lblRegisteredName.width - currentRegisteredID.width

        Label {
            id: lblRegisteredName

            anchors.verticalCenter: parent.verticalCenter

            text: JamiStrings.username
            color: JamiTheme.textColor
            font.pointSize: JamiTheme.settingsFontSize
            font.kerning: true

            horizontalAlignment: Text.AlignLeft
            verticalAlignment: Text.AlignVCenter
        }

        UsernameTextEdit {
            id: currentRegisteredID

            width: JamiTheme.preferredFieldWidth
            height: JamiTheme.preferredFieldHeight + 16

            anchors.margins: 8

            fontPixelSize: JamiTheme.jamiIdFontSize
            staticText: CurrentAccount.registeredName
            placeholderText: JamiStrings.chooseUsername
            editMode: !CurrentAccount.registeredName
            isPersistent: !CurrentAccount.registeredName

            onAccepted: {
                if (dynamicText === '') {
                    return
                }
                var dlg = viewCoordinator.presentDialog(
                            appWindow,
                            "settingsview/components/NameRegistrationDialog.qml",
                            { registeredName: dynamicText })
                dlg.accepted.connect(function() {
                    currentRegisteredID.nameRegistrationState =
                            UsernameTextEdit.NameRegistrationState.BLANK
                })
            }
        }
    }
}
