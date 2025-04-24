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

    property int underlineHeight: 2
    property alias text: textArea.text
    property var textAreaObj: textArea
    property alias placeholderText: textArea.placeholderText
    property alias selectedText: textArea.selectedText
    property alias selectionStart: textArea.selectionStart
    property alias selectionEnd: textArea.selectionEnd
    property bool showPreview: false
    property bool isShowTypo: UtilsAdapter.getAppValue(Settings.Key.ShowMardownOption)
    property int textWidth: textArea.contentWidth
    property var spellCheckActive: AppSettingsManager.getValue(Settings.EnableSpellCheck)
    property var language: AppSettingsManager.getValue(Settings.SpellLang)

    // Used to cache the editable text when showing the preview message
    // and also to debounce the textChanged signal's effect on the composing status.
    property var underlineList: []
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
        checkSpell: true

        onContextMenuRequirePaste: {
            // Intercept paste event to use C++ QMimeData
            MessagesAdapter.onPaste();
        }
    }

    ScrollBar.vertical.visible: text
    ScrollBar.horizontal.visible: text

    // HACK: remove after migration to Qt 6.7+
    boundsBehavior: Flickable.StopAtBounds

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

        CachedFile {
            id: cachedFile
        }

        function updateCorrection(language) {
            cachedFile.updateDictionnary(language);
            textArea.updateUnderlineText();
        }

        Loader {
            active: spellCheckActive
            Connections {
                target: UtilsAdapter

                function onSpellLangChanged() {
                    root.language = AppSettingsManager.getSpellLanguage();
                    textArea.updateCorrection(root.language);
                }

                function onEnableSpellCheckChanged() {
                    spellCheckActive = AppSettingsManager.getValue(Settings.EnableSpellCheck);
                    if (spellCheckActive == true) {
                        root.language = AppSettingsManager.getSpellLanguage();
                        textArea.updateCorrection(root.language);
                        console.warn("Spell check enabled");
                    } else {
                        textArea.clearUnderlines();
                        console.warn("Spell check disabled");
                    }
                }
            }
        }

        readOnly: showPreview
        leftPadding: JamiTheme.scrollBarHandleSize
        rightPadding: JamiTheme.scrollBarHandleSize
        topPadding: 0
        bottomPadding: underlineHeight

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

        TextMetrics {
            id: textMetrics
            elide: Text.ElideMiddle
            font.family: textArea.font.family
        }

        Text {
            id: highlight
            color: "black"
            font.bold: true
            visible: false
        }

        onReleased: function (event) {
            if (event.button === Qt.RightButton) {
                var position = textArea.positionAt(event.x, event.y);
                textArea.moveCursorSelection(position, TextInput.SelectWords);
                textArea.selectWord();
                if (!MessagesAdapter.spell(textArea.selectedText)) {
                    var wordList = MessagesAdapter.spellSuggestionsRequest(textArea.selectedText);
                    if (wordList.length !== 0) {
                        textAreaContextMenu.addMenuItem(wordList);
                    }
                }
                textAreaContextMenu.openMenuAt(event);
            }
        }

        onTextChanged: {
            updateUnderlineText();
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
            // Update underline on each input to take into account deleted text and sent ones
            updateUnderlineText();
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

        function updateUnderlineText() {
            /* Need to refresh all of the underline object. Otherwise the
                * underline stay persistent on type
                */
            clearUnderlines();
            if (spellCheckActive) {
                var text = textArea.text;
                var cursorPosition = textArea.cursorPosition;

                // Use regex to find words and their positions
                var wordRegex = /\b\w+\b/g;
                var match;
                while ((match = wordRegex.exec(text)) !== null) {
                    var word = match[0];
                    var wordStart = match.index;

                    if (!MessagesAdapter.spell(word)) {
                        textMetrics.text = word;
                        var xPos = textArea.positionToRectangle(wordStart).x;
                        var yPos = textArea.positionToRectangle(wordStart).y + textArea.positionToRectangle(wordStart).height;

                        var underlineObject = Qt.createQmlObject('import QtQuick 2.5; Rectangle {height: 2; color: "red";}', textArea);
                        underlineObject.x = xPos;
                        underlineObject.y = yPos;
                        underlineObject.width = textMetrics.width;
                        underlineList.push(underlineObject);
                    }
                }
            }
        }

        function clearUnderlines() {
            // Destroy all of the underline boxes
            while (underlineList.length > 0) {
                // Get the previous item
                var underlineObject = underlineList[underlineList.length - 1];
                // Remove the last item
                underlineList.pop();
                // Destroy the removed item
                underlineObject.destroy();
            }
        }
    }
}
