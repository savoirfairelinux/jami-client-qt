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
    property int preferredWidth: Math.min(JamiTheme.maximumWidthSettingsView , root.width - JamiTheme.preferredMarginSize*4)
    property bool isSIP
    property int itemWidth
    signal showAdvancedSettingsRequest

    signal navigateToMainView
    signal navigateToNewWizardView

    color: JamiTheme.secondaryBackgroundColor

    ColumnLayout {

        id: currentAccountEnableColumnLayout
        anchors.left: root.left
        width: Math.min(JamiTheme.maximumWidthSettingsView, root.width)
        spacing: JamiTheme.wizardViewPageBackButtonMargins *2


        AdvancedSIPSecuritySettings {
            id: advancedSIPSecuritySettings

            Layout.fillWidth: true
            itemWidth: 250

            visible: LRCInstance.currentAccountType === Profile.Type.SIP
        }

        AdvancedNameServerSettings {
            id: advancedNameServerSettings

            Layout.fillWidth: true
            itemWidth: 250

            visible: LRCInstance.currentAccountType === Profile.Type.JAMI
        }

        AdvancedOpenDHTSettings {
            id: advancedOpenDHTSettings

            Layout.fillWidth: true
            itemWidth: 250

            visible: LRCInstance.currentAccountType === Profile.Type.JAMI
        }

        AdvancedJamiSecuritySettings {
            id: advancedJamiSecuritySettings

            Layout.fillWidth: true
            itemWidth: 250

            visible: LRCInstance.currentAccountType === Profile.Type.JAMI
        }

        AdvancedConnectivitySettings {
            id: advancedConnectivitySettings

            Layout.fillWidth: true
            itemWidth: 250

            isSIP: LRCInstance.currentAccountType === Profile.Type.SIP
        }

        AdvancedPublicAddressSettings {
            id: advancedPublicAddressSettings

            Layout.fillWidth: true
            itemWidth: 250

            visible: isSIP
        }

        AdvancedMediaSettings {
            id: advancedMediaSettings

            Layout.fillWidth: true
        }

        AdvancedSDPSettings {
            id: advancedSDPStettings
            itemWidth: 250

            Layout.fillWidth: true

            visible: LRCInstance.currentAccountType === Profile.Type.SIP
        }



    }
}
