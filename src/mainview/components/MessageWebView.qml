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

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1

import "../../commoncomponents"
import "../js/pluginhandlerpickercreation.js" as PluginHandlerPickerCreation

Rectangle {
    id: root

    property string headerUserAliasLabelText: ""
    property string headerUserUserNameLabelText: ""

    property bool allMessagesLoaded

    signal needToHideConversationInCall
    signal messagesCleared
    signal messagesLoaded

    function focusChatView() {
        messageWebViewFooter.textInput.forceActiveFocus()
    }

    color: JamiTheme.primaryBackgroundColor

    ColumnLayout {
        anchors.fill: root

        spacing: 0

        MessageWebViewHeader {
            id: messageWebViewHeader

            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: true
            Layout.preferredHeight: JamiTheme.messageWebViewHeaderPreferredHeight
            Layout.maximumHeight: JamiTheme.messageWebViewHeaderPreferredHeight

            userAliasLabelText: headerUserAliasLabelText
            userUserNameLabelText: headerUserUserNameLabelText

            DropArea {
                anchors.fill: parent
                onDropped: messageWebViewFooter.setFilePathsToSend(drop.urls)
            }

            onBackClicked: {
                mainView.showWelcomeView()
            }

            onNeedToHideConversationInCall: {
                root.needToHideConversationInCall()
            }

            onPluginSelector: {
                // Create plugin handler picker - PLUGINS
                PluginHandlerPickerCreation.createPluginHandlerPickerObjects(
                            root, false)
                PluginHandlerPickerCreation.calculateCurrentGeo(root.width / 2,
                                                                root.height / 2)
                PluginHandlerPickerCreation.openPluginHandlerPicker()
            }
        }

        StackLayout {
            id: messageWebViewStack

            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.topMargin: JamiTheme.messageWebViewHairLineSize
            Layout.bottomMargin: JamiTheme.messageWebViewHairLineSize

            currentIndex: CurrentConversation.isRequest ||
                          CurrentConversation.needsSyncing

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                ListView {
                    id: chatView

                    topMargin: 12
                    bottomMargin: 6
                    spacing: 2
                    width: parent.width
                    implicitHeight: Math.min(contentHeight +
                                             topMargin + bottomMargin,
                                             parent.height)
                    anchors.bottom: parent.bottom
                    displayMarginBeginning: 256
                    displayMarginEnd: 256
                    boundsBehavior: Flickable.StopAtBounds
                    verticalLayoutDirection: ListView.TopToBottom
                    clip: true

                    ScrollBar.vertical: ScrollBar {}

                    model: MessagesAdapter.messageListModel

                    delegate: MessageDelegate {
                        function setSeq_(item, seq) {
                            item.seq = seq
                        }

                        function setSeq(item, seq) {
                            Qt.callLater(setSeq_, item, seq)
                        }

                        Component.onCompleted: {
                            if (isGenerated)
                                seq = MsgSeq.single
                            var pItem = chatView.itemAtIndex(index - 1)
                            var nItem = chatView.itemAtIndex(index + 1)
                            if (pItem !== null && nItem !== null) {
                                // added in between
                                if (pItem.isGenerated || author !== pItem.author) {
                                    seq = MsgSeq.single
                                } else if (!isGenerated) {
                                    seq = MsgSeq.last
                                    if (pItem.seq === MsgSeq.single) {
                                        pItem.seq = MsgSeq.first
                                    } else {
                                        pItem.seq = MsgSeq.middle
                                    }
                                }
                            } else if (pItem !== null) {
                                // added to end
                                if (pItem.isGenerated) {
                                    seq = MsgSeq.single
                                } else {
                                    if (author !== pItem.author) {
                                        seq = MsgSeq.single
                                    } else if (!isGenerated) {
                                        seq = MsgSeq.last
                                        if (pItem.seq === MsgSeq.single) {
                                            pItem.seq = MsgSeq.first
                                        } else {
                                            pItem.seq = MsgSeq.middle
                                        }
                                    }
                                }
                            } else if (nItem !== null) {
                                // added to beginning
                                if (nItem.isGenerated) {
                                    seq = MsgSeq.single
                                } else {
                                    if (author !== nItem.author) {
                                        seq = MsgSeq.single
                                    } else if (!isGenerated) {
                                        seq = MsgSeq.first
                                        if (nItem.seq === MsgSeq.single) {
                                            nItem.seq = MsgSeq.last
                                        } else {
                                            nItem.seq = MsgSeq.middle
                                        }
                                    }
                                }
                            }
                        }
                    }

                    function getDistanceToBottom() {
                        const scrollDiff = ScrollBar.vertical.position -
                                         (1.0 - ScrollBar.vertical.size)
                        return Math.abs(scrollDiff) * contentHeight
                    }

                    onAtYBeginningChanged: {
                        if (!atYBeginning ||
                                MessagesAdapter.msgRequestPending ||
                                CurrentConversation.allMessagesLoaded)
                            return
                        MessagesAdapter.loadMoreMessages()
                    }

                    onContentHeightChanged: {
                        if (atYEnd)
                            positionViewAtEnd()
                    }

                    Connections {
                        target: MessagesAdapter

                        function onNewInteraction() {
                            if (chatView.getDistanceToBottom() < 40)
                                Qt.callLater(chatView.positionViewAtEnd)
                            chatView.computeSequencing(chatView.count - 1)
                        }

                        function onInitialMessagesLoaded() {
                            Qt.callLater(chatView.positionViewAtEnd)
                        }

                        function onMoreMessagesLoaded(rowCount) {
                            Qt.callLater(chatView.positionViewAtIndex,
                                         chatView.count - rowCount,
                                         ListView.Beginning)
                        }
                    }

                    DropArea {
                        anchors.fill: parent
                        onDropped: messageWebViewFooter.setFilePathsToSend(drop.urls)
                    }
                }
            }

            InvitationView {
                id: invitationView

                Layout.fillWidth: true
                Layout.fillHeight: true
            }
        }

        ReadOnlyFooter {
            visible: CurrentConversation.readOnly
            Layout.fillWidth: true
        }

        MessageWebViewFooter {
            id: messageWebViewFooter

            visible: {
                if (CurrentConversation.needsSyncing || CurrentConversation.readOnly)
                    return false
                else if (CurrentConversation.isSwarm && CurrentConversation.isRequest)
                    return false
                return true
            }

            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: true
            Layout.preferredHeight: implicitHeight
            Layout.maximumHeight: JamiTheme.messageWebViewFooterMaximumHeight

            DropArea {
                anchors.fill: parent
                onDropped: messageWebViewFooter.setFilePathsToSend(drop.urls)
            }
        }
    }
}
