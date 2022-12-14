/*
 * Copyright (C) 2020-2022 Savoir-faire Linux Inc.
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

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import net.jami.Enums 1.1
import net.jami.Models 1.1

// Import qml component files.
import "components"
import "../"
import "../wizardview"
import "../settingsview"
import "../settingsview/components"

import "js/keyboardshortcuttablecreation.js" as KeyboardShortcutTableCreation

Rectangle {
    id: mainView

    objectName: "mainView"

    property int sidePanelViewStackCurrentWidth: 300
    property int mainViewStackPreferredWidth: sidePanelViewStackCurrentWidth + JamiTheme.chatViewHeaderMinimumWidth
    property int settingsViewPreferredWidth: 460
    property int onWidthChangedTriggerDistance: 5
    property int lastSideBarSplitSize: sidePanelViewStackCurrentWidth

    property bool sidePanelOnly: (!mainViewStack.visible) && sidePanelViewStack.visible
    property int previousWidth: width

    // To calculate tab bar bottom border hidden rect left margin.
    property int tabBarLeftMargin: 8
    property int tabButtonShrinkSize: 8
    property bool inSettingsView: false

    // For updating msgWebView
    property string currentConvUID: ""

    signal loaderSourceChangeRequested(int sourceToLoad)

    property string currentAccountId: LRCInstance.currentAccountId
    onCurrentAccountIdChanged: {
        if (inSettingsView) {
            settingsView.setSelected(settingsView.selectedMenu, true)
        } else {
            backToMainView(true)
        }
    }

    function isPageInStack(objectName, stackView) {
        var foundItem = stackView.find(function (item, index) {
            return item.objectName === objectName
        })

        return foundItem ? true : false
    }

    function showWelcomeView() {
        currentConvUID = ""
        callStackView.needToCloseInCallConversationAndPotentialWindow()
        LRCInstance.deselectConversation()
        if (isPageInStack("callStackViewObject", sidePanelViewStack) ||
                isPageInStack("chatView", sidePanelViewStack) ||
                isPageInStack("chatView", mainViewStack) ||
                isPageInStack("newSwarmPage", sidePanelViewStack) ||
                isPageInStack("newSwarmPage", mainViewStack) ||
                isPageInStack("callStackViewObject", mainViewStack)) {
            sidePanelViewStack.pop(StackView.Immediate)
            mainViewStack.pop(welcomePage, StackView.Immediate)
        }
    }

    function pushCallStackView() {
        if (sidePanelOnly) {
            sidePanelViewStack.pop(StackView.Immediate)
            sidePanelViewStack.push(callStackView, StackView.Immediate)
        } else {
            sidePanelViewStack.pop(StackView.Immediate)
            mainViewStack.pop(welcomePage, StackView.Immediate)
            mainViewStack.push(callStackView, StackView.Immediate)
        }
    }

    function pushCommunicationMessageWebView() {
        if (sidePanelOnly) {
            sidePanelViewStack.pop(StackView.Immediate)
            sidePanelViewStack.push(chatView, StackView.Immediate)
        } else {
            mainViewStack.pop(welcomePage, StackView.Immediate)
            mainViewStack.push(chatView, StackView.Immediate)
        }
    }

    function pushNewSwarmPage() {
        if (sidePanelOnly) {
            sidePanelViewStack.pop(StackView.Immediate)
            sidePanelViewStack.push(newSwarmPage, StackView.Immediate)
        } else {
            mainViewStack.pop(welcomePage, StackView.Immediate)
            mainViewStack.push(newSwarmPage, StackView.Immediate)
        }
    }

    function startWizard() {
        mainViewStackLayout.currentIndex = 1
    }

    function currentAccountIsCalling() {
        return UtilsAdapter.hasCall(LRCInstance.currentAccountId)
    }

    // Only called onWidthChanged
    function recursionStackViewItemMove(stackOne, stackTwo, depth=1) {
        // Move all items (expect the bottom item) to stacktwo by the same order in stackone.
        if (stackOne.depth === depth) {
            return
        }

        var tempItem = stackOne.pop(StackView.Immediate)
        recursionStackViewItemMove(stackOne, stackTwo, depth)
        stackTwo.push(tempItem, StackView.Immediate)
    }

    // Back to WelcomeView required, but can also check, i. e., on account switch or
    // settings exit, if there is need to switch to a current call
    function backToMainView(checkCurrentCall = false) {
        if (inSettingsView)
            return
        if (checkCurrentCall && currentAccountIsCalling()) {
            var callConv = UtilsAdapter.getCallConvForAccount(
                        LRCInstance.currentAccountId)
            LRCInstance.selectConversation(callConv, currentAccountId)
            CallAdapter.updateCall(callConv, currentAccountId)
        } else {
            showWelcomeView()
        }
    }

    function toggleSettingsView() {
        inSettingsView = !inSettingsView

        if (inSettingsView) {
            if (sidePanelOnly)
                sidePanelViewStack.push(settingsMenu, StackView.Immediate)
            else {
                mainViewStack.pop(welcomePage, StackView.Immediate)
                mainViewStack.push(settingsView, StackView.Immediate)
                sidePanelViewStack.push(settingsMenu, StackView.Immediate)
            }
        } else {
            sidePanelViewStack.pop(StackView.Immediate)
            mainViewStack.pop(StackView.Immediate)
            backToMainView(true)
        }
    }

    function setMainView(convId) {
        var item = ConversationsAdapter.getConvInfoMap(convId)
        if (item.convId === undefined)
            return
        if (item.callStackViewShouldShow) {
            if (inSettingsView) {
                toggleSettingsView()
            }
            MessagesAdapter.setupChatView(item)
            callStackView.setLinkedWebview(chatView)
            callStackView.responsibleAccountId = LRCInstance.currentAccountId
            callStackView.responsibleConvUid = convId
            currentConvUID = convId

            if (item.callState === Call.Status.IN_PROGRESS ||
                    item.callState === Call.Status.PAUSED) {
                CallAdapter.updateCall(convId, LRCInstance.currentAccountId)
                callStackView.showOngoingCallPage()
            } else {
                callStackView.showInitialCallPage(item.callState, item.isAudioOnly)
            }
            pushCallStackView()

        } else if (!inSettingsView) {
            if (currentConvUID !== convId) {
                callStackView.needToCloseInCallConversationAndPotentialWindow()
                MessagesAdapter.setupChatView(item)
                pushCommunicationMessageWebView()
                chatView.focusChatView()
                currentConvUID = convId
            } else if (isPageInStack("callStackViewObject", sidePanelViewStack)
                       || isPageInStack("callStackViewObject", mainViewStack)) {
                callStackView.needToCloseInCallConversationAndPotentialWindow()
                pushCommunicationMessageWebView()
                chatView.focusChatView()
            }
        }
    }

    color: JamiTheme.backgroundColor

    Connections {
        target: LRCInstance

        function onSelectedConvUidChanged() {
            mainView.setMainView(LRCInstance.selectedConvUid)
        }

        function onConversationUpdated(convUid, accountId) {
            if (convUid === LRCInstance.selectedConvUid &&
                    accountId === currentAccountId)
                mainView.setMainView(convUid)
        }
    }

    Connections {
        target: WizardViewStepModel

        function onCloseWizardView() {
            mainViewStackLayout.currentIndex = 0
            backToMainView()
        }
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
                color: JamiTheme.primaryBackgroundColor
                Rectangle {
                    implicitWidth: 1
                    implicitHeight: splitView.height
                    color: JamiTheme.tabbarBorderColor
                }
            }

            Rectangle {
                id: mainViewSidePanelRect

                SplitView.maximumWidth: splitView.width
                SplitView.minimumWidth: sidePanelViewStackCurrentWidth
                SplitView.preferredWidth: sidePanelViewStackCurrentWidth
                SplitView.fillHeight: true
                color: JamiTheme.backgroundColor

                // AccountComboBox is not a ComboBox
                AccountComboBox {
                    id: accountComboBox

                    anchors.top: mainViewSidePanelRect.top
                    width: mainViewSidePanelRect.width
                    height: JamiTheme.accountListItemHeight

                    visible: (mainViewSidePanel.visible || settingsMenu.visible)

                    onSettingBtnClicked: {
                        toggleSettingsView()
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

                SplitView.maximumWidth: splitView.width
                SplitView.minimumWidth: JamiTheme.chatViewHeaderMinimumWidth
                SplitView.preferredWidth: mainViewStackPreferredWidth
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
                backToMainView()
            }
        }
    }

    SettingsMenu {
        id: settingsMenu

        objectName: "settingsMenu"

        visible: false

        width: mainViewSidePanelRect.width
        height: mainViewSidePanelRect.height

        onItemSelected: function (index) {
            settingsView.setSelected(index)
            if (sidePanelOnly)
                sidePanelViewStack.push(settingsView, StackView.Immediate)
        }
    }

    SidePanel {
        id: mainViewSidePanel

        Connections {
            target: ConversationsAdapter

            function onNavigateToWelcomePageRequested() {
                backToMainView()
            }

        }

        onCreateSwarmClicked: {
            if (newSwarmPage.visible) {
                backToMainView()
                mainViewSidePanel.showSwarmListView(false)
            } else {
                pushNewSwarmPage()
            }
        }

        onHighlightedMembersChanged: {
            newSwarmPage.members = mainViewSidePanel.highlightedMembers
        }
    }

    CallStackView {
        id: callStackView

        visible: false
        objectName: "callStackViewObject"
    }

    WelcomePage {
        id: welcomePage

        visible: false
    }

    SettingsView {
        id: settingsView

        visible: false

        onSettingsViewNeedToShowMainView: {
            AccountAdapter.changeAccount(0)
            toggleSettingsView()
        }

        onSettingsViewNeedToShowNewWizardWindow: loaderSourceChangeRequested(
                                                     MainApplicationWindow.LoadedSource.WizardView)

        onSettingsBackArrowClicked: sidePanelViewStack.pop(StackView.Immediate)
    }

    ChatView {
        id: chatView

        objectName: "chatView"
        visible: false
        Component.onCompleted: {
            MessagesAdapter.setQmlObject(this)
            PositionManager.setQmlObject(this)
        }
    }

    NewSwarmPage {
        id: newSwarmPage

        objectName: "newSwarmPage"
        visible: false

        onVisibleChanged: {
            mainViewSidePanel.showSwarmListView(newSwarmPage.visible)
        }

        onRemoveMember: function(convId, member) {
            mainViewSidePanel.removeMember(convId, member)
        }

        onCreateSwarmClicked: function(title, description, avatar) {
            var uris = []
            for (var idx in newSwarmPage.members) {
                var uri = newSwarmPage.members[idx].uri
                if (uris.indexOf(uri) === -1) {
                    uris.push(uri)
                }
            }
            ConversationsAdapter.createSwarm(title, description, avatar, uris)
            backToMainView()
        }
    }

    onWidthChanged: {
        // Hide unnecessary stackview when width is changed.
        var isExpanding = previousWidth < mainView.width

        if (mainView.width < JamiTheme.chatViewHeaderMinimumWidth + mainViewSidePanelRect.width
                && mainViewStack.visible && !isExpanding) {
            lastSideBarSplitSize = mainViewSidePanelRect.width
            mainViewStack.visible = false

            // The find callback function is called for each item in the stack.
            var inWelcomeViewStack = mainViewStack.find(
                        function (item, index) {
                            return index > 0
                        })

            if (inSettingsView) {
                mainViewStack.pop(StackView.Immediate)
                sidePanelViewStack.push(settingsView, StackView.Immediate)
            }
            else if (inWelcomeViewStack)
                recursionStackViewItemMove(mainViewStack, sidePanelViewStack)
        } else if (mainView.width >= lastSideBarSplitSize + JamiTheme.chatViewHeaderMinimumWidth
                   && !mainViewStack.visible && isExpanding && !layoutManager.isFullScreen) {
            mainViewStack.visible = true

            var inSidePanelViewStack = sidePanelViewStack.find(
                        function (item, index) {
                            return index > 0
                        })

            if (inSettingsView) {
                if (sidePanelViewStack.currentItem.objectName !== settingsMenu.objectName)
                    sidePanelViewStack.pop(StackView.Immediate)
                mainViewStack.push(settingsView, StackView.Immediate)
            } else if (inSidePanelViewStack) {
                recursionStackViewItemMove(sidePanelViewStack, mainViewStack)
                if (currentAccountIsCalling())
                    pushCallStackView()
            }
        }

        previousWidth = mainView.width

        JamiQmlUtils.updateMessageBarButtonsPoints()
    }

    onHeightChanged: JamiQmlUtils.updateMessageBarButtonsPoints()

    Component.onCompleted: {
        JamiQmlUtils.mainViewRectObj = mainView
    }

    AboutPopUp {
        id: aboutPopUpDialog
        width: Math.min(mainView.width - 2 * JamiTheme.preferredMarginSize, JamiTheme.secondaryDialogDimension)
        height: Math.min(mainView.height - 2 * JamiTheme.preferredMarginSize, JamiTheme.secondaryDialogDimension)
    }

    WelcomePageQrDialog {
        id: qrDialog
    }

    UserProfile {
        id: userProfile
        width: Math.min(mainView.width - 2 * JamiTheme.preferredMarginSize, JamiTheme.secondaryDialogDimension)
        height: Math.min(mainView.height - 2 * JamiTheme.preferredMarginSize, JamiTheme.secondaryDialogDimension)
    }

    Shortcut {
        sequence: "Ctrl+M"
        context: Qt.ApplicationShortcut
        onActivated: {
            if (!inSettingsView) {
                toggleSettingsView()
            }
            settingsMenu.buttonSelectedManually(SettingsView.Media)
        }
    }

    WheelHandler {
        onWheel: (wheel)=> {
            if (wheel.modifiers & Qt.ControlModifier) {
                var delta = wheel.angleDelta.y / 120
                UtilsAdapter.setAppValue(Settings.BaseZoom, parseFloat(UtilsAdapter.getAppValue(Settings.BaseZoom)) + delta * 0.1)
            }
        }
    }

    Shortcut {
        sequence: "Ctrl++"
        context: Qt.ApplicationShortcut
        onActivated: {
            UtilsAdapter.setAppValue(Settings.BaseZoom, parseFloat(UtilsAdapter.getAppValue(Settings.BaseZoom)) + 0.1)
        }
    }

    Shortcut {
        sequence: "Ctrl+="
        context: Qt.ApplicationShortcut
        onActivated: {
            UtilsAdapter.setAppValue(Settings.BaseZoom, parseFloat(UtilsAdapter.getAppValue(Settings.BaseZoom)) + 0.1)
        }
    }

    Shortcut {
        sequence: "Ctrl+-"
        context: Qt.ApplicationShortcut
        onActivated: {
            UtilsAdapter.setAppValue(Settings.BaseZoom, parseFloat(UtilsAdapter.getAppValue(Settings.BaseZoom)) - 0.1)
        }
    }

    Shortcut {
        sequence: "Ctrl+_"
        context: Qt.ApplicationShortcut
        onActivated: {
            UtilsAdapter.setAppValue(Settings.BaseZoom, parseFloat(UtilsAdapter.getAppValue(Settings.BaseZoom)) - 0.1)
        }
    }

    Shortcut {
        sequence: "Ctrl+0"
        context: Qt.ApplicationShortcut
        onActivated: {
            UtilsAdapter.setAppValue(Settings.BaseZoom, 1.0)
        }
    }

    Shortcut {
        sequence: "Ctrl+G"
        context: Qt.ApplicationShortcut
        onActivated: {
            if (!inSettingsView) {
                toggleSettingsView()
            }
            settingsMenu.buttonSelectedManually(SettingsView.General)
        }
    }

    Shortcut {
        sequence: "Ctrl+I"
        context: Qt.ApplicationShortcut
        onActivated: {
            if (!inSettingsView) {
                toggleSettingsView()
            }
            settingsMenu.buttonSelectedManually(SettingsView.Account)
        }
    }

    Shortcut {
        sequence: "Ctrl+P"
        context: Qt.ApplicationShortcut
        onActivated: {
            if (!inSettingsView) {
                toggleSettingsView()
            }
            settingsMenu.buttonSelectedManually(SettingsView.Plugin)
        }
    }

    Shortcut {
        sequence: "F10"
        context: Qt.ApplicationShortcut
        onActivated: {
            KeyboardShortcutTableCreation.createKeyboardShortcutTableWindowObject(appWindow)
            KeyboardShortcutTableCreation.showKeyboardShortcutTableWindow()
        }
    }

    Shortcut {
        sequence: "F11"
        context: Qt.ApplicationShortcut
        onActivated: layoutManager.toggleWindowFullScreen()
    }

    Shortcut {
        sequence: "Escape"
        context: Qt.ApplicationShortcut
        onActivated: {
            MessagesAdapter.replyToId = ""
            MessagesAdapter.editId = ""
            layoutManager.popFullScreenItem()
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
        onActivated: LRCInstance.makeConversationPermanent()
    }

    Shortcut {
        sequence: "Ctrl+Shift+N"
        context: Qt.ApplicationShortcut
        onActivated: startWizard()
    }

    Shortcut {
        sequence: StandardKey.Quit
        context: Qt.ApplicationShortcut
        onActivated: Qt.quit()
    }
}
