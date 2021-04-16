/*
 * Copyright (C) 2021 by Savoir-faire Linux
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

import QtQuick 2.14
import QtQuick.Controls 2.14
import QtQuick.Layouts 1.14

import net.jami.Models 1.0
import net.jami.Adapters 1.0
import net.jami.Constants 1.0

ListView {
    id: root

    required model
    required delegate
    required property string headerLabel
    required property bool headerVisible

    opacity: count ? 1 :0
    visible: opacity
    clip: true
    maximumFlickVelocity: 1024
    ScrollIndicator.vertical: ScrollIndicator {}

    headerPositioning: ListView.OverlayHeader
    header: Rectangle {
        z: 2
        color: JamiTheme.backgroundColor
        visible: root.headerVisible
        width: root.width
        height: visible ? 24 : 0
        Text {
            anchors {
                left: parent.left
                leftMargin: 16
                verticalCenter: parent.verticalCenter
            }
            text: headerLabel + " (" + root.count + ")"
            font.pointSize: JamiTheme.smartlistItemFontSize
            font.weight: Font.DemiBold
            color: JamiTheme.textColor
        }
    }

    onCountChanged: positionViewAtBeginning()

    Component.onCompleted: {
        ConversationsAdapter.setQmlObject(this)
        currentIndex = -1
    }

    add: Transition {
        NumberAnimation { property: "opacity"; from: 0; to: 1.0; duration: 250 }
    }

    displaced: Transition {
        NumberAnimation { properties: "x,y"; duration: 250; easing.type: Easing.OutCubic }
    }

    move: Transition {
        NumberAnimation { properties: "x,y"; duration: 250; easing.type: Easing.OutCubic }
    }

    Behavior on Layout.preferredHeight {
        NumberAnimation { duration: 500; easing.type: Easing.OutCubic }
    }

    Behavior on opacity {
        NumberAnimation { duration: 500; easing.type: Easing.OutCubic }
    }

    ConversationSmartListContextMenu {
        id: smartListContextMenu
    }

    Shortcut {
        sequence: "Ctrl+Shift+X"
        context: Qt.ApplicationShortcut
        enabled: root.visible
        onActivated: {
            CallAdapter.placeCall()
            communicationPageMessageWebView.setSendContactRequestButtonVisible(false)
        }
    }

    Shortcut {
        sequence: "Ctrl+Shift+C"
        context: Qt.ApplicationShortcut
        enabled: root.visible
        onActivated: {
            CallAdapter.placeAudioOnlyCall()
            communicationPageMessageWebView.setSendContactRequestButtonVisible(false)
        }
    }

    Shortcut {
        sequence: "Ctrl+Shift+L"
        context: Qt.ApplicationShortcut
        enabled: root.visible
        onActivated: MessagesAdapter.clearConversationHistory(
                         AccountAdapter.currentAccountId,
                         UtilsAdapter.getCurrConvId())
    }

    Shortcut {
        sequence: "Ctrl+Shift+B"
        context: Qt.ApplicationShortcut
        enabled: root.visible
        onActivated: {
            MessagesAdapter.blockConversation(UtilsAdapter.getCurrConvId())
        }
    }

    Shortcut {
        sequence: "Ctrl+Shift+Delete"
        context: Qt.ApplicationShortcut
        enabled: root.visible
        onActivated: MessagesAdapter.removeConversation(
                         AccountAdapter.currentAccountId,
                         UtilsAdapter.getCurrConvId(),
                         false)
    }

    Shortcut {
        sequence: "Ctrl+Down"
        context: Qt.ApplicationShortcut
        enabled: root.visible
        onActivated: {
            if (currentIndex + 1 >= count)
                return
            root.currentIndex += 1
        }
    }

    Shortcut {
        sequence: "Ctrl+Up"
        context: Qt.ApplicationShortcut
        enabled: root.visible
        onActivated: {
            if (currentIndex <= 0)
                return
            root.currentIndex -= 1
        }
    }
}
