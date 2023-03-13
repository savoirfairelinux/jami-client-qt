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

    property int contentWidth: currentAccountEnableColumnLayout.width
    property int preferredHeight: currentAccountEnableColumnLayout.implicitHeight
    property int preferredColumnWidth : Math.min(root.width / 2 - 50, 350)
    property bool isSIP

    signal navigateToMainView
    signal navigateToNewWizardView

    color: JamiTheme.secondaryBackgroundColor

    ColumnLayout {
        id: currentAccountEnableColumnLayout

        anchors.left: root.left
        anchors.leftMargin: JamiTheme.preferredMarginSize * 2

        width: Math.min(JamiTheme.maximumWidthSettingsView, root.width)
        spacing: 20
        Text {
            id: linkedDevicesTitle

            Layout.alignment: Qt.AlignLeft
            Layout.topMargin: JamiTheme.wizardViewPageBackButtonMargins
            Layout.preferredWidth: Math.min(350, root.width - JamiTheme.preferredMarginSize * 2)

            text: JamiStrings.linkedAccountList
            color: JamiTheme.textColor
            horizontalAlignment: Text.AlignLeft
            verticalAlignment: Text.AlignVCenter
            wrapMode : Text.WordWrap

            font.weight: Font.Medium
            font.pixelSize: 22
            font.kerning: true
        }

        Text {
            id: thisDeviceTitle

            Layout.alignment: Qt.AlignLeft
            Layout.topMargin: JamiTheme.wizardViewPageBackButtonMargins
            Layout.preferredWidth: Math.min(350, root.width - JamiTheme.preferredMarginSize * 2)

            text: JamiStrings.linkedThisDevice
            color: JamiTheme.textColor
            horizontalAlignment: Text.AlignLeft
            verticalAlignment: Text.AlignVCenter
            wrapMode : Text.WordWrap

            font.weight: Font.Medium
            font.pixelSize: 22
            font.kerning: true
        }

        DeviceItemDelegate {
            id: settingsListDelegate

            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: Math.min(350, root.width - JamiTheme.preferredMarginSize * 2)

            deviceName: CurrentAccount.id
            deviceId: CurrentAccount.uri
            isCurrent: true
        }

        Text {
            id: otherDevicesTitle

            Layout.alignment: Qt.AlignLeft
            Layout.topMargin: JamiTheme.wizardViewPageBackButtonMargins
            Layout.preferredWidth: Math.min(350, root.width - JamiTheme.preferredMarginSize * 2)

            text: JamiStrings.linkedOtherDevices
            color: JamiTheme.textColor
            horizontalAlignment: Text.AlignLeft
            verticalAlignment: Text.AlignVCenter
            wrapMode : Text.WordWrap

            font.weight: Font.Medium
            font.pixelSize: 22
            font.kerning: true
        }

        LinkedDevices {
            id: linkedDevices
            visible: !isSIP

            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            Layout.rightMargin: JamiTheme.preferredMarginSize
        }

    }
}
