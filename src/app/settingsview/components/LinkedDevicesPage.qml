/*
 * Copyright (C) 2023 Savoir-faire Linux Inc.
 * Author: Fadi Shehadeh <fadi.shehadeh@savoirfairelinux.com>
 * Author: Franck Laurent <franck.laurent@savoirfairelinux.com>
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

    signal navigateToMainView
    signal navigateToNewWizardView
    title: JamiStrings.linkedDevicesSettingsTitle


    flickableContent: ColumnLayout {
        id: currentAccountEnableColumnLayout

        width: contentFlickableWidth
        spacing: JamiTheme.settingsBlockSpacing
        anchors.left: parent.left
        anchors.leftMargin: JamiTheme.preferredSettingsMarginSize

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

        ColumnLayout {
            id: linkedDevices

            width: parent.width
            spacing: JamiTheme.settingsCategorySpacing

            LinkedDevicesBase {
                id: thisDevice

                Layout.fillWidth: true
                Layout.preferredWidth: parent.width
                Layout.alignment: Qt.AlignHCenter
                title: JamiStrings.linkedThisDevice
            }

            LinkedDevicesBase {
                id: otherDevices

                Layout.fillWidth: true
                Layout.preferredWidth: parent.width
                Layout.alignment: Qt.AlignHCenter
                inverted: true
                isCurrent: false
                title: JamiStrings.linkedOtherDevices
            }
        }

        Text {
            id: linkedDevicesDescription

            Layout.alignment: Qt.AlignLeft
            Layout.preferredWidth: parent.width
            visible: (CurrentAccount.managerUri === "" && CurrentAccount.enabled)

            text: JamiStrings.linkedAccountDescription
            color: JamiTheme.textColor
            horizontalAlignment: Text.AlignLeft
            verticalAlignment: Text.AlignVCenter
            wrapMode : Text.WordWrap

            font.pixelSize: JamiTheme.settingsDescriptionPixelSize
            font.kerning: true
            lineHeight: JamiTheme.wizardViewTextLineHeight
        }

        MaterialButton {
            id: linkDevPushButton

            TextMetrics{
                id: linkDevPushButtonTextSize
                font.weight: Font.Bold
                font.pixelSize: JamiTheme.wizardViewButtonFontPixelSize
                text: linkDevPushButton.text
            }

            Layout.alignment: Qt.AlignLeft
            preferredWidth: linkDevPushButtonTextSize.width + 2*JamiTheme.buttontextWizzardPadding

            visible: CurrentAccount.managerUri === "" && CurrentAccount.enabled

            primary: true
            toolTipText: JamiStrings.tipLinkNewDevice
            text: JamiStrings.linkAnotherDevice

            onClicked: viewCoordinator.presentDialog(
                           appWindow,
                           "settingsview/components/LinkDeviceDialog.qml",
                           )
        }
    }
}
