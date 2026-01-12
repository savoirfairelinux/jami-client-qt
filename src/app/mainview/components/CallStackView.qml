/*
 * Copyright (C) 2020-2026 Savoir-faire Linux Inc.
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

Item {
    id: root
    property var chatViewContainer: {
        if (callStackMainView.item instanceof OngoingCallPage)
            return callStackMainView.item.chatViewContainer;
        return undefined;
    }
    property alias contentView: callStackMainView

    property var sipKeys: ["1", "2", "3", "A", "4", "5", "6", "B", "7", "8", "9", "C", "*", "0", "#", "D"]

    Shortcut {
        sequence: "Ctrl+D"
        context: Qt.ApplicationShortcut
        onActivated: CallAdapter.endCall()
        onActivatedAmbiguously: CallAdapter.endCall()
    }

    Shortcut {
        sequence: "F11"
        context: Qt.ApplicationShortcut
        enabled: CurrentConversation.hasCall && !layoutManager.isWebFullscreen
        onActivated: toggleFullScreen();
    }

    Keys.onPressed: {
        if (LRCInstance.currentAccountType !== Profile.Type.SIP)
            return;
        var key = event.text.toUpperCase();
        if (sipKeys.find(function (item) {
                return item === key;
            })) {
            CallAdapter.sipInputPanelPlayDTMF(key);
        }
    }

    Connections {
            target: CallOverlayModel
            function onPttKeyPressed() {
                CallAdapter.muteAudioToggle();
            }
            function onPttKeyReleased() {
                CallAdapter.muteAudioToggle();
            }
    }

    // TODO: this should all be done by listening to
    // parent visibility change or parent `Component.onDestruction`
    function needToCloseInCallConversationAndPotentialWindow() {
        if (callStackMainView.item instanceof OngoingCallPage) {
            callStackMainView.item.closeInCallConversation();
            callStackMainView.item.closeContextMenuAndRelatedWindows();
        }
    }

    function toggleFullScreen() {
        if (!layoutManager.isCallFullscreen) {
            layoutManager.pushFullScreenItem(callStackMainView);
        } else {
            layoutManager.removeFullScreenItem(callStackMainView);
        }
    }

    Loader {
        id: callStackMainView
        objectName: "callViewLoader"

        anchors.fill: parent

        sourceComponent: {
            switch (CurrentCall.status) {
            case Call.Status.IN_PROGRESS:
            case Call.Status.CONNECTED:
            case Call.Status.PAUSED:
                return ongoingCallPageComponent;
            case Call.Status.SEARCHING:
            case Call.Status.CONNECTING:
            case Call.Status.INCOMING_RINGING:
            case Call.Status.OUTGOING_RINGING:
                return initialCallPageComponent;
            default:
                return null;
            }
        }

        Component {
            id: initialCallPageComponent
            InitialCallPage {}
        }

        Component {
            id: ongoingCallPageComponent
            OngoingCallPage {}
        }
    }
}
