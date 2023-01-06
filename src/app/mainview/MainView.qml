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

    property bool sidePanelOnly: false//(!mainViewStack.visible) && sidePanelViewStack.visible
    property int previousWidth: width

    // To calculate tab bar bottom border hidden rect left margin.
    property int tabBarLeftMargin: 8
    property int tabButtonShrinkSize: 8
    property bool inSettingsView: viewCoordinator.inSettings

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
        viewCoordinator.present("WelcomePage")
        LRCInstance.deselectConversation()
    }

    function pushCallStackView() {
        viewCoordinator.present("CallStackView")
    }

    function pushCommunicationMessageWebView() {
        viewCoordinator.present("ChatView")
        viewCoordinator.currentView.focusChatView()
    }

    function pushNewSwarmPage() {
        viewCoordinator.present("NewSwarmPage")
    }

    function startWizard() {
        //mainViewStackLayout.currentIndex = 1
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
        console.warn("toggleSettingsView DEPRECATED")
    }

    function setMainView(convId) {
        var item = ConversationsAdapter.getConvInfoMap(convId)
        if (item.convId === undefined)
            return
        if (item.callStackViewShouldShow) {
//            if (inSettingsView) {
//                toggleSettingsView()
//            }
//            MessagesAdapter.setupChatView(item)
//            callStackView.setLinkedWebview(chatView)
//            callStackView.responsibleAccountId = LRCInstance.currentAccountId
//            callStackView.responsibleConvUid = convId
//            currentConvUID = convId

//            if (item.callState === Call.Status.IN_PROGRESS ||
//                    item.callState === Call.Status.PAUSED) {
//                CallAdapter.updateCall(convId, LRCInstance.currentAccountId)
//                callStackView.showOngoingCallPage()
//            } else {
//                callStackView.showInitialCallPage(item.callState, item.isAudioOnly)
//            }
            pushCallStackView()

        } else if (!inSettingsView) {
            pushCommunicationMessageWebView()
            MessagesAdapter.setupChatView(item)

//            if (currentConvUID !== convId) {
//                callStackView.needToCloseInCallConversationAndPotentialWindow()
//                MessagesAdapter.setupChatView(item)
//                pushCommunicationMessageWebView()
//                chatView.focusChatView()
//                currentConvUID = convId
//            } else if (isPageInStack("callStackViewObject", sidePanelViewStack)
//                       || isPageInStack("callStackViewObject", mainViewStack)) {
//                callStackView.needToCloseInCallConversationAndPotentialWindow()
//                pushCommunicationMessageWebView()
//                chatView.focusChatView()
//            }
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

    // Needed by ViewCoordinator.
    property alias splitView: splitView
    property alias sv1: sv1
    property alias sv2: sv2

    SplitView {
        id: splitView
        anchors.fill: parent

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

        StackView {
            id: sv1
            objectName: "sv1"

            SplitView.maximumWidth: splitView.width
            SplitView.minimumWidth: sidePanelViewStackCurrentWidth
            SplitView.preferredWidth: sidePanelViewStackCurrentWidth
            SplitView.fillHeight: true
        }

        StackView {
            id: sv2
            objectName: "sv2"

            SplitView.fillHeight: true
        }
    }

    onHeightChanged: JamiQmlUtils.updateMessageBarButtonsPoints()

    Component.onCompleted: {
        JamiQmlUtils.mainViewRectObj = mainView
    }

    Shortcut {
        sequence: "Ctrl+M"
        context: Qt.ApplicationShortcut
        onActivated: JamiQmlUtils.settingsPageRequested(SettingsView.Media)
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
        onActivated: UtilsAdapter.setAppValue(Settings.BaseZoom, 1.0)
    }

    Shortcut {
        sequence: "Ctrl+G"
        context: Qt.ApplicationShortcut
        onActivated: JamiQmlUtils.settingsPageRequested(SettingsView.General)
    }

    Shortcut {
        sequence: "Ctrl+I"
        context: Qt.ApplicationShortcut
        onActivated: JamiQmlUtils.settingsPageRequested(SettingsView.Account)
    }

    Shortcut {
        sequence: "Ctrl+P"
        context: Qt.ApplicationShortcut
        onActivated: JamiQmlUtils.settingsPageRequested(SettingsView.Plugin)
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
