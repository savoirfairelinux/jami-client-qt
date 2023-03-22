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

ListSelectionView {
    id: viewNode
    objectName: "SettingsView"

    enum SettingsMenu {
        Account,
        General,
        Media,
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

    selectionFallback: true
    property int selectedMenu: index
    onSelectedMenuChanged: {
        if (selectedMenu === SettingsView.Account) {
            pageIdCurrentAccountSettings.updateAccountInfoDisplayed()
        } else if (selectedMenu === SettingsView.Media) {
            avSettings.populateAVSettings()
        }
    }

    rightPaneItem: Rectangle {
        id: settingsViewRect

        anchors.fill: parent
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
            anchors.leftMargin: {
                var pageWidth = rightSettingsStackLayout.itemAt(
                            rightSettingsStackLayout.currentIndex).contentWidth
                return (settingsViewRect.width - pageWidth) / 2 + JamiTheme.preferredMarginSize
            }

            height: JamiTheme.settingsHeaderpreferredHeight

            title: {
                switch(selectedMenu){
                    default:
                    case SettingsView.Account:
                        return JamiStrings.accountSettingsTitle
                    case SettingsView.General:
                        return JamiStrings.generalSettingsTitle
                    case SettingsView.Media:
                        return JamiStrings.avSettingsTitle
                    case SettingsView.Plugin:
                        return JamiStrings.pluginSettingsTitle
                }
            }

            onBackArrowClicked: viewNode.dismiss()
        }

        JamiFlickable {
            id: settingsViewScrollView

            anchors.top: settingsHeader.bottom
            anchors.horizontalCenter: settingsViewRect.horizontalCenter

            height: settingsViewRect.height - settingsHeader.height
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

                currentIndex: {
                    switch(selectedMenu){
                        default:
                        case SettingsView.Account:
                            return pageIdCurrentAccountSettingsPage
                        case SettingsView.General:
                            return pageIdGeneralSettingsPage
                        case SettingsView.Media:
                            return pageIdAvSettingPage
                        case SettingsView.Plugin:
                            return pageIdPluginSettingsPage
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

                // current account setting scroll page, index 0
                CurrentAccountSettings {
                    id: pageIdCurrentAccountSettings

                    Layout.alignment: Qt.AlignCenter

                    isSIP: settingsViewRect.isSIP

                    onNavigateToMainView: dismiss()
                    Connections {
                        target: LRCInstance

                        function onAccountListChanged() {
                            if (!UtilsAdapter.getAccountListSize()) {
                                viewCoordinator.requestAppWindowWizardView()
                            }
                        }
                    }

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
            }
        }
    }
}
