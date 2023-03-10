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
import net.jami.Constants 1.1

import "components"
import "../commoncomponents"
import "../mainview/js/contactpickercreation.js" as ContactPickerCreation

BaseView {
    id: root
    objectName: "SettingsView"
    requiresIndex: true

    onDismissed: {
        settingsViewRect.stopBooth()
        if (UtilsAdapter.getAccountListSize() === 0) {
            viewCoordinator.requestAppWindowWizardView()
        } else {
            AccountAdapter.changeAccount(0)
        }
    }

    enum SettingsMenu {
        Account,
        General,
        Media,
        Plugin,
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
        PluginSettings

    }

    onVisibleChanged: if(visible) setSelected(selectedMenu, true)

    property int selectedMenu: SettingsView.Account
    onSelectedMenuChanged: {
        if (selectedMenu === SettingsView.Account) {
            pageIdCurrentAccountSettings.updateAccountInfoDisplayed()
        } else if (selectedMenu === SettingsView.Media) {
            avSettings.populateAVSettings()
        }
    }

    function setSelected(idx, recovery = false) {
        if (selectedMenu === idx && !recovery) return
        selectedMenu = idx
    }

    Rectangle {
        id: settingsViewRect

        anchors.fill: root
        anchors.leftMargin: JamiTheme.preferredMarginSize * 2


        color: JamiTheme.secondaryBackgroundColor

        signal stopBooth

        property bool isSIP: {
            switch (CurrentAccount.type) {
            case Profile.Type.SIP:
                return true;
            default:
                return false;
            }
        }

        SettingsHeader {
            id: settingsHeader

            anchors.top: settingsViewRect.top

            anchors.left: settingsViewRect.left


            height: JamiTheme.settingsHeaderpreferredHeight

            title: {
                switch(selectedMenu){
                case SettingsView.Account:
                    return JamiStrings.accountSettingsTitle

                case SettingsView.General:
                    return JamiStrings.generalSettingsTitle

                case SettingsView.Media:
                    return JamiStrings.avSettingsTitle

                case SettingsView.Plugin:
                    return JamiStrings.pluginSettingsTitle

                case SettingsView.CustomizeProfile:
                    return JamiStrings.customizeProfileSettingsTitle

                case SettingsView.ManageAccount:
                    return JamiStrings.manageAccountSettingsTitle

                case SettingsView.LinkedDevices:
                    return JamiStrings.linkedDevicesSettingsTitle

                case SettingsView.AdvancedSettings:
                    return JamiStrings.advancedSettingsTitle

                case SettingsView.System:
                    return JamiStrings.system

                case SettingsView.CallSettings:
                    return JamiStrings.callSettingsTitle

                case SettingsView.Appearence:
                    return JamiStrings.appearence

                case SettingsView.LocationSharing:
                    return JamiStrings.locationSharingLabel

                case SettingsView.FileTransfer:
                    return JamiStrings.fileTransfer

                case SettingsView.CallRecording:
                    return JamiStrings.callRecording

                case SettingsView.Troubleshoot:
                    return JamiStrings.troubleshootTitle

                case SettingsView.Update:
                    return JamiStrings.updatesTitle

                case SettingsView.Audio:
                    return JamiStrings.audio

                case SettingsView.Video:
                    return JamiStrings.video

                case SettingsView.Screensharing:
                    return  JamiStrings.screenSharing

                case SettingsView.PluginSettings:
                    return  JamiStrings.pluginSettingsTitle

                }
            }

            onBackArrowClicked: viewCoordinator.hideCurrentView()
        }

        JamiFlickable {
            id: settingsViewScrollView

            anchors.top: settingsHeader.bottom
            anchors.horizontalCenter: settingsViewRect.horizontalCenter

            height: settingsViewRect.height - settingsHeader.height*1.5
            width: settingsViewRect.width

            contentHeight: rightSettingsStackLayout.height

            StackLayout {
                id: rightSettingsStackLayout

                anchors.centerIn: parent


                width: settingsViewScrollView.width

                property int pageIdCurrentAccountSettingsPage: 0
                property int pageIdGeneralSettingsPage: 1
                property int pageIdAvSettingPage: 2
                property int pageIdPluginSettingsPage: 3
                property int pageIdManageAccountPage: 4
                property int pageIdCustomizeProfilePage: 5
                property int pageIdLinkedDevicesPage: 6
                property int pageIdAdvancedSettingsPage: 7
                property int pageIdSystemSettingsPage:8
                property int pageIdCallSettingsPage: 9
                property int pageIdAppearencePage:10
                property int pageIdLocationSharingPage:11
                property int pageIdFileTransferPage:12
                property int pageIdCallRecordingPage:13
                property int pageIdTroubleshootPage:14
                property int pageIdUpdatePage:15
                property int pageIdAudioPage:16
                property int pageIdVideoPage:17
                property int pageIdScreensharingPage:18
                //property int pageIdPluginSettingsPage:19



                currentIndex: {
                    switch(selectedMenu){
                    case SettingsView.Account:
                        return pageIdCurrentAccountSettingsPage

                    case SettingsView.General:
                        return pageIdGeneralSettingsPage

                    case SettingsView.Media:
                        return pageIdAvSettingPage

                    case SettingsView.Plugin:
                        return pageIdPluginSettingsPage

                    case SettingsView.CustomizeProfile:
                        return pageIdCustomizeProfilePage

                    case SettingsView.ManageAccount:
                        return pageIdManageAccountPage

                    case SettingsView.LinkedDevices:
                        return pageIdLinkedDevicesPage

                    case SettingsView.AdvancedSettings:
                        return pageIdAdvancedSettingsPage

                    case SettingsView.System:
                        return pageIdSystemSettingsPage

                    case SettingsView.CallSettings:
                        return pageIdCallSettingsPage

                    case SettingsView.Appearence:
                        return pageIdAppearencePage

                    case SettingsView.LocationSharing:
                        return pageIdFileTransferPage

                    case SettingsView.FileTransfer:
                        return pageIdFileTransferPage

                    case SettingsView.CallRecording:
                        return pageIdCallRecordingPage

                    case SettingsView.Troubleshoot:
                        return pageIdTroubleshootPage

                    case SettingsView.Update:
                        return pageIdUpdatePage

                    case SettingsView.Audio:
                        return pageIdAudioPage

                    case SettingsView.Video:
                        return pageIdVideoPage

                    case SettingsView.Screensharing:
                        return  pageIdScreensharingPage

                    case SettingsView.PluginSettings:
                        return  pageIdPluginSettingsPage

                    }

                }
            }

            Component.onCompleted: {
                // avoid binding loop
                height = Qt.binding(function (){
                    return Math.max(
                                rightSettingsStackLayout.itemAt(currentIndex).preferredHeight,
                                settingsViewScrollView.height)
                })
            }

            //current account setting scroll page, index 0

            CurrentAccountSettings {
                id: pageIdCurrentAccountSettings

                Layout.alignment: Qt.AlignCenter

                isSIP: settingsViewRect.isSIP

                onNavigateToMainView: dismiss()
                onNavigateToNewWizardView: dismiss()

                onAdvancedSettingsToggled: function (settingsVisible) {
                    if (settingsVisible)
                        settingsViewScrollView.contentY = getAdvancedSettingsScrollPosition()
                    else
                        settingsViewScrollView.contentY = 0
                }
            }

            // general setting page, index 1
            GeneralSettingsPage {
                id: generalSettings

                Layout.alignment: Qt.AlignCenter
            }

            // av setting page, index 2
            AvSettingPage {
                id: avSettings

                Layout.alignment: Qt.AlignCenter
            }

            // plugin setting page, index 3
            PluginSettingsPage {
                id: pluginSettings

                Layout.alignment: Qt.AlignCenter
            }

            ManageAccountPage {
                id: manageAccount
                Layout.alignment: Qt.AlignCenter
                isSIP: settingsViewRect.isSIP
                onNavigateToMainView: dismiss()
                onNavigateToNewWizardView: dismiss()
            }

            CustomizeProfilePage {
                id: customizeAccount
                Layout.alignment: Qt.AlignCenter

            }

            LinkedDevicesPage {
                id: linkedDevices
                Layout.alignment: Qt.AlignCenter

            }

            AdvancedSettingsPage {
                id: advancedSettings
                Layout.alignment: Qt.AlignCenter

            }

            SystemSettingsPage {
                id: systemSettings
                Layout.alignment: Qt.AlignCenter
            }
            CallSettingsPage {
                id: callSettings
                Layout.alignment: Qt.AlignCenter

            }

            ChatSettingsPage {
                id: chatSettings
                Layout.alignment: Qt.AlignCenter

            }
        }

    }
}
