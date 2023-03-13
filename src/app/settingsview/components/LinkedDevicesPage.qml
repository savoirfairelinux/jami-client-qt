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
        spacing: JamiTheme.settingsBlockSpacing
        anchors.left: parent.left
        anchors.leftMargin: JamiTheme.preferredSettingsMarginSize

        //spacing: JamiTheme.settingsCategorySpacing

        Text {
            id: linkedDevicesTitle

            Layout.alignment: Qt.AlignLeft
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
            font.pixelSize: JamiTheme.settingsDescriptionPixelSize
            font.kerning: true
        }

        DeviceItemDelegate {
            id: settingsListDelegate

            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: parent.width
            Layout.preferredHeight: 70

            deviceName: CurrentAccount.id
            deviceId: CurrentAccount.deviceId
            isCurrent: true
        }

        LinkedDevices {
            id: linkedDevices
            Layout.fillWidth: true
            Layout.preferredWidth: parent.width
            Layout.alignment: Qt.AlignHCenter
            Layout.bottomMargin: JamiTheme.preferredSettingsBottomMarginSize
        }
    }
}
