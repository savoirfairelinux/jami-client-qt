/*
 * Copyright (C) 2023 Savoir-faire Linux Inc.
 * Author: Fadi Shehadeh   <fadi.shehadeh@savoirfairelinux.com>
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
import QtQuick.Controls
import QtQuick.Layouts
import Qt.labs.platform

import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import net.jami.Enums 1.1
import net.jami.Models 1.1

import "../../commoncomponents"

Rectangle {
    id: root

    property int contentWidth: manageAccountEnableColumnLayout.width
    property int preferredHeight: manageAccountEnableColumnLayout.implicitHeight
    property int preferredWidth: Math.min(JamiTheme.maximumWidthSettingsView , root.width - JamiTheme.preferredMarginSize*4)
    property bool isSIP

    signal navigateToMainView
    signal navigateToNewWizardView

    color: JamiTheme.secondaryBackgroundColor

    ColumnLayout {

        id: manageAccountEnableColumnLayout
        anchors.left: root.left
        width: Math.min(JamiTheme.maximumWidthSettingsView, root.width)
        spacing: JamiTheme.wizardViewPageBackButtonMargins *2

        ColumnLayout {
            id: enableAccount

            width: preferredWidth
            spacing: 15

            Text {
                id: enableAccountTitle

                Layout.alignment: Qt.AlignLeft
                Layout.preferredWidth: Math.min(350, root.width - JamiTheme.preferredMarginSize * 2)

                text: JamiStrings.enableAccount
                color: JamiTheme.textColor
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
                wrapMode : Text.WordWrap

                font.pixelSize: 22
                font.kerning: true

            }

            ToggleSwitch {
                id: accountEnableCheckBox

                Layout.alignment: Qt.AlignLeft
                Layout.preferredWidth: preferredWidth
                labelText: JamiStrings.enableAccountDescription

                widthOfSwitch: 60
                heightOfSwitch: 30

                checked: CurrentAccount.enabled
                onSwitchToggled: CurrentAccount.enableAccount(checked)
            }

        }

    }
}
