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
                    spacing: 4
                    width: parent.width
                    implicitHeight: Math.min(contentHeight,
                                             parent.height)
                    anchors.bottom: parent.bottom
                    displayMarginBeginning: 256
                    displayMarginEnd: 256
                    boundsBehavior: Flickable.StopAtBounds
                    verticalLayoutDirection: ListView.TopToBottom
                    clip: true

                    model: MessagesAdapter.messageListModel

                    delegate: MessageDelegate {}

                    ScrollBar.vertical: ScrollBar {}

                    function getDistanceToBottom() {
                        const scrollDiff = ScrollBar.vertical.position - (1.0 - ScrollBar.vertical.size)
                        return Math.abs(scrollDiff) * contentHeight
                    }

                    function computeTimestampVisibility(i) {
                        var t0, t1, t2
                        t1 = model.data(model.index(i, 0), MessageList.Timestamp)
                        if (i > 0)
                            t0 = model.data(model.index(i - 1, 0), MessageList.Timestamp)
                        if (i < model.rowCount())
                            t2 = model.data(model.index(i - 1, 0), MessageList.Timestamp)
                        const isFirst = t0 === undefined
                        const isLast = t2 === undefined
                        if (isFirst || isLast) {
                            return true
                        }
                        if (!isFirst) {
                            var min0 = new Date(t0).getUTCMinutes()
                            var min1 = new Date(t1).getUTCMinutes()
                            return min1 - min0 >= 1
                        }
                        return true
                    }

                    function computeSequencing(i) {
                        let sameAuthor = (a, b) => a === b
                        var seq = MsgSeq.unknown
                        var a0, a1, a2
                        a1 = model.data(model.index(i, 0), MessageList.Author)
                        if (i > 0)
                            a0 = model.data(model.index(i - 1, 0), MessageList.Author)
                        if (i < model.rowCount())
                            a2 = model.data(model.index(i + 1, 0), MessageList.Author)
                        const isFirst = a0 === undefined
                        const isLast = a2 === undefined
                        if (isFirst && isLast) {
                            return MsgSeq.single
                        }
                        if (isFirst) {
                            if (!sameAuthor(a1, a2)) {
                                seq = MsgSeq.single
                            } else {
                                seq = MsgSeq.first
                            }
                        } else if (isLast) {
                            if (!sameAuthor(a1, a0)) {
                                seq = MsgSeq.single
                            } else {
                                seq = MsgSeq.last
                            }
                        } else {
                            if (sameAuthor(a1, a0) && sameAuthor(a1, a2)) {
                                seq = MsgSeq.middle
                            } else {
                                if (!sameAuthor(a1, a0)) {
                                    if (!sameAuthor(a1, a2)) {
                                        seq = MsgSeq.single
                                    } else {
                                        seq = MsgSeq.first
                                    }
                                } else {
                                    if (!sameAuthor(a1, a0)) {
                                        seq = MsgSeq.single
                                    } else {
                                        seq = MsgSeq.last
                                    }
                                }
                            }
                        }
                        var adjustedSeq = seq
                        var timeVis = computeTimestampVisibility(i)
                        if (timeVis) {
                            if (adjustedSeq === MsgSeq.middle) {
                                adjustedSeq = MsgSeq.last
                            } else if (adjustedSeq === MsgSeq.first) {
                                adjustedSeq = MsgSeq.single
                            }
                        }
                        var previousTimeVis = computeTimestampVisibility(i - 1)
                        if (previousTimeVis) {
                            if (adjustedSeq === MsgSeq.middle) {
                                adjustedSeq = MsgSeq.first
                            } else if (adjustedSeq === MsgSeq.last) {
                                adjustedSeq = MsgSeq.single
                            }
                        }
                        return {"seq": adjustedSeq, "timeVis": timeVis }
                    }

                    onAtYBeginningChanged: {
                        if (!atYBeginning ||
                                MessagesAdapter.msgRequestPending ||
                                CurrentConversation.allMessagesLoaded)
                            return
                        MessagesAdapter.loadMoreMessages()
                    }

                    // handle auto-scrolling
                    onContentHeightChanged: {
                        if (atYEnd)
                            positionViewAtEnd()
                    }
                    Connections {
                        target: MessagesAdapter

                        function onNewInteraction() {
                            if (chatView.getDistanceToBottom() < 40)
                                Qt.callLater(chatView.positionViewAtEnd)
                        }

                        function onInitialMessagesLoaded() {
                            chatView.positionViewAtEnd()
                        }

                        function onMoreMessagesLoaded(rowCount) {
                            chatView.positionViewAtIndex(
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
