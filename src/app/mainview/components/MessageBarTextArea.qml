/*
 * Copyright (C) 2020-2023 Savoir-faire Linux Inc.
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
import "../../commoncomponents"

JamiFlickable {
    id: root
    property alias placeholderText: textArea.placeholderText
    property alias text: textArea.text
    property var textAreaObj: textArea

    ScrollBar.horizontal.visible: textArea.text
    ScrollBar.vertical.visible: textArea.text
    attachedFlickableMoving: contentHeight > height || root.moving
    interactive: true

    function clearText() {
        textArea.clear();
    }
    function insertText(text) {
        textArea.insert(textArea.cursorPosition, text);
    }
    function pasteText() {
        textArea.paste();
    }
    signal sendMessagesRequired

    LineEditContextMenu {
        id: textAreaContextMenu
        customizePaste: true
        lineEditObj: textArea

        onContextMenuRequirePaste: {
            // Intercept paste event to use C++ QMimeData
            MessagesAdapter.onPaste();
        }
    }

    TextArea.flickable: TextArea {
        id: textArea
        bottomPadding: 0
        color: JamiTheme.textColor
        font.hintingPreference: Font.PreferNoHinting
        font.pointSize: JamiTheme.textFontSize + 2
        leftPadding: JamiTheme.scrollBarHandleSize
        placeholderTextColor: JamiTheme.placeholderTextColor
        rightPadding: JamiTheme.scrollBarHandleSize
        selectByMouse: true
        textFormat: TextEdit.PlainText
        topPadding: 0
        verticalAlignment: TextEdit.AlignVCenter
        wrapMode: TextEdit.Wrap

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
                if (!(keyEvent.modifiers & Qt.ShiftModifier)) {
                    root.sendMessagesRequired();
                    keyEvent.accepted = true;
                }
            } else if (keyEvent.key === Qt.Key_Tab) {
                nextItemInFocusChain().forceActiveFocus(Qt.TabFocusReason);
                keyEvent.accepted = true;
            }
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

        background: Rectangle {
            border.width: 0
            color: JamiTheme.transparentColor
        }
    }
}
