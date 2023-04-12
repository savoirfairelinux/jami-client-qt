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
    title: JamiStrings.linkedDevicesSettingsTitle

    flickableContent: ColumnLayout {
        id: currentAccountEnableColumnLayout
        anchors.left: parent.left
        anchors.leftMargin: JamiTheme.preferredSettingsMarginSize
        spacing: JamiTheme.settingsBlockSpacing
        width: contentFlickableWidth

        Text {
            id: linkedDevicesTitle
            Layout.alignment: Qt.AlignLeft
            Layout.preferredWidth: parent.width
            color: JamiTheme.textColor
            font.kerning: true
            font.pixelSize: JamiTheme.settingsDescriptionPixelSize
            horizontalAlignment: Text.AlignLeft
            text: JamiStrings.linkedAccountList
            verticalAlignment: Text.AlignVCenter
            wrapMode: Text.WordWrap
        }
        ColumnLayout {
            id: linkedDevices
            spacing: JamiTheme.settingsCategorySpacing
            width: parent.width

            LinkedDevicesBase {
                id: thisDevice
                Layout.alignment: Qt.AlignHCenter
                Layout.fillWidth: true
                Layout.preferredWidth: parent.width
                title: JamiStrings.linkedThisDevice
            }
            LinkedDevicesBase {
                id: otherDevices
                Layout.alignment: Qt.AlignHCenter
                Layout.fillWidth: true
                Layout.preferredWidth: parent.width
                inverted: true
                isCurrent: false
                title: JamiStrings.linkedOtherDevices
            }
        }
        Text {
            id: linkedDevicesDescription
            Layout.alignment: Qt.AlignLeft
            Layout.preferredWidth: parent.width
            color: JamiTheme.textColor
            font.kerning: true
            font.pixelSize: JamiTheme.settingsDescriptionPixelSize
            horizontalAlignment: Text.AlignLeft
            lineHeight: JamiTheme.wizardViewTextLineHeight
            text: JamiStrings.linkedAccountDescription
            verticalAlignment: Text.AlignVCenter
            visible: (CurrentAccount.managerUri === "" && CurrentAccount.enabled)
            wrapMode: Text.WordWrap
        }
        MaterialButton {
            id: linkDevPushButton
            Layout.alignment: Qt.AlignLeft
            preferredWidth: linkDevPushButtonTextSize.width + 2 * JamiTheme.buttontextWizzardPadding
            primary: true
            text: JamiStrings.linkAnotherDevice
            toolTipText: JamiStrings.tipLinkNewDevice
            visible: CurrentAccount.managerUri === "" && CurrentAccount.enabled

            onClicked: viewCoordinator.presentDialog(appWindow, "settingsview/components/LinkDeviceDialog.qml")

            TextMetrics {
                id: linkDevPushButtonTextSize
                font.pixelSize: JamiTheme.wizardViewButtonFontPixelSize
                font.weight: Font.Bold
                text: linkDevPushButton.text
            }
        }
    }
}
