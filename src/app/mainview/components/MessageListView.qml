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

    // The interaction ID a jump is waiting on, while its history is being fetched.
    property string pendingScrollToId: ""

    // The loading request that jump is waiting on, so an unrelated batch landing
    // first neither completes nor discards it.
    property int pendingScrollToRequest: -1

    // Older messages are fetched once the oldest loaded one comes within the offscreen
    // buffer, so the history is already there by the time the user scrolls onto it.
    readonly property bool nearBeginning: contentY - originY < displayMarginBeginning

    // Model count when history was last requested, so a request that delivers
    // nothing does not immediately trigger another one.
    property int countAtLastRequest: -1

    // True while a batch of older messages is on its way.
    property bool loadingMore: false

    // The list draws the proxy, so the proxy's row count is what sizes the
    // scrollbar. Keep it bounded by showing a run of rows around the viewport
    // and leaving the rest loaded but unshown. Rows are only ever added or
    // removed a long way from what is on screen, so the view stays put.
    readonly property int shownRowCap: 250
    readonly property int shownRowBuffer: 60
    property bool rowsAreTrimmed: false

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

    function updateShownRows() {
        if (!model || !model.setWindow || count === 0)
            return;
        // Nothing to bound yet, and nothing was taken away to put back.
        if (count <= shownRowCap && !rowsAreTrimmed)
            return;
        // A jump is mid-flight and owns what has to stay shown.
        if (pendingScrollToId !== "" || jumpSettleFrames > 0)
            return;
        // A moving view is still building delegates for the rows it is
        // crossing, and some of those build asynchronously. Taking rows away
        // now destroys that work mid-flight, so wait until the view settles.
        if (moving || verticalScrollBar.pressed) {
            shownRowsTimer.restart();
            return;
        }

        var first = indexAt(width / 2, contentY);
        var last = indexAt(width / 2, contentY + height - 1);
        if (first === -1 || last === -1)
            return;
        var lo = Math.min(first, last);
        var hi = Math.max(first, last);

        // Row 0 is the newest message.
        var newest = Math.max(0, lo - shownRowBuffer);
        var oldest = Math.min(count - 1, hi + shownRowBuffer);
        if (oldest - newest + 1 > shownRowCap)
            oldest = newest + shownRowCap - 1;

        rowsAreTrimmed = newest > 0 || oldest < count - 1;
        model.setWindow(model.idAt(oldest), model.idAt(newest));
    }

    Timer {
        id: shownRowsTimer

        interval: 150
        repeat: false
        onTriggered: root.updateShownRows()
    }

    onContentYChanged: shownRowsTimer.restart()

    function loadMoreMsgsIfNeeded() {
        if (!convContext || !nearBeginning || convContext.allMessagesLoaded)
            return;
        // Wait for the previous request to actually deliver something before asking
        // again, otherwise a request that brings nothing back turns into a busy loop.
        if (count === countAtLastRequest)
            return;
        countAtLastRequest = count;
        loadingMore = true;
        if (convContext !== CurrentConversation)
            convContext.loadMoreMessages();
        else
            MessagesAdapter.loadMoreMessages();
    }

    // A row's day separator, timestamp and bubble sequencing all depend on its
    // older neighbour, which is not instantiated yet when that row is created
    // while scrolling up. Recomputing the whole instantiated block, coalesced to
    // once per frame, is both cheaper and correct in every case.
    function scheduleGroupingRefresh(seedIndex) {
        pendingGroupingSeed = seedIndex;
        Qt.callLater(refreshGrouping);
    }

    property int pendingGroupingSeed: -1

    function refreshGrouping() {
        var seed = pendingGroupingSeed;
        pendingGroupingSeed = -1;
        if (seed < 0 || itemAtIndex(seed) === null)
            return;

        // Delegates are instantiated as one contiguous block, so walking out from
        // any live index finds all of them.
        var lo = seed;
        var hi = seed;
        while (lo > 0 && itemAtIndex(lo - 1) !== null)
            --lo;
        while (hi < count - 1 && itemAtIndex(hi + 1) !== null)
            ++hi;

        // Higher indices are older: proxy row 0 is the newest message.
        for (var i = lo; i <= hi; ++i) {
            var item = itemAtIndex(i);
            if (!item)
                continue;
            var older = itemAtIndex(i + 1);
            if (older) {
                item.showTime = item.timestamp - older.timestamp > JamiTheme.timestampIntervalTime;
                item.showDay = item.formattedDay !== older.formattedDay;
            } else if (i === count - 1 && convContext && convContext.allMessagesLoaded) {
                item.showTime = true;
                item.showDay = true;
            }
        }

        // Sequencing reads the neighbours' showTime, so it needs a second pass.
        for (var j = lo; j <= hi; ++j)
            computeSequencing(itemAtIndex(j - 1), itemAtIndex(j), itemAtIndex(j + 1));
    }

    function scrollToBottom() {
        verticalScrollBar.position = 1 - verticalScrollBar.size;
    }

    function computeSequencing(pItem, item, nItem) {
        if (root === undefined || !item)
            return;
        function isFirst() {
            if (!nItem)
                return true;
            else {
                if (item.showTime || item.isReply) {
                    return true;
                } else if (nItem.author !== item.author) {
                    return true;
                }
            }
            return false;
        }
        function isLast() {
            if (!pItem)
                return true;
            else {
                if (pItem.showTime || pItem.isReply) {
                    return true;
                } else if (pItem.author !== item.author) {
                    return true;
                }
            }
            return false;
        }
        if (isLast() && isFirst())
            item.seq = MsgSeq.single;
        if (!isLast() && isFirst())
            item.seq = MsgSeq.first;
        if (isLast() && !isFirst())
            item.seq = MsgSeq.last;
        if (!isLast() && !isFirst())
            item.seq = MsgSeq.middle;
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
            // Get the filtered index from the interaction ID.
            var idx = root.model.getDisplayIndex(id);
            if (idx < 0 && root.model.showMessage && root.model.showMessage(id)) {
                // It was loaded, just not shown. Widening the run reveals it.
                idx = root.model.getDisplayIndex(id);
            }
            if (idx < 0) {
                // The message is not in the loaded window yet. Ask for the history up
                // to it and complete the jump once that request reports back.
                root.pendingScrollToId = id;
                root.pendingScrollToRequest = root.convContext !== CurrentConversation
                    ? root.convContext.loadMessagesUntil(id)
                    : MessagesAdapter.loadMessagesUntil(id);
                return;
            }
            root.jumpToIndex(idx);
        }
    }

    // Finishes a jump that was waiting on history. The batch it asked for is the
    // only one that can satisfy it, so once that arrives the pending state is
    // dropped either way: a target still missing from it is unreachable, and
    // keeping the ID would hijack some later, unrelated load.
    function completePendingJump(loadingRequestId) {
        if (pendingScrollToId === "" || loadingRequestId !== pendingScrollToRequest)
            return;
        const idx = model.getDisplayIndex(pendingScrollToId);
        pendingScrollToId = "";
        pendingScrollToRequest = -1;
        if (idx >= 0)
            jumpToIndex(idx);
    }

    function jumpToIndex(idx) {
        // Rows may have just been inserted, so lay them out before positioning on one.
        forceLayout();
        positionViewAtIndex(idx, ListView.Center);
        // Drives the highlight, which ListView keeps aligned with the current row.
        currentIndex = idx;
        // positionViewAtIndex places the row from the delegate heights the view
        // happens to know. After a jump most of the block has just been inserted
        // and is not instantiated yet, so it positions against an estimate that
        // keeps changing as the real rows are built and later pages land, sliding
        // the target off screen again. Re-assert until the geometry stops moving.
        jumpSettleFrames = 40;
        jumpSettleTimer.restart();
        jumpHighlightAnimation.restart();
    }

    // Remaining attempts to put the jumped-to row where it was asked to go.
    property int jumpSettleFrames: 0

    // True while a jump is still holding its row against a moving layout.
    readonly property alias jumpSettling: jumpSettleTimer.running

    Timer {
        id: jumpSettleTimer

        interval: 16
        repeat: true

        onTriggered: {
            // Never fight the user: a drag wins over a jump that is still settling.
            if (root.currentIndex < 0 || root.dragging || root.jumpSettleFrames <= 0) {
                stop();
                // The jump held the shown run open while it landed; bound it again
                // now that the view has come to rest.
                root.jumpSettleFrames = 0;
                shownRowsTimer.restart();
                return;
            }
            --root.jumpSettleFrames;
            const item = root.itemAtIndex(root.currentIndex);
            if (item === null) {
                root.positionViewAtIndex(root.currentIndex, ListView.Center);
                return;
            }
            const top = item.mapToItem(root, 0, 0).y;
            if (Math.abs(top + item.height / 2 - root.height / 2) <= 1) {
                stop();
                root.jumpSettleFrames = 0;
                shownRowsTimer.restart();
                return;
            }
            const contentYBefore = root.contentY;
            root.positionViewAtIndex(root.currentIndex, ListView.Center);
            if (Math.abs(root.contentY - contentYBefore) < 0.5) {
                // The view is clamped against an end, so the row cannot be centred.
                // Settle for having all of it on screen.
                if (top < 0 || top + item.height > root.height)
                    root.positionViewAtIndex(root.currentIndex, ListView.Contain);
                stop();
            }
        }
    }

    // Fades the row of a jumped-to message in and out so it can be picked out of
    // the surrounding history.
    property real jumpHighlightOpacity: 0

    highlightMoveDuration: 0
    highlightResizeDuration: 0
    highlight: Rectangle {
        radius: 5
        color: root.convContext ? root.convContext.color : JamiTheme.transparentColor
        opacity: root.jumpHighlightOpacity
    }

    SequentialAnimation {
        id: jumpHighlightAnimation

        NumberAnimation {
            target: root
            property: "jumpHighlightOpacity"
            to: 0.4
            duration: 200
        }
        PauseAnimation {
            duration: 1200
        }
        NumberAnimation {
            target: root
            property: "jumpHighlightOpacity"
            to: 0
            duration: 600
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
            countAtLastRequest = -1;
            loadingMore = false;
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
                Component.onCompleted: scheduleGroupingRefresh(index)
            }
        }

        DelegateChoice {
            roleValue: Interaction.Type.CALL

            CallMessageDelegate {
                convContext: root.convContext
                Component.onCompleted: scheduleGroupingRefresh(index)
            }
        }

        DelegateChoice {
            roleValue: Interaction.Type.CONTACT

            ContactMessageDelegate {
                Component.onCompleted: scheduleGroupingRefresh(index)
            }
        }

        DelegateChoice {
            roleValue: Interaction.Type.INITIAL

            GeneratedMessageDelegate {
                font.bold: true
                Component.onCompleted: scheduleGroupingRefresh(index)
            }
        }

        DelegateChoice {
            roleValue: Interaction.Type.DATA_TRANSFER

            DataTransferMessageDelegate {
                convContext: root.convContext
                Component.onCompleted: scheduleGroupingRefresh(index)
            }
        }

        DelegateChoice {
            roleValue: Interaction.Type.COLLAB_DOC

            CollabDocMessageDelegate {
                convContext: root.convContext
                Component.onCompleted: scheduleGroupingRefresh(index)
            }
        }
    }

    onNearBeginningChanged: loadMoreMsgsIfNeeded()

    Timer {
        id: chunkLoadDebounceTimer

        interval: 100
        repeat: false
        running: false
        onTriggered: root.loadMoreMsgsIfNeeded()
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
            root.loadingMore = false;
            root.completePendingJump(loadingRequestId);
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
            root.loadingMore = false;
            root.completePendingJump(loadingRequestId);
            chunkLoadDebounceTimer.restart();
        }

        function onFileCopied(dest) {
            toastManager.instantiateToast(dest);
        }
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

    // Placeholder bubbles standing in for the batch of older messages being
    // fetched. BottomToTop puts the footer at the top, which is where they
    // land. Reserving the space keeps the list scrollable past the oldest
    // loaded message instead of dead-ending against it.
    footer: Column {
        id: loadingSkeleton

        width: root.width
        height: root.loadingMore ? implicitHeight : 0
        visible: height > 0
        clip: true
        spacing: 4

        Behavior on height {
            NumberAnimation {
                duration: 150
                easing.type: Easing.OutQuad
            }
        }

        SequentialAnimation on opacity {
            running: root.loadingMore
            loops: Animation.Infinite
            NumberAnimation {
                to: 0.35
                duration: 600
                easing.type: Easing.InOutQuad
            }
            NumberAnimation {
                to: 1
                duration: 600
                easing.type: Easing.InOutQuad
            }
        }

        Repeater {
            model: [0.55, 0.35, 0.7]

            Rectangle {
                width: Math.max(60, root.width * modelData * 0.6)
                height: 32
                x: JamiTheme.messageBarMarginSize
                radius: 5
                color: JamiTheme.messageInBgColor
            }
        }
    }
}
