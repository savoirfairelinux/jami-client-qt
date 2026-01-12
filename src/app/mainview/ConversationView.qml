/*
 * Copyright (C) 2024-2026 Savoir-faire Linux Inc.
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
import Qt5Compat.GraphicalEffects
import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import "../commoncomponents"
import "components"

ListSelectionView {
    id: viewNode
    objectName: "ConversationView"
    managed: false

    splitViewStateKey: "Main"
    hasValidSelection: CurrentConversation.id !== ''

    visible: false
    onPresented: visible = true

    onDismissed: {
        callStackView.needToCloseInCallConversationAndPotentialWindow();
        LRCInstance.deselectConversation();
    }

    property string currentAccountId: CurrentAccount.id
    onCurrentAccountIdChanged: dismiss()

    color: JamiTheme.transparentColor

    leftPaneItem: viewCoordinator.getView("SidePanel", true)

    rightPaneItem: StackLayout {
        id: conversationStackLayout
        objectName: "ConversationLayout"

        currentIndex: CurrentConversation.hasCall ? 1 : 0

        anchors.fill: parent

        Item {
            id: chatViewContainer

            Layout.fillWidth: true
            Layout.fillHeight: true

            ChatView {
                id: chatView
                anchors.fill: parent

                // Use callStackView.chatViewContainer only when hasCall is true
                // and callStackView.chatViewContainer not null.
                // Because after a swarm call ends, callStackView.chatViewContainer might not be null
                // due to a lack of call state change signals for the swarm call.
                readonly property bool hasCall: CurrentConversation.hasCall
                readonly property var inCallChatContainer: hasCall ? callStackView.chatViewContainer : null

                // Parent the chat view to the call stack view when in call.
                parent: inCallChatContainer ? inCallChatContainer : chatViewContainer
                inCallView: parent === callStackView.chatViewContainer

                readonly property string currentConvId: CurrentConversation.id
                onCurrentConvIdChanged: {
                    Qt.callLater(function() {
                        if (CurrentConversation.hasCall) {
                            callStackView.contentView.forceActiveFocus();
                        } else {
                            focusChatView();
                        }
                    });
                }

                onDismiss: {
                    if (inCallView) {
                        callStackView.chatViewContainer.visible = false;
                        callStackView.contentView.forceActiveFocus();
                    } else {
                        viewNode.dismiss();
                    }
                }

                // Handle visibility change for the in-call chat only.
                onVisibleChanged: {
                    if (inCallView) {
                        if (visible) {
                            focusChatView();
                        } else {
                            callStackView.contentView.forceActiveFocus();
                        }
                    }
                }
            }
        }

        CallStackView {
            id: callStackView
            Layout.fillWidth: true
            Layout.fillHeight: true

            onVisibleChanged: {
                if (visible)
                    contentView.forceActiveFocus();
                else
                    chatView.focusChatView();
            }
        }
    }
}
