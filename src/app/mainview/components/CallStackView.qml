/*
 * Copyright (C) 2020-2024 Savoir-faire Linux Inc.
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

Item {
    id: root
    property alias chatViewContainer: ongoingCallPage.chatViewContainer
    property alias contentView: callStackMainView

    property var sipKeys: ["1", "2", "3", "A", "4", "5", "6", "B", "7", "8", "9", "C", "*", "0", "#", "D"]

    Shortcut {
        sequence: "Ctrl+D"
        context: Qt.ApplicationShortcut
        onActivated: CallAdapter.hangUpThisCall()
        onActivatedAmbiguously: CallAdapter.hangUpThisCall()
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
        ongoingCallPage.closeInCallConversation();
        ongoingCallPage.closeContextMenuAndRelatedWindows();
    }

    function toggleFullScreen() {
        if (!layoutManager.isCallFullscreen) {
            layoutManager.pushFullScreenItem(callStackMainView.currentItem, callStackMainView, null, null);
        } else {
            layoutManager.removeFullScreenItem(callStackMainView.currentItem);
        }
    }

    StackLayout {
        id: callStackMainView

        anchors.fill: parent

        property Item currentItem: itemAt(currentIndex)

        currentIndex: {
            switch (CurrentCall.status) {
            case Call.Status.IN_PROGRESS:
            case Call.Status.CONNECTED:
            case Call.Status.PAUSED:
                return 1;
            case Call.Status.SEARCHING:
            case Call.Status.CONNECTING:
            case Call.Status.INCOMING_RINGING:
            case Call.Status.OUTGOING_RINGING:
            default:
                return 0;
            }
        }

        InitialCallPage {
        }
        OngoingCallPage {
            id: ongoingCallPage
        }
    }
}
