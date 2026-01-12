/*
 * Copyright (C) 2020-2026 Savoir-faire Linux Inc.
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

    property int underlineHeight: JamiTheme.messageUnderlineHeight
    property alias text: textArea.text
    property var textAreaObj: textArea
    property alias placeholderText: textArea.placeholderText
    property alias selectedText: textArea.selectedText
    property alias selectionStart: textArea.selectionStart
    property alias selectionEnd: textArea.selectionEnd
    property bool showPreview: false
    property bool isShowTypo: UtilsAdapter.getAppValue(Settings.Key.ShowMardownOption)
    property int textWidth: textArea.contentWidth
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

    // Spell check is active under the following conditions:
    // 1. Spell check is enabled in settings
    // 2. The selected spell language is not ""
    // 3. We are not in preview mode
    function isSpellCheckActive() {
        return AppSettingsManager.getValue(Settings.EnableSpellCheck) && AppSettingsManager.getValue(Settings.SpellLang) !== "" && !showPreview;
    }

    TextArea.flickable: TextArea {
        id: textArea

        Connections {
            target: SpellCheckAdapter

            function onDictionaryChanged() {
                textArea.updateSpellCorrection();
            }
        }

        // Listen to settings changes to apply it to the text area
        Connections {
            target: UtilsAdapter

            function onChangeLanguage() {
                textArea.updateSpellCorrection();
            }

            function onChangeFontSize() {
                textArea.updateSpellCorrection();
            }

            function onEnableSpellCheckChanged() {
                textArea.updateSpellCorrection();
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
            font.pointSize: JamiTheme.textFontSize + 2
        }

        Text {
            id: highlight
            color: "black"
            font.bold: true
            visible: false
        }

        onReleased: function (event) {
            if (event.button === Qt.RightButton) {
                if (isSpellCheckActive() && SpellCheckAdapter.hasLoadedDictionary) {
                    var position = textArea.positionAt(event.x, event.y);
                    textArea.moveCursorSelection(position, TextInput.SelectWords);
                    textArea.selectWord();
                    if (!SpellCheckAdapter.spell(textArea.selectedText)) {
                        var wordList = SpellCheckAdapter.spellSuggestionsRequest(textArea.selectedText);
                        if (wordList.length !== 0) {
                            textAreaContextMenu.addMenuItem(wordList);
                        }
                    }
                }
                textAreaContextMenu.openMenuAt(event);
            }
        }

        onTextChanged: {
            updateSpellCorrection();
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
            updateSpellCorrection();
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

        function updateSpellCorrection() {
            clearUnderlines();
            // We iterate over the whole text to find words to check and underline them if needed
            if (isSpellCheckActive() && SpellCheckAdapter.hasLoadedDictionary) {
                var text = textArea.text;
                var words = SpellCheckAdapter.findWords(text);
                if (!words)
                    return;
                for (var i = 0; i < words.length; i++) {
                    var wordInfo = words[i];
                    if (wordInfo && wordInfo.word && !SpellCheckAdapter.spell(wordInfo.word)) {
                        textMetrics.text = wordInfo.word;
                        var xPos = textArea.positionToRectangle(wordInfo.position).x;
                        var yPos = textArea.positionToRectangle(wordInfo.position).y + textArea.positionToRectangle(wordInfo.position).height;
                        var underlineObject = Qt.createQmlObject('import QtQuick; Rectangle {height: 2; color: "red";}', textArea);
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
