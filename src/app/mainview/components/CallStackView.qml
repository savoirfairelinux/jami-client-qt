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

import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1

import "../../commoncomponents"

BaseView {
    id: root

    property Item chatViewContainer
    //property alias chatViewContainer: outgoingCallPage.chatViewContainer

    property var sipKeys: [
        "1", "2", "3", "A",
        "4", "5", "6", "B",
        "7", "8", "9", "C",
        "*", "0", "#", "D"
    ]

    Shortcut {
        sequence: "Ctrl+D"
        context: Qt.ApplicationShortcut
        onActivated: CallAdapter.hangUpThisCall()
        onActivatedAmbiguously: CallAdapter.hangUpThisCall()
    }

    Keys.onPressed: {
        if (LRCInstance.currentAccountType !== Profile.Type.SIP)
            return
        var key = event.text.toUpperCase()
        if(sipKeys.find(function (item) {
            return item === key
        })) {
            CallAdapter.sipInputPanelPlayDTMF(key)
        }
    }

//    // TODO: this should all be done by listening to
//    // parent visibility change or parent `Component.onDestruction`
//    function needToCloseInCallConversationAndPotentialWindow() {
//        // Close potential window, context menu releated windows.
//        ongoingCallPage.closeInCallConversation()
//        ongoingCallPage.closeContextMenuAndRelatedWindows()
//    }

    function setLinkedWebview(webViewId) {
        //ongoingCallPage.setLinkedWebview(webViewId)
    }

    function toggleFullScreen() {
        if (layoutManager.isCallFullscreen) {
            layoutManager.removeFullScreenItem(
                        callStackMainView.currentItem)
        } else {
            layoutManager.pushFullScreenItem(
                        callStackMainView.currentItem,
                        callStackMainView,
                        null,
                        null)
        }
    }

//    StackLayout {
//        id: callStackMainView

//        anchors.fill: parent

//        property Item currentItem: itemAt(currentIndex)

//        currentIndex: {
//            switch (CurrentCall.status) {
//            case Call.Status.IN_PROGRESS:
//            case Call.Status.CONNECTED:
//            case Call.Status.PAUSED:
//                return 1
//            case Call.Status.SEARCHING:
//            case Call.Status.CONNECTING:
//            case Call.Status.INCOMING_RINGING:
//            case Call.Status.OUTGOING_RINGING:
//            default:
//                return 0
//            }
//        }

//        InitialCallPage {}
//        OngoingCallPage {
//            id: outgoingCallPage
//        }
//    }

    Component {
        id: ongoingCallPageComp
        OngoingCallPage {}
    }

    Component {
        id: initialCallPageComp
        InitialCallPage {}
    }

    Connections {
        target: CurrentConversation
        function onHasCallChanged() {
            if (!CurrentConversation.hasCall) {
                callStackMainView.clear()
            }
        }
    }

    Connections {
        target: CurrentCall
        function onStatusChanged() {
            switch (CurrentCall.status) {
            case Call.Status.IN_PROGRESS:
            case Call.Status.CONNECTED:
            case Call.Status.PAUSED:
                callStackMainView.replace(ongoingCallPageComp, StackView.Immediate)
                return
            case Call.Status.SEARCHING:
            case Call.Status.CONNECTING:
            case Call.Status.INCOMING_RINGING:
            case Call.Status.OUTGOING_RINGING:
                callStackMainView.replace(initialCallPageComp, StackView.Immediate)
                return
            default:
                callStackMainView.clear()
                return
            }
        }
    }

    StackView {
        id: callStackMainView

        anchors.fill: parent

        initialItem: initialCallPageComp
    }
}
