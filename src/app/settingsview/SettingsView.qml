/*
 * Copyright (C) 2019-2023 Savoir-faire Linux Inc.
 * Author: Yang Wang <yang.wang@savoirfairelinux.com>
 * Author: Aline Gondim Santos <aline.gondimsantos@savoirfairelinux.com>
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

import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Enums 1.1
import net.jami.Constants 1.1
import net.jami.Helpers 1.1

import "components"
import "../commoncomponents"

import "../mainview/js/contactpickercreation.js" as ContactPickerCreation

ListSelectionView {
    id: viewNode
    objectName: "SettingsView"

    enum SettingsMenu {
        ManageAccount,
        CustomizeProfile,
        LinkedDevices,
        AdvancedSettings,
        System,
        CallSettings,
        Appearence,
        LocationSharing,
        FileTransfer,
        CallRecording,
        Troubleshoot,
        Update,
        Audio,
        Video,
        Screensharing,
        Plugin
    }

    splitViewStateKey: "Main"
    inhibits: ["ConversationView"]

    leftPaneItem: viewCoordinator.getView("SettingsSidePanel")

    onDismissed: {
        // Trigger an update to messages if needed.
        // Currently needed when changing the show link preview setting.
        CurrentConversation.reloadInteractions()
        if (UtilsAdapter.getAccountListSize() === 0) {
            viewCoordinator.requestAppWindowWizardView()
        } else {
            AccountAdapter.changeAccount(0)
        }
    }


    onVisibleChanged: if(visible) setSelected(selectedMenu, true)

    property int selectedMenu: index

    onSelectedMenuChanged: {
        if (selectedMenu === SettingsView.ManageAccount) {
            //pageIdCurrentAccountSettings.updateAccountInfoDisplayed()
        } else if (selectedMenu === SettingsView.Media) {
            avSettings.populateAVSettings()
        }
    }

    rightPaneItem: StackLayout {
        id: settingsViewRect

        currentIndex: selectedMenu !== -1 ? selectedMenu : 0
        anchors.fill: parent

        signal stopBooth

        property bool isSIP: {
            switch (CurrentAccount.type) {
            case Profile.Type.SIP:
                return true;
            default:
                return false;
            }
        }

        ManageAccountPage {
            isSIP: settingsViewRect.isSIP
            onNavigateToMainView: dismiss()
            onNavigateToNewWizardView: dismiss()
        }

        CustomizeProfilePage {}

        LinkedDevicesPage {
            visible: !settingsViewRect.isSIP
        }

        AdvancedSettingsPage {}

        SystemSettingsPage {}

        CallSettingsPage {}

        AppearenceSettingsPage {}

        LocationSharingSettingsPage {}

        FileTransferSettingsPage{}

        CallRecordingSettingsPage {}

        TroubleshootSettingsPage {}

        UpdatesSettingsPage {
            visible: UpdateManager.isUpdaterEnabled()
        }

        AudioSettingsPage {}

        VideoSettingsPage {}

        ScreenSharingSettingsPage {}

        PluginSettingsPage {}
    }
}
