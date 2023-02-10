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
import QtQuick.Layouts

import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Enums 1.1
import net.jami.Constants 1.1
import net.jami.Helpers 1.1

import "../../commoncomponents"

Rectangle {
    id: root

    property int contentWidth: currentAccountEnableColumnLayout.width
    property int preferredHeight: currentAccountEnableColumnLayout.implicitHeight
    property int preferredColumnWidth : Math.min(root.width / 2 - 50, 350)

    signal navigateToMainView
    signal navigateToNewWizardView

    color: JamiTheme.secondaryBackgroundColor

    ColumnLayout {
        id: currentAccountEnableColumnLayout

        anchors.left: root.left
        anchors.leftMargin: JamiTheme.preferredMarginSize * 2

        width: Math.min(JamiTheme.maximumWidthSettingsView, root.width)

        Text {
            id: title

            Layout.alignment: Qt.AlignLeft
            Layout.topMargin: JamiTheme.wizardViewPageBackButtonMargins
            Layout.preferredWidth: Math.min(350, root.width - JamiTheme.preferredMarginSize * 2)

            text: JamiStrings.enableAccount
            color: JamiTheme.textColor
            horizontalAlignment: Text.AlignLeft
            verticalAlignment: Text.AlignVCenter
            wrapMode : Text.WordWrap

            font.weight: Font.Medium
            font.pixelSize: 15
            font.kerning: true
        }

        ToggleSwitch {
            id: accountEnableCheckBox

            Layout.topMargin: 10
            Layout.rightMargin: JamiTheme.preferredMarginSize
            Layout.alignment: Qt.AlignLeft

            widthOfSwitch: 60
            heightOfSwitch: 30

            checked: CurrentAccount.enabled
            onSwitchToggled: CurrentAccount.enableAccount(checked)
        }

        Text {
            id: description

            Layout.alignment: Qt.AlignLeft
            Layout.topMargin: 20
            Layout.preferredWidth: Math.min(450, root.width - JamiTheme.preferredMarginSize * 2)

            text: JamiStrings.enableAccountDescription
            color: JamiTheme.textColor
            horizontalAlignment: Text.AlignLeft
            verticalAlignment: Text.AlignVCenter
            wrapMode : Text.WordWrap

            font.pixelSize: 15
            font.kerning: true
        }

    }
}
