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

SettingsPageBase {
    id: root

    property bool isSIP
    property int itemWidth
    signal showAdvancedSettingsRequest

    signal navigateToMainView
    signal navigateToNewWizardView

    title: JamiStrings.advancedSettingsTitle

    flickableContent: ColumnLayout {

        id: currentAccountEnableColumnLayout

        width: contentFlickableWidth
        spacing: JamiTheme.settingsBlockSpacing
        anchors.left: parent.left
        anchors.leftMargin: JamiTheme.preferredSettingsMarginSize

        ColumnLayout {

            width: parent.width
            spacing: JamiTheme.settingsBlockSpacing
            Layout.topMargin: JamiTheme.preferredSettingsContentMarginSize

            AdvancedSIPSecuritySettings {
                id: advancedSIPSecuritySettings

                Layout.fillWidth: true
                width: parent.width
                itemWidth: 250

                visible: LRCInstance.currentAccountType === Profile.Type.SIP
            }

            AdvancedNameServerSettings {
                id: advancedNameServerSettings

                Layout.fillWidth: true
                width: parent.width
                itemWidth: 250

                visible: LRCInstance.currentAccountType === Profile.Type.JAMI
            }

            AdvancedOpenDHTSettings {
                id: advancedOpenDHTSettings

                Layout.fillWidth: true
                width: parent.width
                itemWidth: 250

                visible: LRCInstance.currentAccountType === Profile.Type.JAMI
            }

            AdvancedJamiSecuritySettings {
                id: advancedJamiSecuritySettings

                Layout.fillWidth: true
                width: parent.width
                itemWidth: 250

                visible: LRCInstance.currentAccountType === Profile.Type.JAMI
            }

            AdvancedConnectivitySettings {
                id: advancedConnectivitySettings

                Layout.fillWidth: true
                width: parent.width
                itemWidth: 250

                isSIP: LRCInstance.currentAccountType === Profile.Type.SIP
            }

            AdvancedPublicAddressSettings {
                id: advancedPublicAddressSettings

                Layout.fillWidth: true
                width: parent.width
                itemWidth: 250

                visible: isSIP
            }

            AdvancedMediaSettings {
                id: advancedMediaSettings

                Layout.fillWidth: true
                width: parent.width
            }

            AdvancedSDPSettings {
                id: advancedSDPStettings
                itemWidth: 250

                Layout.fillWidth: true
                width: parent.width

                visible: LRCInstance.currentAccountType === Profile.Type.SIP
            }

            /* TO DO
            MaterialButton {
                id: defaultSettings

                TextMetrics{
                    id: defaultSettingsTextSize
                    font.weight: Font.Bold
                    font.pixelSize: JamiTheme.wizardViewButtonFontPixelSize
                    font.capitalization: Font.AllUppercase
                    text: defaultSettings.text
                }

                secondary: true

                text: JamiStrings.defaultSettings
                preferredWidth: defaultSettingsTextSize.width + 2*JamiTheme.buttontextWizzardPadding
                preferredHeight: JamiTheme.preferredButtonSettingsHeight
                Layout.bottomMargin: JamiTheme.preferredSettingsContentMarginSize

            }*/
        }



    }
}
