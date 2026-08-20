/*
 * Copyright (C) 2021-2026 Savoir-faire Linux Inc.
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

ListView {
    id: root
    property alias verticalScrollBar: verticalScrollBar
    layer.mipmap: false
    clip: true

    // Injected conversation context; defaults to the global singleton for
    // the main window.
    property var convContext: CurrentConversation
    property string pendingScrollToId: ""
    property int pendingScrollAttempts: 0

    ScrollBar.vertical: JamiScrollBar {
        id: verticalScrollBar

        attachedFlickableMoving: root.moving
    }

    keyNavigationEnabled: true
    keyNavigationWraps: false

    focus: true
    activeFocusOnTab: true

    Accessible.role: Accessible.List
    Accessible.name: JamiStrings.conversationMessages

    function getDistanceToBottom() {
        const scrollDiff = ScrollBar.vertical.position - (1.0 - ScrollBar.vertical.size);
        return Math.abs(scrollDiff) * contentHeight;
    }

    function loadMoreMsgsIfNeeded() {
        if (convContext && atYBeginning && !convContext.allMessagesLoaded) {
            if (convContext !== CurrentConversation)
                convContext.loadMoreMessages();
            else
                MessagesAdapter.loadMoreMessages();
        }
    }

    function modelItem(index) {
        if (!root.model || index < 0 || index >= root.count || typeof root.model.get !== "function")
            return null;
        return root.model.get(index);
    }

    function computeTimestampVisibility(item, itemIndex) {
        if (!item)
            return;
        const current = modelItem(itemIndex);
        const next = modelItem(itemIndex + 1);
        if (!current)
            return;
        item.showTime = next ? current.Timestamp - next.Timestamp > JamiTheme.timestampIntervalTime
                             : !!(convContext && convContext.allMessagesLoaded);
        item.showDay = next ? MessagesAdapter.getFormattedDay(current.Timestamp)
                                  !== MessagesAdapter.getFormattedDay(next.Timestamp)
                            : !!(convContext && convContext.allMessagesLoaded);
    }

    function computeSequencing(item, itemIndex) {
        if (!item)
            return;
        const current = modelItem(itemIndex);
        const previous = modelItem(itemIndex - 1);
        const next = modelItem(itemIndex + 1);
        if (!current)
            return;
        const isFirst = !next || item.showTime || !!current.ReplyTo || next.Author !== current.Author;
        const previousShowTime = previous
            && previous.Timestamp - current.Timestamp > JamiTheme.timestampIntervalTime;
        const isLast = !previous || previousShowTime || !!previous.ReplyTo || previous.Author !== current.Author;
        if (isLast && isFirst)
            item.seq = MsgSeq.single;
        if (!isLast && isFirst)
            item.seq = MsgSeq.first;
        if (isLast && !isFirst)
            item.seq = MsgSeq.last;
        if (!isLast && !isFirst)
            item.seq = MsgSeq.middle;
    }

    function computeChatview(item, itemIndex) {
        if (!item)
            return;
        // ponytail: derive layout metadata from model rows so virtualization cannot change item heights.
        for (let i = Math.max(0, itemIndex - 1); i <= Math.min(root.count - 1, itemIndex + 1); ++i) {
            const delegate = root.itemAtIndex(i);
            if (delegate) {
                computeTimestampVisibility(delegate, i);
                computeSequencing(delegate, i);
            }
        }
    }

    function retryPendingScroll() {
        if (!pendingScrollToId)
            return;
        const id = pendingScrollToId;
        const index = root.model && root.model.getDisplayIndex ? root.model.getDisplayIndex(id) : -1;
        if (index >= 0) {
            root.positionViewAtIndex(index, ListView.Center);
            if (++pendingScrollAttempts < 10)
                pendingScrollTimer.restart();
            else {
                pendingScrollToId = "";
                pendingScrollAttempts = 0;
            }
        } else if (convContext !== CurrentConversation || !MessagesAdapter.loadMessagesUntil(id)) {
            pendingScrollToId = "";
            pendingScrollAttempts = 0;
        }
    }

    function scrollToMessage(id) {
        pendingScrollToId = id;
        pendingScrollAttempts = 0;
        retryPendingScroll();
    }

    function scrollToBottom() {
        positionViewAtBeginning();
    }

    Component.onCompleted: {
        positionViewAtBeginning();
    }

    ToastManager {
        id: toastManager

        anchors.fill: parent

        function instantiateToast(fileName, downloadDir) {
            instantiate(JamiStrings.fileSaved.arg(fileName).arg(downloadDir), 1000, 400);
        }
    }

    Connections {
        target: convContext
        function onScrollTo(id) {
            scrollToMessage(id);
        }
    }

    topMargin: JamiTheme.qwkTitleBarHeight + JamiTheme.sidePanelIslandsPadding * 2
    spacing: 2

    // The offscreen buffer is set to a reasonable value to avoid flickering
    // when scrolling up and down in a list with items of different heights.
    displayMarginBeginning: 2048
    displayMarginEnd: 2048

    maximumFlickVelocity: 2048
    verticalLayoutDirection: ListView.BottomToTop
    boundsBehavior: Flickable.StopAtBounds
    currentIndex: -1

    Connections {
        target: convContext
        function onIdChanged() {
            currentIndex = -1;
            pendingScrollToId = "";
            pendingScrollAttempts = 0;
        }
    }

    model: (convContext && convContext !== CurrentConversation) ? convContext.messageListModel : MessagesAdapter.messageListModel
    delegate: DelegateChooser {
        id: delegateChooser
        role: "Type"

        DelegateChoice {
            roleValue: Interaction.Type.TEXT

            TextMessageDelegate {
                convContext: root.convContext
                Component.onCompleted: {
                    computeChatview(this, index);
                }
            }
        }

        DelegateChoice {
            roleValue: Interaction.Type.CALL

            CallMessageDelegate {
                convContext: root.convContext
                Component.onCompleted: {
                    computeChatview(this, index);
                }
            }
        }

        DelegateChoice {
            roleValue: Interaction.Type.CONTACT

            ContactMessageDelegate {
                Component.onCompleted: {
                    computeChatview(this, index);
                }
            }
        }

        DelegateChoice {
            roleValue: Interaction.Type.INITIAL

            GeneratedMessageDelegate {
                font.bold: true
                Component.onCompleted: {
                    computeChatview(this, index);
                }
            }
        }

        DelegateChoice {
            roleValue: Interaction.Type.DATA_TRANSFER

            DataTransferMessageDelegate {
                convContext: root.convContext
                Component.onCompleted: {
                    computeChatview(this, index);
                }
            }
        }

        DelegateChoice {
            roleValue: Interaction.Type.COLLAB_DOC

            CollabDocMessageDelegate {
                convContext: root.convContext
                Component.onCompleted: {
                    computeChatview(this, index);
                }
            }
        }
    }

    onAtYBeginningChanged: loadMoreMsgsIfNeeded()
    onContentHeightChanged: {
        if (pendingScrollToId && pendingScrollAttempts > 0)
            pendingScrollTimer.restart();
    }

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
        enabled: convContext === CurrentConversation

        function onNewInteraction() {
            if (root.getDistanceToBottom() < 80 && !root.atYEnd) {
                Qt.callLater(root.positionViewAtBeginning);
            }
        }

        function onMoreMessagesLoaded(loadingRequestId) {
            retryPendingScroll();
            // This needs to be throttled, otherwise we will continue to load more messages
            // prior to the loaded chunk being rendered and changing the contentHeight.
            chunkLoadDebounceTimer.restart();
        }

        function onFileCopied(fileName, downloadDir) {
            toastManager.instantiateToast(fileName, downloadDir);
        }
    }

    // Mirror the same signals from other conversation contexts.
    Connections {
        target: convContext !== CurrentConversation ? convContext : null

        function onNewInteraction() {
            if (root.getDistanceToBottom() < 80 && !root.atYEnd) {
                Qt.callLater(root.positionViewAtBeginning);
            }
        }

        function onMoreMessagesLoaded(loadingRequestId) {
            retryPendingScroll();
            chunkLoadDebounceTimer.restart();
        }

        function onFileCopied(dest) {
            toastManager.instantiateToast(dest);
        }
    }

    Timer {
        id: pendingScrollTimer

        interval: 50
        repeat: false
        onTriggered: retryPendingScroll()
    }

    ScrollToBottomButton {
        id: scrollToBottomButton

        anchors.bottom: root.bottom
        anchors.bottomMargin: JamiTheme.chatViewScrollToBottomButtonBottomMargin
        anchors.horizontalCenter: root.horizontalCenter
        visible: 1 - verticalScrollBar.position >= verticalScrollBar.size * 2

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
                Layout.leftMargin: JamiTheme.messageBarRadius
            }

            Connections {
                target: MessagesAdapter

                function onCurrentConvComposingListChanged() {
                    var nameList = MessagesAdapter.currentConvComposingList;
                    if (nameList.length > 4) {
                        typeIndicatorNameText.text = "";
                        typeIndicatorEndingText.text = JamiStrings.typeIndicatorMax;
                        typeIndicatorNameText.calculateWidth();
                        return;
                    }
                    if (nameList.length === 1) {
                        typeIndicatorNameText.text = nameList[0];
                        typeIndicatorEndingText.text = JamiStrings.typeIndicatorSingle.arg("");
                        typeIndicatorNameText.calculateWidth();
                        return;
                    }
                    var typeIndicatorNameTextString = "";
                    if (nameList.length === 2) {
                        typeIndicatorNameTextString = JamiStrings.typeIndicatorAnd.arg(nameList[0]).arg(nameList[1]);
                    } else {
                        var namesExceptLast = nameList.slice(0, -1);
                        var lastName = nameList[nameList.length - 1];
                        typeIndicatorNameTextString = JamiStrings.typeIndicatorAnd.arg(namesExceptLast.join(", ")).arg(lastName);
                    }
                    typeIndicatorNameText.text = typeIndicatorNameTextString;
                    typeIndicatorEndingText.text = JamiStrings.typeIndicatorPlural.arg("");
                    typeIndicatorNameText.calculateWidth();
                }
            }

            Text {
                id: typeIndicatorNameText

                property int textWidth: 0

                function calculateWidth() {
                    if (!text)
                        return 0;
                    else {
                        var textSize = JamiQmlUtils.getTextBoundingRect(font, text).width;
                        var typingContentWidth = typingDots.width + typingDots.anchors.leftMargin + typeIndicatorNameText.anchors.leftMargin + typeIndicatorEndingText.contentWidth;
                        typeIndicatorNameText.Layout.preferredWidth = Math.min(typeIndicatorContainer.width - 5 - typingContentWidth, textSize);
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
