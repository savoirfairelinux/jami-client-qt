/*
 * Copyright (C) 2021-2023 Savoir-faire Linux Inc.
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
import Qt.labs.qmlmodels

import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1

import "../../commoncomponents"

JamiListView {
    id: root

    function getDistanceToBottom() {
        const scrollDiff = ScrollBar.vertical.position -
                         (1.0 - ScrollBar.vertical.size)
        return Math.abs(scrollDiff) * contentHeight
    }

    function loadMoreMsgsIfNeeded() {
        if (atYBeginning && !CurrentConversation.allMessagesLoaded) {
            print("load more messages", atYBeginning, CurrentConversation.allMessagesLoaded)
            MessagesAdapter.loadMoreMessages()
        }
    }

    function computeTimestampVisibility(item1, item1Index, item2, item2Index) {
        if (item1 && item2) {
            if (item1Index < item2Index) {
                item1.showTime = item1.timestamp - item2.timestamp > JamiTheme.timestampIntervalTime
                item1.showDay = item1.formattedDay !== item2.formattedDay
            } else {
                item2.showTime = item2.timestamp - item1.timestamp > JamiTheme.timestampIntervalTime
                item2.showDay = item2.formattedDay !== item1.formattedDay
            }
            return true
        }
        return false
    }

    function scrollToBottom() {
        verticalScrollBar.position = 1 - verticalScrollBar.size;
    }

    function computeChatview(item, itemIndex) {
        if (!root) return
        var rootItem = root.itemAtIndex(0)
        var pItem = root.itemAtIndex(itemIndex - 1)
        var pItemIndex = itemIndex - 1
        var nItem = root.itemAtIndex(itemIndex + 1)
        var nItemIndex = itemIndex + 1

        // middle insertion
        if (pItem && nItem) {
            computeTimestampVisibility(item, itemIndex, nItem, nItemIndex)
            computeSequencing(item, nItem, root.itemAtIndex(itemIndex + 2))
        }
        // top buffer insertion = scroll up
        if (pItem && !nItem) {
            computeTimestampVisibility(item, itemIndex, pItem, pItemIndex)
            computeSequencing(root.itemAtIndex(itemIndex - 2), pItem, item)
        }
        // bottom buffer insertion = scroll down
        if (!pItem && nItem) {
            computeTimestampVisibility(item, itemIndex, nItem, nItemIndex)
            computeSequencing(item, nItem, root.itemAtIndex(itemIndex + 2))
        }
        // index 0 insertion = new message
        if (itemIndex === 0) {
            // Compute the timestamp visibility when a new message is received/sent.
            // This needs to be done in a delayed fashion because the new message is inserted
            // at the top of the list and the list is not yet updated.
            Qt.callLater(() => {
                var fItem = root.itemAtIndex(1)
                if (fItem) {
                    computeTimestampVisibility(item, 0, fItem, 1)
                    computeSequencing(null, item, fItem)
                    computeSequencing(item, fItem, root.itemAtIndex(2))
                }
            })
        }
        // top element
        if(itemIndex === root.count - 1 && CurrentConversation.allMessagesLoaded) {
            item.showTime = true
            item.showDay = true
        }
    }

    function computeSequencing(pItem, item, nItem) {
        if (root === undefined || !item)
            return

        function isFirst() {
            if (!nItem) return true
            else {
                if (item.showTime || item.isReply ) {
                    return true
                } else if (nItem.author !== item.author) {
                    return true
                }
            }
            return false
        }

        function isLast() {
            if (!pItem) return true
            else {
                if (pItem.showTime || pItem.isReply) {
                    return true
                } else if (pItem.author !== item.author) {
                    return true
                }
            }
            return false
        }

        if (isLast() && isFirst())
            item.seq = MsgSeq.single
        if (!isLast() && isFirst())
            item.seq = MsgSeq.first
        if (isLast() && !isFirst())
            item.seq = MsgSeq.last
        if (!isLast() && !isFirst())
            item.seq = MsgSeq.middle
    }

    // fade-in mechanism
    Component.onCompleted: fadeAnimation.start()
    Rectangle {
        id: overlay
        anchors.fill: parent
        color: JamiTheme.chatviewBgColor
        visible: opacity !== 0
        SequentialAnimation {
            id: fadeAnimation
            NumberAnimation {
                target: overlay; property: "opacity"
                to: 1; duration: 0
            }
            NumberAnimation {
                target: overlay; property: "opacity"
                to: 0; duration: 240
            }
        }
    }

    ToastManager {
        id: toastManager

        anchors.fill: parent

        function instantiateToast(dest) {
            instantiate(JamiStrings.fileSaved.arg(dest), 1000, 400)
        }
    }

    Connections {
        target: CurrentConversation
        function onScrollTo(id) {
            // Get the filtered index from the interaction ID.
            var idx = MessagesAdapter.messageListModel.getDisplayIndex(id)
            positionViewAtIndex(idx, ListView.Visible)
        }
    }

    topMargin: 12
    spacing: 2

    // The offscreen buffer is set to a reasonable value to avoid flickering
    // when scrolling up and down in a list with items of different heights.
    displayMarginBeginning: 2048
    displayMarginEnd: 2048

    maximumFlickVelocity: 2048
    verticalLayoutDirection: ListView.BottomToTop
    boundsBehavior: Flickable.StopAtBounds
    currentIndex: -1

    model: MessagesAdapter.messageListModel
    delegate: DelegateChooser {
        id: delegateChooser
        role: "Type"

        DelegateChoice {
            id: delegateChoice
            roleValue: Interaction.Type.TEXT

            TextMessageDelegate {
                Component.onCompleted:  {
                    computeChatview(this, index)
                }
            }
        }

        DelegateChoice {
            roleValue: Interaction.Type.CALL

            CallMessageDelegate {
                Component.onCompleted:  {
                    computeChatview(this, index)
                }
            }
        }

        DelegateChoice {
            roleValue: Interaction.Type.CONTACT

            ContactMessageDelegate {
                Component.onCompleted:  {
                    computeChatview(this, index)
                }
            }
        }

        DelegateChoice {
            roleValue: Interaction.Type.INITIAL

            GeneratedMessageDelegate {
                font.bold: true
                Component.onCompleted:  {
                    computeChatview(this, index)
                }
            }
        }

        DelegateChoice {
            roleValue: Interaction.Type.DATA_TRANSFER

            DataTransferMessageDelegate {
                Component.onCompleted:  {
                    computeChatview(this, index)
                }
            }
        }

    }

    onAtYBeginningChanged: loadMoreMsgsIfNeeded()

    Timer {
        id: chunkLoadDebounceTimer

        interval: 100
        repeat: false
        running: false
        onTriggered: {
            if (root.contentHeight < root.height) {
                root.loadMoreMsgsIfNeeded();
            }
        }
    }

    Connections {
        target: MessagesAdapter

        function onNewInteraction() {
            if (root.getDistanceToBottom() < 80 &&
                    !root.atYEnd) {
                Qt.callLater(root.positionViewAtBeginning)
            }
        }

        function onMoreMessagesLoaded(loadingRequestId) {
            // This needs to be throttled, otherwise we will continue to load more messages
            // prior to the loaded chunk being rendered and changing the contentHeight.
            chunkLoadDebounceTimer.restart();
        }

        function onFileCopied(dest) {
            toastManager.instantiateToast(dest)
        }
    }

    ScrollToBottomButton {
        id: scrollToBottomButton

        anchors.bottom: root.bottom
        anchors.bottomMargin: JamiTheme.chatViewScrollToBottomButtonBottomMargin
        anchors.horizontalCenter: root.horizontalCenter
        visible:  1 - verticalScrollBar.position >= verticalScrollBar.size * 2

        onClicked: scrollToBottom()
    }

    header: Control {
        id: typeIndicatorContainer

        topPadding: 6

        width: root.width
        height: typeIndicatorNameText.contentHeight + topPadding

        visible: MessagesAdapter.currentConvComposingList.length

        RowLayout {
            anchors.left: typeIndicatorContainer.left
            anchors.leftMargin: JamiTheme.messageBarMarginSize
            anchors.bottom: typeIndicatorContainer.bottom
            anchors.bottomMargin: 2

            spacing: 0

            TypingDots {
                id: typingDots

                Layout.alignment: Qt.AlignVCenter
            }

            Connections {
                target: MessagesAdapter

                function onCurrentConvComposingListChanged () {
                    var typeIndicatorNameTextString = ""
                    var nameList = MessagesAdapter.currentConvComposingList

                    if (nameList.length > 4) {
                        typeIndicatorNameText.text = ""
                        typeIndicatorEndingText.text = JamiStrings.typeIndicatorMax
                        typeIndicatorNameText.calculateWidth()
                        return
                    }
                    if (nameList.length === 1) {
                        typeIndicatorNameText.text = nameList[0]
                        typeIndicatorEndingText.text =
                                JamiStrings.typeIndicatorSingle.replace("{}", "")
                        typeIndicatorNameText.calculateWidth()
                        return
                    }

                    for (var i = 0; i < nameList.length; i++) {
                        typeIndicatorNameTextString += nameList[i]

                        if (i === nameList.length - 2)
                            typeIndicatorNameTextString += JamiStrings.typeIndicatorAnd
                        else if (i !== nameList.length - 1)
                            typeIndicatorNameTextString += ", "
                    }
                    typeIndicatorNameText.text = typeIndicatorNameTextString
                    typeIndicatorEndingText.text =
                            JamiStrings.typeIndicatorPlural.replace("{}", "")
                    typeIndicatorNameText.calculateWidth()
                }
            }

            Text {
                id: typeIndicatorNameText

                property int textWidth: 0

                function calculateWidth () {
                    if (!text)
                        return 0
                    else {
                        var textSize = JamiQmlUtils.getTextBoundingRect(font, text).width
                        var typingContentWidth = typingDots.width + typingDots.anchors.leftMargin
                                + typeIndicatorNameText.anchors.leftMargin
                                + typeIndicatorEndingText.contentWidth
                        typeIndicatorNameText.Layout.preferredWidth =
                                Math.min(typeIndicatorContainer.width - 5 - typingContentWidth,
                                         textSize)
                    }
                }

                Layout.alignment: Qt.AlignVCenter
                Layout.leftMargin: JamiTheme.sbsMessageBasePreferredPadding

                font.pointSize: 8
                font.bold: Font.DemiBold
                elide: Text.ElideRight
                color: JamiTheme.textColor
            }

            Text {
                id: typeIndicatorEndingText

                Layout.alignment: Qt.AlignVCenter

                font.pointSize: 8
                color: JamiTheme.textColor
            }
        }
    }
}
