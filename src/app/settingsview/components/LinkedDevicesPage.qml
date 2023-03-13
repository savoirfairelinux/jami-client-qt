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

SettingsPageBase {
    id: root

    property bool isSIP

    signal navigateToMainView
    signal navigateToNewWizardView
    title: JamiStrings.linkedDevicesSettingsTitle


    flickableContent: ColumnLayout {
        id: currentAccountEnableColumnLayout

        width: contentFlickableWidth
        spacing: JamiTheme.wizardViewPageBackButtonMargins *2
        anchors.left: parent.left
        anchors.leftMargin: JamiTheme.preferredSettingsMarginSize

        Text {
            id: linkedDevicesTitle

            Layout.alignment: Qt.AlignLeft
            Layout.topMargin: JamiTheme.preferredSettingsContentMarginSize
            Layout.preferredWidth: parent.width

            text: JamiStrings.linkedAccountList
            color: JamiTheme.textColor
            horizontalAlignment: Text.AlignLeft
            verticalAlignment: Text.AlignVCenter
            wrapMode : Text.WordWrap

            font.pixelSize: JamiTheme.settingsDescriptionPixelSize
            font.kerning: true
        }

        Text {
            id: thisDeviceTitle

            Layout.alignment: Qt.AlignLeft
            Layout.preferredWidth: parent.width

            text: JamiStrings.linkedThisDevice
            color: JamiTheme.textColor
            horizontalAlignment: Text.AlignLeft
            verticalAlignment: Text.AlignVCenter
            wrapMode : Text.WordWrap

            font.weight: Font.Medium
            font.pixelSize: JamiTheme.settingsTitlePixelSize
            font.kerning: true
        }

        DeviceItemDelegate {
            id: settingsListDelegate

            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: parent.width

            deviceName: CurrentAccount.id
            deviceId: CurrentAccount.uri
            isCurrent: true
        }

        Text {
            id: otherDevicesTitle

            visible: !isSIP
            Layout.alignment: Qt.AlignLeft
            Layout.preferredWidth: parent.width

            text: JamiStrings.linkedOtherDevices
            color: JamiTheme.textColor
            horizontalAlignment: Text.AlignLeft
            verticalAlignment: Text.AlignVCenter
            wrapMode : Text.WordWrap

            font.weight: Font.Medium
            font.pixelSize: JamiTheme.settingsTitlePixelSize
            font.kerning: true
        }

        LinkedDevices {
            id: linkedDevices
            visible: !isSIP

            Layout.fillWidth: true
            Layout.preferredWidth: parent.width

            Layout.alignment: Qt.AlignLeft
        }

    }
}
