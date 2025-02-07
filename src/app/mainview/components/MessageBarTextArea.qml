/*
 * Copyright (C) 2020-2025 Savoir-faire Linux Inc.
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

import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import net.jami.Enums 1.1
import net.jami.Models 1.1

import SortFilterProxyModel 0.2

import "../../commoncomponents"

JamiFlickable {
    id: root

    property alias text: textArea.text
    property var textAreaObj: textArea
    property alias placeholderText: textArea.placeholderText
    property alias selectedText: textArea.selectedText
    property alias selectionStart: textArea.selectionStart
    property alias selectionEnd: textArea.selectionEnd
    property bool showPreview: false
    property bool isShowTypo: UtilsAdapter.getAppValue(Settings.Key.ShowMardownOption)
    property int textWidth: textArea.contentWidth

    // Used to cache the editable text when showing the preview message
    // and also to debounce the textChanged signal's effect on the composing status.
    property string cachedText
    property string debounceText

    signal sendMessagesRequired

    function selectText(start, end) {
        textArea.select(start, end);
    }

    function insertText(text) {
        textArea.insert(textArea.cursorPosition, text);
    }

    function pasteText() {
        textArea.paste();
    }

    function clearText() {
        textArea.clear();
    }

    function restoreVisibilityAfterSend() {
        showPreview = false;
    }

    LineEditContextMenu {
        id: textAreaContextMenu

        lineEditObj: textArea
        customizePaste: true

        onContextMenuRequirePaste: {
            // Intercept paste event to use C++ QMimeData
            MessagesAdapter.onPaste();
        }
    }

    ScrollBar.vertical.visible: text
    ScrollBar.horizontal.visible: text

    boundsMovement: Flickable.StopAtBounds
    boundsBehavior: Flickable.DragOverBounds
    interactive: true

    function resetEditableText() {
        textArea.text = cachedText;
        textArea.update();
    }

    onShowPreviewChanged: {
        if (showPreview) {
            cachedText = textArea.text;
            MessagesAdapter.parseMessage("", textArea.text, false, "", "");
        } else {
            textArea.textFormatChanged.disconnect(resetEditableText);
            textArea.textFormatChanged.connect(resetEditableText);
        }
    }

    Connections {
        target: MessagesAdapter
        function onMessageParsed(messageId, messageText) {
            if (messageId === "") {
                textArea.text = messageText;
                textArea.update();
            }
        }
    }

    TextArea.flickable: TextArea {
        id: textArea

        readOnly: showPreview
        leftPadding: JamiTheme.scrollBarHandleSize
        rightPadding: JamiTheme.scrollBarHandleSize
        persistentSelection: true
        verticalAlignment: TextEdit.AlignVCenter
        font.pointSize: JamiTheme.textFontSize + 2
        font.hintingPreference: Font.PreferNoHinting
        color: JamiTheme.textColor
        wrapMode: TextEdit.Wrap
        selectByMouse: !showPreview
        textFormat: showPreview ? TextEdit.RichText : TextEdit.PlainText

        placeholderTextColor: JamiTheme.messageBarPlaceholderTextColor
        horizontalAlignment: Text.AlignLeft

        background: Rectangle {
            border.width: 0
            color: "transparent"
        }

        onReleased: function (event) {
            if (event.button === Qt.RightButton)
                textAreaContextMenu.openMenuAt(event);
        }

        onTextChanged: {
            if (text !== debounceText && !showPreview) {
                debounceText = text;
                MessagesAdapter.userIsComposing(text ? true : false);
            }
        }

        // Intercept paste event to use C++ QMimeData
        // And enter event to customize send behavior
        // eg. Enter -> Send messages
        //     Shift + Enter -> Next Line
        Keys.onPressed: function (keyEvent) {
            if (keyEvent.matches(StandardKey.Paste)) {
                MessagesAdapter.onPaste();
                keyEvent.accepted = true;
            } else if (keyEvent.matches(StandardKey.MoveToPreviousLine)) {
                if (root.text !== "")
                    return;
                MessagesAdapter.replyToId = "";
                MessagesAdapter.editId = CurrentConversation.lastSelfMessageId;
                keyEvent.accepted = true;
            } else if (keyEvent.key === Qt.Key_Enter || keyEvent.key === Qt.Key_Return) {
                const isEnterNewLine = UtilsAdapter.getAppValue(Settings.Key.ChatViewEnterIsNewLine);
                const isShiftPressed = (keyEvent.modifiers & Qt.ShiftModifier);
                const isCtrlPressed = (keyEvent.modifiers & Qt.ControlModifier);
                if (!root.isShowTypo && !isShiftPressed) {
                    root.sendMessagesRequired();
                    keyEvent.accepted = true;
                } else if (isCtrlPressed) {
                    root.sendMessagesRequired();
                    keyEvent.accepted = true;
                } else if (!isEnterNewLine && !isShiftPressed) {
                    root.sendMessagesRequired();
                    keyEvent.accepted = true;
                }
            } else if (keyEvent.key === Qt.Key_Tab) {
                nextItemInFocusChain().forceActiveFocus(Qt.TabFocusReason);
                keyEvent.accepted = true;
            }
        }
    }
}
