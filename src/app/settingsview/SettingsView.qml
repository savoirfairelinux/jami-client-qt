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
    selectionFallback: true

    // A map of view names to file paths for QML files that define each view.
    property variant resources: {
        "ManageAccountPage": Qt.resolvedUrl("components/ManageAccountPage.qml"),
        "CustomizeProfilePage": Qt.resolvedUrl("components/CustomizeProfilePage.qml"),
        "LinkedDevicesPage": Qt.resolvedUrl("components/LinkedDevicesPage.qml"),
        "CallSettingsPage": Qt.resolvedUrl("components/CallSettingsPage.qml"),
        "AdvancedSettingsPage": Qt.resolvedUrl("components/AdvancedSettingsPage.qml"),
        "SystemSettingsPage": Qt.resolvedUrl("components/SystemSettingsPage.qml"),
        "AppearanceSettingsPage": Qt.resolvedUrl("components/AppearanceSettingsPage.qml"),
        "Chat": Qt.resolvedUrl("components/ChatSettingsPage.qml"),
        "LocationSharingSettingsPage": Qt.resolvedUrl("components/LocationSharingSettingsPage.qml"),
        "CallRecordingSettingsPage": Qt.resolvedUrl("components/CallRecordingSettingsPage.qml"),
        "TroubleshootSettingsPage": Qt.resolvedUrl("components/TroubleshootSettingsPage.qml"),
        "UpdateSettingsPage": Qt.resolvedUrl("components/UpdateSettingsPage.qml"),
        "AudioSettingsPage": Qt.resolvedUrl("components/AudioSettingsPage.qml"),
        "VideoSettingsPage": Qt.resolvedUrl("components/VideoSettingsPage.qml"),
        "ScreenSharingSettingsPage": Qt.resolvedUrl("components/ScreenSharingSettingsPage.qml"),
        "PluginSettingsPage": Qt.resolvedUrl("components/PluginSettingsPage.qml")
    }

    splitViewStateKey: "Main"
    inhibits: ["ConversationView"]

    leftPaneItem: viewCoordinator.getView("SettingsSidePanel")

    Component.onCompleted: {
        leftPaneItem.updateModel();
        leftPaneItem.currentIndex = rightPaneItem.currentIndex;
    }

    Connections {
        target: viewNode

        function onIsSinglePaneChanged() {
            leftPaneItem.isSinglePane = viewNode.isSinglePane;
        }
    }

    onDismissed: {
        // Trigger an update to messages if needed.
        // Currently needed when changing the show link preview setting.
        CurrentConversation.reloadInteractions();
        if (UtilsAdapter.getAccountListSize() === 0) {
            viewCoordinator.requestAppWindowWizardView();
        } else {
            AccountAdapter.changeAccount(0);
        }
    }

    property int selectedMenu: index

    rightPaneItem: StackView {
        id: settingsView
        objectName: "settingsView"

        property var currentIndex: selectedMenu !== -1 ? selectedMenu : 0
        anchors.fill: parent

        signal stopBooth

        initialItem: viewNode.resources["ManageAccountPage"]

        onCurrentIndexChanged: {
            switch (currentIndex) {
            default:
            case 0:
                replace(currentItem, viewNode.resources["ManageAccountPage"], StackView.Immediate);
                break;
            case 1:
                replace(currentItem, viewNode.resources["CustomizeProfilePage"], StackView.Immediate);
                break;
            case 2:
                replace(currentItem, viewNode.resources["LinkedDevicesPage"], StackView.Immediate);
                break;
            case 3:
                replace(currentItem, viewNode.resources["CallSettingsPage"], StackView.Immediate);
                break;
            case 4:
                replace(currentItem, viewNode.resources["AdvancedSettingsPage"], StackView.Immediate);
                break;
            case 5:
                replace(currentItem, viewNode.resources["SystemSettingsPage"], StackView.Immediate);
                break;
            case 6:
                replace(currentItem, viewNode.resources["AppearanceSettingsPage"], StackView.Immediate);
                break;
            case 7:
                replace(currentItem, viewNode.resources["Chat"], StackView.Immediate);
                break;
            case 8:
                replace(currentItem, viewNode.resources["LocationSharingSettingsPage"], StackView.Immediate);
                break;
            case 9:
                replace(currentItem, viewNode.resources["CallRecordingSettingsPage"], StackView.Immediate);
                break;
            case 10:
                replace(currentItem, viewNode.resources["TroubleshootSettingsPage"], StackView.Immediate);
                break;
            case 11:
                replace(currentItem, viewNode.resources["UpdateSettingsPage"], StackView.Immediate);
                break;
            case 12:
                replace(currentItem, viewNode.resources["AudioSettingsPage"], StackView.Immediate);
                break;
            case 13:
                replace(currentItem, viewNode.resources["VideoSettingsPage"], StackView.Immediate);
                break;
            case 14:
                replace(currentItem, viewNode.resources["ScreenSharingSettingsPage"], StackView.Immediate);
                break;
            case 15:
                replace(currentItem, viewNode.resources["PluginSettingsPage"], StackView.Immediate);
                break;
            }
        }
    }
}
