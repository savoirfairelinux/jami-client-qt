/*
 * Copyright (C) 2020-2024 Savoir-faire Linux Inc.
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
import QtQuick
import QtQuick.Controls
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import net.jami.Enums 1.1
import net.jami.Models 1.1
import "../../commoncomponents"
import QtQuick.Layouts
import SortFilterProxyModel 0.2

JamiFlickable {
    id: root

    property int maxWidth: 330
    property bool tooMuch: {
        if (maxWidth > 0)
            return textArea.contentWidth > maxWidth;
        return false;
    }
    property alias text: textArea.text
    property var textAreaObj: textArea
    property alias placeholderText: textArea.placeholderText
    property alias selectedText: textArea.selectedText
    property alias selectionStart: textArea.selectionStart
    property alias selectionEnd: textArea.selectionEnd
    property bool showPreview: false
    property bool isShowTypo: UtilsAdapter.getAppValue(Settings.Key.ShowMardownOption)

    ScrollBar.vertical.visible: textArea.text
    ScrollBar.horizontal.visible: textArea.text

    signal sendMessagesRequired

    function heightBinding() {
        textArea.height = Qt.binding(() => textArea.lineCount === 1 ? 35 : textArea.paintedHeight);
    }

    function selectText(start, end) {
        textArea.select(start, end);
    }

    function insertText(text) {
        textArea.insert(textArea.cursorPosition, text);
    }

    function clearText() {
        var multiLine = textArea.lineCount !== 1;
        textArea.clear();
        if (multiLine) {
            heightBinding();
        }
    }

    function pasteText() {
        textArea.paste();
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

    interactive: true
    attachedFlickableMoving: textAreaPreview.height > height || textArea.height > height || root.moving

    contentHeight: showPreview ? textAreaPreview.height : textArea.height

    onShowPreviewChanged: {
        if (showPreview) {
            textAreaPreview.height = textArea.lineCount === 1 ? textArea.height : textAreaPreview.paintedHeight;
        }
        heightBinding();
    }

    TextArea {
        id: textAreaPreview

        onWidthChanged: root.height = this.height

        overwriteMode: false
        readOnly: true

        height: textArea.lineCount === 1 ? textArea.height : this.paintedHeight
        width: textArea.width

        visible: showPreview
        leftPadding: JamiTheme.scrollBarHandleSize
        rightPadding: JamiTheme.scrollBarHandleSize
        topPadding: 0
        bottomPadding: 0

        Connections {
            target: textArea
            function onTextChanged() {
                MessagesAdapter.parseMessage("", textArea.text, false, "", "");
            }
        }

        Connections {
            target: MessagesAdapter
            function onMessageParsed(messageId, messageText) {
                if (messageId === "") {
                    textAreaPreview.text = messageText;
                }
            }
        }

        verticalAlignment: TextEdit.AlignVCenter

        font.pointSize: JamiTheme.textFontSize + 2
        font.hintingPreference: Font.PreferNoHinting

        color: JamiTheme.textColor
        wrapMode: TextEdit.Wrap
        textFormat: TextEdit.RichText
        placeholderTextColor: JamiTheme.messageBarPlaceholderTextColor
        horizontalAlignment: Text.AlignLeft

        background: Rectangle {
            border.width: 0
            color: "transparent"
        }
    }

    TextArea.flickable: TextArea {
        id: textArea

        visible: !showPreview

        leftPadding: JamiTheme.scrollBarHandleSize
        rightPadding: JamiTheme.scrollBarHandleSize
        topPadding: 0
        bottomPadding: 0

        persistentSelection: true

        height: textArea.lineCount === 1 ? 35 : textArea.paintedHeight

        verticalAlignment: TextEdit.AlignVCenter

        font.pointSize: JamiTheme.textFontSize + 2
        font.hintingPreference: Font.PreferNoHinting

        color: JamiTheme.textColor
        wrapMode: TextEdit.Wrap
        selectByMouse: true
        textFormat: TextEdit.PlainText
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
            if (text)
                MessagesAdapter.userIsComposing(true);
            else
                MessagesAdapter.userIsComposing(false);
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
