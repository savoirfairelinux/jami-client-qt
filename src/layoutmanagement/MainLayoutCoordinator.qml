/*
 * Copyright (C) 2020 by Savoir-faire Linux
 * Author: Mingrui Zhang <mingrui.zhang@savoirfairelinux.com>
 * Author: Andreas Traczyk <andreas.traczyk@savoirfairelinux.com>
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

// MainLayoutCoordinator as a singleton is to provide global ui presentation management
// for main view
pragma Singleton

import QtQuick 2.14
import QtQuick.Controls 2.14
import net.jami.Adapters 1.0

import "../constant"

Item {
    id: root

    // map<name, obj>
    property var views: new Map()
    property bool initialized: false

    property var mainApplicationWindow: ""

    // MainView
    property bool inSettingsView: {
        if (initialized)
            return leftStackView.currentItem.objectName === "settingsMenu"
        return false
    }

    onInSettingsViewChanged: console.log(inSettingsView)
    property bool sidePanelOnly: {
        if (initialized)
            return (!rightStackView.visible) && leftStackView.visible
        return false
    }

    property var mainStackLayout: ""
    property var leftStackView: ""
    property var rightStackView: ""

    function registerMainLayout(mainStackLayout, leftStackView, rightStackView) {
        root.mainStackLayout = mainStackLayout
        root.leftStackView = leftStackView
        root.rightStackView = rightStackView

        initialized = true
    }

    function registerSettingsLayout(settingsViewStackLayout) {
        settingsLayoutCoordinator.registerLayout(settingsViewStackLayout)
    }

    function registerView(view, name, type = ViewBase.Type.Main) {
        if (JamiQmlUtils.isEmpty(view) || JamiQmlUtils.isEmpty(name)) {
            console.log("View registered failed")
            return
        }

        switch(type){
        case ViewBase.Type.Main:
            views.set(name, view)
            return
        case ViewBase.Type.Settings:
            settingsLayoutCoordinator.registerView(view, name)
            return
        case ViewBase.Type.Call:
            return
        }
    }

    function recursionStackViewItemMove(stackOne, stackTwo, depth=1) {
        // Move all items (expect the bottom item) to stacktwo by the same order in stackone.
        if (stackOne.depth === depth) {
            return
        }

        var tempItem = stackOne.pop(StackView.Immediate)
        recursionStackViewItemMove(stackOne, stackTwo, depth)
        stackTwo.push(tempItem, StackView.Immediate)
    }

    function isPageInStack(objectName, stackView) {
        var foundItem = stackView.find(function (item, index) {
            return item.objectName === objectName
        })

        return foundItem ? true : false
    }

    function pushCommunicationMessageWebView() {
        if (sidePanelOnly) {
            leftStackView.pop(StackView.Immediate)
            leftStackView.push(views.get("communicationPageMessageWebView"), StackView.Immediate)
        } else {
            rightStackView.pop(views.get("welcomePage"), StackView.Immediate)
            rightStackView.push(views.get("communicationPageMessageWebView"), StackView.Immediate)
        }
    }

    // Back to WelcomeView required, but can also check, i. e., on account switch or
    // settings exit, if there is need to switch to a current call
    function backToMainView(checkCurrentCall = false) {
        if (inSettingsView)
            return
        if (checkCurrentCall && UtilsAdapter.hasCall(AccountAdapter.currentAccountId)) {
            var callConv = UtilsAdapter.getCallConvForAccount(
                        AccountAdapter.currentAccountId)
            ConversationsAdapter.selectConversation(
                        AccountAdapter.currentAccountId, callConv)
        } else
            showWelcomeView()
    }

    function showWelcomeView() {
        views.get("callStackView").needToCloseInCallConversationAndPotentialWindow()
        views.get("mainViewSidePanel").deselectConversationSmartList()
        if (isPageInStack("callStackView", leftStackView) ||
                isPageInStack("communicationPageMessageWebView", leftStackView) ||
                isPageInStack("communicationPageMessageWebView", rightStackView) ||
                isPageInStack("callStackView", rightStackView)) {
            leftStackView.pop(StackView.Immediate)
            rightStackView.pop(views.get("welcomePage"), StackView.Immediate)
        }
        //recordBox.visible = false
    }

    function toggleSettingsView() {
        if (inSettingsView) {
            leftStackView.pop(StackView.Immediate)
            rightStackView.pop(StackView.Immediate)
            backToMainView(true)
        } else {
            if (sidePanelOnly)
                leftStackView.push(views.get("settingsMenu"), StackView.Immediate)
            else {
                rightStackView.pop(views.get("welcomePage"), StackView.Immediate)
                rightStackView.push(views.get("settingsView"), StackView.Immediate)
                leftStackView.push(views.get("settingsMenu"), StackView.Immediate)

                var windowCurrentMinimizedSize = JamiTheme.settingsViewPreferredWidth
                        + JamiTheme.sidePanelViewStackPreferredWidth + JamiTheme.onWidthChangedTriggerDistance
                if (mainApplicationWindow.width < windowCurrentMinimizedSize)
                    mainApplicationWindow.width = windowCurrentMinimizedSize
            }
        }
    }

    function mainViewWidthChanged(currentWidth) {
        // Hide unnecessary stackview when width is changed.
        var widthToCompare = JamiTheme.sidePanelViewStackPreferredWidth +
                (inSettingsView ? JamiTheme.settingsViewPreferredWidth : JamiTheme.mainViewStackPreferredWidth)

        if (currentWidth < widthToCompare - JamiTheme.onWidthChangedTriggerDistance
                && rightStackView.visible) {
            rightStackView.visible = false

            // The find callback function is called for each item in the stack.
            var inWelcomeViewStack = rightStackView.find(
                        function (item, index) {
                            return index > 0
                        })

            if (inSettingsView) {
                rightStackView.pop(StackView.Immediate)
                leftStackView.push(views.get("settingsView"), StackView.Immediate)
            }
            else if (inWelcomeViewStack)
                recursionStackViewItemMove(rightStackView, leftStackView)
        } else if (currentWidth >= widthToCompare + JamiTheme.onWidthChangedTriggerDistance
                   && !rightStackView.visible) {
            rightStackView.visible = true

            var inSidePanelViewStack = leftStackView.find(
                        function (item, index) {
                            return index > 0
                        })

            if (inSettingsView) {
                if (leftStackView.currentItem.objectName !== "settingsMenu")
                    leftStackView.pop(StackView.Immediate)
                rightStackView.push(views.get("settingsView"), StackView.Immediate)
            } else if (inSidePanelViewStack) {
                recursionStackViewItemMove(leftStackView, rightStackView)
                if (currentAccountIsCalling())
                    pushCallStackView()
            }
        }
    }

    Connections {
        target: AccountAdapter

        function onCurrentAccountIdChanged() {
            if (views.size === 0)
                return
            views.get("mainViewSidePanel").refreshAccountComboBox()
            if (MainLayoutCoordinator.inSettingsView) {
                //settingsView.accountListChanged()
                //settingsView.setSelected(settingsView.selectedMenu, true)
            } else {
                backToMainView(true)
            }
        }
    }

    objectName: "MainLayoutCoordinator"

    SettingsLayoutCoordinator {
        id: settingsLayoutCoordinator

        objectName: "SettingsLayoutCoordinator"
    }
}
