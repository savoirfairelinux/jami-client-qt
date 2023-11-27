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
import QtQuick.Layouts
import QtQuick.Controls
import SortFilterProxyModel 0.2
import net.jami.Adapters 1.1
import net.jami.Models 1.1
import net.jami.Enums 1.1
import net.jami.Constants 1.1
import "../../commoncomponents"

RowLayout {
    id: root

    property alias text: messageBarTextArea.text
    property var textAreaObj: messageBarTextArea
    property real marginSize: JamiTheme.messageBarMarginSize
    property bool sendButtonVisibility: true
    property bool animate: false
    property bool showDefault: !UtilsAdapter.getAppValue(Settings.Key.ShowSendOption)
    property bool showTypo: UtilsAdapter.getAppValue(Settings.Key.ShowMardownOption)
    property bool chatViewEnterIsNewLine: UtilsAdapter.getAppValue(Settings.Key.ChatViewEnterIsNewLine)
    property bool showTypoSecond: false
    property bool showPreview: false
    property bool multiLine: messageBarTextArea.tooMuch

    property int messageBarLayoutMaximumWidth: 486

    readonly property bool isFullScreen: visibility === Window.FullScreen

    signal sendMessageButtonClicked
    signal sendFileButtonClicked
    signal audioRecordMessageButtonClicked
    signal videoRecordMessageButtonClicked
    signal showMapClicked
    signal emojiButtonClicked

    height: {
        if (showTypo || multiLine)
            return messageBarTextArea.height + 25 + 3 * marginSize + 1
        else
            return textAreaObj.height + marginSize + 1
    }

    Rectangle {

        Layout.preferredHeight: parent.height
        Layout.preferredWidth: childrenRect.width
        visible: !CurrentConversation.isSip
        color: JamiTheme.transparentColor
        ComboBox {
            id: showMoreButton
            focus: true
            width: JamiTheme.chatViewFooterButtonSize
            height: JamiTheme.chatViewFooterButtonSize
            anchors.bottom: parent.bottom
            anchors.bottomMargin: marginSize / 2

            // Used to choose the correct color for the button.
            readonly property bool highlight: down || hovered

            background: Rectangle {
                implicitWidth: showMoreButton.width
                implicitHeight: showMoreButton.height
                radius: 5
                color: showMoreButton.highlight ?
                           JamiTheme.hoveredButtonColor :
                           JamiTheme.transparentColor
            }

            MaterialToolTip {
                id: toolTipMoreButton

                parent: showMoreButton
                visible: showMoreButton.hovered && (text.length > 0)
                delay: Qt.styleHints.mousePressAndHoldInterval
                text: showMoreButton.down ? JamiStrings.showLess : JamiStrings.showMore
            }

            indicator: ResponsiveImage {

                width: 25
                height: 25

                anchors.verticalCenter: parent.verticalCenter
                anchors.horizontalCenter: parent.horizontalCenter

                source: JamiResources.more_menu_black_24dp_svg

                color: showMoreButton.highlight ?
                           JamiTheme.chatViewFooterImgHoverColor :
                           JamiTheme.chatViewFooterImgColor;
            }

            Component {
                id: sharePopupComp
                ShareMenu {
                    id: sharePopup
                    onAudioRecordMessageButtonClicked: root.audioRecordMessageButtonClicked()
                    onVideoRecordMessageButtonClicked: root.videoRecordMessageButtonClicked()
                    onShowMapClicked: root.showMapClicked()
                    modelList: listViewMoreButton.menuMoreButton
                    y: showMoreButton.y + 31
                    x: showMoreButton.x - 3
                }
            }

            popup: ShareMenu {
                id: sharePopup
                onAudioRecordMessageButtonClicked: root.audioRecordMessageButtonClicked()
                onVideoRecordMessageButtonClicked: root.videoRecordMessageButtonClicked()
                onShowMapClicked: root.showMapClicked()
                modelList: listViewMoreButton.menuMoreButton
                y: showMoreButton.y + 31
                x: showMoreButton.x - 3
            }
        }
    }

    Rectangle {
        id: rectangle

        Layout.fillWidth: true
        Layout.fillHeight: true

        radius: 5
        color: JamiTheme.transparentColor
        border.color: JamiTheme.chatViewFooterRectangleBorderColor
        border.width: 2

        onWidthChanged: {
            height = Qt.binding(() => root.height);
            if (width < JamiTheme.messageBarMinimumWidth) {
                showTypoSecond = false;
            } else {
                showTypoSecond = true;
            }
        }

        GridLayout {
            id: rowLayout

            columns: 2
            rows: 2
            columnSpacing: 0
            rowSpacing: 0

            anchors.fill: parent

            MessageBarTextArea {
                id: messageBarTextArea

                objectName: "messageBarTextArea"
                maxWidth: rectangle.width - messageBarRowLayout.width - 35
                Layout.row: showTypo || multiLine ? 0 : 1
                Layout.column: 0

                // forward activeFocus to the actual text area object
                onActiveFocusChanged: {
                    if (activeFocus)
                        textAreaObj.forceActiveFocus();
                }

                placeholderText: JamiStrings.writeTo.arg(CurrentConversation.title)

                Layout.alignment: showTypo ? Qt.AlignLeft | Qt.AlignBottom : Qt.AlignBottom
                Layout.fillWidth: true
                Layout.leftMargin: marginSize / 2
                Layout.topMargin: marginSize / 2
                Layout.bottomMargin: marginSize / 2
                Layout.rightMargin: marginSize / 2
                Layout.minimumHeight: JamiTheme.chatViewFooterPreferredHeight
                Layout.preferredHeight: contentHeight
                Layout.maximumHeight: JamiTheme.chatViewFooterTextAreaMaximumHeight - marginSize / 2

                onSendMessagesRequired: {
                    sendMessageButtonClicked();
                }
                onTextChanged: {
                    MessagesAdapter.userIsComposing(text ? true : false);
                    if (!text) {
                        messageBarTextArea.heightBinding();
                    }
                }
                property var markdownShortCut: {
                    "Bold": function () {
                        if (!showPreview) {
                            listViewTypoFirst.itemAtIndex(0).action.triggered();
                        }
                    },
                    "Italic": function () {
                        if (!showPreview) {
                            listViewTypoFirst.itemAtIndex(1).action.triggered();
                        }
                    },
                    "Barre": function () {
                        if (!showPreview) {
                            listViewTypoFirst.itemAtIndex(2).action.triggered();
                        }
                    },
                    "Heading": function () {
                        if (!showPreview) {
                            listViewTypoFirst.itemAtIndex(3).action.triggered();
                        }
                    },
                    "Link": function () {
                        if (!showPreview) {
                            listViewTypoFirst.itemAtIndex(4).action.triggered();
                        }
                    },
                    "Code": function () {
                        if (!showPreview) {
                            listViewTypoFirst.itemAtIndex(5).action.triggered();
                        }
                    },
                    "Quote": function () {
                        if (!showPreview) {
                            listViewTypoSecond.itemAtIndex(0).action.triggered();
                        }
                    },
                    "Unordered list": function () {
                        if (!showPreview) {
                            listViewTypoSecond.itemAtIndex(1).action.triggered();
                        }
                    },
                    "Ordered list": function () {
                        if (!showPreview) {
                            listViewTypoSecond.itemAtIndex(2).action.triggered();
                        }
                    },
                    "Enter is new line": function () {
                        if (!showPreview) {
                            listViewTypoSecond.itemAtIndex(3).action.triggered();
                        }
                    }
                }

                Shortcut {
                    sequence: "Ctrl+B"
                    context: Qt.ApplicationShortcut
                    onActivated: messageBarTextArea.markdownShortCut["Bold"]()
                }

                Shortcut {
                    sequence: "Ctrl+I"
                    context: Qt.ApplicationShortcut
                    onActivated: messageBarTextArea.markdownShortCut["Italic"]()
                }

                Shortcut {
                    sequence: "Shift+Alt+X"
                    context: Qt.ApplicationShortcut
                    onActivated: messageBarTextArea.markdownShortCut["Barre"]()
                }

                Shortcut {
                    sequence: "Ctrl+Alt+H"
                    context: Qt.ApplicationShortcut
                    onActivated: messageBarTextArea.markdownShortCut["Heading"]()
                }

                Shortcut {
                    sequence: "Ctrl+Alt+K"
                    context: Qt.ApplicationShortcut
                    onActivated: messageBarTextArea.markdownShortCut["Link"]()
                }

                Shortcut {
                    sequence: "Ctrl+Alt+C"
                    context: Qt.ApplicationShortcut
                    onActivated: messageBarTextArea.markdownShortCut["Code"]()
                }

                Shortcut {
                    sequence: "Shift+Alt+9"
                    context: Qt.ApplicationShortcut
                    onActivated: messageBarTextArea.markdownShortCut["Quote"]()
                }

                Shortcut {
                    sequence: "Shift+Alt+8"
                    context: Qt.ApplicationShortcut
                    onActivated: messageBarTextArea.markdownShortCut["Unordered list"]()
                }

                Shortcut {
                    sequence: "Shift+Alt+7"
                    context: Qt.ApplicationShortcut
                    onActivated: messageBarTextArea.markdownShortCut["Ordered list"]()
                }

                Shortcut {
                    sequence: "Shift+Alt+T"
                    context: Qt.ApplicationShortcut
                    onActivated: {
                        showTypo = !showTypo;
                        messageBarTextArea.isShowTypo = showTypo;
                        UtilsAdapter.setAppValue(Settings.Key.ShowMardownOption, showTypo);
                    }
                }

                Shortcut {
                    sequence: "Shift+Alt+P"
                    context: Qt.ApplicationShortcut
                    onActivated: {
                        showPreview = !showPreview;
                        messageBarTextArea.showPreview = showPreview;
                    }
                }
            }

            Row {
                id: messageBarRowLayout

                Layout.row: showTypo || multiLine ? 1 : 1
                Layout.column: showTypo || multiLine ? 0 : 1
                Layout.alignment: showTypo || multiLine ? Qt.AlignRight : Qt.AlignBottom
                Layout.columnSpan: showTypo || multiLine ? 2 : 1
                Layout.topMargin: marginSize / 2
                Layout.rightMargin: 0

                Row {
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: marginSize / 2

                    Row {
                        id: listViewTypo
                        height: JamiTheme.chatViewFooterButtonSize

                        function isStyle(text, start, end, char1, char2, regex) {
                            if (char1 === "**") {
                                return isStarStyle(text, start, end, "bold");
                            }
                            if (char1 === "*") {
                                return isStarStyle(text, start, end, "italic");
                            }
                            var selectedText = text.substring(start - char1.length, end + char2.length);
                            return (selectedText.startsWith(char1) && selectedText.endsWith(char2));
                        }

                        function isStarStyle(text, selectionStart, selectionEnd, type) {
                            let start = selectionStart;
                            while (start > 0 && text[start - 1] === "*") {
                                start--;
                            }
                            let end = selectionEnd;
                            while (end < text.length && text[end] === "*") {
                                end++;
                            }
                            const starCount = Math.min(selectionStart - start, end - selectionEnd);
                            if (type === "italic") {
                                return starCount === 1 || starCount === 3;
                            }
                            return starCount === 2 || starCount === 3;
                        }

                        function addStyle(text, start, end, char1, char2, regex) {
                            // get the selected text with markdown effect
                            var selectedText = text.substring(start - char1.length, end + char2.length);
                            if (isStyle(text, start, end, char1, char2, regex)) {
                                // If the selected text is already formatted with the given characters, remove them
                                selectedText = text.substring(start, end);
                                root.text = text.substring(0, start - char1.length) + selectedText + text.substring(end + char2.length);
                                messageBarTextArea.selectText(start - char1.length, end - char1.length);
                            } else {
                                // Otherwise, add the formatting characters to the selected text
                                root.text = text.substring(0, start) + char1 + text.substring(start, end) + char2 + text.substring(end);
                                messageBarTextArea.selectText(start + char1.length, end + char1.length);
                            }
                        }

                        function isPrefixSyle(message, selectionStart, selectionEnd, delimiter, isOrderedList) {
                            //represents all the selected lines
                            var multilineSelection;
                            var newPrefix;
                            var newSuffix;
                            var newStartPos;
                            var newEndPos;
                            function nextIndexOf(text, char1, startPos) {
                                return text.indexOf(char1, startPos + 1);
                            }

                            //get the previous index of the multilineSelection text
                            if (message[selectionStart] === "\n")
                                newStartPos = message.lastIndexOf('\n', selectionStart - 1);
                            else
                                newStartPos = message.lastIndexOf('\n', selectionStart);

                            //get the next index of the multilineSelection text
                            if (message[selectionEnd] === "\n" || message[selectionEnd] === undefined)
                                newEndPos = selectionEnd;
                            else
                                newEndPos = nextIndexOf(message, "\n", selectionEnd);

                            //if the text is empty
                            if (newStartPos === -1)
                                newStartPos = 0;
                            newPrefix = message.slice(0, newStartPos);
                            multilineSelection = message.slice(newStartPos, newEndPos);
                            newSuffix = message.slice(newEndPos);
                            var isFirstLineSelected = !multilineSelection.startsWith('\n') || newPrefix === "";
                            var getDelimiter_counter = 1;
                            function getDelimiter() {
                                return `${getDelimiter_counter++}. `;
                            }
                            function getHasCurrentMarkdown() {
                                const linesQuantity = (multilineSelection.match(/\n/g) || []).length;
                                const newLinesWithDelimitersQuantity = (multilineSelection.match(new RegExp(`\n${delimiter}`, 'g')) || []).length;
                                if (newLinesWithDelimitersQuantity === linesQuantity && !isFirstLineSelected)
                                    return true;
                                return linesQuantity === newLinesWithDelimitersQuantity && multilineSelection.startsWith(delimiter);
                            }
                            function getHasCurrentMarkdownBullet() {
                                const linesQuantity = (multilineSelection.match(/\n/g) || []).length;
                                const newLinesWithDelimitersQuantity = (multilineSelection.match(/\n\d+\. /g) || []).length;
                                if (newLinesWithDelimitersQuantity === linesQuantity && !isFirstLineSelected)
                                    return true;
                                return linesQuantity === newLinesWithDelimitersQuantity && (/^\d\. /).test(multilineSelection);
                            }
                            var newValue;
                            var newStart;
                            var newEnd;
                            var count;
                            var startPos;
                            var multilineSelectionLength;
                            if (!isOrderedList) {
                                return getHasCurrentMarkdown();
                            } else {
                                return getHasCurrentMarkdownBullet();
                            }
                        }

                        function addPrefixStyle(message, selectionStart, selectionEnd, delimiter, isOrderedList) {
                            //represents all the selected lines
                            var multilineSelection;
                            var newPrefix;
                            var newSuffix;
                            var newStartPos;
                            var newEndPos;
                            function nextIndexOf(text, char1, startPos) {
                                return text.indexOf(char1, startPos + 1);
                            }

                            //get the previous index of the multilineSelection text
                            if (message[selectionStart] === "\n")
                                newStartPos = message.lastIndexOf('\n', selectionStart - 1);
                            else
                                newStartPos = message.lastIndexOf('\n', selectionStart);

                            //get the next index of the multilineSelection text
                            if (message[selectionEnd] === "\n" || message[selectionEnd] === undefined)
                                newEndPos = selectionEnd;
                            else
                                newEndPos = nextIndexOf(message, "\n", selectionEnd);

                            //if the text is empty
                            if (newStartPos === -1)
                                newStartPos = 0;
                            newPrefix = message.slice(0, newStartPos);
                            multilineSelection = message.slice(newStartPos, newEndPos);
                            newSuffix = message.slice(newEndPos);
                            var isFirstLineSelected = !multilineSelection.startsWith('\n') || newPrefix === "";
                            var getDelimiter_counter = 1;
                            function getDelimiter() {
                                return `${getDelimiter_counter++}. `;
                            }
                            function getHasCurrentMarkdown() {
                                const linesQuantity = (multilineSelection.match(/\n/g) || []).length;
                                const newLinesWithDelimitersQuantity = (multilineSelection.match(new RegExp(`\n${delimiter}`, 'g')) || []).length;
                                if (newLinesWithDelimitersQuantity === linesQuantity && !isFirstLineSelected)
                                    return true;
                                return linesQuantity === newLinesWithDelimitersQuantity && multilineSelection.startsWith(delimiter);
                            }
                            function getHasCurrentMarkdownBullet() {
                                const linesQuantity = (multilineSelection.match(/\n/g) || []).length;
                                const newLinesWithDelimitersQuantity = (multilineSelection.match(/\n\d+\. /g) || []).length;
                                if (newLinesWithDelimitersQuantity === linesQuantity && !isFirstLineSelected)
                                    return true;
                                return linesQuantity === newLinesWithDelimitersQuantity && (/^\d\. /).test(multilineSelection);
                            }
                            var newValue;
                            var newStart;
                            var newEnd;
                            var count;
                            var startPos;
                            var multilineSelectionLength;
                            if (!isOrderedList) {
                                if (getHasCurrentMarkdown()) {

                                    // clear first line from delimiter
                                    if (isFirstLineSelected)
                                        multilineSelection = multilineSelection.slice(delimiter.length);
                                    newValue = newPrefix + multilineSelection.replace(new RegExp(`\n${delimiter}`, 'g'), '\n') + newSuffix;
                                    count = 0;
                                    if (isFirstLineSelected)
                                        count++;
                                    count += (multilineSelection.match(/\n/g) || []).length;
                                    newStart = Math.max(selectionStart - delimiter.length, 0);
                                    newEnd = Math.max(selectionEnd - (delimiter.length * count), 0);
                                } else {
                                    newValue = newPrefix + multilineSelection.replace(/\n/g, `\n${delimiter}`) + newSuffix;
                                    count = 0;
                                    if (isFirstLineSelected) {
                                        newValue = delimiter + newValue;
                                        count++;
                                    }
                                    count += (multilineSelection.match(new RegExp('\\n', 'g')) || []).length;
                                    newStart = selectionStart + delimiter.length;
                                    newEnd = selectionEnd + (delimiter.length * count);
                                }
                            } else if (getHasCurrentMarkdownBullet()) {
                                if (message[selectionStart] === "\n")
                                    startPos = message.lastIndexOf('\n', selectionStart - 1) + 1;
                                else
                                    startPos = message.lastIndexOf('\n', selectionStart) + 1;
                                newStart = startPos;
                                multilineSelection = multilineSelection.replace(/^\d+\.\s/gm, '');
                                newValue = newPrefix + multilineSelection + newSuffix;
                                multilineSelectionLength = multilineSelection.length;

                                //if the first line is not selected, we need to remove the first "\n" of multilineSelection
                                if (newStart)
                                    multilineSelectionLength = multilineSelection.length - 1;
                                newEnd = Math.max(newStart + multilineSelectionLength, 0);
                            } else {
                                if (message[selectionStart] === "\n")
                                    startPos = message.lastIndexOf('\n', selectionStart - 1) + 1;
                                else
                                    startPos = message.lastIndexOf('\n', selectionStart) + 1;
                                newStart = startPos;

                                // if no text is selected
                                if (selectionStart === selectionEnd)
                                    newStart = newStart + 3;
                                if (isFirstLineSelected)
                                    multilineSelection = getDelimiter() + multilineSelection;
                                const selectionArr = Array.from(multilineSelection);
                                for (var i = 0; i < selectionArr.length; i++) {
                                    if (selectionArr[i] === '\n')
                                        selectionArr[i] = `\n${getDelimiter()}`;
                                }
                                multilineSelection = selectionArr.join('');
                                newValue = newPrefix + multilineSelection + newSuffix;
                                multilineSelectionLength = multilineSelection.length;

                                //if the first line is not selected, we meed to remove the first "\n" of multilineSelection
                                if (startPos)
                                    multilineSelectionLength = multilineSelection.length - 1;
                                newEnd = Math.max(startPos + multilineSelectionLength, 0);
                            }
                            root.text = newValue;
                            messageBarTextArea.selectText(newStart, newEnd);
                        }

                        ListView {
                            id: listViewTypoFirst

                            objectName: "listViewTypoFirst"

                            visible: showTypo
                            width: contentWidth + 2 * leftMargin

                            Behavior on width  {
                                NumberAnimation {
                                    duration: JamiTheme.longFadeDuration / 2
                                }
                            }

                            height: JamiTheme.chatViewFooterButtonSize
                            orientation: ListView.Horizontal
                            interactive: false
                            leftMargin: 5
                            rightMargin: 5
                            spacing: 5

                            property list<Action> menuTypoActionsFirst: [
                                Action {
                                    id: boldAction
                                    property var iconSrc: JamiResources.bold_black_24dp_svg
                                    property var shortcutText: JamiStrings.bold
                                    property string shortcutKey: "Ctrl+B"
                                    property bool isStyle: listViewTypo.isStyle(root.text, messageBarTextArea.selectionStart, messageBarTextArea.selectionEnd, "**", "**", /\\*\*.+\\*\*/)
                                    onTriggered: function clickAction() {
                                        listViewTypo.addStyle(root.text, messageBarTextArea.selectionStart, messageBarTextArea.selectionEnd, "**", "**", /\\*\*.+\\*\*/);
                                    }
                                },
                                Action {
                                    id: italicAction
                                    property var iconSrc: JamiResources.italic_black_24dp_svg
                                    property var shortcutText: JamiStrings.italic
                                    property string shortcutKey: "Ctrl+I"
                                    property bool isStyle: listViewTypo.isStyle(root.text, messageBarTextArea.selectionStart, messageBarTextArea.selectionEnd, "*", "*", /(?:\*.+\*|\*\*\*.+\*\*\*)/)
                                    onTriggered: function clickAction() {
                                        listViewTypo.addStyle(root.text, messageBarTextArea.selectionStart, messageBarTextArea.selectionEnd, "*", "*", /(?:\*.+\*|\*\*\*.+\*\*\*)/);
                                    }
                                },
                                Action {
                                    id: strikethroughAction
                                    property var iconSrc: JamiResources.s_barre_black_24dp_svg
                                    property var shortcutText: JamiStrings.strikethrough
                                    property string shortcutKey: "Shift+Alt+X"
                                    property bool isStyle: listViewTypo.isStyle(root.text, messageBarTextArea.selectionStart, messageBarTextArea.selectionEnd, "~~", "~~", /\~\~.+\~\~/)
                                    onTriggered: function clickAction() {
                                        listViewTypo.addStyle(root.text, messageBarTextArea.selectionStart, messageBarTextArea.selectionEnd, "~~", "~~", /\~\~.+\~\~/);
                                    }
                                },
                                Action {
                                    id: titleAction
                                    property var iconSrc: JamiResources.title_black_24dp_svg
                                    property var shortcutText: JamiStrings.heading
                                    property string shortcutKey: "Ctrl+Alt+H"
                                    property bool isStyle: listViewTypo.isPrefixSyle(root.text, messageBarTextArea.selectionStart, messageBarTextArea.selectionEnd, "### ", false)
                                    onTriggered: function clickAction() {
                                        listViewTypo.addPrefixStyle(root.text, messageBarTextArea.selectionStart, messageBarTextArea.selectionEnd, "### ", false);
                                    }
                                },
                                Action {
                                    id: linkAction
                                    property var iconSrc: JamiResources.link_web_black_24dp_svg
                                    property var shortcutText: JamiStrings.link
                                    property string shortcutKey: "Ctrl+Alt+K"
                                    property bool isStyle: listViewTypo.isStyle(root.text, messageBarTextArea.selectionStart, messageBarTextArea.selectionEnd, "[", "](url)", /\[.+\]\(.+\)/)
                                    onTriggered: function clickAction() {
                                        listViewTypo.addStyle(root.text, messageBarTextArea.selectionStart, messageBarTextArea.selectionEnd, "[", "](url)", /\[.+\]\(.+\)/);
                                    }
                                },
                                Action {
                                    id: codeAction
                                    property var iconSrc: JamiResources.code_black_24dp_svg
                                    property var shortcutText: JamiStrings.code
                                    property string shortcutKey: "Ctrl+Alt+C"
                                    property bool isStyle: listViewTypo.isStyle(root.text, messageBarTextArea.selectionStart, messageBarTextArea.selectionEnd, "```", "```", /\`\`\`.+\`\`\`/)
                                    onTriggered: function clickAction() {
                                        listViewTypo.addStyle(root.text, messageBarTextArea.selectionStart, messageBarTextArea.selectionEnd, "```", "```", /\`\`\`.+\`\`\`/);
                                    }
                                }
                            ]

                            model: menuTypoActionsFirst

                            delegate: PushButton {
                                anchors.verticalCenter: parent ? parent.verticalCenter : undefined
                                preferredSize: JamiTheme.chatViewFooterRealButtonSize
                                imageContainerWidth: 15
                                imageContainerHeight: 15
                                radius: 5

                                hoverEnabled: !showPreview
                                enabled: !showPreview

                                toolTipText: modelData.shortcutText
                                shortcutKey: modelData.shortcutKey
                                hasShortcut: true

                                source: modelData.iconSrc
                                focusPolicy: Qt.TabFocus

                                normalColor: {
                                    if (showPreview) {
                                        return JamiTheme.primaryBackgroundColor;
                                    } else if (modelData.isStyle) {
                                        return JamiTheme.hoveredButtonColor;
                                    } else {
                                        return JamiTheme.primaryBackgroundColor;
                                    }
                                }
                                imageColor: {
                                    if (showPreview) {
                                        return JamiTheme.chatViewFooterImgDisableColor;
                                    } else if (hovered) {
                                        return JamiTheme.chatViewFooterImgHoverColor;
                                    } else if (modelData.isStyle) {
                                        return JamiTheme.chatViewFooterImgHoverColor;
                                    } else {
                                        return JamiTheme.chatViewFooterImgColor;
                                    }
                                }
                                hoveredColor: JamiTheme.hoveredButtonColor
                                pressedColor: hoveredColor

                                action: modelData
                            }
                        }

                        Rectangle {
                            height: JamiTheme.chatViewFooterButtonSize
                            color: JamiTheme.primaryBackgroundColor
                            visible: showTypo && showTypoSecond
                            width: 2

                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 2
                                height: JamiTheme.chatViewFooterButtonSize / 2
                                color: showPreview ? JamiTheme.chatViewFooterImgDisableColor : JamiTheme.chatViewFooterSeparateLineColor
                            }
                        }

                        Rectangle {
                            z: -1
                            radius: 0
                            color: JamiTheme.primaryBackgroundColor
                            width: JamiTheme.chatViewFooterButtonSize
                            height: JamiTheme.chatViewFooterButtonSize

                            visible: showTypo && !showTypoSecond

                            ComboBox {
                                id: showMoreTypoButton
                                width: JamiTheme.chatViewFooterRealButtonSize
                                height: width
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.horizontalCenter: parent.horizontalCenter

                                enabled: !showPreview
                                hoverEnabled: !showPreview

                                MaterialToolTip {
                                    id: toolTip
                                    parent: showMoreTypoButton
                                    visible: showMoreTypoButton.hovered && (text.length > 0)
                                    delay: Qt.styleHints.mousePressAndHoldInterval
                                    text: markdownPopup.visible ? JamiStrings.showLess : JamiStrings.showMore
                                }

                                background: Rectangle {
                                    implicitWidth: showMoreTypoButton.width
                                    implicitHeight: showMoreTypoButton.height
                                    radius: 5
                                    color: showPreview ? JamiTheme.transparentColor : (parent && parent.hovered ? JamiTheme.hoveredButtonColor : JamiTheme.transparentColor)
                                }

                                indicator: ResponsiveImage {
                                    containerHeight: 20
                                    containerWidth: 20
                                    width: 18
                                    height: 18

                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.horizontalCenter: parent.horizontalCenter

                                    source: JamiResources.more_vert_24dp_svg

                                    color: showPreview ? JamiTheme.chatViewFooterImgDisableColor : (parent && parent.hovered ? JamiTheme.chatViewFooterImgHoverColor : JamiTheme.chatViewFooterImgColor)
                                }

                                popup: MarkdownPopup {
                                    id: markdownPopup
                                    y: 1.5 * parent.height
                                    x: -parent.width * 2
                                    width: 105
                                    height: JamiTheme.chatViewFooterButtonSize

                                    menuTypoActionsSecond: listViewTypoSecond.menuTypoActionsSecond
                                }
                            }
                        }

                        ListView {
                            id: listViewTypoSecond
                            visible: showTypo && showTypoSecond
                            width: contentWidth + 2 * leftMargin

                            height: JamiTheme.chatViewFooterButtonSize
                            orientation: ListView.Horizontal
                            interactive: false
                            leftMargin: 10
                            rightMargin: 10
                            spacing: 10

                            Rectangle {
                                anchors.fill: parent
                                color: JamiTheme.transparentColor
                                z: -1
                            }

                            property list<Action> menuTypoActionsSecond: [
                                Action {
                                    id: quoteAction
                                    property var iconSrc: JamiResources.quote_black_24dp_svg
                                    property var shortcutText: JamiStrings.quote
                                    property string shortcutKey: "Shift+Alt+9"
                                    property bool isStyle: listViewTypo.isPrefixSyle(root.text, messageBarTextArea.selectionStart, messageBarTextArea.selectionEnd, "> ", false)
                                    onTriggered: function clickAction() {
                                        listViewTypo.addPrefixStyle(root.text, messageBarTextArea.selectionStart, messageBarTextArea.selectionEnd, "> ", false);
                                    }
                                },
                                Action {
                                    id: unorderedListAction
                                    property var iconSrc: JamiResources.bullet_point_black_24dp_svg
                                    property var shortcutText: JamiStrings.unorderedList
                                    property string shortcutKey: "Shift+Alt+8"
                                    property bool isStyle: listViewTypo.isPrefixSyle(root.text, messageBarTextArea.selectionStart, messageBarTextArea.selectionEnd, "- ", false)
                                    onTriggered: function clickAction() {
                                        listViewTypo.addPrefixStyle(root.text, messageBarTextArea.selectionStart, messageBarTextArea.selectionEnd, "- ", false);
                                    }
                                },
                                Action {
                                    id: orderedListAction
                                    property var iconSrc: JamiResources.bullet_number_black_24dp_svg
                                    property var shortcutText: JamiStrings.orderedList
                                    property string shortcutKey: "Shift+Alt+7"
                                    property bool isStyle: listViewTypo.isPrefixSyle(root.text, messageBarTextArea.selectionStart, messageBarTextArea.selectionEnd, "", true)
                                    onTriggered: function clickAction() {
                                        listViewTypo.addPrefixStyle(root.text, messageBarTextArea.selectionStart, messageBarTextArea.selectionEnd, "", true);
                                    }
                                }
                            ]

                            model: menuTypoActionsSecond

                            delegate: PushButton {
                                anchors.verticalCenter: parent ? parent.verticalCenter : undefined
                                preferredSize: JamiTheme.chatViewFooterRealButtonSize
                                imageContainerWidth: 20
                                imageContainerHeight: 20
                                radius: 5

                                hoverEnabled: !showPreview
                                enabled: !showPreview

                                toolTipText: modelData.shortcutText
                                shortcutKey: modelData.shortcutKey
                                hasShortcut: modelData.hasShortcut ? true : false
                                source: modelData.iconSrc
                                focusPolicy: Qt.TabFocus

                                normalColor: {
                                    if (showPreview) {
                                        return JamiTheme.primaryBackgroundColor;
                                    } else if (modelData.normalColor) {
                                        return modelData.normalColor;
                                    } else if (modelData.isStyle) {
                                        return JamiTheme.hoveredButtonColor;
                                    } else {
                                        return JamiTheme.primaryBackgroundColor;
                                    }
                                }
                                imageColor: {
                                    if (showPreview) {
                                        return JamiTheme.chatViewFooterImgDisableColor;
                                    } else if (hovered) {
                                        return JamiTheme.chatViewFooterImgHoverColor;
                                    } else if (modelData.imageColor !== null) {
                                        return modelData.imageColor;
                                    } else if (modelData.isStyle) {
                                        return JamiTheme.chatViewFooterImgHoverColor;
                                    } else {
                                        return JamiTheme.chatViewFooterImgColor;
                                    }
                                }
                                hoveredColor: JamiTheme.hoveredButtonColor
                                pressedColor: hoveredColor

                                action: modelData
                            }
                        }
                    }

                    PushButton {
                        id: typoButton

                        preferredSize: JamiTheme.chatViewFooterButtonSize
                        imageContainerWidth: 24
                        imageContainerHeight: 24

                        radius: JamiTheme.chatViewFooterButtonRadius

                        hoverEnabled: !showPreview
                        enabled: !showPreview

                        toolTipText: showTypo ? JamiStrings.hideFormatting : JamiStrings.showFormatting
                        source: JamiResources.text_edit_black_24dp_svg

                        normalColor: showPreview ? JamiTheme.primaryBackgroundColor : (showTypo ? JamiTheme.hoveredButtonColor : JamiTheme.primaryBackgroundColor)
                        imageColor: showPreview ? JamiTheme.chatViewFooterImgDisableColor : (hovered || showTypo ? JamiTheme.chatViewFooterImgHoverColor : JamiTheme.chatViewFooterImgColor)
                        hoveredColor: JamiTheme.hoveredButtonColor
                        pressedColor: hoveredColor

                        onClicked: {
                            showTypo = !showTypo;
                            messageBarTextArea.isShowTypo = showTypo;
                            if (messageBar.width < messageBarLayoutMaximumWidth + sendMessageButton.width + 2 * JamiTheme.preferredMarginSize)
                                showTypoSecond = false;
                            if (!showDefault)
                                showDefault = true;
                            UtilsAdapter.setAppValue(Settings.Key.ShowMardownOption, showTypo);
                            UtilsAdapter.setAppValue(Settings.Key.ShowSendOption, !showDefault);
                        }
                    }
                }

                Row {
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: marginSize / 2

                    ListView {
                        id: listViewAction

                        width: contentWidth + 2 * leftMargin

                        Behavior on width  {
                            NumberAnimation {
                                duration: JamiTheme.longFadeDuration / 2
                            }
                        }

                        height: JamiTheme.chatViewFooterButtonSize
                        orientation: ListView.Horizontal
                        interactive: false

                        leftMargin: 5
                        rightMargin: 5
                        spacing: 5

                        property list<Action> menuActions: [
                            Action {
                                id: sendFile
                                property var iconSrc: JamiResources.link_black_24dp_svg
                                property var toolTip: JamiStrings.sendFile
                                property bool show: true
                                property bool needWebEngine: false
                                property bool needVideoDevice: false
                                property bool noSip: false
                                onTriggered: function clickAction() {
                                    sendFileButtonClicked();
                                    textAreaObj.forceActiveFocus();
                                }
                            },
                            Action {
                                id: addEmoji
                                property var iconSrc: JamiResources.emoji_black_24dp_svg
                                property var toolTip: JamiStrings.addEmoji
                                property bool show: true
                                property bool needWebEngine: true
                                property bool needVideoDevice: false
                                property bool noSip: true
                                onTriggered: function clickAction() {
                                    emojiButtonClicked();
                                }
                            }
                        ]

                        ListModel {
                            id: listActions
                            Component.onCompleted: {
                                for (var i = 0; i < listViewAction.menuActions.length; i++) {
                                    append({
                                            "menuAction": listViewAction.menuActions[i]
                                        });
                                }
                            }
                        }

                        model: SortFilterProxyModel {
                            sourceModel: listActions
                            filters: [
                                ExpressionFilter {
                                    expression: menuAction.show === true
                                    enabled: root.showDefault
                                },
                                ExpressionFilter {
                                    expression: menuAction.needWebEngine === false
                                    enabled: !WITH_WEBENGINE
                                },
                                ExpressionFilter {
                                    expression: menuAction.noSip === true
                                    enabled: CurrentConversation.isSip
                                },
                                ExpressionFilter {
                                    expression: menuAction.needVideoDevice === false
                                    enabled: VideoDevices.listSize === 0
                                }
                            ]
                        }

                        delegate: PushButton {
                            id: buttonDelegate
                            anchors.verticalCenter: parent ? parent.verticalCenter : undefined
                            preferredSize: JamiTheme.chatViewFooterButtonSize
                            imageContainerWidth: 25
                            imageContainerHeight: 25
                            radius: 5

                            hoverEnabled: !showPreview
                            enabled: !showPreview

                            toolTipText: modelData.toolTip
                            source: modelData.iconSrc

                            normalColor: JamiTheme.primaryBackgroundColor
                            imageColor: showPreview ? JamiTheme.chatViewFooterImgDisableColor : (hovered ? JamiTheme.chatViewFooterImgHoverColor : JamiTheme.chatViewFooterImgColor)
                            hoveredColor: JamiTheme.hoveredButtonColor
                            pressedColor: hoveredColor

                            action: modelData
                        }
                    }

                    ListView {
                        id: listViewMoreButton

                        width: 0
                        Behavior on width  {
                            NumberAnimation {
                                duration: JamiTheme.longFadeDuration / 2
                            }
                        }

                        height: JamiTheme.chatViewFooterButtonSize
                        orientation: ListView.Horizontal
                        interactive: false

                        leftMargin: 10
                        rightMargin: 10
                        spacing: 10

                        property list<Action> menuMoreButton: [
                            Action {
                                id: leaveAudioMessage
                                property var iconSrc: JamiResources.message_audio_black_24dp_svg
                                property var toolTip: JamiStrings.leaveAudioMessage
                                property bool show: false
                                property bool needWebEngine: false
                                property bool needVideoDevice: false
                                property bool noSip: false
                                onTriggered: function clickAction() {
                                    audioRecordMessageButtonClicked();
                                }
                            },
                            Action {
                                id: leaveVideoMessage
                                property var iconSrc: JamiResources.message_video_black_24dp_svg
                                property var toolTip: JamiStrings.leaveVideoMessage
                                property bool show: false
                                property bool needWebEngine: false
                                property bool needVideoDevice: true
                                property bool noSip: false
                                onTriggered: function clickAction() {
                                    videoRecordMessageButtonClicked();
                                }
                            },
                            Action {
                                id: shareLocation
                                property var iconSrc: JamiResources.localisation_sharing_send_pin_svg
                                property var toolTip: JamiStrings.shareLocation
                                property bool show: false
                                property bool needWebEngine: true
                                property bool needVideoDevice: false
                                property bool noSip: false
                                onTriggered: function clickAction() {
                                    showMapClicked();
                                }
                            }
                        ]

                        ListModel {
                            id: listMoreButton
                            Component.onCompleted: {
                                for (var i = 0; i < listViewMoreButton.menuMoreButton.length; i++) {
                                    append({
                                            "menuAction": listViewMoreButton.menuMoreButton[i]
                                        });
                                }
                            }
                        }

                        model: SortFilterProxyModel {
                            sourceModel: listMoreButton
                            filters: [
                                ExpressionFilter {
                                    expression: menuAction.show === true
                                    enabled: showDefault
                                },
                                ExpressionFilter {
                                    expression: menuAction.needWebEngine === false
                                    enabled: !WITH_WEBENGINE
                                },
                                ExpressionFilter {
                                    expression: menuAction.noSip === true
                                    enabled: CurrentConversation.isSip
                                },
                                ExpressionFilter {
                                    expression: menuAction.needVideoDevice === false
                                    enabled: VideoDevices.listSize === 0
                                }
                            ]
                        }

                        delegate: PushButton {
                            id: buttonDelegateMoreButton
                            anchors.verticalCenter: parent ? parent.verticalCenter : undefined
                            preferredSize: JamiTheme.chatViewFooterRealButtonSize
                            imageContainerWidth: 20
                            imageContainerHeight: 20
                            radius: 5

                            toolTipText: modelData.toolTip
                            source: modelData.iconSrc

                            normalColor: JamiTheme.chatViewFooterListColor
                            imageColor: JamiTheme.chatViewFooterImgHoverColor
                            hoveredColor: JamiTheme.hoveredButtonColor
                            pressedColor: hoveredColor

                            action: modelData
                        }
                    }
                }
            }

            Rectangle {
                color: JamiTheme.transparentColor
                visible: showTypo
                height: 50
                width: previewButton.width + marginSize
                Layout.row: showTypo ? 0 : 0
                Layout.column: showTypo ? 1 : 1

                PushButton {
                    id: previewButton
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: parent.right
                    anchors.rightMargin: marginSize
                    preferredSize: JamiTheme.chatViewFooterButtonSize
                    imageContainerWidth: 25
                    imageContainerHeight: 25
                    radius: 5
                    source: JamiResources.preview_black_24dp_svg
                    normalColor: showPreview ? hoveredColor : JamiTheme.primaryBackgroundColor
                    imageColor: (hovered || showPreview) ? JamiTheme.chatViewFooterImgHoverColor : JamiTheme.chatViewFooterImgColor
                    hoveredColor: JamiTheme.hoveredButtonColor
                    pressedColor: hoveredColor
                    toolTipText: showPreview ? JamiStrings.continueEditing : JamiStrings.showPreview

                    onClicked: {
                        showPreview = !showPreview;
                        messageBarTextArea.showPreview = showPreview;
                    }
                }
            }
        }
    }

    Rectangle {
        Layout.preferredHeight: parent.height
        Layout.preferredWidth: childrenRect.width
        visible: sendButtonVisibility
        color: JamiTheme.transparentColor
        PushButton {
            id: sendMessageButton

            objectName: "sendMessageButton"
            anchors.bottom: parent.bottom
            anchors.bottomMargin: marginSize / 2

            enabled: sendButtonVisibility
            hoverEnabled: enabled

            width: scale * JamiTheme.chatViewFooterButtonSize
            height: JamiTheme.chatViewFooterButtonSize

            radius: JamiTheme.chatViewFooterButtonRadius
            preferredSize: JamiTheme.chatViewFooterButtonIconSize - 6
            imageContainerWidth: 25
            imageContainerHeight: 25

            toolTipText: JamiStrings.send

            mirror: UtilsAdapter.isRTL

            source: JamiResources.send_black_24dp_svg

            normalColor: enabled ? JamiTheme.chatViewFooterSendButtonColor : JamiTheme.chatViewFooterSendButtonDisableColor
            imageColor: enabled ? JamiTheme.chatViewFooterSendButtonImgColor : JamiTheme.chatViewFooterSendButtonImgColorDisable
            hoveredColor: JamiTheme.buttonTintedBlueHovered
            pressedColor: hoveredColor

            opacity: 1
            scale: opacity

            Behavior on opacity  {
                enabled: animate
                NumberAnimation {
                    duration: JamiTheme.shortFadeDuration
                    easing.type: Easing.InOutQuad
                }
            }

            onClicked: {
                root.showPreview = false;
                sendMessageButtonClicked();
            }
        }
    }
}
