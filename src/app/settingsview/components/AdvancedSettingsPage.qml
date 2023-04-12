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
    property int itemWidth

    title: JamiStrings.advancedSettingsTitle

    signal showAdvancedSettingsRequest

    flickableContent: ColumnLayout {
        id: currentAccountEnableColumnLayout
        Layout.bottomMargin: JamiTheme.preferredSettingsContentMarginSize
        Layout.fillWidth: true
        anchors.left: parent.left
        anchors.leftMargin: JamiTheme.preferredSettingsMarginSize
        spacing: JamiTheme.settingsBlockSpacing
        width: contentFlickableWidth

        AdvancedSIPSecuritySettings {
            id: advancedSIPSecuritySettings
            itemWidth: 250
            visible: CurrentAccount.type === Profile.Type.SIP
            width: parent.width
        }
        AdvancedChatSettings {
            id: advancedChatSettings
            width: parent.width
        }
        AdvancedNameServerSettings {
            id: advancedNameServerSettings
            itemWidth: 250
            visible: CurrentAccount.type === Profile.Type.JAMI
            width: parent.width
        }
        AdvancedOpenDHTSettings {
            id: advancedOpenDHTSettings
            itemWidth: 250
            visible: CurrentAccount.type === Profile.Type.JAMI
            width: parent.width
        }
        AdvancedJamiSecuritySettings {
            id: advancedJamiSecuritySettings
            itemWidth: 250
            visible: CurrentAccount.type === Profile.Type.JAMI
            width: parent.width
        }
        AdvancedConnectivitySettings {
            id: advancedConnectivitySettings
            isSIP: CurrentAccount.type === Profile.Type.SIP
            itemWidth: 250
            width: parent.width
        }
        AdvancedPublicAddressSettings {
            id: advancedPublicAddressSettings
            itemWidth: 250
            visible: CurrentAccount.type === Profile.Type.SIP
            width: parent.width
        }
        AdvancedMediaSettings {
            id: advancedMediaSettings
            width: parent.width
        }
        AdvancedSDPSettings {
            id: advancedSDPStettings
            itemWidth: 250
            visible: CurrentAccount.type === Profile.Type.SIP
            width: parent.width
        }
    }
}
