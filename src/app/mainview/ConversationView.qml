/*
 * Copyright (C) 2023 Savoir-faire Linux Inc.
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

BaseView {
    id: root
    objectName: "ConversationView"
    managed: false

    onPresented: {
        if (!visible && viewCoordinator.singlePane &&
                CurrentConversation.id !== '') {
            viewCoordinator.present(objectName)
        }
    }

    onDismissed: {
        callStackView.needToCloseInCallConversationAndPotentialWindow()
        LRCInstance.deselectConversation()
    }

    property string currentAccountId: CurrentAccount.id
    onCurrentAccountIdChanged: dismiss()

    onVisibleChanged: {
        if (visible) return
        UtilsAdapter.clearInteractionsCache(CurrentAccount.id, CurrentConversation.id)
    }

    color: JamiTheme.transparentColor

    StackLayout {
        currentIndex: !CurrentConversation.hasCall ? 0 : 1
        onCurrentIndexChanged: chatView.parent = currentIndex == 1 ?
                                   callStackView.chatViewContainer :
                                   chatViewContainer

        anchors.fill: root

        Item {
            id: chatViewContainer

            Layout.fillWidth: true
            Layout.fillHeight: true

            ChatView {
                id: chatView
                anchors.fill: parent
                inCallView: parent == callStackView.chatViewContainer

                property string currentConvId: CurrentConversation.id
                onCurrentConvIdChanged: {
                    if (!CurrentConversation.hasCall) {
                        resetPanels()
                        Qt.callLater(focusChatView)
                    } else {
                        dismiss()
                        callStackView.contentView.forceActiveFocus()
                    }
                }

                onDismiss: {
                    if (parent == chatViewContainer) {
                        root.dismiss()
                    } else {
                        callStackView.chatViewContainer.visible = false
                        callStackView.contentView.forceActiveFocus()
                    }
                }

                onVisibleChanged: {
                    if (!inCallView)
                        return
                    if (visible && !parent.showDetails) {
                        focusChatView()
                    } else {
                        callStackView.contentView.forceActiveFocus()
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
                    contentView.forceActiveFocus()
                else
                    chatView.focusChatView()
            }
        }
    }
}
