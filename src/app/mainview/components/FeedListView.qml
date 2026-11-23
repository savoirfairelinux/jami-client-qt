/*
 * Copyright (C) 2026 Savoir-faire Linux Inc.
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
import QtQml.Models
import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import "../../commoncomponents"

// A feed shown as posts, newest at the bottom like a chat. Only top-level messages are listed;
// each post shows its comments in place when opened.
ListView {
    id: root
    objectName: "feedMessageList"

    property alias verticalScrollBar: verticalScrollBar

    // Posts whose comments are open, by id. Kept here since post delegates are recycled.
    property var expandedPosts: ({})

    function isExpanded(postId) {
        return expandedPosts[postId] === true;
    }

    function setExpanded(postId, on) {
        if (isExpanded(postId) === on)
            return;
        const posts = Object.assign({}, expandedPosts);
        if (on)
            posts[postId] = true;
        else
            delete posts[postId];
        expandedPosts = posts;
    }

    function loadMoreMsgsIfNeeded() {
        if (MessagesAdapter.historyStalled)
            return;
        if (atYBeginning && !CurrentConversation.allMessagesLoaded)
            MessagesAdapter.loadMoreMessages();
    }

    // Shows a message: a post, or the post a comment belongs to, with its comments open.
    function showMessage(id) {
        const postId = model.threadRootOf(id) || id;
        const idx = model.getDisplayIndex(postId);
        if (idx < 0)
            return;
        if (postId !== id)
            setExpanded(postId, true);
        positionViewAtIndex(idx, ListView.Contain);
    }

    function getDistanceToBottom() {
        const scrollDiff = verticalScrollBar.position - (1.0 - verticalScrollBar.size);
        return Math.abs(scrollDiff) * contentHeight;
    }

    function scrollToBottom() {
        verticalScrollBar.position = 1 - verticalScrollBar.size;
    }

    model: MessagesAdapter.threadedMessageListModel
    clip: true
    layer.mipmap: false

    verticalLayoutDirection: ListView.BottomToTop
    topMargin: JamiTheme.qwkTitleBarHeight + JamiTheme.sidePanelIslandsPadding * 2
    bottomMargin: JamiTheme.feedPostSpacing
    boundsBehavior: Flickable.StopAtBounds
    maximumFlickVelocity: 2048
    displayMarginBeginning: 2048
    displayMarginEnd: 2048
    currentIndex: -1

    keyNavigationEnabled: true
    focus: true
    activeFocusOnTab: true

    Accessible.role: Accessible.List
    Accessible.name: JamiStrings.conversationMessages

    ScrollBar.vertical: JamiScrollBar {
        id: verticalScrollBar

        attachedFlickableMoving: root.moving
    }

    Component.onCompleted: positionViewAtBeginning()

    onAtYBeginningChanged: loadMoreMsgsIfNeeded()

    // The list keeps its bottom in place when resized (e.g. the composer's reply bar opening or
    // closing), which shifts the posts. Keep the top in place instead, unless at the bottom.
    property real lastHeight: height
    onHeightChanged: {
        const delta = height - lastHeight;
        lastHeight = height;
        const distanceToBottom = getDistanceToBottom();
        if (delta !== 0 && distanceToBottom > 1)
            contentY += Math.min(delta, distanceToBottom);
    }

    Binding {
        target: MessagesAdapter.messageListModel
        property: "hideSystemEvents"
        value: true
    }

    Connections {
        target: CurrentConversation

        function onIdChanged() {
            root.expandedPosts = {};
            root.currentIndex = -1;
        }

        function onScrollTo(id) {
            root.showMessage(id);
        }
    }

    Timer {
        id: chunkLoadDebounceTimer

        interval: 100
        onTriggered: {
            if (root.contentHeight < root.height)
                root.loadMoreMsgsIfNeeded();
        }
    }

    Connections {
        target: MessagesAdapter

        function onNewInteraction() {
            // Keep a new post in sight if the reader is at the bottom.
            if (root.getDistanceToBottom() < 80 && !root.atYEnd)
                Qt.callLater(root.positionViewAtBeginning);
        }

        function onMoreMessagesLoaded(loadingRequestId) {
            // Throttled so the loaded chunk is laid out before deciding to load another.
            chunkLoadDebounceTimer.restart();
        }

        function onFileCopied(fileName, downloadDir) {
            toastManager.instantiate(JamiStrings.fileSaved.arg(fileName).arg(downloadDir), 1000, 400);
        }
    }

    ToastManager {
        id: toastManager

        anchors.fill: parent
    }

    ScrollToBottomButton {
        anchors.bottom: root.bottom
        anchors.bottomMargin: JamiTheme.chatViewScrollToBottomButtonBottomMargin
        anchors.horizontalCenter: root.horizontalCenter
        visible: 1 - verticalScrollBar.position >= verticalScrollBar.size * 2

        onClicked: root.scrollToBottom()
    }

    delegate: DelegateChooser {
        role: "Type"

        DelegateChoice {
            roleValue: Interaction.Type.TEXT

            FeedPostDelegate {}
        }

        DelegateChoice {
            roleValue: Interaction.Type.DATA_TRANSFER

            FeedPostDelegate {}
        }

        DelegateChoice {
            roleValue: Interaction.Type.CALL

            CallMessageDelegate {}
        }

        DelegateChoice {
            roleValue: Interaction.Type.COLLAB_DOC

            CollabDocMessageDelegate {}
        }
    }
}
