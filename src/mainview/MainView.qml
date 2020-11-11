/*
 * Copyright (C) 2020 by Savoir-faire Linux
 * Author: Mingrui Zhang <mingrui.zhang@savoirfairelinux.com>
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
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

import QtQuick 2.14
import QtQuick.Window 2.14
import QtQuick.Controls 2.14
import QtQuick.Layouts 1.14
import QtQuick.Controls.Universal 2.14
import QtGraphicalEffects 1.14
import net.jami.Models 1.0
import net.jami.Adapters 1.0

// Import qml component files.
import "components"
import "../"
import "../wizardview"
import "../settingsview"
import "../settingsview/components"
import "../layoutmanagement"

Rectangle {
    id: mainView

    objectName: "mainView"

    property var containerWindow: ""

    signal loaderSourceChangeRequested(int sourceToLoad)

    function currentAccountIsCalling() {
        return UtilsAdapter.hasCall(AccountAdapter.currentAccountId)
    }

    AccountListModel {
        id: accountListModel
    }

    SettingsMenu {
        id: settingsMenu

        objectName: "settingsMenu"

        visible: false
    }

    SidePanel {
        id: mainViewSidePanel

        objectName: "mainViewSidePanel"
    }

    CallStackView {
        id: callStackView

        objectName: "callStackView"

        visible: false
    }

    WelcomePage {
        id: welcomePage

        objectName: "welcomePage"

        visible: false
    }

    SettingsView {
        id: settingsView

        objectName: "settingsView"

        visible: false
    }

    MessageWebView {
        id: communicationPageMessageWebView

        objectName: "communicationPageMessageWebView"

        visible: false
        Component.onCompleted: {
            // Set qml MessageWebView object pointer to c++.
            MessagesAdapter.setQmlObject(this)
        }
    }

    onWidthChanged: {
        if (MainLayoutCoordinator.initialized)
            MainLayoutCoordinator.mainViewWidthChanged(mainView.width)
    }

    AboutPopUp {
        id: aboutPopUpDialog

        height: Math.min(preferredHeight,
                         mainView.height - JamiTheme.preferredMarginSize * 2)
    }

    WelcomePageQrDialog {
        id: qrDialog
    }

    RecordBox{
        id: recordBox
        visible: false
    }

    UserProfile {
        id: userProfile
    }

    Shortcut {
        sequence: "Ctrl+M"
        context: Qt.ApplicationShortcut
        onActivated: {
            if (!inSettingsView) {
                MainLayoutCoordinator.toggleSettingsView()
            }
            settingsMenu.btnMediaSettings.clicked()
        }
    }

    Shortcut {
        sequence: "Ctrl+G"
        context: Qt.ApplicationShortcut
        onActivated: {
            if (!inSettingsView) {
                MainLayoutCoordinator.toggleSettingsView()
            }
            settingsMenu.btnGeneralSettings.clicked()
        }
    }

    Shortcut {
        sequence: "Ctrl+I"
        context: Qt.ApplicationShortcut
        onActivated: {
            if (!inSettingsView) {
                MainLayoutCoordinator.toggleSettingsView()
            }
            settingsMenu.btnAccountSettings.clicked()
        }
    }

    Shortcut {
        sequence: "Ctrl+P"
        context: Qt.ApplicationShortcut
        onActivated: {
            if (!inSettingsView) {
                MainLayoutCoordinator.toggleSettingsView()
            }
            settingsMenu.btnPluginSettings.clicked()
        }
    }

    Shortcut {
        sequence: "F10"
        context: Qt.ApplicationShortcut
        onActivated: {
            shortcutsTable.open()
        }
    }

    Shortcut {
        sequence: "F11"
        context: Qt.ApplicationShortcut
        onActivated: {
            if (containerWindow.visibility !== Window.FullScreen)
                containerWindow.visibility = Window.FullScreen
            else
                containerWindow.visibility = Window.Windowed
        }
    }

    Shortcut {
        sequence: "Ctrl+D"
        context: Qt.ApplicationShortcut
        onActivated: CallAdapter.hangUpThisCall()
        onActivatedAmbiguously: CallAdapter.hangUpThisCall()
    }

    Shortcut {
        sequence: "Ctrl+Shift+A"
        context: Qt.ApplicationShortcut
        onActivated: {
            UtilsAdapter.makePermanentCurrentConv()
            communicationPageMessageWebView.setSendContactRequestButtonVisible(false)
        }
    }

    Shortcut {
        sequence: "Ctrl+Shift+N"
        context: Qt.ApplicationShortcut
        onActivated: startWizard()
    }

    KeyBoardShortcutTable {
        id: shortcutsTable
    }

    StackLayout {
        id: mainViewStackLayout

        anchors.fill: parent

        currentIndex: 0

        SplitView {
            id: splitView

            Layout.fillWidth: true
            Layout.fillHeight: true

            width: mainView.width
            height: mainView.height

            handle: Rectangle {
                implicitWidth: JamiTheme.splitViewHandlePreferredWidth
                implicitHeight: splitView.height
                color:"white"
                Rectangle {
                    implicitWidth: 1
                    implicitHeight: splitView.height
                    color: SplitHandle.pressed ? JamiTheme.pressColor :
                                                 (SplitHandle.hovered ? JamiTheme.hoverColor :
                                                                        JamiTheme.tabbarBorderColor)
                }
            }

            Rectangle {
                id: mainViewSidePanelRect

                SplitView.minimumWidth: JamiTheme.sidePanelViewStackPreferredWidth
                SplitView.maximumWidth: (MainLayoutCoordinator.sidePanelOnly ? splitView.width :
                                                      splitView.width - JamiTheme.sidePanelViewStackPreferredWidth)
                SplitView.fillHeight: true

                // AccountComboBox is always visible
                AccountComboBox {
                    id: accountComboBox

                    anchors.top: mainViewSidePanelRect.top
                    width: mainViewSidePanelRect.width
                    height: 64

                    visible: (mainViewSidePanel.visible || settingsMenu.visible)

                    currentIndex: 0

                    Connections {
                        target: AccountAdapter

                        function onUpdateConversationForAddedContact() {
                            MessagesAdapter.updateConversationForAddedContact()
                            mainViewSidePanel.clearContactSearchBar()
                            mainViewSidePanel.forceReselectConversationSmartListCurrentIndex()
                        }

                        function onAccountStatusChanged(accountId) {
                            accountComboBox.resetAccountListModel(accountId)
                        }
                    }

                    onSettingBtnClicked: {
                        MainLayoutCoordinator.toggleSettingsView()
                    }

                    Component.onCompleted: {
                        AccountAdapter.setQmlObject(this)
                    }
                }

                StackView {
                    id: sidePanelViewStack

                    initialItem: mainViewSidePanel

                    anchors.top: accountComboBox.visible ? accountComboBox.bottom :
                                                           mainViewSidePanelRect.top
                    width: mainViewSidePanelRect.width
                    height: accountComboBox.visible ? mainViewSidePanelRect.height - accountComboBox.height :
                                                      mainViewSidePanelRect.height

                    clip: true
                }
            }

            StackView {
                id: mainViewStack

                initialItem: welcomePage

                SplitView.maximumWidth: MainLayoutCoordinator.sidePanelOnly ?
                                            splitView.width :
                                            splitView.width - JamiTheme.sidePanelViewStackPreferredWidth
                SplitView.minimumWidth: JamiTheme.sidePanelViewStackPreferredWidth
                SplitView.fillHeight: true

                clip: true
            }
        }

        WizardView {
            id: wizardView

            Layout.fillWidth: true
            Layout.fillHeight: true

            onLoaderSourceChangeRequested: {
                mainViewStackLayout.currentIndex = 0
                MainLayoutCoordinator.backToMainView()
            }

            onWizardViewIsClosed: {
                mainViewStackLayout.currentIndex = 0
                MainLayoutCoordinator.backToMainView()
            }
        }
    }

    Component.onCompleted: {
        MainLayoutCoordinator.registerMainLayout(
                    mainViewStackLayout, sidePanelViewStack, mainViewStack)
    }
}
